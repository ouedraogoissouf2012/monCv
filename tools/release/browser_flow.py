"""Playwright page object for the end-to-end CV creation smoke flow."""

from __future__ import annotations

import secrets
import time
import re
from dataclasses import dataclass

from playwright.sync_api import Locator, Page, expect

from .smoke_api import SmokeApi


@dataclass(frozen=True)
class SmokeIdentity:
    email: str
    password: str = "Test1234!"
    first_name: str = "Smoke"
    last_name: str = "Codex"
    cv_title: str = "Architecte QA Web"

    @classmethod
    def unique(cls) -> "SmokeIdentity":
        suffix = f"{time.time_ns()}.{secrets.token_hex(3)}"
        return cls(email=f"smoke.{suffix}@example.com")


class BrowserSmokeFlow:
    def __init__(self, page: Page, api: SmokeApi) -> None:
        self.page = page
        self.api = api
        self.identity = SmokeIdentity.unique()
        self.token: str | None = None
        self.cv_id: int | None = None
        self.duplicate_id: int | None = None

    def run(self, base_url: str) -> None:
        try:
            self._register(base_url)
            self.token = self.api.login(self.identity.email, self.identity.password)
            self._create_cv()
            created = self.api.find_cv(self.identity.cv_title, self.token)
            self._assert_location(created)
            self.cv_id = self._integer_id(created, "created CV")
            self._verify_detail_and_api()
            self._customize()
            print("[browser-smoke] Complete CV flow passed", flush=True)
        except BaseException:
            self._cleanup(suppress_errors=True)
            raise
        else:
            self._cleanup(suppress_errors=False)

    def _register(self, base_url: str) -> None:
        self.page.goto(
            f"{base_url.rstrip('/')}/#/landing", wait_until="domcontentloaded"
        )
        self._enable_flutter_semantics()
        self._click("Créer mon CV gratuitement")
        self._visible_text("Créer mon compte")
        for index, value in enumerate(
            (
                self.identity.first_name,
                self.identity.last_name,
                self.identity.email,
                self.identity.password,
                self.identity.password,
            )
        ):
            self._fill(self._textbox(index), value)
        self._click("Créer mon compte")
        self._visible_text("Mes CVs", timeout=30_000)
        print("[browser-smoke] Registration passed", flush=True)

    def _create_cv(self) -> None:
        self._click("Nouveau CV")
        self._visible_text("Nouveau CV")
        for label, value in (
            ("Prénom *", self.identity.first_name),
            ("Nom *", self.identity.last_name),
            ("Titre du poste", self.identity.cv_title),
            ("Email *", self.identity.email),
            ("Téléphone", "+2250700000000"),
        ):
            self._fill(self._field(label), value)
        self._select_suggestion("Pays", "Côte d'Ivoire")
        self._select_suggestion("Ville", "Abidjan")
        summary = "Profil QA cree par le smoke E2E web du parcours CV complet."
        self._fill(self._field("Resume professionnel"), summary)
        for label, value in (
            ("Prénom *", self.identity.first_name),
            ("Nom *", self.identity.last_name),
            ("Email *", self.identity.email),
            ("Resume professionnel", summary),
        ):
            expect(self._field(label)).to_have_value(value)
        expect(
            self.page.get_by_text(re.compile(r"Complétion : [1-9]\d?%"), exact=False)
        ).to_be_visible()
        for _ in range(4):
            self._click("Suivant")
        self._click("Enregistrer le CV")
        title = re.compile(re.escape(self.identity.cv_title))
        card_marker = self.page.get_by_text(
            self.identity.cv_title, exact=True
        ).or_(self.page.get_by_role("progressbar", name=title))
        expect(card_marker.first).to_be_visible(timeout=30_000)
        print("[browser-smoke] CV creation passed", flush=True)

    def _verify_detail_and_api(self) -> None:
        assert self.cv_id is not None and self.token is not None
        self._click("Voir")
        expect(self._button("Personnaliser")).to_be_visible()
        self.api.assert_exports(self.cv_id, self.token)
        self.api.assert_public_share(self.cv_id, self.identity.cv_title, self.token)
        self.duplicate_id = self.api.duplicate(self.cv_id, self.token)
        self.api.delete_cv(self.duplicate_id, self.token)
        self.duplicate_id = None
        print("[browser-smoke] Exports, share and duplicate passed", flush=True)

    def _customize(self) -> None:
        assert self.cv_id is not None and self.token is not None
        self._button("Personnaliser").click()
        self._visible_text("Personnaliser le CV")
        self._click("Classique")
        self._click("Lato")
        self.api.wait_for_style(self.cv_id, self.token)
        print("[browser-smoke] Theme persistence passed", flush=True)

    def _cleanup(self, *, suppress_errors: bool) -> None:
        if self.token is None:
            return
        errors: list[Exception] = []
        for cv_id in (self.duplicate_id, self.cv_id):
            if cv_id is None:
                continue
            try:
                self.api.delete_cv(cv_id, self.token)
            except Exception as error:
                errors.append(error)
                print(f"[browser-smoke] Cleanup warning for CV {cv_id}: {error}")
        if errors and not suppress_errors:
            raise RuntimeError("Browser smoke cleanup failed") from errors[0]

    def _enable_flutter_semantics(self) -> None:
        placeholder = self.page.locator("flt-semantics-placeholder")
        expect(placeholder).to_be_attached(timeout=30_000)
        placeholder.evaluate("element => element.click()")
        expect(self.page.locator("flt-semantics").first).to_be_attached()

    def _field(self, label: str) -> Locator:
        label_pattern = re.compile(rf"^{re.escape(label)}(?:\n|$)")
        candidate = self.page.get_by_label(label_pattern).or_(
            self.page.get_by_role("textbox", name=label_pattern)
        )
        target = candidate.first
        expect(target).to_be_visible()
        return target

    def _textbox(self, index: int) -> Locator:
        target = self.page.get_by_role("textbox").nth(index)
        expect(target).to_be_visible()
        return target

    def _fill(self, target: Locator, value: str) -> Locator:
        target.scroll_into_view_if_needed()
        self.page.wait_for_timeout(100)
        for attempt in range(2):
            target.fill(value)
            try:
                expect(target).to_have_value(value, timeout=3_000)
                self.page.wait_for_timeout(100)
                return target
            except AssertionError:
                if attempt == 1:
                    raise
                self.page.wait_for_timeout(250)
        raise AssertionError(f"Unable to fill field with {value!r}")

    def _select_suggestion(self, label: str, value: str) -> None:
        # Reuse the retrying _fill primitive: the Flutter Autocomplete field
        # keeps an internal controller that re-syncs on rebuild, so a bare
        # fill + immediate assertion is racy and fails intermittently.
        target = self._fill(self._field(label), value)

        option = self.page.get_by_text(value, exact=True)
        if option.count() and option.first.is_visible():
            option.first.click()
        else:
            focused = self.page.locator("input:focus, textarea:focus")
            focused_label = (
                focused.first.get_attribute("aria-label")
                if focused.count()
                else None
            )
            if focused_label == label:
                self.page.keyboard.press("ArrowDown")
                self.page.keyboard.press("Enter")
        expect(self._field(label)).to_have_value(value)

    def _button(self, label: str) -> Locator:
        target = self.page.get_by_role("button", name=label, exact=True).first
        expect(target).to_be_visible()
        return target

    def _click(self, label: str) -> None:
        button = self.page.get_by_role("button", name=label, exact=False)
        text = self.page.get_by_text(label, exact=True)
        target = button.or_(text).first
        expect(target).to_be_visible()
        target.click()

    def _visible_text(
        self, value: str, *, timeout: float = 20_000, exact: bool = True
    ) -> None:
        expect(self.page.get_by_text(value, exact=exact).first).to_be_visible(
            timeout=timeout
        )

    @staticmethod
    def _integer_id(payload: dict[str, object], label: str) -> int:
        identifier = payload.get("id")
        if not isinstance(identifier, int):
            raise RuntimeError(f"The {label} has no integer id")
        return identifier

    @staticmethod
    def _assert_location(payload: dict[str, object]) -> None:
        personal_info = payload.get("personalInfo")
        if not isinstance(personal_info, dict):
            raise RuntimeError("The created CV has no personal information")
        actual = (personal_info.get("pays"), personal_info.get("ville"))
        expected = ("Côte d'Ivoire", "Abidjan")
        if actual != expected:
            raise RuntimeError(
                f"The created CV location is invalid: expected {expected}, got {actual}"
            )
