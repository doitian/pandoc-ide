--- Pandoc Lua filter to normalize mdBook-style code blocks for PDF output.
---
--- Handles:
--- 1. Code block classes like "rust,ignore", "rust,no_run", "rust,compile_fail",
---    "rust,edition2021", etc. → normalized to just "rust" for syntax highlighting.
--- 2. Hidden lines in Rust code blocks (lines starting with "# ") are stripped,
---    matching mdBook's behavior of hiding setup code.
--- 3. HTML <details>/<summary> blocks are converted to visible content with
---    a bold label (since collapsible sections don't exist in PDF).

function CodeBlock(el)
  local dominated_by_rust = false

  for i, class in ipairs(el.classes) do
    if class:match("^rust") then
      el.classes[i] = "rust"
      dominated_by_rust = true
    end
  end

  -- Deduplicate: if multiple classes resolved to "rust", keep only one
  if dominated_by_rust then
    local seen_rust = false
    local new_classes = {}
    for _, class in ipairs(el.classes) do
      if class == "rust" then
        if not seen_rust then
          table.insert(new_classes, "rust")
          seen_rust = true
        end
      else
        table.insert(new_classes, class)
      end
    end
    el.classes = new_classes

    -- Strip hidden lines (mdBook hides lines starting with "# ")
    local lines = {}
    for line in el.text:gmatch("([^\n]*)\n?") do
      if not (line:match("^# ") or line == "#") then
        table.insert(lines, line)
      end
    end
    el.text = table.concat(lines, "\n")
    -- Trim leading/trailing blank lines left by stripping
    el.text = el.text:gsub("^\n+", ""):gsub("\n+$", "")
  end

  return el
end

--- Walk the full document block list to convert <summary>...</summary>
--- sections into bold paragraphs and drop <details> wrapper tags.
function Pandoc(doc)
  local blocks = doc.blocks
  local new_blocks = {}
  local i = 1
  while i <= #blocks do
    local b = blocks[i]
    if b.t == "RawBlock" and b.format == "html" then
      local text = b.text
      -- Drop <details> and </details> tags
      if text:match("^%s*</?details>%s*$") then
        i = i + 1
      -- Handle self-contained <summary>Text</summary>
      elseif text:match("<summary>(.-)</summary>") then
        local summary = text:match("<summary>(.-)</summary>")
        table.insert(new_blocks, pandoc.Para({pandoc.Strong({pandoc.Str(summary)})}))
        i = i + 1
      -- Handle split <summary> tag: make the next block bold, drop </summary>
      elseif text:match("^%s*<summary>%s*$") then
        i = i + 1
        -- Collect blocks until </summary>
        while i <= #blocks do
          local nb = blocks[i]
          if nb.t == "RawBlock" and nb.format == "html" and nb.text:match("^%s*</summary>%s*$") then
            i = i + 1
            break
          end
          -- Make the summary content bold
          if nb.t == "Plain" or nb.t == "Para" then
            table.insert(new_blocks, pandoc.Para({pandoc.Strong(nb.content)}))
          else
            table.insert(new_blocks, nb)
          end
          i = i + 1
        end
      else
        table.insert(new_blocks, b)
        i = i + 1
      end
    else
      table.insert(new_blocks, b)
      i = i + 1
    end
  end
  doc.blocks = new_blocks
  return doc
end

return {{CodeBlock = CodeBlock, Pandoc = Pandoc}}
