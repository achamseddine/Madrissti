import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError
from tutor.main import create_app
from tutor.math_tools import Rational, FractionBars, equivalent

@pytest.fixture
def client(tmp_path):
    return TestClient(create_app(f'sqlite:///{tmp_path}/test.db', access_code='test-only-code'))

def token(client):
    result = client.post('/v1/demo/auth', json={'access_code': 'test-only-code'})
    assert result.status_code == 200
    return {'Authorization': 'Bearer ' + result.json()['access_token']}

def selection(id='equal-parts'):
    return dict(lesson_id=id, content_version='1.0.0', selected_block_id='intro')

def start(client, headers):
    result = client.post('/v1/sessions', headers=headers, json=selection())
    assert result.status_code == 200
    return result.json()['session_id']

def test_auth_and_catalogue(client):
    assert client.get('/v1/courses').status_code == 401
    h = token(client)
    assert len(client.get('/v1/courses/grade4-maths/lessons', headers=h).json()) == 3

def test_rate_limit(client):
    for _ in range(5):
        assert client.post('/v1/demo/auth', json={'access_code': 'wrong'}).status_code == 401
    assert client.post('/v1/demo/auth', json={'access_code': 'wrong'}).status_code == 429

@pytest.mark.parametrize('change', [{'lesson_id':'missing'}, {'content_version':'old'}, {'selected_block_id':'missing'}])
def test_context_validation(client, change):
    assert client.post('/v1/sessions', headers=token(client), json=selection() | change).status_code == 422

def test_ownership(client):
    h = token(client)
    sid = start(client, h)
    assert client.get(f'/v1/sessions/{sid}/summary', headers=token(client)).status_code == 404

def test_revision_and_representations(client):
    h = token(client)
    sid = start(client, h)
    route = f'/v1/sessions/{sid}/workspace/fraction-bars'
    render = {'context_revision': 1, 'whole_id':'same', 'values':[{'numerator':1,'denominator':2}]}
    assert client.post(route, headers=h, json=render).status_code == 200
    update = selection('equal-sharing') | {'previous_revision':1}
    assert client.post(f'/v1/sessions/{sid}/context', headers=h, json=update).json()['context_revision'] == 2
    assert client.post(f'/v1/sessions/{sid}/context', headers=h, json=update).status_code == 409
    assert client.post(route, headers=h, json=render).status_code == 409
    assert client.post(route, headers=h, json=render | {'context_revision':2}).status_code == 422

def test_end_delete_and_provider_unavailable(client):
    h = token(client)
    sid = start(client, h)
    assert client.post(f'/v1/sessions/{sid}/realtime', headers=h).status_code == 503
    assert client.get(f'/v1/sessions/{sid}/summary', headers=h).json()['evidence_level'] == 'insufficient_evidence'
    assert client.post(f'/v1/sessions/{sid}/end', headers=h).status_code == 200
    assert client.post(f'/v1/sessions/{sid}/realtime', headers=h).status_code == 409
    assert client.delete(f'/v1/sessions/{sid}', headers=h).status_code == 200
    assert client.get(f'/v1/sessions/{sid}/summary', headers=h).status_code == 404

@pytest.mark.parametrize('data', [{'numerator':1,'denominator':0}, {'numerator':3,'denominator':2}, {'numerator':True,'denominator':2}, {'numerator':1,'denominator':13}, {'numerator':1,'denominator':2,'script':'bad'}])
def test_invalid_fractions(data):
    with pytest.raises(ValidationError): Rational(**data)

def test_exact_math_and_tool_limits():
    assert equivalent('2/4', '1/2')
    assert not equivalent('1/4', '1/2')
    with pytest.raises(ValueError): equivalent('1/0', '1/2')
    with pytest.raises(ValidationError): FractionBars(whole_id='whole', values=[Rational(numerator=1, denominator=2)] * 5)
