require "/scripts/extern/terra_json.lua"

terraschematics = {}
local function tfind(org, findValue)
    for key,value in pairs(org) do
        if value == findValue then
            return key
        end
    end
    return nil
end
local function split(t, inpvalues) -- places all unique values of a structure into 1 array, and replaces the original values in the structure with indexes to this array
  values = inpvalues or {}
  local data = {}
  for k,v in next, t do
    if type(v) == "table" then
      data[k] = split(v, values)
    else
      local ind = tfind(values, v)
      if ind then
        data[k] = ind
      else
        table.insert(values, v)
        data[k] = #values
      end
    end
  end
  if not inpvalues then
    local o = {data=data, values=values, s=true}
    if #json.stringify(t) < #json.stringify(o) then -- does compressing help at all?
      return t
    else
      return o
    end
  end
  return data
end
local function condense(t, a) -- condenses adjacent values in arrays together
  local o = {}
  local last = "cnull"
  local lastN = 0
  for k,v in next, t do
    if type(k) == "number" then
      if type(v) == "table" then
        if last ~= "cnull" then
          table.insert(o, {v=last,c=lastN})
        end
        table.insert(o, condense(v, true))
        last = "cnull"
      elseif v == last then
        lastN = lastN + 1
      else
        if last ~= "cnull" then
          table.insert(o, {v=last,c=lastN})
        end
        last = v
        lastN = 1
      end
    else
      if type(v) == "table" then
        o[k] = condense(v, true)
      else
        o[k] = v
      end
    end
  end
  if last ~= "cnull" then
    table.insert(o, {v=last,c=lastN})
  end
  if not a then
    o.c = true
    if #json.stringify(t) < #json.stringify(o) then -- does compressing help at all?
      return t
    else
      return o
    end
  end
  return o
end
local function uncondense(t, a)
  if not a and not t.c then
    return t
  end
  local o = {}
  for k,v in next, t do
    if type(k) == "number" then
      if type(v) == "number" then
        sb.logError("Condensed data contains number in array?")
        sb.logError(sb.printJson(t, 1))
      end
      if v.v or v.c then
        for i=v.c,1,-1 do
          table.insert(o, v.v)
        end
      else
        table.insert(o, uncondense(v, true))
      end
    else
      if type(v) == "table" then
        o[k] = uncondense(v, true)
      else
        o[k] = v
      end
    end
  end
  return o
end
local function combine(t, inpvalues)
  local d = t.data
  local values = inpvalues or t.values
  if inpvalues then
    d = t
  elseif not t.s then
    return t
  end
  local o = {}
  for k,v in next, d do
    if type(v) == "table" then
      o[k] = combine(v, values)
    else
      o[k] = values[v]
    end
  end
  return o
end
function terraschematics.compressSchematic(schem)
  local output = split(schem)
  if output.s then
    output.data = condense(output.data)
  else
    output = condense(output)
  end
  return output
end
function terraschematics.decompressSchematic(schem)
  local output = schem
  if output.s then
    output.data = uncondense(output.data)
  else
    output = uncondense(output)
  end
  return combine(output)
end
