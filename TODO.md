# Tech Debt & Maintenance TODO

## Documentation Bugs

- [ ] **LICENSE mismatch**: README.md:204 says "MIT License" but the actual `LICENSE` file is Apache 2.0. Pick one and fix the other.
- [ ] **Typo in README**: README.md:99 says "callots" — should be "callouts".
- [ ] **Wrong callout name in README**: README.md:106 shows `[!dnd-musc]` but the actual code uses `[!dnd-music]` (content-transformer.sh:164).
- [ ] **Project structure is incomplete in README**: README.md:134-158 doesn't list `filters/subsubsubsection.lua` or `filters/force-tabular.lua`, which both exist in the repo.
- [ ] **Misleading comment in LaTeX template**: dnd-notes.tex:62 comment says `"flexible ~20pt spacing"` but the value is `8pt`.
- [ ] **Wrong color comments in LaTeX template**: dnd-notes.tex:139 and :142 both say `"% White borders"` but the hex value `000000` is black, not white.

## Dead / Unreachable Code

- [ ] **`$?` checks are dead code under `set -e`**: In monster-blocks.sh:56, yaml-processor.sh:31, content-transformer.sh:215, and cleanup.sh:31, the pattern `command > file; if [[ $? -eq 0 ]]` is dead — `set -e` (inherited from the parent script) would already abort the script before the check runs. Same issue in upnote-export.sh:124.
- [ ] **Unused functions in common.sh**: `cleanup_temp_files()` (line 35), `get_script_dir()` (line 94), and `get_project_root()` (line 98) are defined but never called anywhere.
- [ ] **Unused Lua filters**: `filters/force-tabular.lua` and `filters/subsubsubsection.lua` exist but are never referenced in any Pandoc invocation in `upnote-export.sh`. The H4-to-subsubsubsection conversion that would feed into `subsubsubsection.lua` is commented out at content-transformer.sh:91. Either delete these filters or wire them up.
- [ ] **Unused Lua functions**: `flatten_bullet_list` and `flatten_ordered_list` (highlight-boxes.lua:19-25) are defined but never registered in the return filter table, so Pandoc never calls them.
- [ ] **Commented-out code**: content-transformer.sh:91 has a commented-out H4 conversion. Decide whether to implement or remove it.

## Config Drift / Confabulations

- [x] **`transform-config.json` is never read by any code**: ~~It exists as "documentation" but has already drifted from reality.~~ Fixed: callout types are now loaded from this config by both Perl and Lua. Removed stale `callout_boxes`, `unicode_patterns`, and `text_processing` sections. Only `table_styling` remains as documentation-only.
- [ ] **Test expected patterns are wrong and unused**: tests/test-fix-upnote-markdown.sh:103-111 creates `expected-patterns.txt` with `\\textcolor{sectioncolor}{\\textbf{Wikilink}}` and `\\texttt{-2}`, but the actual code produces `\\uline{}` (not `\\textbf{}`) for wikilinks and does NOT wrap negative numbers in `\\texttt{}`. Furthermore, no test ever reads this file — it's created and then ignored.

## Bugs

- [ ] **Uninitialized variable**: upnote-export.sh:81 uses `$INPUT` which is only set inside the `while` loop's `*)` case. If the user passes only flags (e.g. `./upnote-export.sh --one-column`), `$INPUT` is unset and `validate_input` receives an empty string, producing a usage message but no clear error about the missing file argument.
- [ ] **Broken `Meta` filter in highlight-boxes.lua**: Lines 12-16 — `pandoc.MetaMap(meta)` is not a valid constructor call (MetaMap takes a plain table, not a Meta object), and `pandoc.MetaBool('tight_lists', true)` passes a string where a boolean is expected. Returning a list from `Meta` is also incorrect (it should return a single Meta table). The tight_lists metadata is likely never set.
- [ ] **`flatten_ordered_list` has wrong arguments**: highlight-boxes.lua:24 calls `pandoc.OrderedList(olist.start, ...)` but `OrderedList` expects items as the first argument, not a number. This is a latent bug (the function is never called, so it never manifests).
- [ ] **Redundant `source` calls**: monster-blocks.sh:4, yaml-processor.sh:4, content-transformer.sh:4, and cleanup.sh:4 all `source common.sh`, but `fix-upnote-markdown.sh` already sources it at line 15 before sourcing these modules. Each lib file re-sources common.sh unnecessarily. This is harmless but wasteful and could become a problem if common.sh gains side effects.

## Test Quality

- [ ] **`run_test` swallows failures**: tests/test-fix-upnote-markdown.sh:53-54 — `run_test` always returns 0 even when the inner test fails. The test suite will report failures in the summary but the exit code from `run_test` is always success, which means a CI pipeline wouldn't catch individual test failures mid-run.
- [ ] **Tests re-run the full pipeline for every assertion**: Each of the 7 processing tests (lines 122-190) independently calls `"$FIX_SCRIPT" "$input" "$output"`, running the entire pipeline from scratch. Running it once and checking the single output file would be much faster.
- [ ] **No test coverage for**: emoji conversion, table processing edge cases (empty tables, single-column), `--one-column` flag, `--output-dir` flag, multiline callout boxes, wikilinks with pipe aliases (`[[target|display]]`), or the Lua filters themselves.

## Maintainability / Architecture

- [ ] **200-line Perl script embedded in a bash heredoc**: content-transformer.sh:17-213 is a massive inline Perl script. It's impossible to lint, syntax-check, or test in isolation. Extracting it to a standalone `.pl` file would improve debuggability significantly.
- [ ] **Fragile `__BODY_LINE__` marker coupling**: yaml-processor.sh adds the prefix and content-transformer.sh strips it. If any intermediate step corrupts or strips this marker, the pipeline silently breaks. This coupling is undocumented and non-obvious.
- [x] **Callout types defined in 3 separate places**: ~~Adding a new callout type requires synchronized edits to `content-transformer.sh` (Perl regex), `highlight-boxes.lua` (Div handler), and `transform-config.json` (if you keep it). There's no single source of truth.~~ Fixed: `config/transform-config.json` is now the single source of truth. Both `transform-content.pl` (via JSON::PP) and the Lua filters (via `utils.load_config()`) read callout types from it at runtime.
- [ ] **Misleading variable name in utils.lua**: `create_tcolorbox(color, border_color, ...)` — the `border_color` parameter is actually used as the icon color (line 36-37), not the box border color. The actual `colframe` is set to `color` (line 30), not `border_color`.
- [ ] **Inconsistent icon color arg for music box**: highlight-boxes.lua:131 passes the literal string `'black'` while all other callout types use named LaTeX color variables (`'encounterborder'`, `'imageborder'`, `'rememberborder'`).

## Misleading / Stale Content

- [ ] **Wrong filename in file header**: content-transformer.sh:2 says `# content-transformer-complete.sh` but the file is named `content-transformer.sh`. Leftover from a rename.
- [ ] **`demo/sample.md` is both generated and committed**: `make demo` overwrites it (Makefile:63-68), but it's tracked in git. Either .gitignore it or don't overwrite it in the Makefile.
- [ ] **Makefile lint only checks `scripts/`**: Makefile:42 runs `find scripts -name "*.sh"` but doesn't lint `upnote-export.sh` in the project root.

## Bloated .gitignore

- [ ] **Entire Python gitignore section is unnecessary**: .gitignore:321-493 contains a full Python template (Django, Flask, Jupyter, pyenv, etc.) but the project has zero Python files. This adds ~170 lines of noise.
- [ ] **`lib/` gitignore rule could shadow `scripts/lib/`**: .gitignore:339 has `lib/` from the Python template, which matches directories named `lib` at any depth. Existing tracked files aren't affected, but *new* files added to `scripts/lib/` would be silently ignored by git.
