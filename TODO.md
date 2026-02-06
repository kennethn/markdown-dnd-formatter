# TODO: Style & Maintainability Improvements

## 1. ~~Extract the Perl script from shell~~

`scripts/lib/content-transformer.sh:17-213` — The ~200-line Perl program embedded in a shell heredoc is the biggest maintainability issue. It's hard to edit (shell quoting interferes — note the `don'\''t` on line 125), impossible to lint or test independently, and gets no syntax highlighting in editors.

Move it to a standalone `scripts/lib/content-transformer.pl` file and invoke it with `perl -CSD "$PERL_SCRIPT" "$input_file" > "$output_file"`. This also lets you run `perl -c` to syntax-check it.

## 2. The config file is unused

`config/transform-config.json` defines callout box types, emoji mappings, and processing options, but nothing reads it. The Perl script and Lua filters have all of this hardcoded. Either wire up the config or remove it — dead config is worse than no config because it gives the false impression that changing it does something.

## 3. Dead code in `filters/`

- `force-tabular.lua` and `subsubsubsection.lua` are never referenced in the pandoc pipeline (`upnote-export.sh:130-143`).
- `scripts/lib/content-transformer-simplified.sh.backup` is a leftover.

Remove these or move them to a `filters/unused/` directory if you want to keep them for reference.

## 4. Redundant exit-code checks after `set -e`

In `upnote-export.sh:122-127`:
```bash
"$FIX_SCRIPT" "$INPUT_PATH" "$CLEANED_FILE"

if [ $? -ne 0 ]; then
    echo "..." >&2
    exit 1
fi
```
With `set -euo pipefail`, the script already exits on a non-zero return — the `if` block is dead code. The same pattern appears for the pandoc call (lines 159-167). Either remove the checks or use `||` instead:
```bash
"$FIX_SCRIPT" "$INPUT_PATH" "$CLEANED_FILE" || { echo "..." >&2; exit 1; }
```

Similarly in `content-transformer.sh:215`, the `if [[ $? -eq 0 ]]` after the perl invocation will never see a non-zero code because `set -e` would have already killed the function.

## 5. Callout box detection is duplicated and fragile

The callout box patterns are matched in three different places with slightly different logic:

- `content-transformer.sh:132-170` (Perl regex) — detects encounter/image/remember/music patterns
- `highlight-boxes.lua:110-134` — processes the resulting div classes
- `highlight-keywords.lua:189-193` — skips those same div classes

If you add a new callout type, you need to update all three. Consider defining the pattern-to-class mapping in one place (the config file you already have) and having the Perl script read it.

## 6. ~~`highlight-keywords.lua` has deep repetitive branching~~

The `Pandoc` filter function at `highlight-keywords.lua:165-215` is a 50-line nested `if/elseif` that repeats the same pattern — check block type, then call `highlight_inlines` on `.content`. A generic block walker or Pandoc's `Walk` API would cut this substantially:

```lua
local function walk_blocks(blocks)
  return pandoc.List(blocks):map(function(blk)
    if blk.t == "BlockQuote" or blk.t == "Header" then return blk end
    if blk.t == "Para" or blk.t == "Plain" then
      blk.content = highlight_inlines(blk.content)
    elseif blk.t == "BulletList" or blk.t == "OrderedList" then
      blk.content = pandoc.List(blk.content):map(function(item)
        return walk_blocks(item)
      end)
    elseif blk.t == "Div" then
      if not skip_classes[blk.classes] then
        blk.content = walk_blocks(blk.content)
      end
    end
    return blk
  end)
end
```

## 7. Bug: `highlight-boxes.lua` misleading indentation in `Div`

In `highlight-boxes.lua:31-106`, the monsterblock handling returns inside the `Div` function at line 106, but the subsequent `if el.classes:includes('highlightencounterbox')` at line 110 is outside that return. The code works, but the indentation makes the encounter/image/remember/music checks look like they're at the top level of the file rather than inside `Div`. Fix the indentation to prevent confusion.

## 8. Tests re-run the full pipeline per test case

Every test in `test-fix-upnote-markdown.sh` calls `"$FIX_SCRIPT" "$input" "$output"` independently, re-running the entire pipeline 7 times on the same input. Run it once in setup and have individual tests just grep the single output file.

## 9. Magic string coupling

The `__BODY_LINE__` prefix (`yaml-processor.sh` adds it, `content-transformer.sh` strips it) is a fragile convention. If any upstream step accidentally introduces or strips this marker, transformations silently break. Define it as a constant in `common.sh` and reference it from both scripts rather than having it as a literal string in two places.

## 10. Minor items

- `upnote-export.sh:81` — `$INPUT` is used before being guaranteed to be set. If no positional argument is passed, `set -u` causes an unbound variable error before `validate_input` runs. Initialize `INPUT=""` before the while loop.
- `utils.lua:30` — `border_color` parameter is only used for the icon color (line 36), not the frame. The frame uses `color` for both `colback` and `colframe`. Either the parameter name is misleading or the frame color should use `border_color`.
- `Makefile:42-43` — `lint` only runs shellcheck on `scripts/`, but `upnote-export.sh` is at the project root and gets skipped.
