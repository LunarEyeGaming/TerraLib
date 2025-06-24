require "/scripts/terra_quads.lua"

-- requires transformation groups with same name as every quad
-- also requires animation states that handle z levels at same precision as the script
local groups = {}
quadAnimator = {
    groups=groups,
    rootGroups={},
    zFormatter=nil,
    zMax=0
}
function quadAnimator.init(params)
    quadAnimator.zFormatter=string.format("z_%%.%df",params.zPrecision)
    quadAnimator.zMax = params.zMax
end
function quadAnimator.createTransformationGroup(name, parent)
    local g = {
        name=name,
        matrix=mat4.identity(),
        quads={},
        children={}
    }
    groups[name] = g
    if parent and groups[parent] then
        table.insert(groups[parent].children,g)
    else
        table.insert(quadAnimator.rootGroups,g)
    end
end

function quadAnimator.resetTransformationGroup(name)
    groups[name].matrix = mat4.identity()
end
function quadAnimator.rotateTransformationGroup(name,r,a,p)
    groups[name].matrix = mat4.rotate(groups[name].matrix,r,a,p)
end
function quadAnimator.translateTransformationGroup(name,t)
    groups[name].matrix = mat4.translate(groups[name].matrix,t)
end
function quadAnimator.scaleTransformationGroup(name,sov,p)
    groups[name].matrix = mat4.scale(groups[name].matrix,sov,p)
end
function quadAnimator.transformTransformationGroup(name,m)
    groups[name].matrix = mat4.multiply(groups[name].matrix,m)
end

local function transformGroup(g,m)
    m = m or mat4.identity()
    m = mat4.multiply(g.matrix,m)
    local faces = {}
    local lowestZ = -1/0
    local highestZ = 1/0
    for k,v in next, g.quads do
        if v.active then
            v:reset()
            v:transform(m)
            local face = v:getVisible()
            local tg = v.name
            local as = v.stateType
            if not v.special then
                animator.resetTransformationGroup(tg)
            end
            if face.transform then
                if not v.special then
                    animator.transformTransformationGroup(tg,table.unpack(face.transform))
                end
                face.updateState = v.updateState
                face.as = as
                faces[k] = face
                if face.z > highestZ then
                    highestZ = face.z
                elseif face.z < lowestZ then
                    lowestZ = face.z
                end
            elseif not v.special then
                animator.scaleTransformationGroup(tg,0)
            end
        end
    end
    local zMax = quadAnimator.zMax
    local zMul = 2*zMax/(highestZ-lowestZ)
    for k,v in next, faces do
        -- force all faces into the Z range
        local z = (v.z-lowestZ)*zMul-zMax
        if v.updateState then
            animator.setAnimationState(v.as,string.format(quadAnimator.zFormatter,z))
        end
    end
    for k,v in next, g.children do
        transformGroup(v,m)
    end
end

function quadAnimator.doTransformations()
    for k,v in next, quadAnimator.rootGroups do
        transformGroup(v)
    end
end
