-- Keyword list
local keywords = {
  ["Therynzhaal"] = true,
  ["Ryland"] = true,
  ["Kelmenor"] = true,
  ["Glynda"] = true,
  ["Sir Talavar"] = true,
  ["Aeltheryn"] = true,
  ["Orcus"] = true,
  ["Raven Queen"] = true,
  ["Summer Queen"] = true,
  ["Titania"] = true
}

-- Utilities
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

local function escape_latex_braces(str)
  return str:gsub("([{}])", "\\%1")
end

local function latex_bold(text)
  local safe = escape_latex_braces(string.lower(text))
  return pandoc.RawInline("latex", "\\hlfancy{imagecolor}{\\textsc{" .. safe .. "}}")
end

local function normalize_keyword(text)
  return text:match("^(.-)[%.,;:!?]?$")
end

local function match_keyword(inlines, i)
  -- Limit to max 3-word keywords for performance
  local MAX_KEYWORD_LEN = 3
  local maxlen = math.min(MAX_KEYWORD_LEN, #inlines - i + 1)
  for len = maxlen, 1, -1 do
    local slice = {}
    for j = i, i + len - 1 do
      table.insert(slice, inlines[j])
    end
    local raw_text = inlines_to_text(slice)
    local normalized = normalize_keyword(raw_text)
    if keywords[normalized] then
      local punctuation = raw_text:match("[%.,;:!?]$")
      local formatted = latex_bold(normalized)
      if punctuation then
        return len, { formatted, pandoc.Str(punctuation) }
      else
        return len, { formatted }
      end
    end
  end
  return nil
end

-- Only highlight keywords in paragraphs and spans
local function highlight_inlines(inlines)
  local output = {}
  local i = 1
  while i <= #inlines do
    local match_len, replacement = match_keyword(inlines, i)
    if match_len then
      for _, item in ipairs(replacement) do
        table.insert(output, item)
      end
      i = i + match_len
    else
      table.insert(output, inlines[i])
      i = i + 1
    end
  end
  return output
end

function Para(el)
  el.content = highlight_inlines(el.content)
  return el
end

function Span(el)
  if el.classes:includes("wikilink") then
    local text = inlines_to_text(el.content)
    local normalized = normalize_keyword(text)
    return latex_bold(normalized)
  end
  -- Otherwise, highlight keywords in span content
  el.content = highlight_inlines(el.content)
  return el
end

function Plain(el)
  el.content = highlight_inlines(el.content)
  return el
end

function Strong(el)
  el.content = highlight_inlines(el.content)
  return el
end

function Emph(el)
  el.content = highlight_inlines(el.content)
  return el
end

function Header(el)
  -- Do NOT highlight keywords in headers
  return el
end

function BlockQuote(el)
  -- Do NOT highlight keywords in blockquotes
  return el
end

function Div(el)
  -- Do NOT highlight keywords inside special boxes
  if el.classes:includes("highlightshowimagebox") or el.classes:includes("highlightencounterbox") then
    return el
  end
  -- Otherwise, walk blocks inside the Div, but skip blockquotes
  return pandoc.walk_block(el, {
    Para = Para,
    Span = Span,
    Plain = Plain,
    Strong = Strong,
    Emph = Emph,
    BlockQuote = BlockQuote
  })
end

return {
  { Para = Para, Span = Span, Plain = Plain, Header = Header, Strong = Strong, BlockQuote = BlockQuote, Emph = Emph, Div = Div }
}