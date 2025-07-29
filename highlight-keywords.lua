-- highlight-keywords.lua

-- 1. Your keyword list
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
  Titania      = true
}

local MAX_KEYWORD_LEN = 3

-- 2. Helpers
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
  local safe = escape_latex_braces(string.lower(kw))
  return pandoc.RawInline("latex",
    "\\hlfancy{keywordcolor}{\\textsc{" .. safe .. "}}"
  )
end

-- 3. Try to match up to 3‑word keywords at position i
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

-- 4. Recursively walk a list of inlines, highlighting only at the top level,
--    but recursing into any Strong/Emph/Span found.
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

-- 5. Block‑level filters

-- only touch paragraphs
function Para(el)
  el.content = highlight_inlines(el.content)
  return el
end

-- and plain blocks
function Plain(el)
  el.content = highlight_inlines(el.content)
  return el
end

-- leave headers completely alone
function Header(el)
  return el
end

-- never highlight inside blockquotes
function BlockQuote(el)
  return el
end

-- skip your special divs, otherwise dive in and only re‑process
-- any paragraphs or plain blocks they contain.
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

-- 6. Export only the block‑level handlers
return {
  { Para       = Para,
    Plain      = Plain,
    Header     = Header,
    BlockQuote = BlockQuote,
    Div        = Div }
}
