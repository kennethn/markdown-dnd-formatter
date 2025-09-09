-- highlight-boxes.lua
-- Handles custom fenced Divs, monster stat blocks, and custom callout boxes for D&D notes

-- Get the directory of the current script
local script_dir = debug.getinfo(1, "S").source:match("@?(.*/)") or "./"
package.path = package.path .. ";" .. script_dir .. "?.lua"

local utils = require('utils')

-- Enable tight lists by default
function Meta(meta)
  return {
    pandoc.MetaMap(meta),
    pandoc.MetaBool('tight_lists', true)
  }
end

-- Flatten lists using shared utility
function flatten_bullet_list(blist)
  return pandoc.BulletList(utils.flatten_list_content(blist.content))
end

function flatten_ordered_list(olist)
  return pandoc.OrderedList(olist.start, utils.flatten_list_content(olist.content))
end

-- Main Div filter: handles custom highlightencounterbox and highlightshowimagebox
function Div(el)
  
  -- Monster stat block
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
\monsterFont
\fontsize{9pt}{9pt}\selectfont
\setlength{\parskip}{4pt}
\makeatletter
\setlist[itemize]{left=1.5em, itemsep=1pt, topsep=6pt, parsep=0pt, partopsep=0pt}
\setlist[enumerate]{left=1.5em, itemsep=2pt, topsep=6pt, parsep=0pt, partopsep=0pt}

\titlespacing*{\section}{0pt}{6pt}{4pt}
\titlespacing*{\subsection}{0pt}{6pt}{4pt}
\titlespacing*{\subsubsection}{0pt}{4pt}{4pt}
\titlespacing*{\paragraph}{0pt}{4pt}{4pt}

\titleformat{\section}[block]
  {\stickysubsection\Large\color{monstercolor}\headerfontbold}
  {}
  {0pt}
  {}
  [\vspace{0pt}\color{monstercolor}\hrule height 1pt]

\titleformat{\subsection}[block]
  {\stickysubsection\normalsize\color{monstercolor}\headerfont}
  {}
  {0pt}
  {}
  [\vspace{0pt}\color{monstercolor}\hrule height 1pt]
\titleformat{\subsubsection}[block]
  {\stickysubsection\normalsize\color{monstercolor}\headerfont}
  {}
  {0pt}
  {}
  [\vspace{0pt}\color{monstercolor}\hrule height 1pt]
% Local override for \tightlist so global version doesn't bleed in
\def\tightlist{%
  \setlength{\itemsep}{0pt}%
  \setlength{\topsep}{4pt}%
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

  
  -- Encounter callout box
  if el.classes:includes('highlightencounterbox') then
    return utils.create_tcolorbox(
      'encountercolor', 'encounterborder',
      '\\faIcon{skull-crossbones}', el.content
    )

  -- Image callout box
  elseif el.classes:includes('highlightshowimagebox') then
    return utils.create_tcolorbox(
      'imagecolor', 'imageborder',
      '\\faIcon{scroll}', el.content
    )
  -- Remember callout box
  elseif el.classes:includes('rememberbox') then
    return utils.create_tcolorbox(
      'remembercolor', 'rememberborder',
      '\\faAsterisk', el.content
    )
  -- Music callout box
  elseif el.classes:includes('musicbox') then
    return utils.create_tcolorbox(
      'musiccolor', 'white',
      '\\faIcon{music}', el.content
    )
  end
  return nil
end

return {{Meta = Meta}, {Div = Div}}
