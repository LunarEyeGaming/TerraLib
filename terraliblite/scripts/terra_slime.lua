require "/scripts/behavior.lua"
require "/scripts/pathing.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/drops.lua"
require "/scripts/status.lua"
require "/scripts/companions/capturable.lua"
require "/scripts/tenant.lua"
require "/scripts/actions/movement.lua"
require "/scripts/actions/animator.lua"
require "/scripts/actions/terra_rotateUtil.lua"

function ownerId()
    if capturable.ownerUuid() then
        local playerIds = world.players()
        table.sort(playerIds, function(a)
      return world.entityUniqueId(a) == capturable.ownerUuid() end)
        return playerIds[1]
    else
        return nil
    end
end

local hopTimer = 0
local hopDelay = 15 -- the timer ticks up when the slime is on the ground
local hopDelayIdleMult = 1.5

local jumpHStrength = 1
local jumpVStrength = 1
local heldItem = nil

-- Engine callback - called on initialization of entity
function init()

self.offScreen = true
self.children = {}
  self.shouldDie = true
  self.targetId = nil
  self.queryRange = 100
  self.keepTargetInRange = 250
  self.targets = {}
  self.targetPos = mcontroller.position()
  self.outOfSight = {}
  jumpHStrength = config.getParameter("jumpHStrength",20)
  jumpVStrength = config.getParameter("jumpVStrength",40)
  
  hopDelay = config.getParameter("hopDelay", 90)
  hopDelayIdleMult = config.getParameter("hopDelayIdleMult", 1.5)
  
  heldItem = config.getParameter("heldItem")
  if math.random() < config.getParameter("heldItemChance", 0) then
    local pool = config.getParameter("heldItemPool", {})
    heldItem = pool[math.floor(math.random() * #pool)]
  end
  
  self.notifications = {}
  self.ownerId = config.getParameter("ownerId")
  self.approachSpeed = config.getParameter("approachSpeed",0.5)
  storage.spawnTime = world.time()
  if storage.spawnPosition == nil or config.getParameter("wasRelocated", false) then
    local position = mcontroller.position()
    local groundSpawnPosition
    if mcontroller.baseParameters().gravityEnabled then
      groundSpawnPosition = findGroundPosition(position, -20, 3)
    end
    storage.spawnPosition = groundSpawnPosition or position
  end

  self.behavior = behavior.behavior(config.getParameter("behavior"), sb.jsonMerge(config.getParameter("behaviorConfig", {}), skillBehaviorConfig()), _ENV)
  self.board = self.behavior:blackboard()
  self.board:setPosition("spawn", storage.spawnPosition)

  self.collisionPoly = mcontroller.collisionPoly()

  if animator.hasSound("deathPuff") then
    monster.setDeathSound("deathPuff")
  end
  if config.getParameter("deathParticles") then
    monster.setDeathParticleBurst(config.getParameter("deathParticles"))
  end

  script.setUpdateDelta(config.getParameter("initialScriptDelta", 1))
  mcontroller.setAutoClearControls(false)
  self.behaviorTickRate = config.getParameter("behaviorUpdateDelta", 2)
  self.behaviorTick = math.random(1, self.behaviorTickRate)

  animator.setGlobalTag("flipX", "")
  self.board:setNumber("facingDirection", mcontroller.facingDirection())

  capturable.init()
  
  monster.setAggressive(config.getParameter("aggressive", false))

  -- Listen to damage taken
  self.damageTaken = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        self.targetId = notification.sourceEntityId
        self.targets = {self.targetId}
      end
    end
  end)

  self.debug = true

  message.setHandler("notify", function(_,_,notification)
      return notify(notification)
    end)
  message.setHandler("despawn", function()
      monster.setDropPool(nil)
      monster.setDeathParticleBurst(nil)
      monster.setDeathSound(nil)
      self.deathBehavior = nil
      self.shouldDie = true
      status.addEphemeralEffect("monsterdespawn")
    stopMusic()
    end)

  local deathBehavior = config.getParameter("deathBehavior")
  if deathBehavior then
    self.deathBehavior = behavior.behavior(deathBehavior, config.getParameter("behaviorConfig", {}), _ENV, self.behavior:blackboard())
  end

  self.forceRegions = ControlMap:new(config.getParameter("forceRegions", {}))
  self.damageSources = ControlMap:new(config.getParameter("damageSources", {}))
  self.touchDamageEnabled = false

  monster.setInteractive(config.getParameter("interactive", false))

  monster.setAnimationParameter("chains", config.getParameter("chains"))
end

function stopMusic()
    return
end
function update(dt)
  if config.getParameter("facingMode", "control") == "transformation" then
    mcontroller.controlFace(1)
  end
  if status.resourcePercentage("health") == 0 then
        stopMusic()
    end
  capturable.update(dt)
  self.damageTaken:update()

  if status.resourcePositive("stunned") then
    animator.setAnimationState("damage", "stunned")
    animator.setGlobalTag("hurt", "hurt")
    self.stunned = true
    mcontroller.clearControls()
    if self.damaged then
      self.suppressDamageTimer = config.getParameter("stunDamageSuppression", 0.5)
      monster.setDamageOnTouch(false)
    end
    return
  else
    animator.setGlobalTag("hurt", "")
    animator.setAnimationState("damage", "none")
  end

  monster.setDamageOnTouch(true)
  if config.getParameter("aggressive") then
  if #self.targets == 0 then
    local newTargets = world.entityQuery(mcontroller.position(), self.queryRange, {includedTypes = {"player","npc"}})
    table.sort(newTargets, function(a, b)
      return world.magnitude(world.entityPosition(a), mcontroller.position()) < world.magnitude(world.entityPosition(b), mcontroller.position())
    end)
    for _,entityId in pairs(newTargets) do
      if true then
        table.insert(self.targets, entityId)
      end
    end
  end
  end
repeat
    self.targetId = self.targets[1]
    if self.targetId == nil then break end

    local targetId = self.targetId
    if not world.entityExists(targetId)
       or world.magnitude(world.entityPosition(targetId), mcontroller.position()) > self.keepTargetInRange then
      table.remove(self.targets, 1)
      self.targetId = nil
    end
    if not self.targetId or not entity.isValidTarget(targetId) then
        table.remove(self.targets, 1)
        self.targetId = nil
    end
    if self.targetId then
        if mcontroller.baseParameters().collisionEnabled and not entity.entityInSight(self.targetId) then
            table.remove(self.targets, 1)
            self.targetId = nil
        end
    end
  until #self.targets <= 0 or self.targetId
  if heldItem then
    local iconfig = root.itemConfig(heldItem)
    local image = iconfig.directory..(iconfig.parameters.inventoryIcon or iconfig.config.inventoryIcon)
    animator.setGlobalTag("heldItemImage", image)
    local dims = root.imageSize(image)
    local size = (dims[1] > dims[2] and dims[1]) or dims[2]
    local scale = config.getParameter("scale")
    maxSize = 12 * scale
    size = (size > maxSize and size) or maxSize
    animator.resetTransformationGroup("item")
    animator.scaleTransformationGroup("item", {maxSize / size / scale, maxSize / size / scale})
  end
  move()
  self.behaviorTick = self.behaviorTick + 1
end

function skillBehaviorConfig()
  local skills = config.getParameter("skills", {})
  local skillConfig = {}

  for _,skillName in pairs(skills) do
    local skillHostileActions = root.monsterSkillParameter(skillName, "hostileActions")
    if skillHostileActions then
      construct(skillConfig, "hostileActions")
      util.appendLists(skillConfig.hostileActions, skillHostileActions)
    end
  end

  return skillConfig
end

function interact(args)
  self.interacted = true
  self.board:setEntity("interactionSource", args.sourceId)
end

function shouldDie()
  return (self.shouldDie and status.resource("health") <= 0) or capturable.justCaptured
end

function die()
    if not capturable.justCaptured then
    if self.deathBehavior then
      self.deathBehavior:run(script.updateDt())
    end
    capturable.die()
  end
  spawnDrops()
  if heldItem then
    world.spawnItem(heldItem, mcontroller.position())
  end
end

function uninit()
  BGroup:uninit()
end

function setDamageSources()
  local partSources = {}
  for part,ds in pairs(config.getParameter("damageParts", {})) do
    local damageArea = animator.partPoly(part, "damageArea")
    if damageArea then
      ds.poly = damageArea
      table.insert(partSources, ds)
    end
  end

  local damageSources = util.mergeLists(partSources, self.damageSources:values())
  damageSources = util.map(damageSources, function(ds)
    ds.damage = ds.damage * root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * status.stat("powerMultiplier")
    if ds.knockback and type(ds.knockback) == "table" then
      ds.knockback[1] = ds.knockback[1] * mcontroller.facingDirection()
    end

    local team = entity.damageTeam()
    ds.team = { type = ds.damageTeamType or team.type, team = ds.damageTeam or team.team }

    return ds
  end)
  monster.setDamageSources(damageSources)
end

function setPhysicsForces()
  local regions = util.map(self.forceRegions:values(), function(region)
    if region.type == "RadialForceRegion" then
      region.center = vec2.add(mcontroller.position(), region.center)
    elseif region.type == "DirectionalForceRegion" then
      if region.rectRegion then
        region.rectRegion = rect.translate(region.rectRegion, mcontroller.position())
        util.debugRect(region.rectRegion, "blue")
      elseif region.polyRegion then
        region.polyRegion = poly.translate(region.polyRegion, mcontroller.position())
      end
    end

    return region
  end)

  monster.setPhysicsForces(regions)
end

function overrideCollisionPoly()
  local collisionParts = config.getParameter("collisionParts", {})

  for _,part in pairs(collisionParts) do
    local collisionPoly = animator.partPoly(part, "collisionPoly")
    if collisionPoly then
      -- Animator flips the polygon by default
      -- to have it unflipped we need to flip it again
      if not config.getParameter("flipPartPoly", true) and mcontroller.facingDirection() < 0 then
        collisionPoly = poly.flip(collisionPoly)
      end
      mcontroller.controlParameters({collisionPoly = collisionPoly, standingPoly = collisionPoly, crouchingPoly = collisionPoly})
      break
    end
  end
end

function setupTenant(...)
  require("/scripts/tenant.lua")
  tenant.setHome(...)
end
function move()
    local delay = hopDelay
    if not self.targetPos then
      self.targetPos = mcontroller.position()
    end
    world.debugLine(mcontroller.position(), self.targetPos, "red")
    if math.abs(world.distance(mcontroller.position(), self.targetPos)[1]) < 2 then
      self.targetPos = {math.random() * world.size()[1], mcontroller.yPosition()}
    end
    monster.setAggressive(self.targetId ~= nil)
    if self.targetId then
      self.targetPos = world.entityPosition(self.targetId)
    else
      delay = hopDelay * hopDelayIdleMult
    end
    if mcontroller.onGround() then
      hopTimer = hopTimer + 1
      if hopTimer / delay > 0.5 then
        animator.setAnimationState("body", "windup")
      else
        animator.setAnimationState("body", "idle")
      end
      if hopTimer >= delay then
        hopTimer = 0
        mcontroller.setVelocity(vec2.add(mcontroller.velocity(), {jumpHStrength * ((world.distance(self.targetPos, mcontroller.position())[1] > 0 and 1) or -1), jumpVStrength}))
      end
    elseif mcontroller.liquidPercentage() > 0.5 then
      animator.setAnimationState("body", "floating")
      mcontroller.setYVelocity(mcontroller.yVelocity() + 1)
    else
      animator.setAnimationState("body", "jumping")
    end
end
