-- highlight-keywords.lua

local keywords = {
  ["Therynzhaal"] = true,
  ["Ryland"] = true,
  ["Kelmenor"] = true,
  ["Glynda"] = true,
  ["Sir Talavar"] = true,
  ["Aeltheryn"] = true,
}

local in_header = false
local skip_formatting = false

-- Helper to convert inlines to plain text
local function inlines_to_text(inlines)
  local parts = {}
  for _, inline in ipairs(inlines) do
    if inline.t == "Str" then
      table.insert(parts, inline.text)
    elseif inline.t == "Space" then
      table.insert(parts, " ")
    end
  end
  return table.concat(parts)
end

-- Wrap text in bold, smallcaps, and blue LaTeX
local function latex_bold(text)
  return pandoc.RawInline("latex", "\\textcolor{blue!70!black}{\\textbf{\\smallcapstext{" .. string.lower(text) .. "}}}")
end

-- Keyword formatting, unless suppressed
function Inlines(inlines)
  if in_header or skip_formatting then return inlines end

  local output = {}
  for _, inline in ipairs(inlines) do
    if inline.t == "Str" then
      local replaced = false
      for keyword, _ in pairs(keywords) do
        local start_pos, end_pos = string.find(inline.text, keyword)
        if start_pos then
          if start_pos > 1 then
            table.insert(output, pandoc.Str(string.sub(inline.text, 1, start_pos - 1)))
          end
          table.insert(output, latex_bold(keyword))
          if end_pos < #inline.text then
            table.insert(output, pandoc.Str(string.sub(inline.text, end_pos + 1)))
          end
          replaced = true
          break
        end
      end
      if not replaced then
        table.insert(output, inline)
      end
    else
      table.insert(output, inline)
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

-- Only apply wikilink formatting if not suppressed
function Span(el)
  if skip_formatting then return nil end
  if el.classes:includes("wikilink") then
    local text = inlines_to_text(el.content)
    return latex_bold(text)
  end
  return nil
end

-- Suppress formatting inside highlightshowimagebox
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
