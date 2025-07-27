local seen_first_h1 = false

function Header(el)
  if el.level == 1 and not seen_first_h1 then
    seen_first_h1 = true
    local content = pandoc.utils.stringify(el.content)
    return pandoc.RawBlock("latex", [[
\begingroup
\begin{center}
\fontsize{36pt}{36pt}\color{black}\selectfont
\faDiceD20
\\
\LARGE\color{black}\headerfontbold
]] .. content .. [[
\\[-18pt]
\color{black}\rule{\linewidth}{2pt}
\\[-2pt]
\end{center}
\endgroup
]])
  else
    return el
  end
end
