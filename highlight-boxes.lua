-- highlight-boxes.lua
-- Handles custom fenced Divs and monster stat blocks for D&D notes

function Meta(meta)
  return {
    pandoc.MetaMap(meta),
    pandoc.MetaBool('tight_lists', true)
  }
end

function flatten_bullet_list(blist)
  local new_items = {}
  for _, item in ipairs(blist.content) do
    local flat = {}
    for _, part in ipairs(item) do
      if part.t == "Para" then
        for _, subpart in ipairs(part.c) do
          table.insert(flat, subpart)
        end
      else
        table.insert(flat, part)
      end
    end
    table.insert(new_items, flat)
  end
  return pandoc.BulletList(new_items)
end

function flatten_ordered_list(olist)
  local new_items = {}
  for _, item in ipairs(olist.content) do
    local flat = {}
    for _, part in ipairs(item) do
      if part.t == "Para" then
        for _, subpart in ipairs(part.c) do
          table.insert(flat, subpart)
        end
      else
        table.insert(flat, part)
      end
    end
    table.insert(new_items, flat)
  end
  return pandoc.OrderedList(olist[1], new_items)
end


function Div(el)
  -- MONSTERBLOCK
  if el.classes:includes("monsterblock") then
    local blocks = {
      pandoc.RawBlock("latex", "\\clearpage"),
      pandoc.RawBlock("latex", [[
\begingroup
\clubpenalty=150
\widowpenalty=150
\displaywidowpenalty=150
\blockquoteFont
\linespread{1}%
\fontsize{9pt}{11pt}\selectfont
\setlength{\parskip}{4pt}
\setlength{\baselineskip}{11pt}
\makeatletter
\setlength{\@fptop}{0pt}           % 🔧 allow floats at top
\setlength{\@fpsep}{8pt plus 1pt}  % 🔧 allow float separation
\setlength{\topskip}{0pt}          % 🔧 remove implicit top spacing
% Reduce itemize spacing locally
\def\@listi{%
  \setlength{\leftmargin}{1.5em}%
  \setlength{\itemsep}{0pt}%
  \setlength{\parsep}{0pt}%
  \setlength{\topsep}{10pt}%
  \setlength{\partopsep}{0pt}%
}


% Local header formatting
\titleformat*{\section}{\color{sectioncolor}\sffamily\fontsize{12pt}{14pt}\selectfont\bfseries}
\titleformat*{\subsection}{\color{subsectioncolor}\sffamily\fontsize{10pt}{12pt}\selectfont\bfseries}
\titleformat*{\subsubsection}{\color{subsubsectioncolor}\sffamily\fontsize{9pt}{11pt}\selectfont\bfseries}

\titlespacing*{\section}{0pt}{10pt}{10pt}
\titlespacing*{\subsection}{0pt}{8pt}{10pt}
\titlespacing*{\subsubsection}{0pt}{6pt}{10pt}


\setcounter{secnumdepth}{0}
  
\makeatother

]])
    }
   table.insert(blocks, pandoc.RawBlock("latex", "\\vspace*{-\\topskip}")) 

   for _, b in ipairs(el.content) do
    if b.t == "BulletList" or b.t == "OrderedList" then
      table.insert(blocks, pandoc.RawBlock("latex", "\\begingroup\\setlength{\\parskip}{0pt}"))
      if b.t == "BulletList" then
        table.insert(blocks, flatten_bullet_list(b))
      else
        table.insert(blocks, flatten_ordered_list(b))
      end
      table.insert(blocks, pandoc.RawBlock("latex", "\\endgroup"))
elseif b.t == "Table" then
    table.insert(blocks, pandoc.RawBlock("latex", [[
\begin{center}
\renewcommand{\arraystretch}{1.2}
\setlength{\tabcolsep}{4pt}
\footnotesize\sffamily
\begin{tabularx}{\linewidth}{>{\raggedright\arraybackslash}X >{\raggedright\arraybackslash}X >{\raggedright\arraybackslash}X >{\raggedright\arraybackslash}X}
]]))
    table.insert(blocks, b)
    table.insert(blocks, pandoc.RawBlock("latex", [[
\end{tabularx}
\end{center}
]]))


    else
      table.insert(blocks, b)
    end
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
  boxrule=1pt,
  arc=2pt,
  left=4pt,
  right=4pt,
  top=2pt,
  bottom=2pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper=\blockquoteFont\small,
  before upper={
    \setlength{\parskip}{6pt}
    \setlength{\baselineskip}{13pt}
  }
]
{\color{red!60!black}{\faBomb}~\textbf{Encounter }}]])
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
  boxrule=1pt,
  arc=2pt,
  left=4pt,
  right=4pt,
  top=2pt,
  bottom=2pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper=\blockquoteFont\small,
  before upper={
    \setlength{\parskip}{6pt}
    \setlength{\baselineskip}{13pt}
  }
]
{\color{orange!80!black}{\faEye}~\textbf{Image }}]])
    }

    for _, b in ipairs(el.content) do
      table.insert(blocks, b)
    end

    table.insert(blocks, pandoc.RawBlock("latex", "\\end{tcolorbox}"))
    return blocks
  end

  return nil
end
