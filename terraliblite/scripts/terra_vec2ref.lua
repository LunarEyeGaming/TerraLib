require "/scripts/vec2.lua"

-- vec2, but with additional functions that can be used to make faster code that reduces unnecessary memory allocation
-- vec2 claims to work in place but it actually doesn't
-- this allows reusing tables
local working1 = {0,0}
local working2 = {0,0}
local working3 = {0,0}
local working4 = {0,0}

function vec2.magSq(vector)
  return vector[1] * vector[1] + vector[2] * vector[2]
end

function vec2.copyToRef(vector, out)
    out[1] = vector[1]
    out[2] = vector[2]
    return out
end
function vec2.crossToRef(v,v2,out)
  out[1] = v.y*v2.x-v.x*v2.y
  out[2] = v.x*v2.y-v.y*v2.x
  return out
end
function vec2.normToRef(vector, out)
  return vec2.divToRef(vector, vec2.mag(vector), out)
end

function vec2.mulToRef(vector, scalar_or_vector, out)
  if type(scalar_or_vector) == "table" then
    out[1] = vector[1] * scalar_or_vector[1]
    out[2] = vector[2] * scalar_or_vector[2]
    return out
  else
    out[1] = vector[1] * scalar_or_vector
    out[2] = vector[2] * scalar_or_vector
    return out
  end
end

function vec2.divToRef(vector, scalar, out)
  if scalar == 0 then return vector end
    out[1] = vector[1] / scalar
    out[2] = vector[2] / scalar
    return out
end

function vec2.addToRef(vector, scalar_or_vector, out)
  if type(scalar_or_vector) == "table" then
    out[1] = vector[1] + scalar_or_vector[1]
    out[2] = vector[2] + scalar_or_vector[2]
    return out
  else
    out[1] = vector[1] + scalar_or_vector
    out[2] = vector[2] + scalar_or_vector
    return out
  end
end

function vec2.subToRef(vector, scalar_or_vector, out)
  if type(scalar_or_vector) == "table" then
    out[1] = vector[1] - scalar_or_vector[1]
    out[2] = vector[2] - scalar_or_vector[2]
    return out
  else
    out[1] = vector[1] - scalar_or_vector
    out[2] = vector[2] - scalar_or_vector
    return out
  end
end

function vec2.wrapToRef(vector, out)
  out[1] = world.xwrap(vector[1])
  out[2] = vector[2]
  return out
end

function vec2.disToRef(vector, vector2, out)
  -- world.distance but in place
  local w = world.size()[1]
  vec2.wrapToRef(vector, working1)
  vec2.wrapToRef(vector2, working2)
  vec2.subToRef(working1, working2, out)
  if w == 0 then
    return out
  end
  if out[1] > w/2 then
    out[1] = w-out[1]
  elseif out[1] < -w/2 then
    out[1] = w+out[1]
  end
  return out
end
function vec2.disToRef_nw(vector, vector2, out)
  -- previous function without initial wrapping (a bit faster, expects both vectors to be within world size)
  local w = world.size()[1]
  vec2.subToRef(vector, vector2, out)
  if w == 0 then
    return out
  end
  if out[1] > w/2 then
    out[1] = w-out[1]
  elseif out[1] < -w/2 then
    out[1] = w+out[1]
  end
  return out
end

function vec2.rotateToRef(vector, angle, out)
  if angle == 0 then return vec2.copyToRef(vector, out) end

  local sinAngle = math.sin(angle)
  local cosAngle = math.cos(angle)

  out[1] = vector[1] * cosAngle - vector[2] * sinAngle
  out[2] = vector[1] * sinAngle + vector[2] * cosAngle
  return out
end

function vec2.withAngleToRef(angle, magnitude, out)
  magnitude = magnitude or 1
  out[1] = math.cos(angle) * magnitude
  out[2] = math.sin(angle) * magnitude
  return out
end

function vec2.intersectToRef(a0, a1, b0, b1, out)
  working1[1] = a1[1] - a0[1] 
  working1[2] = a1[2] - a0[2]
  working2[1] = b1[1] - b0[1]
  working2[2] = b1[2] - b0[2]

  local s = (-working1[2] * (a0[1] - b0[1]) + working1[1] * (a0[2] - b0[2])) / (-working2[1] * working1[2] + working1[1] * working2[2]);
  local t = ( working2[1] * (a0[2] - b0[2]) - working2[2] * (a0[1] - b0[1])) / (-working2[1] * working1[2] + working1[1] * working2[2]);

  if s < 0 or s > 1 or t < 0 or t > 1 then
    return nil
  end

  out[1] = a0[1] + (t * working1[1])
  out[2] = a0[2] + (t * working1[2])
  return out
end

function vec2.floorToRef(vector, out)
  out[1] = math.floor(vector[1])
  out[2] = math.floor(vector[2])
  return out
end

function vec2.approachToRef(vector, target, rate, out)
  local maxDist = math.max(math.abs(target[1] - vector[1]), math.abs(target[2] - vector[2]))
  if maxDist <= rate then return target end

  local fractionalRate = rate / maxDist
  out[1] = vector[1] + fractionalRate * (target[1] - vector[1])
  out[2] = vector[2] + fractionalRate * (target[2] - vector[2])
  return out
end

function vec2.lerpToRef(ratio, a, b, out)
  out[1] = a[1] + (b[1] - a[1]) * ratio
  out[2] = a[2] + (b[2] - a[2]) * ratio
  return out
end
