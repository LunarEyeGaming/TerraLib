require "/scripts/terra_proxy.lua"

local music = {}
-- object format:
-- {
--     id="anything unique, entity IDs work",
--     file="music file path", (can be array)
--     undergroundFile="optional underground variant file",
--     nightFile="optional night variant file",
--     expireType="duration" or "entityDistance",
--     entityDis=entityDistanceNum,
--     entityID=entityID,
--     expireTime=ticks,
--     priority=priority,
--     dt=currentUpdateDt
-- }
-- priority should usually be:
-- 10-20: boss music
local playing = nil
function findID(org, findV)
    for k,v in next, org do
        if v.id == findV then
            return k
        end
    end
    return nil
end
-- File for managing music requests; meant to prevent music conflicts.
function init()
    message.setHandler("terraMusic", function (_,_,newmusic) 
                       -- sending this twice with time-based music will refresh the timer
                       local index = findID(music, newmusic.id)
                       if index then
                         if newmusic.expireType == "duration" then
                            music[index].expireTime = newmusic.expireTime
                            music[index].dt = newmusic.dt
                         end
                         music[index].file = newmusic.file
                         music[index].undergroundFile = newmusic.undergroundFile
                         music[index].nightFile = newmusic.nightFile
                      else
                        table.insert(music, newmusic)
                      end
                       end)
        script.setUpdateDelta(1)

    -- why make a new script just to do this when I can just add it to an existing one?
    getmetatable''.player = player
    -- also create a proxy for this
    terra_proxy.setupReceiveMessages("player",player)
    -- this too
    terra_proxy.setupReceiveMessages("celestial",celestial)
end
function update(dt)
    getmetatable''.player = player
    if playing then
        local m = music[findID(music,playing)]
        if not m then
            playing = nil
            world.sendEntityMessage(player.id(), "stopAltMusic", 2.0)
        else
            local file = m.file
            if m.nightFile then
                if world.timeOfDay() > 0.5 then
                    file = m.nightFile
                end
            end
            if m.undergroundFile then
                if world.underground(world.entityPosition(player.id())) then
                    file = m.undergroundFile
                end
            end
            if type(file) == "string" then
                file = {file}
            end
            world.sendEntityMessage(player.id(), "playAltMusic", file, 2.0)
        end
    end
    local r = 0
    for k,v in next, music do
        if v.expireType == "duration" then
            local amount = 1
            if v.dt then
               amount = 60 * v.dt 
            else
               amount = 60 * dt
            end
            v.expireTime = v.expireTime - amount
            if v.expireTime < 0 then
                table.remove(music,k - r)
                r = r + 1
            end
        else
            local id = v.entityID
            local exp = false
            if not world.entityExists(id) then
                exp = true
            elseif world.magnitude(world.entityPosition(id), world.entityPosition(player.id())) > v.entityDis then
                exp = true
            end
            if exp then
                table.remove(music,k - r)
                r = r + 1
            end
        end
    end
    table.sort(music, function (a,b)
               return a.priority > b.priority
              end)
    if #music > 0 then
        playing = music[1].id
    else
        if playing then
            world.sendEntityMessage(player.id(), "stopAltMusic", 2.0)
        end
        playing = nil
    end
end
