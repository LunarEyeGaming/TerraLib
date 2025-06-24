-- spawns the stagehand that manages biome spreading
-- it does nothing else
local stagehandID = nil
function init()
    script.setUpdateDelta(60)
end
function update(dt)
    if not stagehandID then
        local stagehands = world.entityQuery(world.entityPosition(player.id()), 300, {includedTypes={"stagehand"}, boundMode="position"})
        for k,v in next, stagehands do
            if world.stagehandType(v) == "terra_biomemanager" then
                stagehandID = v
            end
        end
        if not stagehandID then
            world.spawnStagehand(world.entityPosition(player.id()), "terra_biomemanager", {spawner=player.id()})
        end
    elseif not world.entityExists(stagehandID) then
        stagehandID = nil
    elseif world.magnitude(world.entityPosition(stagehandID), world.entityPosition(player.id())) > 300 then
        stagehandID = nil
    end
end
