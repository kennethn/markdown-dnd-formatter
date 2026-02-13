# Tech Debt & Maintenance TODO

## Documentation Bugs

- [x] **LICENSE mismatch**: README.md:204 says "MIT License" but the actual `LICENSE` file is Apache 2.0. Pick one and fix the other.
- [x] **Typo in README**: README.md:99 says "callots" — should be "callouts".
- [x] **Wrong callout name in README**: ~~README.md:106 shows `[!dnd-musc]` but the actual code uses `[!dnd-music]`.~~ Fixed in README rewrite.
- [x] **Project structure is incomplete in README**: ~~README.md doesn't list `filters/subsubsubsection.lua` or `filters/force-tabular.lua`.~~ Fixed in README rewrite — both are now listed.
- [ ] **Misleading comment in LaTeX template**: pandoc/dnd-notes.tex:62 comment says `"flexible ~20pt spacing"` but the value is `8pt`.
- [ ] **Wrong color comments in LaTeX template**: pandoc/dnd-notes.tex:139 and :142 both say `"% White borders"` but the hex value `000000` is black, not white.

## Dead / Unreachable Code

- [ ] **`$?` checks are dead code under `set -e`**: In monster-blocks.sh:56, yaml-processor.sh:31, content-transformer.sh:215, and cleanup.sh:31, the pattern `command > file; if [[ $? -eq 0 ]]` is dead — `set -e` (inherited from the parent script) would already abort the script before the check runs. Same issue in md-to-pdf.sh:124.
- [ ] **Unused functions in common.sh**: `cleanup_temp_files()` (line 35), `get_script_dir()` (line 94), and `get_project_root()` (line 98) are defined but never called anywhere.
- [ ] **Unused Lua filters**: `pandoc/filters/force-tabular.lua` and `pandoc/filters/subsubsubsection.lua` exist but are never referenced in any Pandoc invocation in `pandoc/md-to-pdf.sh`. The H4-to-subsubsubsection conversion that would feed into `subsubsubsection.lua` is commented out in transform-content.pl. Either delete these filters or wire them up.
- [ ] **Unused Lua functions**: `flatten_bullet_list` and `flatten_ordered_list` (highlight-boxes.lua:19-25) are defined but never registered in the return filter table, so Pandoc never calls them.
- [ ] **Commented-out code**: transform-content.pl has a commented-out H4 conversion. Decide whether to implement or remove it.

## Config Drift / Confabulations

- [x] **`transform-config.json` is never read by any code**: ~~It exists as "documentation" but has already drifted from reality.~~ Fixed: callout types are now loaded from this config by both Perl and Lua. Removed stale `callout_boxes`, `unicode_patterns`, and `text_processing` sections. Only `table_styling` remains as documentation-only.
- [ ] **Test expected patterns are wrong and unused**: tests/test-fix-markdown.sh creates `expected-patterns.txt` with `\\textcolor{sectioncolor}{\\textbf{Wikilink}}` and `\\texttt{-2}`, but the actual code produces `\\uline{}` (not `\\textbf{}`) for wikilinks and does NOT wrap negative numbers in `\\texttt{}`. Furthermore, no test ever reads this file — it's created and then ignored.

## Bugs

- [ ] **Uninitialized variable**: pandoc/md-to-pdf.sh:81 uses `$INPUT` which is only set inside the `while` loop's `*)` case. If the user passes only flags (e.g. `./pandoc/md-to-pdf.sh --one-column`), `$INPUT` is unset and `validate_input` receives an empty string, producing a usage message but no clear error about the missing file argument.
- [ ] **Broken `Meta` filter in highlight-boxes.lua**: Lines 12-16 — `pandoc.MetaMap(meta)` is not a valid constructor call (MetaMap takes a plain table, not a Meta object), and `pandoc.MetaBool('tight_lists', true)` passes a string where a boolean is expected. Returning a list from `Meta` is also incorrect (it should return a single Meta table). The tight_lists metadata is likely never set.
- [ ] **`flatten_ordered_list` has wrong arguments**: highlight-boxes.lua:24 calls `pandoc.OrderedList(olist.start, ...)` but `OrderedList` expects items as the first argument, not a number. This is a latent bug (the function is never called, so it never manifests).
- [ ] **Redundant `source` calls**: monster-blocks.sh, yaml-processor.sh, content-transformer.sh, and cleanup.sh all `source common.sh`, but `fix-markdown.sh` already sources it before sourcing these modules. Each lib file re-sources common.sh unnecessarily.

## Test Quality

- [ ] **`run_test` swallows failures**: tests/test-fix-markdown.sh — `run_test` always returns 0 even when the inner test fails. The test suite will report failures in the summary but the exit code from `run_test` is always success, which means a CI pipeline wouldn't catch individual test failures mid-run.
- [ ] **Tests re-run the full pipeline for every assertion**: Each of the 7 processing tests independently calls the full pipeline from scratch. Running it once and checking the single output file would be much faster.
- [ ] **No test coverage for**: emoji conversion, table processing edge cases (empty tables, single-column), `--one-column` flag, `--output-dir` flag, multiline callout boxes, wikilinks with pipe aliases (`[[target|display]]`), or the Lua filters themselves.

## Maintainability / Architecture

- [x] **200-line Perl script embedded in a bash heredoc**: ~~Massive inline Perl script impossible to lint or test.~~ Fixed: extracted to standalone `pandoc/scripts/lib/transform-content.pl`.
- [ ] **Fragile `__BODY_LINE__` marker coupling**: yaml-processor.sh adds the prefix and content-transformer.sh strips it. If any intermediate step corrupts or strips this marker, the pipeline silently breaks. This coupling is undocumented and non-obvious.
- [x] **Callout types defined in 3 separate places**: ~~No single source of truth.~~ Fixed: `pandoc/config/transform-config.json` is now the single source of truth.
- [ ] **Misleading variable name in utils.lua**: `create_tcolorbox(color, border_color, ...)` — the `border_color` parameter is actually used as the icon color, not the box border color.
- [x] **Inconsistent icon color arg for music box**: highlight-boxes.lua:131 passes the literal string `'black'` while all other callout types use named LaTeX color variables.

## Misleading / Stale Content

- [x] **Wrong filename in file header**: ~~content-transformer.sh:2 says `# content-transformer-complete.sh`.~~ Fixed.
- [ ] **`demo/sample.md` is both generated and committed**: `make demo` overwrites it, but it's tracked in git. Either .gitignore it or don't overwrite it in the Makefile.
- [x] **Makefile lint only checks `scripts/`**: ~~Didn't lint the main export script.~~ Fixed: Makefile now points to `pandoc/scripts/` and the main script lives there too.

## Bloated .gitignore

- [ ] **Entire Python gitignore section is unnecessary**: .gitignore contains a full Python template (Django, Flask, Jupyter, pyenv, etc.) but the project has zero Python files. This adds ~170 lines of noise.
- [ ] **`lib/` gitignore rule could shadow `pandoc/scripts/lib/`**: .gitignore has `lib/` from the Python template, which matches directories named `lib` at any depth. Existing tracked files aren't affected, but *new* files added to `pandoc/scripts/lib/` would be silently ignored by git.
