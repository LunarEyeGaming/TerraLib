require "/scripts/terra_cubes.lua"

local faces = {"fb","lr","tb"}
local groups = {}
cubeAnimator = {
    groups=groups,
    rootGroups={}
}
function cubeAnimator.createTransformationGroup(name, parent)
    local g = {
        name=name,
        matrix=mat4.identity(),
        cubes={},
        children={}
    }
    groups[name] = g
    if parent and groups[parent] then
        table.insert(groups[parent].children,g)
    else
        table.insert(cubeAnimator.rootGroups,g)
    end
end
function cubeAnimator.addCube(group,size,prefix)
    local g = groups[group]
    local c = cubes.new(size)
    c.prefix = prefix
    table.insert(g.cubes,c)
end

function cubeAnimator.resetTransformationGroup(name)
    groups[name].matrix = mat4.identity()
end
function cubeAnimator.rotateTransformationGroup(name,r,a,p)
    groups[name].matrix = mat4.rotate(groups[name].matrix,r,a,p)
end
function cubeAnimator.translateTransformationGroup(name,t)
    groups[name].matrix = mat4.translate(groups[name].matrix,t)
end
function cubeAnimator.scaleTransformationGroup(name,sov,p)
    groups[name].matrix = mat4.scale(groups[name].matrix,sov,p)
end
function cubeAnimator.transformTransformationGroup(name,m)
    groups[name].matrix = mat4.multiply(groups[name].matrix,m)
end

local function transformGroup(g,m)
    m = m or mat4.identity()
    m = mat4.multiply(g.matrix,m)
    for k,v in next, g.cubes do
        v:reset()
        v:transform(m)
        local transform = v:getVisible()
        for k2,v2 in next, transform do
            local tg = v.prefix..k2
            animator.resetTransformationGroup(tg)
            if v2.transform then
                animator.transformTransformationGroup(tg,table.unpack(v2.transform))
            else
                animator.scaleTransformationGroup(tg,0)
            end
        end
    end
    for k,v in next, g.children do
        transformGroup(v,m)
    end
end

function cubeAnimator.doTransformations()
    for k,v in next, cubeAnimator.rootGroups do
        transformGroup(v)
    end
end
