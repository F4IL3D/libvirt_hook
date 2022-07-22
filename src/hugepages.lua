-- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_tuning_and_optimization_guide/sect-virtualization_tuning_optimization_guide-memory-tuning
local fs = require("fs")

local hpages = {}
hpages.__index = hpages

local function getContent(path)
  local file = io.open(path)
  local number = file:read()
  file:close()
  if number then
    return tonumber(number)
  end
  return nil
end

local function toInt(num)
  local s = tostring(num)
  local i, j = string.find(s, '%.')
  if i then
    return tonumber(s:sub(1, i-1))
  else
    return num
  end
end

function hpages.new(pages, unite)
  local self = setmetatable({}, hpages)
  local unite = unite or "KB"
  local path = {
    -- ["KB"] = "/sys/devices/system/node/#/hugepages/hugepages-2048kB/nr_hugepages",
    ["KB"] = "/tmp/sys/devices/system/node/#/hugepages/hugepages-2048kB/nr_hugepages",
    -- ["GB"] = "/sys/devices/system/node/#/hugepages/hugepages-1048576kB/nr_hugepages",
    ["GB"] = "/tmp/sys/devices/system/node/#/hugepages/hugepages-1048576kB/nr_hugepages",
  }
  local nodes = fs.search("/tmp/sys/devices/system/node/", "node%d+")
  local size = pages / #nodes
  local files = {}

  for _, node in pairs(nodes) do
    local u = string.upper(unite)
    if path[u] then
      local new_path = string.gsub(path[u], "#", node)
      if fs.isFile(new_path) then
        table.insert(files, new_path)
      else
        return nil, "File did not exist: " .. new_path
      end
    else
      return nil, "Wrong unite, Please provide 'kb' or 'gb'!"
    end
  end

  local function setPages(dealloc)
    for _, path in pairs(files) do
      local content = getContent(path)
      local file, err = io.open(path, "w+")
      if not file then return nil, err end

      if content then
        if not dealloc then
          file:write(content + size)
        elseif content - size ~= 0 then
          file:write(content - size)
        end
      else
        if not dealloc then
          file:write(size)
        end
      end
      file:close()
    end
  end

  function self.alloc()
    setPages()
  end

  function self.dealloc()
    setPages(true)
  end
  return self
end

return setmetatable(hpages, {
  __call = function(_, ...)
    return hpages.new(...)
  end
})
