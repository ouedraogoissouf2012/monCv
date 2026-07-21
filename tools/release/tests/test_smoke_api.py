from __future__ import annotations

import io
import unittest
from unittest.mock import Mock

from tools.release.smoke_api import SmokeApi, SmokeApiError


class FakeResponse:
    def __init__(self, status: int, body: bytes) -> None:
        self.status = status
        self._body = io.BytesIO(body)

    def __enter__(self) -> "FakeResponse":
        return self

    def __exit__(self, *_: object) -> None:
        return None

    def read(self) -> bytes:
        return self._body.read()


class SmokeApiTest(unittest.TestCase):
    def test_login_returns_access_token_without_exposing_refresh_token(self) -> None:
        opener = Mock(return_value=FakeResponse(200, b'{"accessToken":"safe"}'))
        api = SmokeApi("http://localhost/api", opener=opener)

        self.assertEqual(api.login("user@example.com", "secret"), "safe")
        request = opener.call_args.args[0]
        self.assertEqual(request.full_url, "http://localhost/api/auth/login")
        self.assertEqual(request.get_method(), "POST")

    def test_login_rejects_missing_access_token(self) -> None:
        api = SmokeApi(
            "http://localhost/api",
            opener=Mock(return_value=FakeResponse(200, b'{"refreshToken":"x"}')),
        )

        with self.assertRaisesRegex(SmokeApiError, "no access token"):
            api.login("user@example.com", "secret")

    def test_json_rejects_malformed_payload(self) -> None:
        api = SmokeApi(
            "http://localhost/api",
            opener=Mock(return_value=FakeResponse(200, b"not-json")),
        )

        with self.assertRaisesRegex(SmokeApiError, "Invalid JSON"):
            api.json("GET", "/cvs", expected={200})

    def test_bytes_rejects_unexpected_status_with_bounded_detail(self) -> None:
        body = b"x" * 500
        api = SmokeApi(
            "http://localhost/api",
            opener=Mock(return_value=FakeResponse(500, body)),
        )

        with self.assertRaises(SmokeApiError) as raised:
            api.bytes("GET", "/cvs", expected={200})
        self.assertLess(len(str(raised.exception)), 380)

    def test_find_cv_rejects_non_list_response(self) -> None:
        api = SmokeApi(
            "http://localhost/api",
            opener=Mock(return_value=FakeResponse(200, b"{}")),
        )

        with self.assertRaisesRegex(SmokeApiError, "did not return a list"):
            api.find_cv("Title", "token")


if __name__ == "__main__":
    unittest.main()
