require "/scripts/terra_mat4.lua" 
require "/scripts/terra_vec3.lua"

-- utility script for either quads or pairs of opposing quads
-- 'special' quads do not have transformation groups, only animation states, and are only present to help integration
quads = {}
function quads.new(properties)
    local quad = {
        matrix=mat4.identity(),
        defaultMatrix=mat4.identity(),
        matrices={},
        hasBack=false,
        name=properties.name,
        stateType=properties.stateType or properties.name.."_Z",
        updateState=properties.updateState
        special=properties.special,
        active=true
    }
    if properties.updateState == nil then
        quad.updateState = true
    end
    if properties.hasBack then
        quad.hasBack = true
        quad.matrices[1] = mat4.getTranslationMatrix({0,0,properties.backZ or properties.sideZ})
        quad.matrices[2] = mat4.getTranslationMatrix({0,0,properties.frontZ or properties.sideZ})
    else
        quad.matrices[1] = mat4.identity()
    end
    return quad
end
function quads.reset(quad)
    quad.matrix = quad.defaultMatrix
end
function quads.translate(q,p)
    q.matrix = mat4.translate(q.matrix,p)
end
function quads.rotate(q,r,a,p)
    q.matrix = mat4.rotate(q.matrix,r,a,p)
end
function quads.scale(q,sov,p)
    q.matrix = mat4.scale(q.matrix,sov,p)
end
function quads.transform(q,m)
    q.matrix = mat4.multiply(q.matrix,m)
end

function quads.getVisible(q)
    local face = {
        side=0,
        z=0,
        matrix=nil,
        transform=nil
    }
    if q.hasBack then
        for k2,v2 in next, q.matrices do
            local tm = mat4.multiply(v2,q.matrix)
            -- check if this matrix is a back face (inverted) or neither (absolutely no area on x or y axis)
            -- only works if face Z is != 0
            local d = tm[12]
            local d2 = q.matrix[12]
            local cond = d > d2
            if cond then
                face.side = k2
                face.z = d
                face.matrix = tm
                face.transform = {mat4.export(tm)}
                break
            end
        end
    else
        face.side = 1
        face.z = q.matrix[12]
        face.matrix = q.matrices[1]
        face.transform = {mat4.export(mat4.multiply(q.matrices[1],q.matrix))}
    end
    return face
end
