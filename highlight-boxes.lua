-- highlight-boxes.lua
-- Renders ::: highlightencounterbox and ::: highlightshowimagebox fenced Divs
-- as LaTeX tcolorboxes with correct font, size, spacing, and markdown rendering

function Div(el)
  if el.classes:includes("highlightencounterbox") then
    return pandoc.RawBlock("latex", [[
\begin{tcolorbox}[
  colback=red!20,
  boxrule=1pt,
  frame style={solid},
  arc=2pt,
  left=6pt,
  right=6pt,
  top=4pt,
  bottom=4pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper=\blockquoteFont\footnotesize,
  before upper={
    \setlength{\parskip}{6pt}
    \setlength{\baselineskip}{13pt}
  }
]
{\symbolsfont ⚔}~\textbf{Encounter:}
]] ..
    pandoc.write(pandoc.Pandoc(el.content), "latex") ..
    "\n\\end{tcolorbox}"
    )
  elseif el.classes:includes("highlightshowimagebox") then
    return pandoc.RawBlock("latex", [[
\begin{tcolorbox}[
  colback=yellow!30,
  boxrule=1pt,
  frame style={solid},
  arc=2pt,
  left=6pt,
  right=6pt,
  top=4pt,
  bottom=4pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper=\blockquoteFont\footnotesize,
  before upper={
    \setlength{\parskip}{6pt}
    \setlength{\baselineskip}{13pt}
  }
]
{\symbolsfont ◆}~\textbf{Show image:}
]] ..
    pandoc.write(pandoc.Pandoc(el.content), "latex") ..
    "\n\\end{tcolorbox}"
    )
  end
end
