-- highlight-boxes.lua
-- Renders ::: highlightencounterbox and ::: highlightshowimagebox fenced Divs
-- as LaTeX tcolorboxes with correct font, size, spacing, and markdown rendering

function Div(el)
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
{\color{red!60!black}{\symbolsfont ⚔}~\textbf{Encounter:}}
]] ..
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
{\color{orange!80!black}{\symbolsfont ◆}~\textbf{Show image:}}
]] ..
    pandoc.write(pandoc.Pandoc(el.content), "latex") ..
    "\n\\end{tcolorbox}"
    )
  end
end
