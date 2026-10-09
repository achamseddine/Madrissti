import hashlib
import hmac
import json
import os
import secrets
import time
from pathlib import Path
from uuid import uuid4
from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, ConfigDict, Field
from .store import LearningSession, make_store
from .math_tools import FractionBars

CONTENT = Path(__file__).resolve().parents[2] / "content"

class Strict(BaseModel):
    model_config = ConfigDict(extra="forbid")

class Auth(Strict):
    access_code: str = Field(min_length=1, max_length=256)

class Selection(Strict):
    lesson_id: str
    content_version: str
    selected_block_id: str
    language: str = "ar"
    mode: str = "text"
    preferences: dict[str, bool] = Field(default_factory=dict)

class Context(Selection):
    previous_revision: int = Field(ge=1)

class RenderRequest(FractionBars):
    context_revision: int = Field(ge=1)

def create_app(database_url=None, access_code=None):
    app = FastAPI(title="Madrissti educational prototype", version="0.1.0")
    store = make_store(database_url or os.getenv("TUTOR_DATABASE_URL", "sqlite:///./tutor.db"))
    tokens = {}
    failures = {}
    bearer = HTTPBearer(auto_error=False)
    lessons = {p.stem: json.loads(p.read_text()) for p in (CONTENT / "lessons").glob("*.json")}

    @app.exception_handler(HTTPException)
    async def error(request: Request, exc: HTTPException):
        return JSONResponse(status_code=exc.status_code, content={"code": str(exc.status_code), "message": str(exc.detail), "retryable": exc.status_code == 503, "request_id": str(uuid4())})

    @app.exception_handler(RequestValidationError)
    async def invalid(request: Request, exc: RequestValidationError):
        return JSONResponse(status_code=422, content={"code": "validation_error", "message": "Request does not match the API schema", "retryable": False, "request_id": str(uuid4())})

    def identity(credentials: HTTPAuthorizationCredentials = Depends(bearer)):
        token = tokens.get(credentials.credentials) if credentials else None
        if not token or token[1] < time.time():
            raise HTTPException(401, "Authentication required")
        return token[0]

    def selection(data):
        lesson = lessons.get(data.lesson_id)
        if not lesson or data.content_version != lesson["content_version"] or data.selected_block_id not in [b["block_id"] for b in lesson["blocks"]]:
            raise HTTPException(422, "Unknown lesson, block or version")
        if data.language != "ar" or data.mode != "text":
            raise HTTPException(422, "Only Arabic text foundation is available")

    def owned(db, sid, owner, active=True):
        s = db.get(LearningSession, sid)
        if not s or s.owner != owner:
            raise HTTPException(404, "Session not found")
        if active and s.ended:
            raise HTTPException(409, "Session ended")
        return s

    @app.get("/health")
    def health():
        return {"status": "ok", "live_ai": False, "voice": False}

    @app.post("/v1/demo/auth")
    def auth(data: Auth, request: Request):
        key = request.client.host if request.client else "local"
        recent = [t for t in failures.get(key, []) if time.time() - t < 60]
        if len(recent) >= 5:
            raise HTTPException(429, "Try again later")
        code = access_code if access_code is not None else os.getenv("DEMO_ACCESS_CODE")
        if not code:
            raise HTTPException(503, "Demo access code is not configured")
        if not hmac.compare_digest(data.access_code.encode(), code.encode()):
            failures[key] = recent + [time.time()]
            raise HTTPException(401, "Invalid access code")
        token = secrets.token_urlsafe(32)
        owner = hashlib.sha256(token.encode()).hexdigest()
        tokens[token] = (owner, time.time() + 900)
        return {"access_token": token, "token_type": "bearer", "expires_in": 900}

    @app.get("/v1/courses")
    def courses(owner=Depends(identity)):
        return [json.loads((CONTENT / "manifest.json").read_text())]

    @app.get("/v1/courses/{course_id}/lessons")
    def catalogue(course_id: str, owner=Depends(identity)):
        if course_id != "grade4-maths":
            raise HTTPException(404, "Course not found")
        return list(lessons.values())

    @app.get("/v1/lessons/{lesson_id}")
    def lesson(lesson_id: str, owner=Depends(identity)):
        if lesson_id not in lessons:
            raise HTTPException(404, "Lesson not found")
        return lessons[lesson_id]

    @app.post("/v1/sessions")
    def start(data: Selection, owner=Depends(identity)):
        selection(data)
        with store() as db:
            s = LearningSession(id=str(uuid4()), owner=owner, lesson_id=data.lesson_id, content_version=data.content_version, selected_block_id=data.selected_block_id, preferences=data.preferences)
            db.add(s)
            db.commit()
            return {"session_id": s.id, "context_revision": s.revision, "transport_capabilities": {"live_ai": False, "voice": False}}

    @app.post("/v1/sessions/{sid}/context")
    def context(sid: str, data: Context, owner=Depends(identity)):
        selection(data)
        with store() as db:
            s = owned(db, sid, owner)
            if s.revision != data.previous_revision:
                raise HTTPException(409, "Stale context revision")
            s.lesson_id, s.content_version = data.lesson_id, data.content_version
            s.selected_block_id = data.selected_block_id
            s.preferences = data.preferences
            s.revision += 1
            db.commit()
            return {"context_revision": s.revision}

    @app.post("/v1/sessions/{sid}/workspace/fraction-bars")
    def render(sid: str, data: RenderRequest, owner=Depends(identity)):
        with store() as db:
            s = owned(db, sid, owner)
            if s.revision != data.context_revision:
                raise HTTPException(409, "Stale context revision")
            if "fraction_bars" not in lessons[s.lesson_id]["approved_representations"]:
                raise HTTPException(422, "Representation not approved for lesson")
            return FractionBars(whole_id=data.whole_id, values=data.values).render()

    @app.post("/v1/sessions/{sid}/realtime")
    def realtime(sid: str, owner=Depends(identity)):
        with store() as db:
            owned(db, sid, owner)
        raise HTTPException(503, "Live provider transport is not implemented; no simulated response is supplied")

    @app.get("/v1/sessions/{sid}/summary")
    def summary(sid: str, owner=Depends(identity)):
        with store() as db:
            s = owned(db, sid, owner, active=False)
            return {"lesson_id": s.lesson_id, "context_revision": s.revision, "evidence_level": "insufficient_evidence", "attempts": [], "ended": s.ended}

    @app.post("/v1/sessions/{sid}/end")
    def end(sid: str, owner=Depends(identity)):
        with store() as db:
            s = owned(db, sid, owner, active=False)
            s.ended = True
            db.commit()
        return {"ended": True}

    @app.delete("/v1/sessions/{sid}")
    def delete(sid: str, owner=Depends(identity)):
        with store() as db:
            s = owned(db, sid, owner, active=False)
            db.delete(s)
            db.commit()
        return {"deleted": True}

    return app
