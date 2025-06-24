spawnLeveled.lua:
- A single util function. Require it in any entity with 'require "/scripts/actions/spawnLeveled.lua"'
- Helps with spawning projectiles, allowing them to be leveled, automatically modifying their power.
- Like world.spawnProjectile, but requires "power" and "level" params.
rotateUtil.lua
- Helps with rotation. Has 2 functions:
    - rotateUtil.getRelativeAngle: Takes 2 absolute angles and outputs a signed difference between them.
    - rotateUtil.slowRotate: Takes the amount needed to be rotated, the current rotation, and the rotation speed, and returns the angle after rotating. Can be directly fed the output of rotateUtil.getRelativeAngle
- Like with spawnLeveled, require it in any entity with 'require "/scripts/actions/rotateUtil.lua"'
