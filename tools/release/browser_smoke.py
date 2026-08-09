"""Run the production browser smoke flow and retain failure diagnostics."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from urllib.parse import urlparse

from playwright.sync_api import BrowserType, ConsoleMessage, Page, Request
from playwright.sync_api import Error as PlaywrightError
from playwright.sync_api import sync_playwright

from .browser_flow import BrowserSmokeFlow
from .smoke_api import SmokeApi


# Message console generique du navigateur lorsqu'un sous-chargement renvoie 401 :
# bruit transitoire et non deterministe (ex. poll /api/ai/status avant obtention
# du jeton, ou rafraichissement post-logout). Les scenarios fonctionnels valident
# deja que l'authentification marche, donc ce message n'est pas bloquant (#348).
_TRANSIENT_CONSOLE_NOISE = (
    "Failed to load resource: the server responded with a status of 401",
)


def _describe_console(message: ConsoleMessage, text: str) -> str:
    """Annexe l'URL de la ressource fautive quand Playwright la fournit (#348)."""
    location = getattr(message, "location", None)
    url = location.get("url") if isinstance(location, dict) else None
    return f"{text} ({url})" if url else text


class BrowserDiagnostics:
    def __init__(self, application_origin: str) -> None:
        self.application_origin = application_origin
        self.console_errors: list[str] = []
        self.page_errors: list[str] = []
        self.failed_requests: list[str] = []

    def attach(self, page: Page) -> None:
        page.on("console", self._on_console)
        page.on("pageerror", lambda error: self.page_errors.append(str(error)))
        page.on("requestfailed", self._on_request_failed)

    def assert_clean(self) -> None:
        failures = [
            *(f"console: {item}" for item in self.console_errors),
            *(f"page: {item}" for item in self.page_errors),
            *(f"request: {item}" for item in self.failed_requests),
        ]
        if failures:
            raise RuntimeError("Browser errors detected:\n" + "\n".join(failures[:20]))

    def as_dict(self) -> dict[str, list[str]]:
        return {
            "consoleErrors": self.console_errors,
            "pageErrors": self.page_errors,
            "failedRequests": self.failed_requests,
        }

    def _on_console(self, message: ConsoleMessage) -> None:
        if message.type != "error":
            return
        text = message.text
        if any(noise in text for noise in _TRANSIENT_CONSOLE_NOISE):
            return
        self.console_errors.append(_describe_console(message, text))

    def _on_request_failed(self, request: Request) -> None:
        parsed = urlparse(request.url)
        origin = f"{parsed.scheme}://{parsed.netloc}"
        if origin != self.application_origin:
            return
        failure = request.failure or "unknown failure"
        if "ERR_ABORTED" not in failure:
            self.failed_requests.append(f"{request.method} {request.url}: {failure}")


def _launch(browser_type: BrowserType, *, headed: bool):
    executable = os.environ.get("CHROME_EXECUTABLE")
    options: dict[str, object] = {
        "headless": not headed,
        "args": ["--disable-dev-shm-usage"],
    }
    if executable:
        options["executable_path"] = executable
    else:
        options["channel"] = os.environ.get("PLAYWRIGHT_CHANNEL", "chrome")
    try:
        return browser_type.launch(**options)
    except PlaywrightError as error:
        raise RuntimeError(
            "Chrome could not be started. Install Chrome or set CHROME_EXECUTABLE."
        ) from error


def run(base_url: str, api_base_url: str, artifacts: Path, *, headed: bool) -> None:
    artifacts.mkdir(parents=True, exist_ok=True)
    origin = f"{urlparse(base_url).scheme}://{urlparse(base_url).netloc}"
    diagnostics = BrowserDiagnostics(origin)
    with sync_playwright() as playwright:
        browser = _launch(playwright.chromium, headed=headed)
        context = browser.new_context(
            locale="fr-FR",
            viewport={"width": 430, "height": 900},
            device_scale_factor=1,
            reduced_motion="reduce",
            service_workers="block",
        )
        context.tracing.start(screenshots=True, snapshots=True, sources=True)
        page = context.new_page()
        page.set_default_timeout(20_000)
        page.set_default_navigation_timeout(30_000)
        diagnostics.attach(page)
        try:
            BrowserSmokeFlow(page, SmokeApi(api_base_url)).run(base_url)
            diagnostics.assert_clean()
        except BaseException:
            page.screenshot(path=artifacts / "failure.png", full_page=True)
            (artifacts / "diagnostics.json").write_text(
                json.dumps(diagnostics.as_dict(), indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
            context.tracing.stop(path=artifacts / "trace.zip")
            raise
        else:
            context.tracing.stop()
        finally:
            context.close()
            browser.close()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--api-base-url")
    parser.add_argument(
        "--artifacts", type=Path, default=Path(".release/browser-smoke")
    )
    parser.add_argument("--headed", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    api_base_url = args.api_base_url or f"{args.base_url.rstrip('/')}/api"
    run(args.base_url, api_base_url, args.artifacts, headed=args.headed)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
