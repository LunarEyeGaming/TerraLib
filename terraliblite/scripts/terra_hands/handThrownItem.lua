require "/scripts/util.lua"
require "/scripts/terra_vec2ref.lua"
require "/scripts/terra_polyref.lua"
require "/scripts/status.lua"
require "/scripts/terra_proxy.lua"

local ownerId
local rootOwnerId
local dieTimer = 20
local doDie = false
local animTimer = -1
local animPosOffset = {0,0}
local animRot = 0
local animTime = 0.4
local fireMode = "none"
local needTables = false
local workVec21 = {0,0}
local workVec22 = {0,0}
local itemConfig = {}
local armLength = 0
local armPosition
local aimPosition
local whichHand = "primary"
local autoDestroy = true
local defaults
local userStatus
local userMcontroller
local userPlayer
local itemParameters = {}
local isFood = false
local cooldown = 0
-- Engine callback - called on initialization of entity
function init()
    self.shouldDie = true
    defaults = root.assetJson("/items/defaultParameters.config")
    ownerId = config.getParameter("ownerId")
    rootOwnerId = config.getParameter("rootOwnerId", ownerId)
    autoDestroy = config.getParameter("autoDestroy", true) -- if true, destroys the monster if item count is below 0 at end of tick
    whichHand = config.getParameter("whichHand","primary")
    armLength = 0
    armPosition = mcontroller.position()
    storage.item = storage.item or config.getParameter("item")
    if type(storage.item) == "string" then
        storage.item = {name=storage.item,count=1,parameters={}}
    end
    if not storage.item.parameters then
        storage.item.parameters = {}
        storage.item.count = 1
    end        
    itemConfig = root.itemConfig(storage.item)
    itemParameters = sb.jsonMerge(itemConfig.config, storage.item.parameters)
  monster.setAggressive(false)
  monster.setDamageOnTouch(false)

  self.collisionPoly = mcontroller.collisionPoly()
  
  script.setUpdateDelta(1)
  
  mcontroller.setAutoClearControls(false)

  animator.setGlobalTag("flipX", "")
  
  mcontroller.controlFace(1)
  monster.setName("Hand")
  
  userStatus = terra_proxy.setupProxy("status",ownerId)
  if not userStatus then
    needTables = true
  else
    userMcontroller = terra_proxy.setupProxy("mcontroller",ownerId)
    userPlayer = terra_proxy.setupProxy("player",ownerId)
  end
end
function setPosition(p, upd)
    armPosition = p
    if upd then
      updatePos()
    end
end
function isHeld()
  return true
end
function twoHanded()
  return false
end
function twoHandedGrip()
  return false
end
function noHeal()
  return true
end
function setTables()
    -- tables should have been provided beforehand
    userStatus = terra_proxy.setupProxy("status",ownerId)
    userMcontroller = terra_proxy.setupProxy("mcontroller",ownerId)
    userPlayer = terra_proxy.setupProxy("player",ownerId)
    needTables = false
end
function keepAlive()
  dieTimer = 20
end
function update(dt)
  mcontroller.setVelocity({0,0})
  dieTimer = dieTimer - 1
  if needTables then
    return 
  end
  if not world.entityExists(ownerId) then
    return
  end
  mcontroller.controlFace(userMcontroller.facingDirection())
  if animTimer ~= -1 then
    animTimer = animTimer + dt/animTime
    if animTimer >= 1 then
      animTimer = -1
    end
  end
  cooldown = cooldown - dt
  updatePos()
  animator.resetTransformationGroup("arm_weapon")
  animator.rotateTransformationGroup("arm_weapon",mcontroller.rotation())
  if storage.item.count <= 0 and autoDestroy then
    destroy()
  end
end
function updatePos()
  if animTimer == -1 then
    mcontroller.setPosition(armPosition)
    mcontroller.setRotation(0)
  else
    mcontroller.setPosition(vec2.add(armPosition, vec2.mul(animPosOffset, 1-animTimer)))
    mcontroller.setRotation(animRot * (1-animTimer))
  end
end
function setAimPosition(pos)
  aimPosition = pos
end
function setFire(mode, shiftHeld)
    if fireMode ~= mode then
      fireMode = mode
      if mode ~= "none" and cooldown <= 0 then
        -- throw the item
        local dis = world.distance(aimPosition, armPosition)
        local projDir = vec2.norm(dis)
        animPosOffset = vec2.mul(projDir,1.25)
        dis[1] = dis[1] * userMcontroller.facingDirection()
        animRot = util.angleDiff(0,vec2.angle(dis))
        animTimer = 0
        local power = itemParameters.projectileConfig.power or root.projectileConfig(itemParameters.projectileType).power
        world.spawnProjectile(itemParameters.projectileType, armPosition, rootOwnerId, projDir, false, sb.jsonMerge(itemParameters.projectileConfig, {power=power*userStatus.stat("powerMultiplier")}))
        cooldown = itemParameters.cooldown or 1
        storage.item.count = storage.item.count - (itemParameters.ammoUsage or 1)
      end
    end
end

function interact(args)
end
function destroy()
    doDie = true
end

function shouldDie()
    return dieTimer < 0 or doDie or not world.entityExists(ownerId)
end
function uninit()
end
function die()
end
