# End-to-end check (Linux substitute for Windows)

Task 10.4 calls for a Windows desktop E2E pass. This Cloud Agent environment
provides Linux desktop + Chrome, not Windows. Coverage instead:

1. Widget/integration suite `test/e2e_flow_test.dart` exercises launch, page
   open with blocks/icon, wikilink + note↔assignment coverage, search index
   hit, database view persistence, review due count, exam plan generation,
   class-page creation from schedule, shell destinations, and light theme.
2. Manual `flutter run -d linux` against the running shell for UI smoke.

To re-run locally on Windows: `flutter run -d windows` and walk the same
checklist (new page → blocks → link → search → database view → review → exam
→ quick capture → theme switch).
