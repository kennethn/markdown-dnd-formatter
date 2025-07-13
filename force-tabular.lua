-- Force parse markdown in table cells
function RawBlock(el)
  if el.format == "latex" then
    el.text = el.text:gsub("%*%*(.-)%*%*", "\\textbf{%1}")
    el.text = el.text:gsub("%_(.-)%_", "\\emph{%1}")
  end
  return el
end

function Str(el)
  -- Bold and italics conversion
  el.text = el.text:gsub("%*%*(.-)%*%*", "\\textbf{%1}")
  el.text = el.text:gsub("%_(.-)%_", "\\emph{%1}")

  -- Convert negative numbers to \textminus{X}
  -- Matches cases like -1, -12, -3.5, etc. but only at start of string or after space
  el.text = el.text:gsub("(^|%s)%-(%d[%d%.]*)", "%1\\textminus%2")

  return el
end

