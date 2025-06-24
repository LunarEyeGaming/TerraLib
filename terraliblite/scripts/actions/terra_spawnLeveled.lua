spawnLeveled = {} 
function spawnLeveled.spawnProjectile(projectile, pos, id, dir, track, params)
    local scaledPower = params.power * root.evalFunction("monsterLevelPowerMultiplier", params.level)
    params.power = scaledPower
    return world.spawnProjectile(projectile, pos, id, dir, track, params)
end
