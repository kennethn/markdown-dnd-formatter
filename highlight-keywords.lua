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

local in_header = false
local skip_formatting = false

-- Helper to convert inlines to plain text
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

-- Wrap text in LaTeX formatting
local function latex_bold(text)
 -- return pandoc.RawInline("latex", "\\textcolor{keywordcolor}{\\textbf{" .. text .. "}}")
     return pandoc.RawInline("latex", "\\textcolor{keywordcolor}{\\textbf{\\textsc{" .. string.lower(text) .. "}}}")
end

-- Checks if a keyword matches, stripping trailing punctuation
local function normalize_keyword(text)
  return text:match("^(.-)[%.,;:!?]?$")
end

-- Try matching keyword starting at index i
local function match_keyword(inlines, i)
  for len = #inlines - i + 1, 1, -1 do
    local slice = {}
    for j = i, i + len - 1 do
      table.insert(slice, inlines[j])
    end
    local raw_text = inlines_to_text(slice)
    local normalized = normalize_keyword(raw_text)
    if keywords[normalized] then
      -- Preserve punctuation by splitting
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

-- Main processing logic
function Inlines(inlines)
  if in_header or skip_formatting then return inlines end

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

function Header(el)
  in_header = true
  el.content = Inlines(el.content)
  in_header = false
  return el
end

function Span(el)
  if skip_formatting then return nil end
  if el.classes:includes("wikilink") then
    local text = inlines_to_text(el.content)
    local normalized = normalize_keyword(text)
    return latex_bold(normalized)
  end
  return nil
end

function Div(el)
  if el.classes:includes("highlightshowimagebox") then
    skip_formatting = true
    el.content = pandoc.walk_block(el, {
      Inlines = Inlines,
      Header = Header,
      Span = Span
    })
    skip_formatting = false
    return el
  end
end

return {
  { Inlines = Inlines, Header = Header, Span = Span, Div = Div }
}
