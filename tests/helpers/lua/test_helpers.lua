---@diagnostic disable: lowercase-global
local spy = require "luassert.spy"
local util = require "luassert.util"

local InstallContext = require "mason-core.installer.context"
local InstallHandle = require "mason-core.installer.handle"
local a = require "mason-core.async"
local registry = require "mason-registry"

function async_test(suspend_fn)
    return function()
        local ok, err = pcall(a.run_blocking, suspend_fn)
        if not ok then
            error(err, util.errorlevel())
        end
    end
end

-- selene: allow(incorrect_standard_library_use)
mockx = {
    just_runs = function() end,
    returns = function(val)
        return function()
            return val
        end
    end,
    throws = function(exception)
        return function()
            error(exception, 2)
        end
    end,
}

---@param package_name string
function InstallHandleGenerator(package_name)
    return InstallHandle.new(registry.get_package(package_name))
end

---@param handle InstallHandle
---@param opts InstallContextOpts | nil
function InstallContextGenerator(handle, opts)
    local context = InstallContext.new(handle, opts or {})
    context.spawn = setmetatable({}, {
        __index = function(s, cmd)
            s[cmd] = spy.new(mockx.just_runs())
            return s[cmd]
        end,
    })
    return context
end
