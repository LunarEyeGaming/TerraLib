-- For monsters and vehicles, the clientmasterrenderer script already requires and executes from this for you.
-- For activeitems, you will need to require this file and call terra_activeitem_hook yourself

-- Should work with both monsters and vehicles
-- Automatically called by the renderer
function terra_generic_hook(key)
    local ac = {}
    local animationConfig = {
        animationParameter=function(k)
            return ac[k]
        end,
        partPoint=animator.partPoint,
        partPoly=animator.partPoly
    }
    local _uninit = uninit
    uninit = function()
        if _uninit then _uninit() end
        getmetatable''.terra_rendererGenericUninit(key)
    end
    local etable = _ENV[entity.entityType()]
    local prev = etable.setAnimationParameter
    etable.setAnimationParameter = function(key,val)
        prev(key,val)
        ac[key] = val
    end
    return {
        entity=entity,
        config=config,
        animationConfig=animationConfig
    }
end

-- must be called manually, sets up the context
function terra_activeitem_hook()
    local id = sb.makeUuid()
    local ac = {}
    local animationConfig = {
        animationParameter=function(k)
            return ac[k]
        end,
        partPoint=animator.partPoint,
        partPoly=animator.partPoly
    }
    local activeItemAnimation = {
        ownerPosition=entity.position,
        ownerAimPosition=activeItem.ownerAimPosition,
        ownerArmAngle=(player and player.primaryArmRotation and (activeItem.hand() == "primary" and player.primaryArmRotation or player.altArmRotation)) or function() return 0 end,
        handPosition=activeItem.handPosition,
        partPoint=animator.partPoint,
        partPoly=animator.partPoly
    }
    local _uninit = uninit
    uninit = function()
        if _uninit then _uninit() end
        getmetatable''.terra_rendererNonEntityUninit(id)
    end
    local prev = activeItem.setScriptedAnimationParameter
    activeItem.setScriptedAnimationParameter = function(key,val)
        prev(key,val)
        ac[key] = val
    end
    getmetatable''.terra_rendererBuildItem(id,entity.id(),config.getParameter("ownerAnimationScripts"),{
        entity=entity,
        config=config,
        activeItemAnimation=activeItemAnimation,
        animationConfig=animationConfig
    })
end
