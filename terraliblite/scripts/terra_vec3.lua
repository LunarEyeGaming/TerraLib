-- Like vec2, but vectors with 3 components, for advanced 3D things or for 3-channel colour manipulation
require "/scripts/vec2.lua"
vec3 = {}
function vec3.eq(vector1, vector2)
  return vector1[1] == vector2[1] and vector1[2] == vector2[2] and vector1[3] == vector2[3]
end

function vec3.mag(vector)
  return math.sqrt(vector[1] * vector[1] + vector[2] * vector[2] + vector[3] * vector[3])
end

function vec3.norm(vector)
  return vec3.div(vector, vec3.mag(vector))
end
function vec3.clone(vector)
  return {
      vector[1],
      vector[2],
      vector[3]
    }
end

function vec3.mul(vector, scalar_or_vector)
  if type(scalar_or_vector) == "table" then
    return {
      vector[1] * scalar_or_vector[1],
      vector[2] * scalar_or_vector[2],
      vector[3] * scalar_or_vector[3]
    }
  else
    return {
      vector[1] * scalar_or_vector,
      vector[2] * scalar_or_vector,
      vector[3] * scalar_or_vector
    }
  end
end

function vec3.div(vector, scalar)
  if scalar == 0 then return vector end
  return {
      vector[1] / scalar,
      vector[2] / scalar,
      vector[3] / scalar
    }
end

function vec3.add(vector, scalar_or_vector)
  if type(scalar_or_vector) == "table" then
    return {
        vector[1] + scalar_or_vector[1],
        vector[2] + scalar_or_vector[2],
        vector[3] + scalar_or_vector[3]
      }
  else
    return {
        vector[1] + scalar_or_vector,
        vector[2] + scalar_or_vector,
        vector[3] + scalar_or_vector
      }
  end
end

function vec3.sub(vector, scalar_or_vector)
  if type(scalar_or_vector) == "table" then
    return {
        vector[1] - scalar_or_vector[1],
        vector[2] - scalar_or_vector[2],
        vector[3] - scalar_or_vector[3]
      }
  else
    return {
        vector[1] - scalar_or_vector,
        vector[2] - scalar_or_vector,
        vector[3] - scalar_or_vector
      }
  end
end

function vec3.min(...)
  local args = {...}
  local out = {1/0,1/0,1/0}
  for k,v in next, args do 
    local t = v
    if type(v) ~= "table" then
      t = {v,v,v}
    end
    out[1] = math.min(t[1],out[1])
    out[2] = math.min(t[2],out[2])
    out[3] = math.min(t[3],out[3])
  end
  return out
end
function vec3.max(...)
  local args = {...}
  local out = {-1/0,-1/0,-1/0}
  for k,v in next, args do 
    local t = v
    if type(v) ~= "table" then
      t = {v,v,v}
    end
    out[1] = math.max(t[1],out[1])
    out[2] = math.max(t[2],out[2])
    out[3] = math.max(t[3],out[3])
  end
  return out
end
function vec3.angle(vector)
  local pitch = math.atan(vector[3], vector[1])
  if pitch < 0 then pitch = pitch + 2 * math.pi end
  local mag = vec2.mag({vector[1], vector[3]})
  local yaw = math.atan(vector[2], mag)
  if yaw < 0 then yaw = yaw + 2 * math.pi end
  return {yaw, pitch}
end
function vec3.rotate(vector, axis, angle)
  if angle == 0 then return {vector[1], vector[2], vector[3]} end

  local sinAngle = math.sin(angle)
  local cosAngle = math.cos(angle)
  if axis == "z" then
    return {
        vector[1] * cosAngle - vector[2] * sinAngle,
        vector[1] * sinAngle + vector[2] * cosAngle,
        vector[3]
    }
  elseif axis == "x" then
    return {
        vector[1],
        vector[2] * cosAngle - vector[3] * sinAngle,
        vector[2] * sinAngle + vector[3] * cosAngle
    }
  elseif axis == "y" then
      return {
        vector[1] * cosAngle - vector[3] * sinAngle,
        vector[2],
        vector[1] * sinAngle * -1 + vector[3] * cosAngle
    }
  else
      --invalid axis
      return {vector[1], vector[2], vector[3]}
  end
end

function vec3.withAngles(yaw, pitch, magnitude)
  local v1 = vec2.withAngle(yaw, magnitude)
  local v2 = vec2.withAngle(pitch, v1[1])
  return {v2[1], v1[2], v2[2]}
end

function vec3.lerp(ratio, a, b)
  return {
          a[1] + (b[1] - a[1]) * ratio,
          a[2] + (b[2] - a[2]) * ratio,
          a[3] + (b[3] - a[3]) * ratio
  }
end

function vec3.fromVec2(vector, num)
    num = num or 0
    return {vector[1], vector[2], num}
end
function vec3.worldDistance(a,b)
  return vec3.fromVec2(world.distance(a, b), a[3]-b[3])
end
function vec3.worldMagnitude(a,b)
  return vec3.mag(vec3.worldDistance(a,b))
end
function vec3.print(vector, precision)
  local fstring = "%."..precision.."f, %."..precision.."f, %."..precision.."f"
  return string.format(fstring, vector[1], vector[2], vector[3])
end

function vec3.copyToRef(vector, out)
  out[1] = vector[1]
  out[2] = vector[2]
  out[3] = vector[3]
  return out
end

function vec3.mulToRef(vector, scalar_or_vector, out)
  if type(scalar_or_vector) == "table" then
    out[1] = vector[1] * scalar_or_vector[1]
    out[2] = vector[2] * scalar_or_vector[2]
    out[3] = vector[3] * scalar_or_vector[3]
    return out
  else
    out[1] = vector[1] * scalar_or_vector
    out[2] = vector[2] * scalar_or_vector
    out[3] = vector[3] * scalar_or_vector
    return out
  end
end

function vec3.divToRef(vector, scalar, out)
  if scalar == 0 then return vector end
    out[1] = vector[1] / scalar
    out[2] = vector[2] / scalar
    out[3] = vector[3] / scalar
    return out
end

function vec3.addToRef(vector, scalar_or_vector, out)
  if type(scalar_or_vector) == "table" then
    out[1] = vector[1] + scalar_or_vector[1]
    out[2] = vector[2] + scalar_or_vector[2]
    out[3] = vector[3] + scalar_or_vector[3]
    return out
  else
    out[1] = vector[1] + scalar_or_vector
    out[2] = vector[2] + scalar_or_vector
    out[3] = vector[3] + scalar_or_vector
    return out
  end
end
