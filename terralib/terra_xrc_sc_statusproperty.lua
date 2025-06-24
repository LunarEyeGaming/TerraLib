--Made by Silver Sokolova#3576
local ini = init or function() end
local applyAdditionalEffect = applyAdditionalEffects or function() end

function init() ini()
  statusProperty = config.getParameter("statusProperty")
end

function applyAdditionalEffects() applyAdditionalEffect()
  if statusProperty then
    local statusPropertyValue = status.statusProperty(statusProperty,0)
    if statusPropertyValue ~= 0 then
      status.setStatusProperty(statusProperty,statusPropertyValue-1)
    end
  end
end
