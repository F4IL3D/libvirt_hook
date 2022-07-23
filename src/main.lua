#!/usr/bin/env lua

-- package.path = './?.lua;' .. package.path
-- package.path = '../3rd/lualogging/src/?.lua;' .. package.path
-- package.path = '../3rd/lualogging/src/logging/?.lua;' .. package.path
-- package.cpath = '../3rd/lua-cjson/build/?.so;' .. package.cpath
-- package.cpath = '../3rd/luafilesystem/src/?.so;' .. package.cpath

-- ignore script name (arg[0])
local args = {
  ["vm"] = arg[1],
  ["operation"] = arg[2] .. "_" .. arg[3],
  ["extra"] = arg[4]
}

-- Enable logging first
local logging = require("logging")
logging.defaultLogger(require("logging.rolling_file") {
  filename = "/var/log/libvirt_hook.log",
  -- filename = "libvirt_hook.log",
  maxFileSize = 1048576, -- 1 MB
  timestampPattern = "%H:%M:%S %m/%d/%y",
  logPatterns = {
    [logging.DEBUG] = "%date | %level %message (%source)\n",
    [logging.INFO] = "%date | %level %message\n",
    [logging.WARN] = "%date | %level %message\n",
    [logging.ERROR] = "%date | %level %message (%source)\n",
    [logging.FATAL] = "%date | %level %message (%source)\n",
  },
  logLevel = logging.ERROR
})
log = logging.defaultLogger()

-- loading other modules
local fs_mod = require("fs")
local vfio_mod = require("vfio")
local cpu_mod = require("cpugov")
local pages_mod = require("hugepages")
-- binary modules
local json = require("cjson")

local config = nil
local err = nil
local levels = {
  ["DEBUG"] = logging.DEBUG,
  ["INFO"] = logging.INFO,
  ["WARN"] = logging.WARN,
  ["ERROR"] = logging.ERROR,
  ["FATAL"] = logging.FATAL,
}

-- loading config
log:debug("Open config file")
local file, err = io.open("config.json", "rb")
if file then
  log:debug("Read config file")
  local data = file:read("*a")
  log:debug(data)
  file:close()
  log:debug("Try to decode json data.")
  ok, config = pcall(json.decode,data)
  if not ok then
    log:error("Error decode json: ")
    log:error("Data: " .. data)
    return
  end
else
  log:error("Could not open config file:")
  log:err(err)
  return
end
log:debug("Got config: ")
log:debug(config)
log:info("Successfully loaded config from file")

local level = string.upper(config["loglevel"])
if levels[level] then
  log:setLevel(levels[level])
  log:info("Apply loglevel from config: " .. level)
else
  log:warn("Wrong loglevel in config. Use default level: ERROR")
end

local switch = {
  ["prepare_begin"] = function(k, v)
    log:debug("[" .. k .. "] OP : prepare_begin.")
    if k == "vfio" then
      log:debug("[vfio] Config Data: ")
      log:debug(v)
      for _, dev in pairs(v) do
        local vfio = nil
        local err = nil
        vfio, err = vfio_mod(dev["id"])
        if not vfio then
          log:fatal("[vfio] Failed to create device instance for " .. dev["id"] .." at prepare begin: ")
          log:fatal("[vfio]   " .. err)
          error()
        end
        if dev["force"] then
          _, err = vfio.bind(true)
        else
          _, err = vfio.bind()
        end
        if err then
          log:fatal("[vfio] Failed to bind device: " .. dev["id"])
          log:fatal("[vfio]   " .. err)
          error()
        end
          log:info("[vfio] Bind device " .. dev["id"] .. " from vfio-pci.")
      end
    elseif k == "hugepages" then
      log:debug("[hugepages] Config Data: ")
      log:debug(v)
      local pages, err = pages_mod(v["size"], v["unit"])
      if not pages then
        log:error("[hugepages] Failed to create cpu instance at prepare begin: ")
        log:error("[hugepages]   " .. err)
      end
      local _, err = pages.alloc()
      if err then
        log:error("[hugepages] Failed to alloc hugepage size: " .. v["size"] .. " and unit: " .. v["unit"])
        log:error("[hugepages]   " .. err)
      else
        log:info("[hugepages] Alloc hugepage size: " .. v["size"] .. " and unit: " .. v["unit"])
      end
    elseif k == "cpugov"  then
      log:debug("[cpu] Config Data: ")
      log:debug(v)
      local cpu, err = cpu_mod()
      if not cpu then
        log:error("[cpu] Failed to create cpu instance at prepare begin: ")
        log:error("[cpu]   " .. err)
      end
      -- local _, err = cpu.setGovernor(cpu.modes.performance)
      local _, err = cpu.performance()
      if err then
        log:error("[cpu] Failed to set cpu governor to performance: ")
        log:error("[cpu]   " .. err)
      else
        log:info("[cpu] Set cpu governor to performance.")
      end
    end
  end,
  ["start_begin"] = function(k, v)
    log:debug("[" .. k .. "] OP : start_begin.")
    log:warn("Not implemented at the moment")
  end,
  ["started_begin"] = function(k, v)
    log:debug("[" .. k .. "] OP : started_begin.")
    log:warn("Not implemented at the moment")
  end,
  ["stopped_end"] = function(k, v)
    log:debug("[" .. k .. "] OP : stopped_end.")
    log:warn("Not implemented at the moment")
  end,
  ["release_end"] = function(k, v)
    log:debug("[" .. k .. "] OP : release_end.")
    if k == "vfio" then
      log:debug("[vfio] Config Data: ")
      log:debug(v)
      for _, dev in pairs(v) do
        local vfio = nil
        local err = nil
        vfio, err = vfio_mod(dev["id"])
        if not vfio then
          log:fatal("[vfio] Failed to create device instance for " .. dev["id"] .." at release end: ")
          log:fatal("[vfio]   " .. err)
          error()
        end
        _, err = vfio.unbind()
        if err then
          log:fatal("[vfio] Failed to unbind device: " .. dev["id"])
          log:fatal("[vfio]   " .. err)
          error()
        else
          log:info("[vfio] Unbind device " .. dev["id"] .. " from vfio-pci.")
        end
      end
    elseif k == "hugepages" then
      log:debug("[hugepages] Config Data: ")
      log:debug(v)
      local pages, err = pages_mod(v["size"], v["unit"])
      if not pages then
        log:error("[hugepages] Failed to create cpu instance at release end: ")
        log:error("[hugepages]   " .. err)
      end
      local _, err = pages.dealloc()
      if err then
        log:error("[hugepages] Failed to dealloc hugepage size: " .. v["size"] .. " and unit: " .. v["unit"])
        log:error("[hugepages]   " .. err)
      else
        log:info("[hugepages] Dealloc hugepage size: " .. v["size"] .. " and unit: " .. v["unit"])
      end
    elseif k == "cpugov" then
      log:debug("[cpu] Config Data: ")
      log:debug(v)
      local cpu, err = cpu_mod()
      if not cpu then
        log:error("[cpu] Failed to create cpu instance at release end: ")
        log:error("[cpu]   " .. err)
      end
      local _, err = cpu.onDemand()
      if err then
        log:error("[cpu] Failed to set cpu governor to onDemand: ")
        log:error("[cpu]   " .. err)
      else
        log:info("[cpu] Set cpu governor to onDemand.")
      end
    else
      return
    end
  end,
}

if config[args.vm] ~= nil then
  log:info("Found config for VM: " .. args.vm)
  local op = switch[args.operation]
  if op then
    log:info("Apply config for operation: " .. args.operation)
    for k, v in pairs(config[args.vm]) do
      op(k, v)
      log:info("[" .. k .. "] Config applied.")
    end
  else
    log:info("There is nothing to do")
    return
  end
end
