# Source line policy

This directory enforces the 300-line limit for maintained Dart and Java files.
The guard scans production code and tests under the four source roots declared
in `source_line_policy.py`.

## Local commands

From the repository root:

```bash
python tools/quality/check_source_lines.py
python -m unittest discover -s tools/quality/tests -p "test_*.py"
```

The implementation uses only the Python standard library and normalizes paths
to POSIX form, so the same commands work on Windows and Linux.

## Ratchet rules

- A maintained file with at most 300 physical lines passes.
- A new file above 300 lines fails and cannot be added to the baseline.
- A legacy file may not exceed its audited `baseline_lines` value.
- Reducing a legacy file while it remains above 300 must lower its baseline in
  the same change; otherwise the guard fails.
- Once a legacy file reaches 300 lines, its entry must be removed.
- An expired legacy entry fails even when the file did not grow.
- Standard `mobile/build`, `mobile/.dart_tool`, and `backend/target` directories
  are outside the scanned roots. The same names inside source roots are scanned.

Every legacy entry records the migration issue and an expiry date. Trusted CI
compares the candidate policy with the base branch: entries may only be removed,
baselines lowered, and expiry dates moved earlier. New entries, raised ceilings,
changed issues, and deadline extensions fail before application builds start.

## Generated localization files

Only the three committed `app_localizations*.dart` outputs listed in the policy
are exempt. The fast guard verifies their expected structure. CI then runs the
pinned Flutter generator and requires a clean diff, which rejects hand-written
replacements even when they copy the static signatures.

Do not split these files manually. Update the ARB inputs, run
`flutter gen-l10n`, and commit the regenerated outputs.
