local fs = require("fs")

local cpu = {}
cpu.__index = cpu

setmetatable(cpu, {
  __call = function(cls, ...)
    return cls.new(...)
  end
})

function cpu.new()
  local self = setmetatable({}, cpu)
  local path = "/sys/devices/system/cpu/#/cpufreq/scaling_governor"
  local cpus = fs.search("/sys/devices/system/cpu", "cpu%d+")
  local files = {}

  for _, cpu in pairs(cpus) do
    local new_path = string.gsub(path, "#", cpu)
    if fs.isFile(new_path) then
      table.insert(files, new_path)
    else
      return nil, "File did not exist: " .. new_path
    end
  end

  self.modes = setmetatable(
    {
      ["performance"] = "performance",
      ["powersave"] = "powersave",
      ["userspace"] = "userspace",
      ["ondemand"] = "ondemand",
      ["conservative"] = "conservative",
      ["schedutil"] = "schedutil"
    },
    {
      __index    = function(_, k) error("Attempt to index non-existant enum '"..tostring(k).."'.", 2) end,
      __newindex = function()     error("Attempt to write to static enum", 2) end,
    }
  )

  function self.setGovernor(mode)
    if not self.modes[mode] then return nil, "Unsupported mode: " .. mode end
    for _, path in pairs(files) do
        local file, err = io.open(path, "w+")
        if not file then return nil, err end
        file:write(self.modes[mode])
        file:close()
    end
  end
  function self.performance()
    self.setGovernor(self.modes.performance)
  end

  function self.onDemand()
    self.setGovernor(self.modes.ondemand)
  end
  return self
end

return cpu
