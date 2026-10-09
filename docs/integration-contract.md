# Future Madristi adapter — unconnected

LessonContextProvider supplies getCurrentContext and subscribeToContextChanges. ContentRepository supplies getLessonVersion. ProgressSink submits objective evidence. Future implementation must verify signed learner/course/lesson/version/objective context, audience and expiry with the operator. Current prototype only reads its own original lesson files. No Madristi identity, export or writeback interface is known or connected.

SQLite storage can move to PostgreSQL through SQLAlchemy; schema migrations, durable authenticated identities and access controls require implementation before any deployment beyond a local adult development demonstration.
