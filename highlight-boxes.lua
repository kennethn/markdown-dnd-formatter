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
    pandoc.RawBlock("latex", "\\clearpage"),
    pandoc.RawBlock("latex", [[
\vspace*{-2\baselineskip}
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
\setlist[itemize]{left=1.5em, itemsep=0pt, topsep=6pt, parsep=0pt, partopsep=0pt}
\setlist[enumerate]{left=1.5em, itemsep=2pt, topsep=6pt, parsep=0pt, partopsep=0pt}

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
  colback=red!8,
  colframe=red!60!black,
  boxrule=0.25pt,
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
  boxrule=0.25pt,
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
