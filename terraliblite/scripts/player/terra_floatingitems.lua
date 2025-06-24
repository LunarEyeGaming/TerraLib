local queryRange = 100
local items = {}
local promises = {}
local nearbyItemProjectiles = {}
local oldInit = init
local oldUpdate = update
local timer = 0
local updateInterval = 1
local updateTimer = 0
function init()
    oldInit()
    items = root.assetJson("/items/terra_floatingitems.config").floatingItems
end
function update(dt)
    updateTimer = updateTimer + 1
    timer = timer + dt
    if updateTimer >= updateInterval then
        updateTimer = 0
        localAnimator.clearDrawables()
        localAnimator.clearLightSources()
        oldUpdate(dt)
        for i,promise in next,promises do
            if promise.promise:finished() then
                if promise.promise:succeeded() then
                    promise.callback(promise.promise:result())
                end
                promises[i] = nil
            end
        end
        local query = world.itemDropQuery(entity.position(), queryRange)
        for k,v in next, query do
            local data = world.itemDropItem(v)
            if items[data.name] then
                local config = root.itemConfig(data)
                local projData = items[data.name]
                local params = projData.params or {}
                local query2 = world.playerQuery(world.entityPosition(v), params.snapRange or 6, {boundMode = "position"})
                if #query2 <= 0 then
                    params.item = data
                    params.itemDrop = v
                    if not params.image then
                        params.animationCycle = nil
                        params.frameNumber = nil
                        params.image = config.config.inventoryIcon
                        if string.sub(params.image, 1, 1) ~= "/" then
                            params.image = config.directory..params.image
                        end
                    end
                    world.debugPoint(world.entityPosition(v), "green")
                    world.spawnProjectile(projData.type or "terra_floatingitem", world.entityPosition(v), nil, {0, 0}, false, params)
                end
            end
        end
        query = world.entityQuery(entity.position(), queryRange, {includedTypes={"projectile"}})
        for k,v in next, query do
            if world.entityName(v) == "terra_floatingitem" then
                table.insert(promises, {promise=world.sendEntityMessage(v, "getRenderConfig"), callback=function(data)
                                        nearbyItemProjectiles[tostring(v)] = data
                                        end})
                local data = nearbyItemProjectiles[tostring(v)]
                if data then
                    local frameTimer = timer % data.animationCycle
                    local frames = data.frameNumber
                    local frame = math.floor(frameTimer / data.animationCycle * frames)
                    world.debugText(sb.print(frame), world.entityPosition(v), "yellow")
                    local transformation = {{1,0,0},{0,1,0},{0,0,1}}
                    if data.scaleEffect then
                        local sin = math.sin(timer * math.pi * (data.scaleSpeed or 0.5)) * (data.scaleMagnitude or 0.1)
                        local scale = 1 + sin
                        transformation[1][1] = scale
                        transformation[2][2] = scale
                    end
                    local drawable = {
                        image=data.image..":"..frame,
                        position=vec2.sub(world.distance(world.entityPosition(v), entity.position()), vec2.mul(world.entityVelocity(entity.id()), dt)),
                        fullbright=data.fullbright,
                        transformation=transformation
                    }
                    localAnimator.addDrawable(drawable, "ItemDrop")
                    if data.light then
                        localAnimator.addLightSource({
                                                    position=world.entityPosition(v),
                                                    color=data.light
                                                    })
                    end
                end
            end
        end
        for k,v in next, nearbyItemProjectiles do
            if not world.entityExists(tonumber(k)) then
                nearbyItemProjectiles[k] = nil
            end
        end
    else
        oldUpdate(dt)
    end
end
