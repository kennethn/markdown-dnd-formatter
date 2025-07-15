-- highlight-boxes.lua
-- Handles custom fenced Divs, monster stat blocks, and custom callout boxes for D&D notes

-- Enable tight lists by default
function Meta(meta)
  return {
    pandoc.MetaMap(meta),
    pandoc.MetaBool('tight_lists', true)
  }
end

-- Flatten a bullet list into inline content
function flatten_bullet_list(blist)
  local new_items = {}
  for _, item in ipairs(blist.content) do
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
  return pandoc.BulletList(new_items)
end

-- Flatten an ordered list into inline content
function flatten_ordered_list(olist)
  local new_items = {}
  for _, item in ipairs(olist.content) do
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
  return pandoc.OrderedList(olist.start, new_items)
end

-- Main Div filter: handles custom highlightencounterbox and highlightshowimagebox
function Div(el)
  
  -- Encounter callout box
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
\vspace*{-2\baselineskip}
\linespread{1}%
\fontsize{9pt}{11pt}\selectfont
\setlength{\parskip}{4pt}
\setlength{\baselineskip}{11pt}
\makeatletter
\setlength{\@fptop}{0pt}           % 🔧 allow floats at top
\setlength{\@fpsep}{8pt plus 1pt}  % 🔧 allow float separation
\setlength{\topskip}{0pt}          % 🔧 remove implicit top spacing
% Reduce itemize spacing locally
\setlist[itemize]{left=1.5em, itemsep=200pt, topsep=6pt, parsep=0pt, partopsep=0pt}
\setlist[enumerate]{left=1.5em, itemsep=2pt, topsep=6pt, parsep=0pt, partopsep=0pt}


% Local header formatting
\titleformat*{\section}{\color{sectioncolor}\sffamily\fontsize{12pt}{14pt}\selectfont\bfseries}
\titleformat*{\subsection}{\color{subsectioncolor}\sffamily\fontsize{10pt}{12pt}\selectfont\bfseries}
\titleformat*{\subsubsection}{\color{subsubsectioncolor}\sffamily\fontsize{9pt}{11pt}\selectfont\bfseries}


%\titlespacing*{\section}{0pt}{0pt}{10pt}
%\titlespacing*{\subsection}{0pt}{8pt}{10pt}
%\titlespacing*{\subsubsection}{0pt}{6pt}{10pt}


\setcounter{secnumdepth}{0}
  
\makeatother



]])
    }
   table.insert(blocks, pandoc.RawBlock("latex", "\\vspace*{-\\topskip}")) 

   for _, b in ipairs(el.content) do
   if b.t == "BulletList" then
  table.insert(blocks, pandoc.RawBlock("latex", [[
\begin{itemize}[left=1.5em, itemsep=8pt, topsep=12pt, parsep=0pt, partopsep=0pt]
]]))
  for _, item in ipairs(b.content) do
    local content = pandoc.write(pandoc.Pandoc(item), "latex")
    table.insert(blocks, pandoc.RawBlock("latex", "\\item " .. content))
  end
  table.insert(blocks, pandoc.RawBlock("latex", "\\end{itemize}"))

elseif b.t == "OrderedList" then
  table.insert(blocks, pandoc.RawBlock("latex", [[
\begin{enumerate}[left=1.5em, itemsep=200pt, topsep=12pt, parsep=0pt, partopsep=0pt]
]]))
  for _, item in ipairs(b.content) do
    local content = pandoc.write(pandoc.Pandoc(item), "latex")
    table.insert(blocks, pandoc.RawBlock("latex", "\\item " .. content))
  end
  table.insert(blocks, pandoc.RawBlock("latex", "\\end{enumerate}"))

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
  
  if el.classes:includes('highlightencounterbox') then
    local blocks = {}
    -- Begin encounter box with red styling
    table.insert(blocks, pandoc.RawBlock('latex', [[
\begin{tcolorbox}[
  colback=red!8,
  colframe=red!60!black,
  boxrule=0.5pt,
  coltext=red!60!black,
  arc=2pt,
  left=4pt,
  right=4pt,
  top=2pt,
  bottom=2pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper={\blockquoteFont\small\color{red!60!black}}
]
]]))
    -- Inject bomb icon inline into the first paragraph
    for i, b in ipairs(el.content) do
      if i == 1 and b.t == 'Para' then
        local icon = pandoc.RawInline('latex', [[\faBomb\hspace{0.5em}]])
        local inlines = { icon }
        for _, inline in ipairs(b.c) do table.insert(inlines, inline) end
        table.insert(blocks, pandoc.Para(inlines))
      else
        table.insert(blocks, b)
      end
    end
    -- End tcolorbox
    table.insert(blocks, pandoc.RawBlock('latex', [[\end{tcolorbox}]]))
    return blocks

  -- Image callout box
  elseif el.classes:includes('highlightshowimagebox') then
    local blocks = {}
    -- Begin image box with orange styling
    table.insert(blocks, pandoc.RawBlock('latex', [[
\begin{tcolorbox}[
  colback=yellow!8,
  coltext=orange!80!black,
  colframe=orange!80!black,
  boxrule=0.5pt,
  arc=2pt,
  left=4pt,
  right=4pt,
  top=2pt,
  bottom=2pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper={\blockquoteFont\small\color{orange!80!black}}
]
]]))
    -- Inject image icon inline into the first paragraph
    for i, b in ipairs(el.content) do
      if i == 1 and b.t == 'Para' then
        local icon = pandoc.RawInline('latex', [[\faEye\hspace{0.5em}]])
        local inlines = { icon }
        for _, inline in ipairs(b.c) do table.insert(inlines, inline) end
        table.insert(blocks, pandoc.Para(inlines))
      else
        table.insert(blocks, b)
      end
    end
    -- End tcolorbox
    table.insert(blocks, pandoc.RawBlock('latex', [[\end{tcolorbox}]]))
    return blocks
  end
  return nil
end

return {{Meta = Meta}, {Div = Div}}
