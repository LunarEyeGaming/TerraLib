require "/scripts/terra_vec2ref.lua" 
-- script to fix aiming for ducking humanoid targets

function entityPosition(eid)
    local pos = world.entityPosition(eid)
    local t = world.entityType(eid)
    if t == "npc" or t == "player" then
        local q = world.entityQuery(pos, 0, {includedTypes={t},boundMode="collisionarea",order="nearest"})
        local found = false
        for k,v in next, q do
            if v == eid then
                found = true
                break
            end
        end
        if found then
            return pos
        else
            return vec2.addToRef(pos, {0,-1},pos)
        end
    else
        return pos
    end
end
