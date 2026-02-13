function adjust_spacing(blocks)
  local out = {}
  for i = 1, #blocks do
    local this = blocks[i]
    local prev = blocks[i - 1]

    if (this.t == "BulletList" or this.t == "OrderedList")
        and prev and prev.t == "Header"
        and (prev.level == 2 or prev.level == 3) then
      table.insert(out, pandoc.RawBlock("latex", "\\vspace{7pt}"))
    end

    table.insert(out, this)
  end
  return out
end

return {
  {
    Pandoc = function(doc)
      doc.blocks = adjust_spacing(doc.blocks)
      return doc
    end
  }
}
