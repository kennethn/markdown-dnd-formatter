-- utils.lua
-- Shared utilities for D&D markdown filters

local utils = {}

-- Create a tcolorbox with specified styling
function utils.create_tcolorbox(color, border_color, icon, content)
  local blocks = {}

  -- Begin tcolorbox with styling
  table.insert(blocks, pandoc.RawBlock('latex', string.format([[
\begin{tcolorbox}[
  enhanced,
  breakable,
  rounded corners,
  arc=9pt,
  colback={%s},
  colframe={%s},
  boxrule=1pt,
  coltext=black,
  left=4pt,
  right=4pt,
  top=2pt,
  bottom=2pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper={\blockquoteFont\selectfont}
]
]], color, color)))

  -- Inject icon into first paragraph
  for i, block in ipairs(content) do
    if i == 1 and block.t == 'Para' then
      local icon_latex = string.format(
        [[\footnotesize\color{%s}%s\hspace{0.8em}\selectfont\begin{minipage}[t]{\dimexpr\linewidth-1.8em\hangindent=1.8em\hangafter=0}]],
        border_color, icon
      )
      local inlines = { pandoc.RawInline('latex', icon_latex) }
      for _, inline in ipairs(block.c) do
        table.insert(inlines, inline)
      end
      table.insert(blocks, pandoc.Para(inlines))
    else
      table.insert(blocks, block)
    end
  end

  -- End tcolorbox
  table.insert(blocks, pandoc.RawBlock('latex', [[\end{minipage}\end{tcolorbox}]]))
  return blocks
end

-- Flatten list content into inline elements
function utils.flatten_list_content(list_items)
  local new_items = {}
  for _, item in ipairs(list_items) do
    local flat = {}
    for _, part in ipairs(item) do
      if part.t == 'Para' then
        for _, subpart in ipairs(part.c) do
          table.insert(flat, subpart)
        end
      else
        table.insert(flat, part)
      end
    end
    table.insert(new_items, flat)
  end
  return new_items
end

return utils