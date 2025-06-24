require "/scripts/vec2.lua"

function activate(fireMode, shiftHeld)
  if not storage.firing then
    if config.getParameter("allowAtNightOnly") then
        if world.timeOfDay() < 0.5 then
            return
        end
    end
    self.active = true
    local offset = config.getParameter("spawnOffset", {0, 0})
    if config.getParameter("allowAnyHorizontalSide") then
        if math.random() > 0.5 then
            offset[1] = offset[1] * -1
        end
    end
    animator.playSound("use")
    world.spawnMonster(config.getParameter("monster"), vec2.add(mcontroller.position(), offset), { level = config.getParameter("spawnLevel")})
    item.consume(1)
  end
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition({0, 0}))
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(config.getParameter("inaccuracy", 0), 0))
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end

function holdingItem()
  return true
end

function recoil()
  return false
end

function outsideOfHand()
  return false
end
