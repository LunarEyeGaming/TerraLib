-- loads of stuff for arms
require "/scripts/terra_vec2ref.lua"

inversekinematics = {}

local vec2working1 = {0,0}

function inversekinematics.solveAngles(baseJoint, handJoint, forearmLength, armLength, useAlt)
    -- https://www.alanzucconi.com/2018/05/02/ik-2d-1/
    if armLength == nil then
        armLength = forearmLength
    end
    -- the arm forms a triangle
    local a = armLength
    local c = forearmLength
    -- magnitude between baseJoint and handJoint = b
    local b = world.magnitude(baseJoint, handJoint)
    -- use cosine law to calculate angles
    local alpha = math.acos((b*b+c*c-a*a)/(2*b*c))
    local beta = math.acos((c*c+a*a-b*b)/(2*a*c))
    local Ba
    if useAlt then
        Ba = math.pi + beta
    else
        Ba = math.pi - beta
    end
    local diff = world.distance(baseJoint, handJoint)
    local An = vec2.angle(diff)
    local Aa
    if useAlt then
        Aa = An - alpha
    else
        Aa = alpha + An
    end
    return Aa,Ba
end
function inversekinematics.solve(baseJoint, handJoint, forearmLength, armLength)
    -- https://www.alanzucconi.com/2018/05/02/ik-2d-1/
    if armLength == nil then
        armLength = forearmLength
    end
    -- the arm forms a triangle
    -- armLength = a
    -- forearmLength = c
    -- magnitude between baseJoint and handJoint = b
    local b = world.magnitude(baseJoint, handJoint)
    -- use cosine law to calculate angles
    local alpha = math.acos((b*b+forearmLength*forearmLength-armLength*armLength)/(2*b*armLength))
    local beta = math.acos((forearmLength*forearmLength+armLength*armLength-b*b)/(2*forearmLength*armLength))
    local Ba = math.pi - beta
    local diff = world.distance(baseJoint, handJoint)
    local An = vec2.angle(diff)
    local Aa = alpha + An
    jointPos = vec2.add(vec2.withAngle(Aa, armLength), handJoint)
    return {pos=jointPos,Aa=Aa,Ba=Ba}
end
function inversekinematics.clampLength(baseJoint, handJoint, maxLength)
    local output = {handJoint[1],handJoint[2]}
    local length = world.magnitude(baseJoint, handJoint)
    if length > maxLength then
        output = vec2.add(vec2.withAngle(vec2.angle(world.distance(handJoint, baseJoint)), maxLength), baseJoint)
    end
    return output
end
function inversekinematics.solvePos(baseJoint, handJoint, forearmLength, armLength)
    if armLength == nil then
        armLength = forearmLength
    end
    local b = world.magnitude(baseJoint, handJoint)
    local Aa = math.acos((b*b+armLength*armLength-forearmLength*forearmLength)/(2*b*armLength)) + vec2.angle(world.distance(baseJoint, handJoint))
    return vec2.add(vec2.withAngle(Aa, armLength), handJoint)
end
function inversekinematics.solvePosToRef(baseJoint, handJoint, forearmLength, armLength, out)
    if armLength == nil then
        armLength = forearmLength
    end
    local b = world.magnitude(baseJoint, handJoint)
    local Aa = math.acos((b*b+armLength*armLength-forearmLength*forearmLength)/(2*b*armLength)) + vec2.angle(world.distance(baseJoint, handJoint))
    return vec2.addToRef(vec2.withAngleToRef(Aa, armLength, vec2working1), handJoint, out)
end
