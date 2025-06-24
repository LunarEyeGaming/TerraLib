require "/scripts/util.lua"
scriptLoader = {}
scriptLoader.cache = {}

-- bug: if a script that allows patching (so it backs up update/init/etc.) is run without manually overriding init/update to nil/false, it will run the original update and cause mayhem
function scriptLoader.loadMultiple(scripts, tables, env, toTrack)
    if not env then
        env = {}
    end
    local toTrackI = {}
    if toTrack then
        for k,v in next, toTrack do
            toTrackI[v] = true
        end
    end
    local baseWorld = tables.world or world
    tables.world = {}
    setmetatable(tables.world, {__index=baseWorld})
    local sd_out = {}
    local sd_funcs = {}
    function sd_originalEnv()
        local t = _ENV
        local mt = getmetatable(_ENV)
        while mt do
            t = mt.__index
            mt = getmetatable(t)
        end
        return t
    end
    local sd_changes = {}
    function terra_toSandboxEnv(extraEnv)
        if terra_sandboxed then
            sb.logWarn("Attempting to sandbox an already sandboxed env!")
        end
        local originalEnv = {}
        setmetatable(tables, {__index=originalEnv})
        local workingEnv = {}
        setmetatable(workingEnv, {__index=tables})
        sd_changes = {}
        for k,v in pairs(_ENV) do
            originalEnv[k] = v
            if v ~= setmetatable and v ~= _ENV and v ~= originalEnv and v ~= tables and v ~= workingEnv and v ~= extraEnv and v ~= sd_changes and v ~= sb then
                _ENV[k] = nil
            end
        end
        setmetatable(_ENV, {__index=workingEnv,__newindex=function(t,k,v)
            if toTrackI[k] then
                sd_changes[k] = v
            end
            workingEnv[k] = v
        end,__pairs=function(t) return next, workingEnv, nil end})
        for k,v in next, extraEnv do
            workingEnv[k] = v
        end
        for k,v in next, env do
            workingEnv[k] = v
        end
        workingEnv.terra_sandboxed = true
        return workingEnv
    end
    function terra_toOriginalEnv()
        local workingEnv = getmetatable(_ENV).__index
        if not workingEnv then
            sb.logWarn("Attempting to unsandbox an already unsandboxed env!")
        end
        local tables = getmetatable(workingEnv).__index
        local originalEnv = getmetatable(tables).__index
        for k,v in next, workingEnv do
            if k ~= "setmetatable" then
                env[k] = v
            end
        end
        for k,v in next, originalEnv do
            if k ~= "output" then
                rawset(_ENV,k,v)
            end
        end
        setmetatable(_ENV, nil)
        setmetatable(tables, nil)
        for k,v in next, _ENV do
            if not originalEnv[k] then
                _ENV[k] = nil
            end
        end
        for k,v in next, sd_changes do
            sd_funcs[k] = terra_wrap(v, false, sd_out)
        end
        if terra_sandboxed then
            sb.logWarn("Unsandboxed env is still marked as sandboxed!")
        end
    end
    function terra_restoreWrap(func, extraEnv)
        return function(...)
            -- temporarily restore env to normal (for things like entity messages and calls to the same entity)
            -- restore the backup
            terra_toOriginalEnv()
            local output = {func(...)}
            terra_toSandboxEnv(extraEnv)
            return table.unpack(output)
        end
    end
    function terra_wrap(func, outputIsEnv, extraEnv)
        return function(...)
            -- back up values
            local workingEnv = terra_toSandboxEnv(extraEnv)
            -- run the function, save its output
            local output = func(...)
            if outputIsEnv then
                output = {}
                for k,v in next, workingEnv do
                    if k ~= "setmetatable" then
                        output[k] = v
                    end
                end
            end
            -- restore the backup
            terra_toOriginalEnv()
            return output
        end
    end
    tables.world.sendEntityMessage = terra_restoreWrap(baseWorld.sendEntityMessage, sd_out)
    tables.world.callScriptedEntity = terra_restoreWrap(baseWorld.callScriptedEntity, sd_out)
    local s = sb.print(scripts)
    if scriptLoader.cache[s] then -- make sure to cache the script, since require doesn't like you switching its env and won't put its output in a second time
        sd_out = scriptLoader.cache[s]
    else
        sd_out = terra_wrap(function(all)
            for _,v in next, all do
                _SBLOADED[v] = nil
                require(v)
            end
        end, true, {})(scripts)
        scriptLoader.cache[s] = sd_out
    end
    -- wrap all functions that are returned
    for k,v in next, sd_out do
        if type(v) == "function" then
            sd_funcs[k] = terra_wrap(v, false, sd_out)
        end
    end
    -- also pass the wrapper, in case custom wrapping is needed
    sd_funcs.sd_wrap = terra_wrap
    return sd_funcs, sd_out
end
function scriptLoader.load(script, env)
    return scriptLoader.loadMultiple({script},env)
end
function scriptLoader.load_old(script, env)
    if not env then
        env = {}
    end
    function wrap(func, outputIsEnv, extraEnv)
        return function(...)
            -- back up values
            local originalEnv = {}
            for k,v in next, _ENV do
                originalEnv[k] = v
                if v ~= setmetatable and v ~= _ENV and v ~= originalEnv and v ~= extraEnv then
                    _ENV[k] = nil
                end
            end
            setmetatable(_ENV, {__index=originalEnv})
            for k,v in next, extraEnv do
                _ENV[k] = v
            end
            for k,v in next, env do
                _ENV[k] = v
            end
            -- run the function, save its output
            local output = func(...)
            if outputIsEnv then
                output = {}
                for k,v in next, _ENV do
                    if k ~= "setmetatable" then
                        output[k] = v
                    end
                end
            end
            -- restore the backup
            for k,v in next, _ENV do
                if k ~= "setmetatable" then
                    env[k] = v
                end
            end
            for k,v in next, originalEnv do
                if k ~= "output" then
                    _ENV[k] = v
                end
            end
            setmetatable(_ENV, nil)
            for k,v in next, _ENV do
                if not originalEnv[k] then
                    _ENV[k] = nil
                end
            end
            return output
        end
    end
    local out = {}
    if scriptLoader.cache[script] then -- make sure to cache the script, since require doesn't like you switching its env and won't put its output in a second time
        out = scriptLoader.cache[script]
    else
        out = wrap(require, true, {})(script)
        scriptLoader.cache[script] = out
    end
    -- wrap all functions that are returned
    local funcs = {}
    for k,v in next, out do
        if type(v) == "function" then
            funcs[k] = wrap(v, false, out)
        end
    end
    -- also pass the wrapper, in case custom wrapping is needed
    funcs.sd_wrap = wrap
    return funcs, out
end
