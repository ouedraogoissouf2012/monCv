"""HTTP assertions and cleanup for the production browser smoke flow."""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from collections.abc import Callable
from typing import Any
from urllib.parse import quote

ResponseOpener = Callable[..., Any]


class SmokeApiError(RuntimeError):
    """Raised when the smoke API contract is not respected."""


class SmokeApi:
    def __init__(
        self,
        base_url: str,
        *,
        timeout: float = 30,
        opener: ResponseOpener = urllib.request.urlopen,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self._open = opener

    def login(self, email: str, password: str) -> str:
        payload = self.json(
            "POST",
            "/auth/login",
            data={"email": email, "password": password},
            expected={200},
        )
        token = payload.get("accessToken")
        if not isinstance(token, str) or not token:
            raise SmokeApiError("The login response has no access token")
        return token

    def find_cv(self, title: str, token: str) -> dict[str, Any]:
        payload = self.json("GET", "/cvs", token=token, expected={200})
        if not isinstance(payload, list):
            raise SmokeApiError("GET /cvs did not return a list")
        for item in payload:
            if isinstance(item, dict) and item.get("titre") == title:
                return item
        raise SmokeApiError(f"Created CV not found: {title}")

    def assert_exports(self, cv_id: int, token: str) -> None:
        for extension in ("pdf", "docx"):
            body = self.bytes(
                "GET",
                f"/cvs/{cv_id}/{extension}",
                token=token,
                expected={200},
            )
            if len(body) <= 1000:
                raise SmokeApiError(
                    f"The {extension.upper()} export is unexpectedly small"
                )

    def assert_public_share(self, cv_id: int, title: str, token: str) -> None:
        shared = self.json(
            "POST", f"/cvs/{cv_id}/share", token=token, expected={200, 201}
        )
        public_token = shared.get("publicToken")
        if not isinstance(public_token, str) or not public_token:
            raise SmokeApiError("The public share response has no token")
        public_cv = self.json(
            "GET", f"/cvs/public/{quote(public_token, safe='')}", expected={200}
        )
        if public_cv.get("titre") != title:
            raise SmokeApiError("The public CV does not match the created CV")

    def duplicate(self, cv_id: int, token: str) -> int:
        payload = self.json(
            "POST", f"/cvs/{cv_id}/duplicate", token=token, expected={200, 201}
        )
        duplicate_id = payload.get("id")
        if not isinstance(duplicate_id, int):
            raise SmokeApiError("The duplicate response has no integer id")
        if not str(payload.get("titre", "")).startswith("Copie de"):
            raise SmokeApiError("The duplicate title is invalid")
        return duplicate_id

    def wait_for_style(self, cv_id: int, token: str) -> None:
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            payload = self.json("GET", f"/cvs/{cv_id}", token=token, expected={200})
            style = payload.get("style")
            if isinstance(style, dict) and (
                style.get("templateId"),
                style.get("fontFamily"),
            ) == ("classique", "Lato"):
                return
            time.sleep(0.25)
        raise SmokeApiError("CV style was not persisted before the timeout")

    def delete_cv(self, cv_id: int, token: str) -> None:
        self.bytes("DELETE", f"/cvs/{cv_id}", token=token, expected={204})

    def json(
        self,
        method: str,
        path: str,
        *,
        token: str | None = None,
        data: dict[str, Any] | None = None,
        expected: set[int],
    ) -> Any:
        body = self.bytes(method, path, token=token, data=data, expected=expected)
        try:
            return json.loads(body)
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise SmokeApiError(f"Invalid JSON returned by {method} {path}") from error

    def bytes(
        self,
        method: str,
        path: str,
        *,
        token: str | None = None,
        data: dict[str, Any] | None = None,
        expected: set[int],
    ) -> bytes:
        headers = {"Accept": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        encoded = None
        if data is not None:
            encoded = json.dumps(data).encode("utf-8")
            headers["Content-Type"] = "application/json"
        request = urllib.request.Request(
            f"{self.base_url}/{path.lstrip('/')}",
            data=encoded,
            headers=headers,
            method=method,
        )
        try:
            with self._open(request, timeout=self.timeout) as response:
                status = int(response.status)
                body = response.read()
        except urllib.error.HTTPError as error:
            status = error.code
            body = error.read()
        except (OSError, urllib.error.URLError) as error:
            raise SmokeApiError(f"Unable to call {method} {path}: {error}") from error
        if status not in expected:
            detail = body.decode("utf-8", errors="replace")[:300]
            raise SmokeApiError(f"HTTP {status} for {method} {path}: {detail}")
        return body
