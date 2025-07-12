-- highlight-keywords.lua
-- Bold and color specific keywords in LaTeX output, excluding headers

local keywords = {
  ["Therynzhaal"] = true,
  ["Ryland"] = true,
  ["Kelmenor"] = true,
  ["Glynda"] = true,
  ["Sir Talavar"] = true,
  ["Aeltheryn"] = true,
}

-- Helper to join a sequence of inlines into plain text
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

-- Context flag to skip processing inside headers
local in_header = false

-- Header handlers — set the flag during header processing
function Header(el)
  in_header = true
  el.content = Inlines(el.content)
  in_header = false
  return el
end

-- Inline filter with skip logic
function Inlines(inlines)
  if in_header then
    return inlines
  end

  local i = 1
  local output = {}

  while i <= #inlines do
    local matched = false

    for length = 3, 1, -1 do
      if i + length - 1 <= #inlines then
        local slice = {}
        for j = i, i + length - 1 do
          table.insert(slice, inlines[j])
        end

        local text = inlines_to_text(slice)
        local clean_text, punct = text:match("^(.-)([%p%s]*)$")

        if keywords[clean_text] then
          local latex = "\\textcolor{blue!70!black}{\\textbf{" .. clean_text .. "}}" .. (punct or "")
          table.insert(output, pandoc.RawInline("latex", latex))
          i = i + length
          matched = true
          break
        end
      end
    end

    if not matched then
      table.insert(output, inlines[i])
      i = i + 1
    end
  end

  return output
end
