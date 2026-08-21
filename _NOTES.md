# Notes — test suite modernization (2026-08-20)

Findings from modernizing this bundle's test suites (the working pattern is described in `taskmate.tmbundle/_NOTES.md`).

## Result

Both suites 100% passing under Ruby 4.0.6, runnable from any working
directory:

    ruby Support/tests/test_gtd.rb      # 9 tests, 108 assertions
    ruby Support/tests/test_utils.rb    # 3 tests,  12 assertions

## What was found

**The headline: an invisible editor-settings dependency.** `dump_object`
(the GTD file serializer) reads `TM_SOFT_TABS` and `TM_TAB_SIZE` from the
environment — TextMate sets these for commands running inside the editor.
The fixtures are authored with two-space soft tabs, but the test never pinned
those variables, so the serialization round-trip test
(`test_dump_object`) only ever passed when launched from within a TextMate
configured for two-space soft tabs. From a plain terminal it fell to the
tab-character default and failed. The author's editor preferences were part
of the test environment without anyone deciding that. Fixed by pinning both
variables in the test, alongside the `TM_GTD_CONTEXTS` pins the file already
had — the suite now documents its complete environment contract explicitly.

**Portability, same as the other 2005-era suites:** `$:.unshift "../lib"`
load-path mutation and bare fixture filenames resolved only from
`Support/tests/`; replaced with `require_relative` and `__dir__`-anchored
paths. `TM_GTD_DIRECTORY` is now pinned to the tests directory so
`GTD.process_directory` scans the fixtures rather than whatever directory the
caller happens to be in.

## Observations (untouched)

- `GTDUtils.rb` monkey-patches `Array` with `next`/`previous` methods —
  live code, exercised by `test_utils.rb`, left alone.
- `test_gtd.rb`'s tests call each other (`test_projects` runs
  `test_GTDFile_initialize` first) — 2005-style interdependence; harmless
  under test/unit, left alone.
- `test_utils.rb` has a stray `puts` printing contexts into the test output —
  left alone.
- The `GTDiCalendar.rb` and `GTDInfoRoutines.rb` libraries have no test
  coverage.
