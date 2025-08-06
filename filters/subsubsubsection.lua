-- subsubsubsection.lua
local pandoc = require("pandoc")

-- tweak these to match your LaTeX setup:
local font_cmd  = "\\headerfontbold\\normalsize"
local color_cmd = "\\color{subsubsectioncolor}"
local before    = "\\vspace{1pt}\\noindent\\stickysubsubsection"
local after     = "\\par"

function Div(el)
  if el.classes:includes("subsubsubsection") then
    -- grab the one line of text
    local txt = pandoc.utils.stringify(el.content)
    -- emit three LaTeX blocks: space above, styled text, space below
    return {
      pandoc.RawBlock("latex", before),
      pandoc.RawBlock("latex",
        "{" .. font_cmd .. " " .. color_cmd .. txt .. "}"),
      pandoc.RawBlock("latex", after),
    }
  end
  -- all other divs stay untouched
  return nil
end

return {
  { Div = Div }
}
