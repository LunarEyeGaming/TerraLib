--Made by Silver Sokolova#3576
function init()
  activeItem.setArmAngle(-math.pi / 2)
  a_useTime = config.getParameter("useTime",0.1)

  foodValue = config.getParameter("foodValue",0)
  ammoUsage = config.getParameter("ammoUsage",1)

  resource = config.getParameter("resource","food")

  emote = config.getParameter("emote")
  effects = config.getParameter("effects")
  blockingEffects = config.getParameter("blockingEffects")
  soundSet = config.getParameter("soundSet","none")

  giveWellfed = config.getParameter("giveWellfed")
  autoFire = config.getParameter("autoFire")

  justUsed = false

  if emote and type(emote) == "string" then emote = {emote} end
  if type(soundSet) == "string" then soundSet = {soundSet} end
end

function update(dt, fireMode)
  a_aimAngle, a_aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  activeItem.setFacingDirection(a_aimDirection)

  if not a_useTimer and fireMode == "primary" and player and not justUsed then
    if blockingEffects then for i = 1, #blockingEffects do if status.uniqueStatusEffectActive(blockingEffects[i]) then return end end end
    a_useTimer = a_useTime
    justUsed = autoFire and true or false
  end

  if a_useTimer then
    a_useTimer = math.max(0, a_useTimer - dt)

    activeItem.setArmAngle((-math.pi / 2) * (a_useTimer / 0.15))

    if a_useTimer == 0 then
      applyAdditionalEffects()
      animator.playSound(soundSet[math.random(#soundSet)])
      if emote then activeItem.emote(emote[math.random(#emote)]) end
	if status.isResource(resource) then
	  if giveWellfed and status.resourceMax(resource) < foodValue + status.resource(resource) then status.addEphemeralEffect("wellfed") end
	  status.modifyResource(resource,foodValue)
	elseif giveWellfed then status.addEphemeralEffect("wellfed") end

	if effects then status.addEphemeralEffects(effects) end

      item.consume(ammoUsage)
      activeItem.setArmAngle(-math.pi / 2)
      a_useTimer = nil
    end
  end
  justUsed = fireMode == "primary" and not autoFire
end

function applyAdditionalEffects() end