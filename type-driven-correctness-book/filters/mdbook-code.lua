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

function RawBlock(el)
  if el.format == "html" then
    -- Convert <summary>Text</summary> to a bold paragraph
    local summary = el.text:match("<summary>(.-)</summary>")
    if summary then
      return pandoc.Para({pandoc.Strong({pandoc.Str(summary)})})
    end
    -- Drop bare <details> and </details> tags
    if el.text:match("^%s*</?details>%s*$") then
      return {}
    end
  end
end

return {{CodeBlock = CodeBlock, RawBlock = RawBlock}}
