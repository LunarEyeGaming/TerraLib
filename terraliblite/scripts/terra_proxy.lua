-- Allows easily sharing tables locally without the use of metatables.
-- Target entities must be local (same master).
-- Entity messages are immediately resolved when created for local entities.
terra_proxy = {}
local cleanupRequests = {}
-- senders
-- both of these functions return a function that will clean up the message handlers, in case it's needed
-- sets up the proxy for messages
local function iterateMessages(name,t,f,msgs)
    -- does this table extend something? if so, setup handlers for its index as well
    local mt = getmetatable(t)
    if mt and type(mt.__index) == "table" then
        iterateMessages(name,mt.__index,f,msgs)
    end
    for k,v in next, t do
        if type(v) == "function" then
            local msg = string.format(f,k)
            message.setHandler(msg,function(_,isLocal,...)
                if not isLocal then return end
                return v(...)
            end)
            table.insert(msgs,msg)
        end
    end
end
local function doCleanup()
    local newCleanupRequests = {}
    for _,v in next, cleanupRequests do
        if world.time() < v.time then
            v.func()
        else
            table.insert(newCleanupRequests,v)
        end
    end
    cleanupRequests = newCleanupRequests
end
function terra_proxy.setupReceiveMessages(name,t)
    doCleanup()
    local f = string.format("%s.%%s",name)
    local msgs = {string.format(f,"terra_proxy_mode"),string.format(f,"terra_proxy_msgs")}
    message.setHandler(msgs[1],function(_,isLocal,...)
        if not isLocal then return end
        return "messages"
    end)
    message.setHandler(msgs[2],function(_,isLocal,...)
        if not isLocal then return end
        return msgs
    end)
    iterateMessages(name,t,f,msgs)
    local function actuallyCleanup()
        -- clean up it all
        for k,v in next, msgs do
            message.setHandler(v,nil)
        end
    end
    return function(later)
        -- also allows cleaning up a bit later so stuff has time to uninitialize
        if later then
            table.insert(cleanupRequests,{time=world.time()+0.5,func=actuallyCleanup})
        else
            actuallyCleanup()
        end
    end
end
-- sets up the proxy for calls (only tells senders to callScriptedEntity)
-- requires the table in question to be present
function terra_proxy.setupReceiveCalls(name)
    doCleanup()
    local msg = string.format("%s.terra_proxy_mode",name)
    message.setHandler(msg,function(_,isLocal,...)
        if not isLocal then return end
        return "calls"
    end)
    local function actuallyCleanup()
        message.setHandler(msg,nil)
    end
    return function(later)
        if later then
            table.insert(cleanupRequests,{time=world.time()+0.5,func=actuallyCleanup})
        else
            actuallyCleanup()
        end
    end
end

-- receiver
-- does not immediately have every function, builds as time goes on
-- requires target already have proxy set up, returns nil otherwise
function terra_proxy.setupProxy(name,entityId,throw)
    local proxy = {}
    local fmt = string.format("%s.%%s",name)
    local p = world.sendEntityMessage(entityId,string.format(fmt,"terra_proxy_mode"))
    if not p:finished() or not p:succeeded() then
        return nil
    end
    local builder
    if p:result() == "calls" then
        builder = function(func)
            return function(...)
                return world.callScriptedEntity(entityId,func,...)
            end
        end
    else
        builder = function(func)
            return function(...)
                local p = world.sendEntityMessage(entityId,func,...)
                if throw and not p:succeeded() then
                    error(string.format("Proxy function %s has no message handler!",func))
                end
                return p:result()
            end
        end
    end
    setmetatable(proxy,{__index=function(t,k)
        local func = builder(string.format(fmt,k))
        t[k] = func
        return func
    end})
    return proxy
end

-- relay
-- receives messages to send them to the target
-- requires target has receiving messages set up
function terra_proxy.setupRelayMessages(name,targetId)
    local proxy = {}
    local fmt = string.format("%s.%%s",name)
    local mode = world.sendEntityMessage(targetId,string.format(fmt,"terra_proxy_mode")):result()
    if mode == "calls" then
        sb.logError("Attempted to create a proxy message relay with a call proxy!")
        return
    elseif not mode then
        sb.logError("Proxy relays require a receiving proxy on the target!")
        return
    end
    local msgs = world.sendEntityMessage(targetId,string.format(fmt,"terra_proxy_msgs")):result()
    local function relay(msg,isLocal,...)
        if not isLocal then return end
        return world.sendEntityMessage(targetId,msg,...):result()
    end
    for k,v in next, msgs do
        message.setHandler(v,relay)
    end
    return function()
        -- cleanup
        for k,v in next, msgs do
            message.setHandler(v,nil)
        end
    end
end
