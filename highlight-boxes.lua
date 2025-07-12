-- highlight-boxes.lua
-- Renders ::: highlightencounterbox and ::: highlightshowimagebox fenced Divs
-- as LaTeX tcolorboxes with correct font, size, spacing, and markdown rendering

function Div(el)
  if el.classes:includes("highlightencounterbox") then
    return pandoc.RawBlock("latex", [[
\begin{tcolorbox}[
  colback=red!10,
  colframe=red!70!black,
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
  fontupper=\blockquoteFont\small,
  before upper={
    \setlength{\parskip}{6pt}
    \setlength{\baselineskip}{13pt}
  }
]
{\color{red!70!black}{\symbolsfont ⚔}~\textbf{Encounter:}}
]] ..
    pandoc.write(pandoc.Pandoc(el.content), "latex") ..
    "\n\\end{tcolorbox}"
    )
  elseif el.classes:includes("highlightshowimagebox") then
    return pandoc.RawBlock("latex", [[
\begin{tcolorbox}[
  colback=yellow!10,
  colframe=orange!90!black,
  frame style={draw=orange!90!black, line width=1pt},
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
  fontupper=\blockquoteFont\small,
  before upper={
    \setlength{\parskip}{6pt}
    \setlength{\baselineskip}{13pt}
  }
]
{\color{orange!90!black}{\symbolsfont ◆}~\textbf{Show image:}}
]] ..
    pandoc.write(pandoc.Pandoc(el.content), "latex") ..
    "\n\\end{tcolorbox}"
    )
  end
end
