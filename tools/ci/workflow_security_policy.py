"""Declarative trust policy for GitHub Actions workflows."""

from pathlib import Path

WORKFLOW_DIR = Path(".github/workflows")
READ_ONLY = {"contents": "read"}

PRIVILEGED_PERMISSIONS = {
    ("ci-reports.yml", "backend-codecov"): {
        "actions": "read",
        "contents": "read",
        "id-token": "write",
    },
    ("ci-reports.yml", "frontend-codecov"): {
        "actions": "read",
        "contents": "read",
        "id-token": "write",
    },
    ("ci-reports.yml", "flutter-coverage-comment"): {
        "actions": "read",
        "contents": "read",
        "pull-requests": "write",
    },
    ("publish.yml", "docker-publish"): {
        "actions": "read",
        "contents": "read",
        "packages": "write",
    },
}

REQUIRED_JOBS = {
    "ci.yml": {
        "source-policy",
        "backend",
        "frontend",
        "web-smoke",
        "docker-verify",
        "build-apk",
    },
    "ci-reports.yml": {
        "backend-codecov",
        "frontend-codecov",
        "flutter-coverage-comment",
    },
    "container-verify.yml": {"docker-verify"},
    "publish.yml": {"docker-publish"},
    "release-apk.yml": {"build-apk"},
    "security.yml": {"gitleaks"},
    "source-policy.yml": {
        "source-policy",
        "generated-localizations",
        "ci-workflows",
    },
}

LOCAL_REUSABLE_WORKFLOWS = {
    ("ci.yml", "docker-verify"): "./.github/workflows/container-verify.yml",
    ("ci.yml", "build-apk"): "./.github/workflows/release-apk.yml",
}

VERIFIED_ACTIONS = {
    "actions/checkout": ("34e114876b0b11c390a56381ad16ebd13914f8d5", "v4.3.1"),
    "actions/download-artifact": (
        "d3f86a106a0bac45b974a628896c90dbdf5c8093",
        "v4.3.0",
    ),
    "actions/setup-java": ("c1e323688fd81a25caa38c78aa6df2d33d3e20d9", "v4.8.0"),
    "actions/setup-python": ("a26af69be951a213d495a4c3e4e4022e16d87065", "v5.6.0"),
    "actions/upload-artifact": (
        "ea165f8d65b6e75b540449e92b4886f43607fa02",
        "v4.6.2",
    ),
    "aquasecurity/trivy-action": (
        "ed142fd0673e97e23eac54620cfb913e5ce36c25",
        "v0.36.0",
    ),
    "astral-sh/setup-uv": ("d0cc045d04ccac9d8b7881df0226f9e82c39688e", "v6.8.0"),
    "codecov/codecov-action": (
        "0fb7174895f61a3b6b78fc075e0cd60383518dac",
        "v5.5.5",
    ),
    "docker/build-push-action": (
        "ca052bb54ab0790a636c9b5f226502c73d547a25",
        "v5.4.0",
    ),
    "docker/login-action": ("c94ce9fb468520275223c153574b00df6fe4bcc9", "v3.7.0"),
    "docker/setup-buildx-action": (
        "8d2750c68a42422c14e847fe6c8ac0403b4cbd6f",
        "v3.12.0",
    ),
    "gitleaks/gitleaks-action": (
        "ff98106e4c7b2bc287b24eaf42907196329070c7",
        "v2.3.9",
    ),
    "marocchino/sticky-pull-request-comment": (
        "5770ad5eb8f42dd2c4f34da00c94c5381e49af88",
        "v3.0.5",
    ),
    "subosito/flutter-action": (
        "1a449444c387b1966244ae4d4f8c696479add0b2",
        "v2.23.0",
    ),
}

PRIVILEGED_ACTIONS = {
    ("ci-reports.yml", "backend-codecov"): {
        "actions/download-artifact",
        "codecov/codecov-action",
    },
    ("ci-reports.yml", "frontend-codecov"): {
        "actions/download-artifact",
        "codecov/codecov-action",
    },
    ("ci-reports.yml", "flutter-coverage-comment"): {
        "actions/download-artifact",
        "marocchino/sticky-pull-request-comment",
    },
    ("publish.yml", "docker-publish"): {
        "actions/download-artifact",
        "docker/login-action",
    },
}

TRUSTED_WORKFLOW_DIGESTS = {
    "ci-reports.yml": frozenset(
        {"a6fe5cf239354ac1609cca83ee5bd49d1e152788aec8f6790afb1a5e2dfcac01"}
    ),
    "publish.yml": frozenset(
        {"125a887ff476544753010a697900dc02477c7cac6180a3d96d7809a91f18b66f"}
    ),
    "source-policy.yml": frozenset(
        {"459f3d4d2e1bb7f59c8ffc9edd1201aad513fcdd2d580727c087bfd35187439b"}
    ),
}
