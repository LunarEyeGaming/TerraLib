-- technically this is just terra_null_primary...
function init()
  message.setHandler("applyStatusEffect", function(_, _, effectConfig, duration, sourceEntityId)
    end)
end

function applyDamageRequest(damageRequest)
    return {}
end

function notifyResourceConsumed(resourceName, amount)
end

function update(dt)
end
