--- Pandoc Lua filter to render Mermaid diagrams as images for PDF output.
---
--- Requires mmdc (mermaid-cli) to be installed.
--- Install via: npm install -g @mermaid-js/mermaid-cli
---
--- If mmdc is not available, mermaid code blocks are rendered as plain
--- code blocks with the label "mermaid".

local mmdc_available = nil

local function check_mmdc()
  if mmdc_available == nil then
    local handle = io.popen("mmdc --version 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      mmdc_available = result ~= nil and result ~= ""
    else
      mmdc_available = false
    end
  end
  return mmdc_available
end

local diagram_count = 0

function CodeBlock(el)
  if not el.classes[1] or el.classes[1] ~= "mermaid" then
    return nil
  end

  if not check_mmdc() then
    -- Fallback: keep as a code block
    return nil
  end

  diagram_count = diagram_count + 1

  -- Use pandoc's sha1 for a unique, safe directory name under /tmp
  local hash = pandoc.utils.sha1(el.text .. tostring(diagram_count))
  local tmpdir = "/tmp/mermaid-" .. hash
  os.execute('mkdir -p "' .. tmpdir .. '"')

  local infile = tmpdir .. "/input.mmd"
  local outfile = tmpdir .. "/output.png"

  local f, err = io.open(infile, "w")
  if not f then
    io.stderr:write("mermaid filter: cannot write temp file: " .. (err or "") .. "\n")
    os.execute('rm -rf "' .. tmpdir .. '"')
    return nil
  end
  f:write(el.text)
  f:close()

  local cmd = string.format(
    'mmdc -i "%s" -o "%s" -b transparent -w 800 2>/dev/null',
    infile, outfile
  )
  local success = os.execute(cmd)

  if success then
    -- Read the generated image
    local imgf = io.open(outfile, "rb")
    if imgf then
      -- Copy image to working directory so pandoc can find it
      local imgname = string.format("mermaid-%d.png", diagram_count)
      local outf, oerr = io.open(imgname, "wb")
      if outf then
        outf:write(imgf:read("*a"))
        outf:close()
        imgf:close()
        os.execute('rm -rf "' .. tmpdir .. '"')
        local caption = el.attributes["alt"] or ""
        return pandoc.Para({pandoc.Image({pandoc.Str(caption)}, imgname)})
      end
      imgf:close()
    end
  end

  -- Clean up on failure
  os.execute('rm -rf "' .. tmpdir .. '"')
  return nil
end

return {{CodeBlock = CodeBlock}}
