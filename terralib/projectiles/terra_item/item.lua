require "/scripts/vec2.lua"
local pickupRange
local snapRange
local snapSpeed
local snapForce
local item
local targetEntity
local pickedUp

function init()
  pickupRange = config.getParameter("pickupRange")
  snapRange = config.getParameter("snapRange")
  snapSpeed = config.getParameter("snapSpeed")
  snapForce = config.getParameter("snapForce")
  item = config.getParameter("item")
  local itemDrop = config.getParameter("itemDrop")
  if itemDrop then
      item = world.takeItemDrop(itemDrop)
  end

  targetEntity = nil
  pickedUp = false
  
  message.setHandler("getRenderConfig", function ()
                     return {image=config.getParameter("image"), frameNumber=config.getParameter("frameNumber"), animationCycle=config.getParameter("animationCycle"), fullbright=config.getParameter("fullbright", true), scaleEffect=config.getParameter("doScaleEffect"), scaleSpeed=config.getParameter("scaleSpeed"), scaleMagnitude=config.getParameter("scaleMagnitude"), light=config.getParameter("lightColor")}
                     end)
end

function update(dt)
  mcontroller.applyParameters({gravityEnabled=false})
  if pickedUp then return end
  if not item then
      projectile.die()
      return
  end

  if not targetEntity then
    findTarget()
  end

  if targetEntity then
    if world.entityExists(targetEntity) then
      local targetPos = world.entityPosition(targetEntity)
      local toTarget = world.distance(targetPos, mcontroller.position())
      local targetDist = vec2.mag(toTarget)
      if targetDist <= pickupRange then
        world.spawnItem(item, targetPos)
        pickedUp = true
        projectile.die()
      else
        mcontroller.applyParameters({gravityEnabled=false, collisionEnabled=false})
        mcontroller.approachVelocity(vec2.mul(vec2.div(toTarget, targetDist), snapSpeed), snapForce)
      end
    else
      targetEntity = nil
      mcontroller.setVelocity({0, 0})
    end
  end

  script.setUpdateDelta(targetEntity and 1 or 10)
end

function findTarget()
  local candidates = world.entityQuery(mcontroller.position(), snapRange, {includedTypes = {"Player"}, boundMode = "position", order = "nearest"})
  targetEntity = candidates[1]
end
