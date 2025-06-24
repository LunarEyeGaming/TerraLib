require "/scripts/terra_scriptLoader.lua"
require "/scripts/terra_scriptLoader_loadstring.lua" 

-- requires oSB

function buildContextConfig(cfg)
    local config = {}
    function config.getParameter(p,d)
        local out
        if p == "" then
            out = sb.jsonMerge({}, cfg)
        else
            out = cfg[p] or d
            if type(out) == "table" then
                return sb.jsonMerge({}, out)
            end
        end
        return out
    end
    return config
end
local function nullFunc() end
local nullTable = {}
setmetatable(nullTable, {
    __index=function() 
        return nullFunc
    end
})
-- also pcalls everything
function buildContext(scripts, oTables, storage, invokables, params)
    params = params or {}
    if params.subMcontroller then
        params.subMcontroller.clearOnUpdate = false
    end
    local env = {}
    local tables = {}
    for k,v in next, oTables do
        tables[k] = v
    end
    local script = {}
    local updateDt = 1
    if scripts.scriptDelta then
        updateDt = scripts.scriptDelta
        scripts = scripts.scripts
    end
    function script.updateDt()
        if updateDt == 0 then
            return 0
        else
            return 1/updateDt
        end
    end
    function script.setUpdateDelta(dt)
        updateDt = dt
    end
    tables.script = script
    tables.storage = storage or {}
    tables.self = {}
    local s, o = pcall(scriptLoader.loadMultiple_loadstring,scripts,tables,env,invokables)
    if s then
        local out = {}
        local dead = false
        local function pcallWrap(f)
            return function(...)
                if dead then return end
                local s,o = pcall(f,...)
                if s then
                    return o
                else
                    sb.logError("Sandboxed context threw an error on invoke!")
                    sb.logError(o)
                    dead = true
                end
            end
        end
        for _,v in next, invokables do
            out[v] = o[v] and pcallWrap(o[v]) or nullFunc
        end
        if out.update then
            local _update = out.update
            local t = 0
            out.update = function(...)
                t = t + 1
                if t >= updateDt then
                    t = 0
                    if params.subMcontroller then
                        params.subMcontroller.autoclear()
                    end
                    _update(...)
                end
            end
        end
        function out.contextDead()
            return dead
        end
        if params.subMcontroller then
            out.mcontroller = params.subMcontroller
        end
        return out
    else
        sb.logError("Sandboxed context threw an error on construct!")
        sb.logError(o)
        return nullTable
    end
end
