require "/scripts/poly.lua"
require "/scripts/terra_vec2ref.lua"

function poly.flipInPlace(p)
    for k,v in next, p do
        v[1] = -v[1]
    end
    return p
end

-- equalizes the length of 2 polies
function poly.equalize(p,out)
    if #p > #out then
        while #p > #out do
            table.insert(out, {0,0})
        end
    elseif #p < #out then
        while #p < #out do
            table.remove(out)
        end
    end
    return out
end

function poly.translateToRef(p,pos,out)
    for k,v in next, p do
        vec2.addToRef(v,pos,out[k])
    end
    return out
end
