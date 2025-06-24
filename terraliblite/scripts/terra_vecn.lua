-- for advanced things, supports vectors with variable dimensions, doesn't currently provide all functions
vecn = {}
function vecn.eq(vector1, vector2)
  for k,v in next, vector1 do
    if v ~= vector2[k] then
      return false
    end
  end
  return true
end

function vecn.mag(vector)
  local sq = 0
  for k,v in next, vector do
    sq = sq + v*v
  end
  return math.sqrt(sq)
end

function vecn.norm(vector)
  return vecn.div(vector, vecn.mag(vector))
end


function vecn.mul(vector, scalar_or_vector)
  if type(scalar_or_vector) == "table" then
    local out = {}
    for k,v in next, vector do
      table.insert(out, v * scalar_or_vector[k])
    end
    return out
  else
    local out = {}
    for k,v in next, vector do
      table.insert(out, v * scalar_or_vector)
    end
    return out
  end
end

function vecn.div(vector, scalar_or_vector)
  if type(scalar_or_vector) == "table" then
    local out = {}
    for k,v in next, vector do
      table.insert(out, v / scalar_or_vector[k])
    end
    return out
  else
    local out = {}
    for k,v in next, vector do
      table.insert(out, v / scalar_or_vector)
    end
    return out
  end
end

function vecn.add(vector, scalar_or_vector)
  if type(scalar_or_vector) == "table" then
    local out = {}
    for k,v in next, vector do
      table.insert(out, v + scalar_or_vector[k])
    end
    return out
  else
    local out = {}
    for k,v in next, vector do
      table.insert(out, v + scalar_or_vector)
    end
    return out
  end
end

function vecn.sub(vector, scalar_or_vector)
  if type(scalar_or_vector) == "table" then
    local out = {}
    for k,v in next, vector do
      table.insert(out, v - scalar_or_vector[k])
    end
    return out
  else
    local out = {}
    for k,v in next, vector do
      table.insert(out, v - scalar_or_vector)
    end
    return out
  end
end
-- runs any function that takes numbers as parameters, using the vectors as parameters
-- allows most other math functions to be executed with vectors
-- scalars will always be last in arguments due to how this is implemented, however
function vecn.run(func, ...)
  local out = {}
  local vals = {}
  local args = {...}
  -- include the components of vectors
  for k,v in next, args do
    if type(v) == "table" then
      for k,v2 in next, v do
        if not vals[k] then
          table.insert(vals,{})
        end
        table.insert(vals[k], v2)
      end
    end
  end
  -- include scalars (the vectors decide how many dimensions there are)
  for k,v in next, args do
    if type(v) ~= "table" then
      for k,v2 in next, vals do
        table.insert(v2, v)
      end
    end
  end
  -- execute the function on every dimension
  for k,v in next, vals do 
    table.insert(out, func(table.unpack(v)))
  end
  return out
end
function vecn.min(...)
  return vecn.run(math.min, ...)
end
function vecn.max(...)
  return vecn.run(math.max, ...)
end
function vecn.fromVecNWithVals(vector, ...)
    local out = {}
    local args = {...}
    for k,v in next, vector do
      table.insert(out, v)
    end
    for k,v in next, args do
      table.insert(out, v)
    end
    return out
end
function vecn.fromVecN(vector, l)
    local out = {}
    for k,v in next, vector do
      table.insert(out, v)
    end
    for i=#out,l do
      table.insert(out,0)
    end
    return out
end
function vecn.print(vector, precision)
  local fstring = ""
  for k,v in next, vector do
    fstring = fstring.."%."..precision.."f"
    if k ~= #vector then
      fstring = fstring..","
    end
  end
  return string.format(fstring, table.unpack(vector))
end
