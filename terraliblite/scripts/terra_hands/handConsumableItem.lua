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
local animTime = 0.25
local fireMode = "none"
local needTables = false
local workVec21 = {0,0}
local workVec22 = {0,0}
local itemConfig = {}
local armLength = 0
local armPosition
local whichHand = "primary"
local autoDestroy = true
local defaults
local userStatus
local userMcontroller
local userPlayer
local itemParameters = {}
local isFood = false
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
    if not itemParameters.emitters then
      itemParameters.emitters = {}
    end
    isFood = not not itemParameters.foodValue
    if isFood then
      table.insert(itemParameters.emitters, "eating")
    end
    if not itemParameters.emote then
      itemParameters.emote = "eat"
    end
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
  updatePos()
  animator.resetTransformationGroup("arm_weapon")
  animator.rotateTransformationGroup("arm_weapon",mcontroller.rotation())
  if storage.item.count <= 0 and autoDestroy and animTimer == -1 then
    destroy()
  end
end
function updatePos()
  if animTimer == -1 then
    mcontroller.setPosition(armPosition)
  else
    mcontroller.setPosition(vec2.add(armPosition, vec2.mul(world.distance(isFood and world.entityMouthPosition(ownerId) or world.entityPosition(ownerId), armPosition), animTimer)))
  end
end
function setAimPosition(pos)
end
function setFire(mode, shiftHeld)
    if fireMode ~= mode then
      fireMode = mode
      if mode ~= "none" then
        local invalid = false
        local effects = userStatus.activeUniqueStatusEffectSummary()
        for k2,v2 in next, effects do
          if isFood and v2[1] == "wellfed" then
            invalid = true
            break
          end
          if invalid then
            break
          end
          for k,v in next, (itemParameters.blockingEffects or {}) do
            if v == v2[1] then
              invalid = true
              break
            end
          end
        end
        if not invalid then
          if animTimer == -1 then
            animTimer = 0
            if string.len(itemParameters.emote) > 0 and userPlayer and userPlayer.emote then
              userPlayer.emote(itemParameters.emote)
            end
            local i = 0
            for _,v in next, itemParameters.emitters do
              local path = string.format("/effects/%s.effectsource",v)
              local effectConfig = root.assetJson(path)
              for _,v2 in next, effectConfig.definition.start.sounds[1] do
                i = i + 1
                local s = string.format("arm_use%.0f",i)
                animator.setSoundPosition(s, world.distance(world.entityPosition(ownerId), mcontroller.position()))
                animator.setSoundPool(s, {v2})
                animator.playSound(s)
              end
            end
            if itemParameters.effects and #itemParameters.effects > 0 then
              local effects = itemParameters.effects[math.random(#itemParameters.effects)]
              userStatus.addEphemeralEffects(effects)
            end
            if isFood then
              userStatus.modifyResource("food",itemParameters.foodValue)
              if userStatus.resourcePercentage("food") == 1 then
                userStatus.addEphemeralEffect("wellfed")
              end
            end
            storage.item.count = storage.item.count - 1
          end
        end
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
