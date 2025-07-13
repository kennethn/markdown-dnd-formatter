-- highlight-boxes.lua
-- Renders ::: highlightencounterbox, ::: highlightshowimagebox, and ::: monsterblock

local monsters_section_found = false
local first_monster_found = false

function Header(el)
  if el.level == 1 then
    local text = pandoc.utils.stringify(el.content)

    -- Detect when we enter the Monsters section
    if text == "Monsters" then
      monsters_section_found = true
      return {
        pandoc.RawBlock("latex", [[
\begingroup
\clubpenalty=150
\widowpenalty=150
\displaywidowpenalty=150
]]),
        el
      }
    end

    -- After Monsters section, insert page breaks before each H1
    if monsters_section_found then
      if first_monster_found then
        return {
          pandoc.RawBlock("latex", "\\newpage"),
          el
        }
      else
        first_monster_found = true
        return el
      end
    end
  end
end

function Div(el)
  if el.classes:includes("monsterblock") then
    return {
      pandoc.RawBlock("latex", [[
\begingroup
\blockquoteFont\small
\linespread{1.05}\selectfont
]]),
      pandoc.Div(el.content),
      pandoc.RawBlock("latex", "\\endgroup")
    }
  end

  if el.classes:includes("highlightencounterbox") then
    return pandoc.RawBlock("latex", [[
\begin{tcolorbox}[
  colback=red!8,
  colframe=red!60!black,
  boxrule=2pt,
  frame style={solid},
  arc=2pt,
  left=6pt,
  right=6pt,
  top=4pt,
  bottom=4pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper=\blockquoteFont\small,
  before upper={
    \setlength{\parskip}{6pt}
    \setlength{\baselineskip}{13pt}
  }
]
{\color{red!60!black}{\symbolsfont ⚔}~\textbf{Encounter:}}]] ..
      pandoc.write(pandoc.Pandoc(el.content), "latex") ..
      "\n\\end{tcolorbox}"
    )
  elseif el.classes:includes("highlightshowimagebox") then
    return pandoc.RawBlock("latex", [[
\begin{tcolorbox}[
  colback=yellow!8,
  colframe=orange!80!black,
  frame style={draw=orange!80!black, line width=1pt},
  boxrule=2pt,
  frame style={solid},
  arc=2pt,
  left=6pt,
  right=6pt,
  top=4pt,
  bottom=4pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper=\blockquoteFont\small,
  before upper={
    \setlength{\parskip}{6pt}
    \setlength{\baselineskip}{13pt}
  }
]
{\color{orange!80!black}{\symbolsfont ◆}~\textbf{Show image:}}]] ..
      pandoc.write(pandoc.Pandoc(el.content), "latex") ..
      "\n\\end{tcolorbox}"
    )
  end
end

function Doc(body)
  -- Close the LaTeX group at the end of the document
  table.insert(body.blocks, pandoc.RawBlock("latex", "\\endgroup"))
  return pandoc.Pandoc(body.blocks, body.meta)
end
