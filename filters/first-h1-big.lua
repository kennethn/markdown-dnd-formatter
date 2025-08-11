-- Escape LaTeX special characters
function escape_latex(str)
  local replacements = {
    ["\\"] = "\\textbackslash{}",
    ["{"] = "\\{", ["}"] = "\\}",
    ["$"] = "\\$", ["&"] = "\\&", ["%"] = "\\%",
    ["#"] = "\\#", ["_"] = "\\_", ["^"] = "\\^{}", ["~"] = "\\~{}"
  }
  return (str:gsub("[\\${}&%%#_^~]", replacements))
end

local seen_first_h1 = false

function Header(el)
  if el.level == 1 and not seen_first_h1 then
    seen_first_h1 = true
    local content = pandoc.utils.stringify(el.content)
    local escaped = escape_latex(content)

    return pandoc.RawBlock("latex", [[
\newcommand{\staticleftmark}{]] .. escaped .. [[}
\begingroup
\begin{center}
\vspace*{-16pt}
\huge\color{sectioncolor}\headerfontbold\faDiceD20\,
]] .. escaped .. [[
\\[-12pt]
\color{sectioncolor}\rule{\linewidth}{2pt}
\end{center}
\endgroup
]])
  else
    return el
  end
end

function Pandoc(doc)
  if not seen_first_h1 then
    -- Prepend the missing \staticleftmark definition
    table.insert(doc.blocks, 1, pandoc.RawBlock("latex", [[
\newcommand{\staticleftmark}{}
]]))
  end
  return doc
end