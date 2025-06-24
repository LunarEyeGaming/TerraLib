
require("/scripts/util.lua")
rotateUtil = {}
function rotateUtil.getRelativeAngle(angle1, angle2) -- angle1 is target, angle2 is entity
    -- util exists, this isn't needed, I made this without knowing it existed
    return util.angleDiff(angle2, angle1)
end
function rotateUtil.slowRotate(rot, amount, speed)
    if math.abs(amount) < speed then
        return rot + amount
    elseif amount > 0 then
        return rot + speed
    else
        return rot - speed
    end
end 
