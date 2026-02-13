-- utils.lua
-- Shared utilities for D&D markdown filters

local utils = {}

-- =========================
-- JSON Decoder
-- =========================

-- Minimal recursive descent JSON parser (fallback for Pandoc < 3.0)
local function _decode_json(str)
  local pos = 1

  local function skip_ws()
    local _, ep = str:find('^[ \t\r\n]+', pos)
    if ep then pos = ep + 1 end
  end

  local function parse_string()
    pos = pos + 1 -- skip opening "
    local parts = {}
    while pos <= #str do
      local c = str:sub(pos, pos)
      if c == '\\' then
        local nc = str:sub(pos + 1, pos + 1)
        if     nc == '"'  then table.insert(parts, '"')
        elseif nc == '\\' then table.insert(parts, '\\')
        elseif nc == '/'  then table.insert(parts, '/')
        elseif nc == 'n'  then table.insert(parts, '\n')
        elseif nc == 't'  then table.insert(parts, '\t')
        elseif nc == 'r'  then table.insert(parts, '\r')
        else table.insert(parts, nc)
        end
        pos = pos + 2
      elseif c == '"' then
        pos = pos + 1
        return table.concat(parts)
      else
        table.insert(parts, c)
        pos = pos + 1
      end
    end
    error("Unterminated JSON string")
  end

  local parse_value -- forward declaration

  local function parse_array()
    pos = pos + 1 -- skip [
    local arr = {}
    skip_ws()
    if str:sub(pos, pos) == ']' then pos = pos + 1; return arr end
    while true do
      skip_ws()
      table.insert(arr, parse_value())
      skip_ws()
      local c = str:sub(pos, pos)
      if c == ',' then pos = pos + 1
      elseif c == ']' then pos = pos + 1; return arr
      else error("Expected ',' or ']' in JSON array at position " .. pos) end
    end
  end

  local function parse_object()
    pos = pos + 1 -- skip {
    local obj = {}
    skip_ws()
    if str:sub(pos, pos) == '}' then pos = pos + 1; return obj end
    while true do
      skip_ws()
      local key = parse_string()
      skip_ws()
      pos = pos + 1 -- skip :
      skip_ws()
      obj[key] = parse_value()
      skip_ws()
      local c = str:sub(pos, pos)
      if c == ',' then pos = pos + 1
      elseif c == '}' then pos = pos + 1; return obj
      else error("Expected ',' or '}' in JSON object at position " .. pos) end
    end
  end

  parse_value = function()
    skip_ws()
    local c = str:sub(pos, pos)
    if c == '"' then return parse_string()
    elseif c == '{' then return parse_object()
    elseif c == '[' then return parse_array()
    elseif str:sub(pos, pos + 3) == 'true' then pos = pos + 4; return true
    elseif str:sub(pos, pos + 4) == 'false' then pos = pos + 5; return false
    elseif str:sub(pos, pos + 3) == 'null' then pos = pos + 4; return nil
    elseif c == '-' or c:match('%d') then
      local num = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
      pos = pos + #num
      return tonumber(num)
    else
      error("Unexpected character '" .. c .. "' in JSON at position " .. pos)
    end
  end

  skip_ws()
  return parse_value()
end

function utils.decode_json(str)
  -- Use Pandoc's built-in JSON decoder if available (Pandoc 3.0+)
  if pandoc and pandoc.json and pandoc.json.decode then
    local ok, result = pcall(pandoc.json.decode, str)
    if ok then return result end
  end
  return _decode_json(str)
end

-- =========================
-- Config Loading
-- =========================

local _config_cache = nil

function utils.get_project_root()
  local script_path = PANDOC_SCRIPT_FILE or ""
  local filters_dir = script_path:match("^(.*)/[^/]+$") or "."
  return filters_dir:match("^(.*)/filters$") or filters_dir .. "/.."
end

function utils.load_config()
  if _config_cache then return _config_cache end
  local root = utils.get_project_root()
  local path = root .. "/config/transform-config.json"
  local f = io.open(path, "r")
  if not f then
    io.stderr:write("Warning: Could not open config: " .. path .. "\n")
    _config_cache = {}
    return _config_cache
  end
  local content = f:read("*a")
  f:close()
  _config_cache = utils.decode_json(content)
  return _config_cache
end

-- =========================
-- LaTeX Box Helpers
-- =========================

-- Create a tcolorbox with specified styling
function utils.create_tcolorbox(color, border_color, icon, content)
  local blocks = {}

  -- Begin tcolorbox with styling
  table.insert(blocks, pandoc.RawBlock('latex', string.format([[
\begin{tcolorbox}[
  enhanced,
  breakable,
  rounded corners,
  arc=9pt,
  colback={%s},
  colframe={%s},
  boxrule=1pt,
  coltext=black,
  left=4pt,
  right=4pt,
  top=2pt,
  bottom=2pt,
  boxsep=4pt,
  before skip=10pt,
  after skip=10pt,
  fontupper={\blockquoteFont\selectfont}
]
]], color, color)))

  -- Inject icon into first paragraph
  for i, block in ipairs(content) do
    if i == 1 and block.t == 'Para' then
      local icon_latex = string.format(
        [[\footnotesize\color{%s}%s\hspace{0.8em}\selectfont\begin{minipage}[t]{\dimexpr\linewidth-1.8em\hangindent=1.8em\hangafter=0}]],
        border_color, icon
      )
      local inlines = { pandoc.RawInline('latex', icon_latex) }
      for _, inline in ipairs(block.c) do
        table.insert(inlines, inline)
      end
      table.insert(blocks, pandoc.Para(inlines))
    else
      table.insert(blocks, block)
    end
  end

  -- End tcolorbox
  table.insert(blocks, pandoc.RawBlock('latex', [[\end{minipage}\end{tcolorbox}]]))
  return blocks
end

-- Flatten list content into inline elements
function utils.flatten_list_content(list_items)
  local new_items = {}
  for _, item in ipairs(list_items) do
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
  return new_items
end

return utils
