
local handMessageHandlers = {}
function cleanHandHandlers()
    for k,v in next, handMessageHandlers do
        local new = {}
        for k2,v2 in next, v do
            if world.entityExists(v2) then
                table.insert(new,v2)
            end
        end
        if #new == 0 then
            handMessageHandlers[k] = nil
            message.setHandler(k,nil)
        else
            handMessageHandlers[k] = new
        end
    end
end
function handHandler(n,...)
    if handMessageHandlers[n] then
        for k,v in next, handMessageHandlers[n] do
            if world.entityExists(v) then
                if k == #handMessageHandlers[n] then
                    return world.callScriptedEntity(v, "handleMessage", n, ...)
                else
                    world.callScriptedEntity(v, "handleMessage", n, ...)
                end
            end
        end
    end
end
function setHandHandler(n,i)
    if handMessageHandlers[n] then
        table.insert(handMessageHandlers[n], i)
    else
        handMessageHandlers[n] = {i}
        message.setHandler(n,handHandler)
    end
end 
function initHandHandlers()
    message.setHandler("terra_setHandHandler", function(_,l,n,i)
        if not l then return end
        setHandHandler(n,i)
    end)
end
