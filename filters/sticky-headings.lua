local result = {}

function Pandoc(doc)
  local blocks = doc.blocks
  local i = 1

  while i <= #blocks do
    local current = blocks[i]
    local next = blocks[i + 1]

    local is_section_pair =
      current.t == "Header" and current.level == 1 and
      next and next.t == "Header" and next.level == 2

    local is_subsection_pair =
      current.t == "Header" and current.level == 2 and
      next and next.t == "Header" and next.level == 3

    if is_section_pair or is_subsection_pair then
      -- Adjust space based on heading level if needed
      table.insert(result, pandoc.RawBlock("latex", "\\needspace{7\\baselineskip}"))
      table.insert(result, current)
      table.insert(result, next)
      i = i + 2
    else
      table.insert(result, current)
      i = i + 1
    end
  end

  return pandoc.Pandoc(result, doc.meta)
end
