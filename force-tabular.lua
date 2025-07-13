-- Force parse markdown in table cells
function RawBlock(el)
  if el.format == "latex" then
    el.text = el.text:gsub("%*%*(.-)%*%*", "\\textbf{%1}")
    el.text = el.text:gsub("%_(.-)%_", "\\emph{%1}")
  end
  return el
end

function Str(el)
  el.text = el.text:gsub("%*%*(.-)%*%*", "\\textbf{%1}")
  el.text = el.text:gsub("%_(.-)%_", "\\emph{%1}")
  return el
end
