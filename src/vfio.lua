local fs = require("fs")

local vfio = {}
vfio.__index = vfio

local function id(vpath, dpath)
  local vendor = nil
  local device = nil
  local err = nil
  if fs.isFile(vpath) then 
    vendor, err = io.open(vpath)
    if not vendor then return nil, err end
  end
  if fs.isFile(dpath) then
    device, err = io.open(dpath)
    if not device then return nil, err end
  end
  local id = string.gsub(vendor:read(), "0x", "") .. ":" .. string.gsub(device:read(), "0x", "")
  vendor:close()
  device:close()
  return id
end

function vfio.new(device)
  local self = setmetatable({}, vfio)
  self.device = nil
  local probe = "/sys/bus/pci/drivers_probe"
  local new_id = "/sys/bus/pci/drivers/vfio-pci/new_id"
  local sysfs = "/sys/bus/pci/devices/0000:" .. device
  local unbind = nil
  local override = nil
  local vendorId = nil
  local deviceId = nil

  if not string.match(device, "^%d%d:%d%d%.%d$") then
    return nil, "Provided device " .. device .. " did not match Bus:Device.Function pattern!"
  elseif not fs.exist(sysfs) then
    return nil, "Device path did not exist in sysfs: " .. sysfs
  else
    self.device = "0000:" .. device
    unbind = sysfs .. "/driver/unbind"
    override = sysfs .. "/driver_override"
    vendorId = sysfs .. "/vendor"
    deviceId = sysfs .. "/device"
  end

  local function drivers_probe()
    if fs.isFile(probe) then
      local file, err = io.open(probe, "a")
      if not file then return nil, err end
      file:write(self.device)
      file:close()
    else
      return nil, "File did not exist: " .. probe
    end
  end

  local function driver_unbind()
    if fs.isFile(unbind) then
      local file, err = io.open(unbind, "a")
      if not file then return nil, err end
      file:write(self.device)
      file:close()
    else
      return nil, "File did not exist: " .. unbind
    end
  end

  local function driver_override(clear)
    if fs.isFile(override) then
      if clear then
        local file, err = io.open(override, "w+")
        if not file then return nil, err end
        file:write("")
        file:close()
      else
        local file, err = io.open(override, "a")
        if not file then return nil, err end
        file:write("vfio-pci")
        file:close()
      end
    else
      return nil, "File did not exist: " .. override
    end
  end

  local function setId()
    local id, err = id(vendorId, deviceId)
    if id then
      local file, err = io.open(new_id, "a")
      if not file then return nil, err end
      file:write(id)
      file:close()
    else
      return nil, "No id because the following err: " .. err
    end
  end

  function self.bind(force)
    if force then
      setId()
    end
    driver_override()
    driver_unbind()
    drivers_probe()
  end

  function self.unbind()
    driver_override(true)
    driver_unbind()
    drivers_probe()
  end
  return self
end

return setmetatable(vfio, {
  __call = function(_, ...)
    return vfio.new(...)
  end
})
