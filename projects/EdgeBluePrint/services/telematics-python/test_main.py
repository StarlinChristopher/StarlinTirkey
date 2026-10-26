import importlib.util
import json
import sys
from pathlib import Path
from unittest.mock import patch

MODULE_PATH = Path(__file__).with_name('main.py')
spec = importlib.util.spec_from_file_location('fleetcue_main', MODULE_PATH)
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)


def test_retention_removes_oldest_files(tmp_path):
    app.BUFFER_PATH = tmp_path
    app.MAX_BUFFER_FILES = 2
    for index in range(3):
        path = tmp_path / f'telematics_{index}.json'
        path.write_text(json.dumps({'sensorId': 'x', 'temperature': index}), encoding='utf-8')
        path.touch()
    app.enforce_retention()
    assert len(app.buffer_files()) == 2
    assert not (tmp_path / 'telematics_0.json').exists()


def test_invalid_payload_is_discarded(tmp_path):
    app.BUFFER_PATH = tmp_path
    path = tmp_path / 'telematics_invalid.json'
    path.write_text('{not-json', encoding='utf-8')
    with patch.object(app, 'try_upload') as upload:
        assert app.drain_buffer() == 0
        upload.assert_not_called()
    assert not path.exists()


def test_retryable_upload_stays_buffered(tmp_path):
    app.BUFFER_PATH = tmp_path
    path = tmp_path / 'telematics_retry.json'
    path.write_text(json.dumps({'sensorId': 'x', 'temperature': 1}), encoding='utf-8')
    with patch.object(app, 'try_upload', return_value=False):
        assert app.drain_buffer() == 0
    assert path.exists()


def test_successful_upload_drains_buffer(tmp_path):
    app.BUFFER_PATH = tmp_path
    path = tmp_path / 'telematics_success.json'
    path.write_text(json.dumps({'sensorId': 'x', 'temperature': 1}), encoding='utf-8')
    with patch.object(app, 'try_upload', return_value=True):
        assert app.drain_buffer() == 1
    assert not path.exists()


def test_upload_recovery_after_transient_failure():
    payload = {'sensorId': 'x', 'temperature': 1}
    with patch.object(app, 'upload', side_effect=[OSError('database or network unavailable'), None]) as upload:
        assert app.try_upload(payload) is False
        assert app.try_upload(payload) is True
        assert upload.call_count == 2
