local seen_first_h1 = false

function Header(el)
  if el.level == 1 and not seen_first_h1 then
    seen_first_h1 = true
    local content = pandoc.utils.stringify(el.content)
    return pandoc.RawBlock("latex", [[
\begingroup
\LARGE\color{sectioncolor}\headerfont
\faCertificate
\\[-2pt]
]] .. content .. [[
\\[-18pt]
\color{sectioncolor}\rule{\linewidth}{2pt}
\\[-2pt]
\endgroup
]])
  else
    return el
  end
end
