--- Pandoc Lua filter to fix mdBook chapter structure for PDF output.
---
--- Handles:
--- 1. Introduction numbering: The introduction chapter (before the first \part)
---    is marked as unnumbered so that subsequent numbered chapters start at 1,
---    matching the original chapter numbers in the heading text.
--- 2. Cross-references: Links to .md files (e.g., ch01-foo.md) used by mdBook
---    for inter-chapter navigation are rewritten to internal PDF anchors.

-- State collected in pass 1
local chapter_num_to_id = {}
local all_headers = {}

-- Pass 1: Collect headers, mark introduction as unnumbered
local function process_doc(doc)
  local seen_part = false

  for _, block in ipairs(doc.blocks) do
    if block.t == "RawBlock" and block.format == "latex"
        and block.text:match("\\part{") then
      seen_part = true
    elseif block.t == "Header" and block.level == 1 then
      local text = pandoc.utils.stringify(block)

      -- Headers before the first \part are introductory — make unnumbered
      if not seen_part and not block.classes:includes("unnumbered") then
        block.classes:insert("unnumbered")
      end

      table.insert(all_headers, { id = block.identifier, text = text })

      -- Extract chapter number from heading text (e.g., "1." from "1. Why Async")
      local num = text:match("^(%d+)%.")
      if num then
        chapter_num_to_id[tonumber(num)] = block.identifier
      end
    end
  end

  return doc
end

-- Resolve a .md filename to a header ID
local function resolve(filename)
  -- Strip any path prefix (e.g., "src/" or "../src/")
  filename = filename:match("([^/]+)$") or filename

  -- Extract chapter number from filename (e.g., "ch01" → 1)
  local num_str = filename:match("^ch(%d+)")
  if num_str then
    local num = tonumber(num_str)

    -- Numbered chapters: match heading that starts with "N."
    if num > 0 and chapter_num_to_id[num] then
      return chapter_num_to_id[num]
    end

    -- ch00 (introduction): return the first header in the document
    if num == 0 and #all_headers > 0 then
      return all_headers[1].id
    end
  end

  -- Fallback: match filename slug against header IDs
  local slug = filename:match("^ch%d+%-(.+)$") or filename
  for _, h in ipairs(all_headers) do
    if h.id == slug or h.id:find(slug, 1, true) then
      return h.id
    end
  end

  return nil
end

-- Pass 2: Rewrite links to .md files
local function rewrite_link(link)
  if not link.target:match("%.md") then
    return nil
  end

  local filename, anchor = link.target:match("^(.-)%.md(#?.*)$")
  if not filename then
    return nil
  end

  local header_id = resolve(filename)
  if header_id then
    if anchor and anchor ~= "" then
      link.target = anchor
    else
      link.target = "#" .. header_id
    end
    return link
  end

  return nil
end

return {
  { Pandoc = process_doc },
  { Link = rewrite_link },
}
