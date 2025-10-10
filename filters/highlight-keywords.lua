-- highlight-keywords.lua
-- Highlights specific keywords and character names in D&D notes

-- Load keywords from external file
local function load_keywords(filename)
  local keywords = {}
  local max_len = 0

  local file = io.open(filename, "r")
  if not file then
    io.stderr:write("Warning: Could not open " .. filename .. "\n")
    return keywords, 0
  end

  for line in file:lines() do
    -- Strip whitespace and skip empty lines or comments
    local keyword = line:match("^%s*(.-)%s*$")
    if keyword ~= "" and not keyword:match("^#") then
      keywords[keyword] = true
      -- Calculate word count for max_len
      local word_count = 0
      for _ in keyword:gmatch("%S+") do
        word_count = word_count + 1
      end
      max_len = math.max(max_len, word_count)
    end
  end

  file:close()
  return keywords, max_len
end

-- Get the directory of the current script and go up one level to the main directory
local script_path = PANDOC_SCRIPT_FILE or arg[0] or ""
local script_dir = script_path:match("(.*[/\\])") or "./"
local keywords_file = script_dir .. "../keywords.txt"

local keywords, MAX_KEYWORD_LEN = load_keywords(keywords_file)

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
    "\\textbf{" .. safe .. "}"
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
        x.content = highlight_inlines(x.content)
        table.insert(out,x)
      else
        table.insert(out,x)
      end
      i = i + 1
    end
  end
  return out
end

-- =========================
-- Pandoc Filters
-- =========================

-- Export the document-level filter
return {
  { Pandoc = function(doc)
      doc.blocks = pandoc.List(doc.blocks):map(function(blk)
        if blk.t == "BlockQuote" then
          return blk -- return unchanged
        elseif blk.t == "Para" then
          blk.content = highlight_inlines(blk.content)
          return blk
        elseif blk.t == "Plain" then
          blk.content = highlight_inlines(blk.content)
          return blk
        elseif blk.t == "Header" then
          return blk -- skip headers
        elseif blk.t == "Div" then
          if blk.classes:includes("highlightshowimagebox")
          or blk.classes:includes("highlightencounterbox")
          or blk.classes:includes("rememberbox")
          or blk.classes:includes("musicbox") then
            return blk
          end
          -- Process div content recursively, but skip blockquotes
          blk.content = pandoc.List(blk.content):map(function(inner_blk)
            if inner_blk.t == "BlockQuote" then
              return inner_blk
            elseif inner_blk.t == "Para" then
              inner_blk.content = highlight_inlines(inner_blk.content)
              return inner_blk
            elseif inner_blk.t == "Plain" then
              inner_blk.content = highlight_inlines(inner_blk.content)
              return inner_blk
            else
              return inner_blk
            end
          end)
          return blk
        else
          return blk
        end
      end)
      return doc
    end }
}
