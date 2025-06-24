-- Utility script for dealing with 4D affine transformation matrices.
-- Should give all the tools needed to render 3D quads.
local identity = {
    1,0,0,0,
    0,1,0,0,
    0,0,1,0,
    0,0,0,1
}
local zeroVec = {0,0,0}
local function dot4(a,b,c,d,e,f,g,h)
    return a*b+c*d+e*f+g*h
end
mat4 = {}
function mat4.identity()
    return {
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        0,0,0,1
    }
end
function mat4.getRotationMatrix(r,a,p)
    p = p or zeroVec
    local sin = math.sin(r)
    local cos = math.cos(r)
    if a == "z" then
        -- exactly like 2d
        return {
            cos,-sin,0,p[1]-p[1]*cos+sin*p[2],
            sin,cos, 0,p[2]-p[1]*sin-cos*p[2],
            0,  0,   1,0,
            0,  0,   0,1
        }
    elseif a == "x" then
        -- like 2d, but x is replaced with z
        return {
            1,0,   0,  0,
            0,cos,sin,p[2]+p[3]*sin-cos*p[2],
            0,-sin,cos, p[3]-p[3]*cos-sin*p[2],
            0,0,   0,  1
        }
    elseif a == "y" then
        -- like 2d, but y is replaced with z
        return {
            cos,0,-sin,p[1]-p[1]*cos-sin*p[3],
            0,  1,0,   0,
            sin,0,cos, p[3]+p[1]*sin-cos*p[3],
            0,  0,0,   1
        }
    end
end
function mat4.getTranslationMatrix(t)
    return {
        1,0,0,t[1],
        0,1,0,t[2],
        0,0,1,t[3],
        0,0,0,1
    }
end
function mat4.getScalingMatrix(sov,p)
    p = p or zeroVec
    if type(sov) == "number" then
        return {
            sov,0,0,p[1]-p[1]*sov,
            0,sov,0,p[2]-p[2]*sov,
            0,0,sov,p[3]-p[3]*sov,
            0,0,0,1
        }
    else
        return {
            sov[1],0,0,p[1]-p[1]*sov[1],
            0,sov[2],0,p[2]-p[2]*sov[2],
            0,0,sov[3],p[3]-p[3]*sov[3],
            0,0,0,1
        }
    end
end
function mat4.translate(m,t)
    local n = mat4.getTranslationMatrix(t)
    return mat4.multiply(m,n)
end
function mat4.scale(m,sov,p)
    local n = mat4.getScalingMatrix(sov,p)
    return mat4.multiply(m,n)
end
function mat4.rotate(m,r,a,p)
    local n = mat4.getRotationMatrix(r,a,p)
    return mat4.multiply(m,n)
end
function mat4.multiply(b,a)
    return {
dot4(a[1 ],b[1],a[2 ],b[5],a[3 ],b[9],a[4 ],b[13]),dot4(a[1 ],b[2],a[2 ],b[6],a[3 ],b[10],a[4 ],b[14]),dot4(a[1 ],b[3],a[2 ],b[7],a[3 ],b[11],a[4 ],b[15]),dot4(a[1 ],b[4],a[2 ],b[8],a[3 ],b[12],a[4 ],b[16]),
dot4(a[5 ],b[1],a[6 ],b[5],a[7 ],b[9],a[8 ],b[13]),dot4(a[5 ],b[2],a[6 ],b[6],a[7 ],b[10],a[8 ],b[14]),dot4(a[5 ],b[3],a[6 ],b[7],a[7 ],b[11],a[8 ],b[15]),dot4(a[5 ],b[4],a[6 ],b[8],a[7 ],b[12],a[8 ],b[16]),
dot4(a[9 ],b[1],a[10],b[5],a[11],b[9],a[12],b[13]),dot4(a[9 ],b[2],a[10],b[6],a[11],b[10],a[12],b[14]),dot4(a[9 ],b[3],a[10],b[7],a[11],b[11],a[12],b[15]),dot4(a[9 ],b[4],a[10],b[8],a[11],b[12],a[12],b[16]),
dot4(a[13],b[1],a[14],b[5],a[15],b[9],a[16],b[13]),dot4(a[13],b[2],a[14],b[6],a[15],b[10],a[16],b[14]),dot4(a[13],b[3],a[14],b[7],a[15],b[11],a[16],b[15]),dot4(a[13],b[4],a[14],b[8],a[15],b[12],a[16],b[16]),
    }
end
function mat4.transform(p,m)
    return {
        p[1]*m[1]+p[2]*m[2]+p[3]*m[3]+m[4],
        p[1]*m[5]+p[2]*m[6]+p[3]*m[7]+m[8],
        p[1]*m[9]+p[2]*m[10]+p[3]*m[11]+m[12]
    }
end
-- Starbound is a 2D game, so to do 3D stuff in it, we just truncate the Z axis
-- applies transformations based on Z to translation so the information is not lost (should properly flatten the transformation)
function mat4.truncate(m,z)
    z = z or 0
    return {
        m[1],m[2],z*m[3]+m[4],
        m[5],m[6],z*m[7]+m[8],
        0,0,1
    }
end
-- exports a mat4 directly to something for animator.transformTransformationGroup without requiring conversion to mat3
function mat4.export(i,z)
    z = z or 0
    return i[1],i[2],i[5],i[6],z*i[3]+i[4],z*i[7]+i[8]
end
