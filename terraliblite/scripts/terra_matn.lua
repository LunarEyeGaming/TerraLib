-- Utility script for dealing with any size of affine transformation matrices.
-- Should give all the tools needed to render something of any dimensions.
-- Not designed for matrices smaller than a Mat3.

local _zeroVec = {}
local function zeroVec(d)
    local out = _zeroVec
    for i=#out,d-1 do
        out[i] = 0
    end
    return out
end
matn = {}
function matn.identity(d)
    local mat = {}
    for i=1,d*d do
        mat[i] = 0
    end
    for i=1,d do
        mat[d*(i-1)+i] = 1
    end
    return mat
end
function matn.getRotationMatrix(d,r,a1,a2,p)
    p = p or zeroVec(d)
    local sin = math.sin(r)
    local cos = math.cos(r)
    local mat = matn.identity(d)
    mat[d*(a1-1)+a1] = cos; mat[d*(a1-1)+a2] = -sin; mat[d*(a1-1)+d] = p[a1]-p[a1]*cos+sin*p[a2];
    mat[d*(a2-1)+a1] = sin; mat[d*(a2-1)+a2] = cos;  mat[d*(a2-1)+d] = p[a2]-p[a1]*sin-cos*p[a2]; 
    return mat
end
function matn.getTranslationMatrix(d,t)
    local mat = matn.identity(d)
    for i=1,(d-1) do
        mat[d*(i-1)+d]=t[i]
    end
    return mat
end
function matn.getScalingMatrix(d,sov,p)
    p = p or zeroVec(d)
    local mat = {}
    for i=1,d*d do
        mat[i] = 0
    end
    if type(sov) == "number" then
        for i=1,d do
            if i == d then
                mat[d*(i-1)+i] = 1
            else
                mat[d*(i-1)+i] = sov
                mat[d*(i-1)+d]=p[i]-p[i]*sov
            end
        end
    else
        for i=1,d do
            if i == d then
                mat[d*(i-1)+i] = 1
            else
                mat[d*(i-1)+i] = sov[i]
                mat[d*(i-1)+d]=p[i]-p[i]*sov[i]
            end
        end
    end
    return mat
end
function matn.translate(d,m,t)
    local n = matn.getTranslationMatrix(d,t)
    return matn.multiply(d,m,n)
end
function matn.scale(d,m,sov,p)
    local n = matn.getScalingMatrix(d,sov,p)
    return matn.multiply(d,m,n)
end
function matn.rotate(d,m,r,a1,a2,p)
    local n = matn.getRotationMatrix(d,r,a1,a2,p)
    return matn.multiply(d,m,n)
end
function matn.multiply(d,b,a)
    local out = {}
    for x=1,d do
        for y=1,d do
            local v = 0
            for i=1,d do
                v = v + a[(y-1)*d+i]*b[(i-1)*d+x]
            end
            out[(y-1)*d+x] = v
        end
    end
    return out
end
function matn.transform(d,p,m)
    local out = {}
    for r=1,d-1 do
        local n = 0
        for c=1,d do
            local v = c == d and 1 or p[c]
            n = n + v*m[(r-1)*d+c]
        end
        out[r] = n
    end
    return out
end
-- Starbound is a 2D game, so to do ND stuff in it, we just truncate the extra axes and convert to a Mat3
function matn.truncate(d,m)
    return {
        m[1],  m[2],  m[d],
        m[d+1],m[d+2],m[d+d],
        0,0,1
    }
end
-- exports a matn directly to something for animator.transformTransformationGroup without requiring conversion to mat3
function matn.export(d,m)
    return m[1],m[2],m[d+1],m[d+2],m[d],m[d+d]
end

function matn.print(d,m)
    local o = ""
    for x=1,d do
        for y=1,d do
            o = o..string.format("%.1f",m[(y-1)*d+x])
            if y ~= d then
                o = o..","
            end
        end
        o = o.."\n"
    end
    return o
end
