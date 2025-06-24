require '/scripts/vec2.lua'

function init()
end
function update()
    object.smash(true)
    if config.getParameter("placeBehind") then
        world.placeMaterial(entity.position(), "background", config.getParameter("material"), config.getParameter("hueShift"), config.getParameter("overlap"))
        if config.getParameter("colour") then
            world.setMaterialColor(entity.position(),"background",config.getParameter("colour"))
        end
    else
        local ppos = vec2.add(entity.position(), {0, -1})
        world.placeMaterial(ppos, config.getParameter("layer"), config.getParameter("material"), config.getParameter("hueShift"), config.getParameter("overlap"))
        if config.getParameter("colour") then
            world.setMaterialColor(ppos,config.getParameter("layer"),config.getParameter("colour"))
        end
    end
end
