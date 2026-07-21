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
        expect(
            self.page.get_by_role(
                "group", name=re.compile(re.escape(self.identity.cv_title))
            ).first
        ).to_be_visible(timeout=30_000)
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
        candidate = self.page.get_by_label(label, exact=True).or_(
            self.page.get_by_role("textbox", name=label, exact=True)
        )
        target = candidate.first
        expect(target).to_be_visible()
        return target

    def _textbox(self, index: int) -> Locator:
        target = self.page.get_by_role("textbox").nth(index)
        expect(target).to_be_visible()
        return target

    def _fill(self, target: Locator, value: str) -> Locator:
        for attempt in range(2):
            focused = self._prepare_input(target)
            self.page.keyboard.type(value, delay=15)
            try:
                expect(focused).to_have_value(value, timeout=3_000)
                self.page.wait_for_timeout(100)
                return focused
            except AssertionError:
                if attempt == 1:
                    raise
                self.page.keyboard.press("Tab")
                self.page.wait_for_timeout(250)
        raise AssertionError(f"Unable to fill field with {value!r}")

    def _select_suggestion(self, label: str, value: str) -> None:
        target = self._field(label)
        focused = self._prepare_input(target)
        self.page.keyboard.insert_text(value)
        expect(focused).to_have_value(value)
        self.page.keyboard.press("ArrowDown")
        self.page.keyboard.press("Enter")
        expect(self._field(label)).to_have_value(value)

    def _prepare_input(self, target: Locator) -> Locator:
        target.click()
        focused = self.page.locator("input:focus, textarea:focus")
        expect(focused).to_be_attached()
        self.page.keyboard.press("ControlOrMeta+A")
        self.page.keyboard.press("Backspace")
        return focused

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
