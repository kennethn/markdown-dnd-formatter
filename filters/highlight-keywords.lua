-- highlight-keywords.lua
-- Highlights specific keywords and character names in D&D notes

-- Configuration: Keywords to highlight
local keywords = {
  Therynzhaal   = true,
  Ryland       = true,
  Kelmenor     = true,
  Glynda       = true,
  ["Sir Talavar"] = true,
  Aeltheryn    = true,
  Orcus        = true,
  ["Raven Queen"]  = true,
  ["Summer Queen"] = true,
  Titania      = true,
  Lillion      = true
}

local MAX_KEYWORD_LEN = 3

-- =========================
-- Utility Functions
-- =========================
local function inlines_to_text(slice)
  local parts = {}
  for _, inline in ipairs(slice) do
    if inline.t == "Str" then
      table.insert(parts, inline.text)
    elseif inline.t == "Space" then
      table.insert(parts, " ")
    end
  end
  return table.concat(parts)
end

local function normalize_keyword(text)
  -- strip trailing punctuation
  return text:match("^(.-)[%.,;:!?]?$")
end

local function escape_latex_braces(s)
  return s:gsub("([{}])","\\%1")
end

local function latex_bold(kw)
  local safe = escape_latex_braces(kw)
  return pandoc.RawInline("latex",
    "{\\textcolor{sectioncolor}{\\textbf{" .. safe .. "}}}"
  )
end

-- Keyword matching function
local function match_keyword(inls,i)
  local maxlen = math.min(MAX_KEYWORD_LEN, #inls - i + 1)
  for len = maxlen,1,-1 do
    local slice = {}
    for j = i, i+len-1 do table.insert(slice, inls[j]) end
    local raw = inlines_to_text(slice)
    local norm = normalize_keyword(raw)
    if keywords[norm] then
      local punct = raw:match("[%.,;:!?]$")
      local fmt   = latex_bold(norm)
      if punct then
        return len, { fmt, pandoc.Str(punct) }
      else
        return len, { fmt }
      end
    end
  end
  return nil
end

-- Main highlighting function - recursively processes inline elements
local function highlight_inlines(inls)
  local out = {}
  local i = 1
  while i <= #inls do
    local match_len, repl = match_keyword(inls,i)
    if match_len then
      -- found a keyword
      for _, x in ipairs(repl) do table.insert(out,x) end
      i = i + match_len
    else
      local x = inls[i]
      if x.t == "Strong" or x.t == "Emph" then
        x.content = highlight_inlines(x.content)
        table.insert(out,x)
      elseif x.t == "Span" then
        if x.classes:includes("wikilink") then
          -- special-case your wikilinks
          local txt  = inlines_to_text(x.content)
          local norm = normalize_keyword(txt)
          table.insert(out, latex_bold(norm))
        else
          x.content = highlight_inlines(x.content)
          table.insert(out,x)
        end
      else
        table.insert(out,x)
      end
      i = i + 1
    end
  end
  return out
end

-- =========================
-- Block Walker
-- =========================

local skip_div_classes = {
  highlightshowimagebox = true,
  highlightencounterbox = true,
  rememberbox = true,
  musicbox = true,
}

local function has_skip_class(classes)
  for _, cls in ipairs(classes) do
    if skip_div_classes[cls] then return true end
  end
  return false
end

local function walk_blocks(blocks)
  return pandoc.List(blocks):map(function(blk)
    if blk.t == "BlockQuote" or blk.t == "Header" then
      return blk
    elseif blk.t == "Para" or blk.t == "Plain" then
      blk.content = highlight_inlines(blk.content)
    elseif blk.t == "BulletList" or blk.t == "OrderedList" then
      blk.content = pandoc.List(blk.content):map(function(item)
        return walk_blocks(item)
      end)
    elseif blk.t == "Div" then
      if not has_skip_class(blk.classes) then
        blk.content = walk_blocks(blk.content)
      end
    end
    return blk
  end)
end

-- =========================
-- Pandoc Filters
-- =========================

<<<<<<< Updated upstream
<<<<<<< Updated upstream
-- Process paragraphs
function Para(el)
  el.content = highlight_inlines(el.content)
  return el
end

-- Process plain text blocks
function Plain(el)
  el.content = highlight_inlines(el.content)
  return el
end

-- Skip headers (no highlighting)
function Header(el)
  return el
end

-- Skip blockquotes (no highlighting)
function BlockQuote(el)
  return el
end

-- Process divs selectively
function Div(el)
  if el.classes:includes("highlightshowimagebox")
  or el.classes:includes("highlightencounterbox") then
    return el
  end
  for i, blk in ipairs(el.content) do
    if blk.t == "Para" then
      el.content[i] = Para(blk)
    elseif blk.t == "Plain" then
      el.content[i] = Plain(blk)
    end
  end
  return el
end

-- Export filter functions
return {
  { Para       = Para,
    Plain      = Plain,
    Header     = Header,
    BlockQuote = BlockQuote,
    Div        = Div }
=======
=======
>>>>>>> Stashed changes
return {
  { Pandoc = function(doc)
      doc.blocks = walk_blocks(doc.blocks)
      return doc
    end }
>>>>>>> Stashed changes
}
