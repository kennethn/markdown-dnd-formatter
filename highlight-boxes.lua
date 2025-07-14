-- highlight-boxes.lua
-- Handles custom fenced Divs and monster stat blocks for D&D notes

function Div(el)
  -- MONSTERBLOCK
  if el.classes:includes("monsterblock") then
    local blocks = {
      pandoc.RawBlock("latex", [[
\begingroup
\clubpenalty=150
\widowpenalty=150
\displaywidowpenalty=150
\blockquoteFont
\linespread{1}%
\fontsize{10pt}{12pt}\selectfont
\setlength{\parskip}{5pt}
\setlength{\baselineskip}{12pt}
\makeatletter
\setlist[itemize]{itemsep=0pt, topsep=0pt, parsep=0pt, partopsep=0pt}
\titlespacing*{\section}{0pt}{0pt}{2pt}
\titlespacing*{\subsection}{0pt}{0pt}{2pt}
\titlespacing*{\subsubsection}{0pt}{0pt}{2pt}
\makeatother
]])
    }

    for _, b in ipairs(el.content) do
      table.insert(blocks, b)
    end

    table.insert(blocks, pandoc.RawBlock("latex", "\\endgroup"))
    return blocks
  end

  -- ENCOUNTER BOX
  if el.classes:includes("highlightencounterbox") then
    local blocks = {
      pandoc.RawBlock("latex", [[
\begin{tcolorbox}[
  colback=red!8,
  colframe=red!60!black,
  boxrule=2pt,
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
{\color{red!60!black}{\symbolsfont ⚔}~\textbf{Encounter }}]])
    }

    for _, b in ipairs(el.content) do
      table.insert(blocks, b)
    end

    table.insert(blocks, pandoc.RawBlock("latex", "\\end{tcolorbox}"))
    return blocks
  end

  -- SHOW IMAGE BOX
  if el.classes:includes("highlightshowimagebox") then
    local blocks = {
      pandoc.RawBlock("latex", [[
\begin{tcolorbox}[
  colback=yellow!8,
  colframe=orange!80!black,
  boxrule=2pt,
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
{\color{orange!80!black}{\symbolsfont ◆}~\textbf{Show image }}]])
    }

    for _, b in ipairs(el.content) do
      table.insert(blocks, b)
    end

    table.insert(blocks, pandoc.RawBlock("latex", "\\end{tcolorbox}"))
    return blocks
  end

  return nil
end
