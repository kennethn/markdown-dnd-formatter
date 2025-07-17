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
  -- Inject spacing override before bullet lists
  local function insert_itemsep_before_lists(blocks)
    local new_blocks = {}
    for _, blk in ipairs(blocks) do
      if blk.t == "BulletList" then
        table.insert(new_blocks, pandoc.RawBlock("latex", "\\setlength{\\itemsep}{0pt}"))
      end
      table.insert(new_blocks, blk)
    end
    return new_blocks
  end

  local monster_content = insert_itemsep_before_lists(el.content)

  local blocks = {
    pandoc.RawBlock("latex", "\\vfill\\break"), 
    pandoc.RawBlock("latex", "\\begingroup"),
    pandoc.RawBlock("latex", [[
\makeatletter
\clubpenalty=150
\widowpenalty=150
\displaywidowpenalty=150
\blockquoteFont
\fontsize{9pt}{9pt}\selectfont
\setlength{\parskip}{3pt}
\makeatletter
\setlist[itemize]{left=1.5em, itemsep=0pt, topsep=6pt, parsep=0pt, partopsep=0pt}
\setlist[enumerate]{left=1.5em, itemsep=2pt, topsep=6pt, parsep=0pt, partopsep=0pt}


\renewcommand{\sectionsize}{\LARGE}
\renewcommand{\subsectionsize}{\normalsize}
\renewcommand{\subsubsectionsize}{\normalsize}

\titlespacing*{\section}{0pt}{6pt plus 2pt minus 1pt}{2pt}
\titlespacing*{\subsection}{0pt}{6pt plus 1pt minus 1pt}{2pt}
\titlespacing*{\subsubsection}{0pt}{4pt plus 1pt minus 1pt}{2pt}
\titlespacing*{\subsubsubsection}{0pt}{4pt plus 1pt minus 1pt}{2pt}

\titleformat{\subsection}[block]
  {\stickysubsection\subsectionsize\color{subsectioncolor}\headerfont}
  {}
  {0pt}
  {}
  [\vspace{0pt}\color{subsectioncolor}\hrule height 1pt]
% Local override for \tightlist so global version doesn't bleed in
\def\tightlist{%
  \setlength{\itemsep}{0pt}%
  \setlength{\topsep}{6pt}%
  \setlength{\parsep}{0pt}%
  \setlength{\parskip}{0pt}%
  \setlength{\partopsep}{0pt}%
}
\makeatother

]]),
  }

  -- Write the filtered content into LaTeX
  local inner_doc = pandoc.Pandoc(monster_content)
  local inner_tex = pandoc.write(inner_doc, "latex")
  table.insert(blocks, pandoc.RawBlock("latex", inner_tex))
  table.insert(blocks, pandoc.RawBlock("latex", "\\endgroup"))

  return blocks
end

  
  if el.classes:includes('highlightencounterbox') then
    local blocks = {}
    -- Begin encounter box with red styling
    table.insert(blocks, pandoc.RawBlock('latex', [[
\begin{tcolorbox}[
  colback={sectioncolor},
  colframe={sectioncolor},
  boxrule=0pt,
  coltext=white,
  arc=4pt,
  left=4pt,
  right=4pt,
  top=2pt,
  bottom=2pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper={\fontsize{9pt}{6pt}\selectfont\color{white}}
]
]]))
    -- Inject bomb icon inline into the first paragraph
    for i, b in ipairs(el.content) do
      if i == 1 and b.t == 'Para' then
        local icon = pandoc.RawInline('latex', [[\faDragon\hspace{0.8em}\begin{minipage}[t]{\dimexpr\linewidth-1.8em\hangindent=1.8em\hangafter=0}]])
        local inlines = { icon }
        for _, inline in ipairs(b.c) do table.insert(inlines, inline) end
        table.insert(blocks, pandoc.Para(inlines))
      else
        table.insert(blocks, b)
      end
    end
    -- End tcolorbox
    table.insert(blocks, pandoc.RawBlock('latex', [[\end{minipage}\end{tcolorbox}]]))
    return blocks

  -- Image callout box
  elseif el.classes:includes('highlightshowimagebox') then
    local blocks = {}
    -- Begin image box with orange styling
    table.insert(blocks, pandoc.RawBlock('latex', [[
\begin{tcolorbox}[
  colback=yellow!8,
  coltext={sectioncolor},
  colframe={sectioncolor},
  boxrule=0.25pt,
  arc=4pt,
  left=4pt,
  right=4pt,
  top=2pt,
  bottom=2pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper={\fontsize{9pt}{6pt}\selectfont\color{sectioncolor}}
]
]]))
    -- Inject image icon inline into the first paragraph
    for i, b in ipairs(el.content) do
      if i == 1 and b.t == 'Para' then
        local icon = pandoc.RawInline('latex', [[\faEye\hspace{0.8em}\begin{minipage}[t]{\dimexpr\linewidth-1.8em\hangindent=1.8em\hangafter=0}]])
        
        local inlines = { icon }
        for _, inline in ipairs(b.c) do table.insert(inlines, inline) end
        table.insert(blocks, pandoc.Para(inlines))
      else
        table.insert(blocks, b)
      end
    end
    -- End tcolorbox
    table.insert(blocks, pandoc.RawBlock('latex', [[\end{minipage}\end{tcolorbox}]]))
    return blocks
  end
  return nil
end

return {{Meta = Meta}, {Div = Div}}
