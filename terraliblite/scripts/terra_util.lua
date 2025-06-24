require "/scripts/terra_vec2ref.lua"
terraUtil = {}
local workVec21 = {0,0}
local workVec22 = {0,0}
local workVec23 = {0,0}
local workVec24 = {0,0}
local workVec25 = {0,0}
local workVec26 = {0,0}
local workVec27 = {0,0}
local workVec28 = {0,0}
local zeroVec = {0,0}
local nullTbl = {}
local workTable4 = {0,0,0,0}
local projPhysConfig
local failOut = {
    vdir={1,0},
    angle=0,
    failed=true
}
-- checking against math.huge is unreliable, so check if larger than really big number instead
local veryBig = 2^1023
function terraUtil.solveQuartic(a,b,c,d,e)
  -- ported from JS code
  if b == 0 and d == 0 then
    -- this is biquadratic
    -- solve using quadratic formula instead
    local sqrt = math.sqrt(c^2-4*a*e)
    local sqrtzp = math.sqrt((-c+sqrt)/(2*a))
    local sqrtzn = math.sqrt((-c-sqrt)/(2*a))
    workTable4[1] = sqrtzp
    workTable4[2] = -sqrtzp
    workTable4[3] = sqrtzn
    workTable4[4] = -sqrtzn
    return workTable4
  end
  -- https://en.wikipedia.org/wiki/Quartic_function#General_formula_for_roots
  local d0 = c^2 - 3*b*d + 12*a*e
  local d1 = 2*c^3 - 9*b*c*d + 27*a*d^2 + 27*b^2*e - 72*a*c*e
  local Q_ = d1 + math.sqrt(-4*d0^3 + d1^2)
  local p = (8*a*c - 3*b^2)/(8*a^2)
  local q = (b^3-4*a*b*c+8*a^2*d)/(8*a^3)
  local S
  if Q_ > veryBig then -- why does Lua have sqrt(-1) return as inf?
    -- an answer probably exists but cannot be found normally due to complex numbers
    -- use alternative solution
    S = math.sqrt((-2*p)/3+((2*math.sqrt(d0))/(3*a))*math.cos(math.acos(d1/(2*math.sqrt(d0^3)))/3))/2
  else
    local Q = (Q_/2)^(1/3)
    S = math.sqrt((-2*p)/3+(Q+d0/Q)/(3*a))
  end
  local A = -b/(4*a)
  local fa = math.sqrt(-4*S^2-2*p+q/S)
  local fb = math.sqrt(-4*S^2-2*p-q/S)
  workTable4[1] = A - S + fa/2
  workTable4[2] = A - S - fa/2
  workTable4[3] = A + S + fb/2
  workTable4[4] = A + S - fb/2
  return workTable4
end
-- aim ahead of the target
-- non-iterative, fast, and doesn't have the precision issues of iterative solutions
-- however, unable to handle projectiles that accelerate (rockets)
function terraUtil.linearTargeting(epos, mepos, evel, projSpeed)
    -- ported from 3D JS code
    
    -- https://robowiki.net/wiki/Linear_Targeting#Explanation
    -- optimized a bit; the robowiki code needlessly calls sqrt multiple times and does the full t calculation twice instead of just doing part of it
    local curPos = epos
    local bV = projSpeed
    local eV = vec2.mag(evel)
    local eD = vec2.divToRef(evel, eV, workVec21)
    local A = world.distance(epos, mepos)--vec2.disToRef(epos, mepos, workVec22)
    vec2.divToRef(A,bV,A)
    local B = vec2.mulToRef(eD, eV/bV, workVec23)
    local a = vec2.magSq(A)
    local b = 2*vec2.dot(A,B)
    local c = vec2.magSq(B)-1
    local discrim = b*b - 4*a*c
    if discrim >= 0 then
      local drt = math.sqrt(discrim)
      local div = drt < b and math.min((-b + drt), (-b - drt)) or math.max((-b + drt), (-b - drt))
      local t = 2*a/div
      -- return enemy predicted position
      return vec2.addToRef(epos, vec2.mulToRef(evel, t, workVec22), workVec24)
    else
      -- no solution exists
      return nil
    end
end
local function validSolution(n)
    return n >= 0 and n < veryBig
end
local arcTargetingOut = {
    ivel={0,0},
    vdir={1,0},
    time=0,
    angle=0
}
-- while vanilla offers a function for firing with arc, it doesn't apply target velocity, so here's a non-iterative function that does just that
function terraUtil.arcTargeting(epos, mepos, v_T, s, a_p, a_T, lob)
    -- ported from 3D JS code, with additional changes for versatility
    if not a_T then a_T = zeroVec end
    if type(a_T) ~= "table" then
        lob = a_T
        a_T = zeroVec
    end
    
    local p_T = world.distance(epos, mepos)--vec2.disToRef(epos, mepos, workVec21)
    local a = vec2.subToRef(a_T, a_p, workVec22)
    failOut.details = {a}
    local solutions = terraUtil.solveQuartic(
      vec2.dot(a,a)/4,
      vec2.dot(a,v_T),
      vec2.dot(a,p_T) + vec2.dot(v_T,v_T) - s^2,
      2*vec2.dot(v_T, p_T),
      vec2.dot(p_T,p_T)
    )
    for i = 1,4 do
      if not validSolution(solutions[i]) then
        solutions[i] = lob and -1/0 or 1/0
      end
    end
    local t = lob and
        math.max(solutions[1],solutions[2],solutions[3],solutions[4]) or
        math.min(solutions[1],solutions[2],solutions[3],solutions[4])
    
    if math.abs(t) > veryBig then
      failOut.reason="noSolutionArc"
      world.debugText("noSolutionArc", mepos, "red")
      return failOut -- no solutions
    end
    arcTargetingOut.time = t
    local travel = vec2.addToRef(p_T,vec2.mulToRef(v_T, t, workVec22), workVec22)
    if a_T ~= zeroVec then
        vec2.addToRef(travel, vec2.mulToRef(vec2.divToRef(a_T,2,workVec21), t^2, workVec21), travel)
    end
    local v_p = vec2.subToRef(vec2.divToRef(travel, t, workVec21), vec2.mulToRef(vec2.divToRef(a_p,2,workVec22), t, workVec22), arcTargetingOut.ivel)
    local dir = vec2.normToRef(v_p,arcTargetingOut.vdir)
    arcTargetingOut.angle = vec2.angle(dir)
    return arcTargetingOut
end
local pConfig_cache
local pConfig_cacheData = {
    t=nil,
    p=nil
}
local aimAtLinearOut = {
    vdir={1,0},
    angle=0
}
defaultPhysConfig = nil
function terraUtil.aimAtEntity(e,mepos,ptype,pparams,lob)
    if type(pparams) ~= "table" then
        lob = pparams
        pparams = nullTbl
    end
    local pconfig
    if pConfig_cacheData.t == ptype and pConfig_cacheData.p == pparams then
        pconfig = pConfig_cache
    else
        if not projPhysConfig then
            projPhysConfig = root.assetJson("/projectiles/physics.config")
        end
        if not defaultPhysConfig then
          defaultPhysConfig = root.assetJson("/default_movement.config")
        end
        local pconfig = sb.jsonMerge(root.projectileConfig(ptype), pparams)
        pconfig.movementParameters = sb.jsonMerge(defaultPhysConfig,sb.jsonMerge(projPhysConfig[pconfig.physics or "default"], pconfig.movementSettings))
        pConfig_cache = pconfig
        pConfig_cacheData.t = ptype
        pConfig_cacheData.p = pparams
    end
    local mepos = mcontroller.position()
    local epos = world.entityPosition(e)
    local evel = world.entityVelocity(e)
    local speed = pconfig.speed or 50
    if type(speed) == "table" then
      -- just use the average
      speed = (speed[1]+speed[2])/2
    end
    if pconfig.movementParameters.gravityEnabled and pconfig.movementParameters.gravityMultiplier ~= 0 then
      -- use arc targeting
      workVec25[1] = 0
      workVec25[2] = -world.gravity(mepos)*pconfig.movementParameters.gravityMultiplier*(1-pconfig.movementParameters.airBuoyancy)
      return terraUtil.arcTargeting(epos, mepos, evel, speed, workVec25, lob) or nullOut
    elseif pconfig.acceleration == 0 then
      -- use linear targeting
      local predictedPos = terraUtil.linearTargeting(epos, mepos, evel, speed)
      if not predictedPos then
        return failOut
      end
      vec2.copyToRef(world.distance(predictedPos, mepos), aimAtLinearOut.vdir)--vec2.disToRef(predictedPos, mepos, aimAtLinearOut.vdir)
      aimAtLinearOut.angle = vec2.angle(aimAtLinearOut.vdir)
      return aimAtLinearOut
    end
    return failOut
end
function terraUtil.aimAtEntity_simple(e,mepos,pconfig,lob)
    local epos = world.entityPosition(e)
    local evel = world.entityVelocity(e)
    local speed = pconfig.speed or 50
    if type(speed) == "table" then
      -- just use the average
      speed = (speed[1]+speed[2])/2
    end
    if pconfig.movementParameters.gravityEnabled and pconfig.movementParameters.gravityMultiplier ~= 0 then
      -- use arc targeting
      workVec25[1] = 0
      workVec25[2] = -world.gravity(mepos)*pconfig.movementParameters.gravityMultiplier*(1-pconfig.movementParameters.airBuoyancy)
      return terraUtil.arcTargeting(epos, mepos, evel, speed, workVec25, lob) or nullOut
    elseif pconfig.acceleration == 0 or not pconfig.acceleration then
      -- use linear targeting
      local predictedPos = terraUtil.linearTargeting(epos, mepos, evel, speed)
      if not predictedPos then
        failOut.reason="noSolutionLinear"
        failOut.details = nil
        return failOut
      end
      vec2.normToRef(vec2.copyToRef(world.distance(predictedPos, mepos), aimAtLinearOut.vdir),aimAtLinearOut.vdir)
      aimAtLinearOut.angle = vec2.angle(aimAtLinearOut.vdir)
      return aimAtLinearOut
    end
    failOut.reason="noGravity,accel~=0"
    failOut.details = nil
    return failOut
end
