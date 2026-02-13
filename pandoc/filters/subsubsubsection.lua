-- subsubsubsection.lua
local pandoc = require("pandoc")

-- tweak these to match your LaTeX setup:
local font_cmd  = "\\headerfont\\paragraphsize"
local color_cmd = "\\color{sectioncolor}"
local before    = "\\vspace{1pt}\\noindent\\stickysubsection"
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
