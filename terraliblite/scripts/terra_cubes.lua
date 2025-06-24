require "/scripts/terra_mat4.lua" 
require "/scripts/terra_vec3.lua"

cubes = {}
-- size is *not* distance from center
function cubes.new(size)
    local hsize = vec3.div(size,2)
    local cube = {
        size=size,
        inverted=false,
        matrix={},
        matrices={
            fb={{},{}},
            lr={{},{}},
            tb={{},{}}
        },
        debugCube={
            { hsize[1], hsize[2], hsize[3]},
            {-hsize[1], hsize[2], hsize[3]},
            {-hsize[1], hsize[2],-hsize[3]},
            { hsize[1], hsize[2],-hsize[3]},
            { hsize[1],-hsize[2], hsize[3]},
            {-hsize[1],-hsize[2], hsize[3]},
            {-hsize[1],-hsize[2],-hsize[3]},
            { hsize[1],-hsize[2],-hsize[3]},
        }
    }
    local front = mat4.identity()
    front[12] = size[3]/2
    local side = mat4.identity()
    side[12] = size[1]/2
    local top = mat4.identity()
    top[12] = size[2]/2
    -- front face
    cube.matrices.fb[1] = front
    -- left face
    cube.matrices.lr[1] = mat4.rotate(side, math.pi/2,"y")
    -- back face
    cube.matrices.fb[2] = mat4.rotate(front,math.pi,"y")
    -- right face
    cube.matrices.lr[2] = mat4.rotate(side,3*math.pi/2,"y")
    -- top face
    cube.matrices.tb[1] = mat4.rotate(top,math.pi/2,"x")
    -- bottom face
    cube.matrices.tb[2] = mat4.rotate(top,-math.pi/2,"x")
    setmetatable(cube,{__index=cubes})
    cubes.reset(cube)
    return cube
end
function cubes.reset(cube)
    cube.matrix = mat4.identity()
end
function cubes.translate(c,p)
    c.matrix = mat4.translate(c.matrix,p)
end
function cubes.rotate(c,r,a,p)
    c.matrix = mat4.rotate(c.matrix,r,a,p)
end
function cubes.scale(c,sov,p)
    c.matrix = mat4.scale(c.matrix,sov,p)
end
function cubes.transform(c,m)
    c.matrix = mat4.multiply(c.matrix,m)
end
-- limitation: scaling a single axis by -1 will break this
-- inverted property should fix this
function cubes.getVisible(c)
    local out = {}
    local tDC = {}
    for k,v in next, c.debugCube do
        table.insert(tDC,vec2.add(mat4.transform(v,c.matrix),mcontroller.position()))
    end
    --[[
    world.debugLine(tDC[1],tDC[2],"cyan")
    world.debugLine(tDC[2],tDC[3],"cyan")
    world.debugLine(tDC[3],tDC[4],"cyan")
    world.debugLine(tDC[4],tDC[1],"cyan")
    world.debugLine(tDC[5],tDC[6],"cyan")
    world.debugLine(tDC[6],tDC[7],"cyan")
    world.debugLine(tDC[7],tDC[8],"cyan")
    world.debugLine(tDC[8],tDC[5],"cyan")
    world.debugLine(tDC[1],tDC[5],"cyan")
    world.debugLine(tDC[2],tDC[6],"cyan")
    world.debugLine(tDC[3],tDC[7],"cyan")
    world.debugLine(tDC[4],tDC[8],"cyan")
    ]]
    for k,v in next, c.matrices do
        local face = {
            side=0,
            matrix=nil,
            transform=nil
        }
        for k2,v2 in next, v do
            local tm = mat4.multiply(v2,c.matrix)
            -- check if this matrix is a back face (inverted) or neither (absolutely no area on x or y axis)
            local d = tm[12]
            local d2 = c.matrix[12]
            local invert = c.inverted
            local cond = d > d2
            if cond then
                face.side = k2
                face.matrix = tm
                face.transform = {mat4.export(tm)}
                break
            end
        end
        out[k] = face
    end
    return out
end
