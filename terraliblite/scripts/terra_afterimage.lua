require "/scripts/vec2.lua"

local portraits = {}
function init()

end
function update()
    local length = config.getParameter("afterImageTime", 5)
    local newportrait = world.entityPortrait(entity.id(), "full")
    for k,v in next, newportrait do
        v.transformation[1][3] = 0
        v.transformation[2][3] = 0
        v.position = vec2.add(entity.position(), v.position or {0, 0})
        v.mirrored = true
    end
    if #portraits > length then
        table.remove(portraits, 1)
    end
    table.insert(portraits, newportrait)
    localAnimator.clearDrawables()
    local invertLayers = config.getParameter("afterImageReverseLayering")
    for k,v in next, portraits do
        for k2,v2 in next, v do
            local layer = string.format("Monster-%d",k)
            if invertLayers then
                layer = string.format("Monster+%d",k)
            end
            world.debugLine(entity.position(), v2.position, "green")
            local drawable = {}
            for k,v in next, v2 do
                drawable[k] = v
            end
            drawable.image = v2.image..string.format("?multiply=ffffff%02x", math.floor(255 * (k2 / length)))
            localAnimator.addDrawable(drawable, layer)
        end
    end
end
