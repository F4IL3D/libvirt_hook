local lfs = require("lfs")

local M = {}

function M.exist(path)
  local type, _ = lfs.attributes(path, "mode")
  if type then
    return true
  end
  return false
end

function M.isFile(path)
  if lfs.attributes(path, "mode") == "file" then
    return true
  end
  return false
end

function M.isDir(path)
  if lfs.attributes(path, "mode") == "directory" then
    return true
  end
  return false
end

function M.search(path, pattern)
  local res = {}
  for obj in lfs.dir(path) do
    if string.match(obj, pattern) then
      table.insert(res, obj)
    end
  end
  table.sort(res)
  return res
end

return M
