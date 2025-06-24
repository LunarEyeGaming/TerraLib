In case you're wondering, heads are the front segment of a worm, tails are the end segment, and body is everything else in the middle
Here's how to use:
1. Create monsters for each different segment sprite.
All worms must have the "body" transformation group, with interpolation recommended to be true.
2. Change the monster script for each segment to the correct script, listed below. Don't use monster.lua with these, these are just modified clones of it.
Body segments:
/scripts/terra_wormbody.lua (Use several different monstertypes if you want every body segment to be different)
/scripts/terra_wormbodysimple.lua (Simplified version that's a bit faster, most worms should use this instead, but doesn't support behaviours)
Tail segments:
/scripts/terra_wormtail.lua
Head segments:
/scripts/terra_wormheaddigger.lua (Works like most Terraria worms)
/scripts/terra_wormheadflier.lua (Like digger but no gravity)
/scripts/terra_wormheadcustom.lua (Allows for full control by behaviours or your own script)

3. Add these in baseParameters:

For heads:
"size": <body segment count>
"bodySegment": <next segment, should be a body segment (should contain a monstertype)>
"speed": <worm acceleration, defaults to 1 (doesn't work for custom AI worms)>
"maxSpeed": <worm max speed, worms cannot get faster than this, defaults to 20 (doesn't work for custom AI worms)>
"capturedLevel": <level for worm body when worm is a pet>
"treatLiquidAsGround": <if true, treats liquids as ground, aka "swimming"> (optional)
"treatOffscreenAsGround": <if true, treats offscreen area as ground> (optional)

For bodies and tails:
"segmentSize": <size of segment> (Experiment around with it until segments are properly aligned, Destroyer segments use 2.5)

For bodies only:
"bodySegment": <either this or whatever segment goes next (should contain a monstertype)>
"tailSegment": <the segment at the end (should contain a monstertype)>
"firstSize": <if this is the segment right behind the head, add this to distance> (optional)

I also recommend adding 
"renderLayer" : "Monster+1"
to heads, as this will make them render over the body, which makes it not look as weird.

For all types:
"facingMode": "transformation" (Keeps worm parts rotating properly)
"flip": <true or false>
If flip is true, the worm will flip at certain rotations. Designed to keep the sprite from going upside-down.
Requires a "flip" transformation group. Interpolation is recommended to be false. Make sure the body part has "flip" set before "body" as its transformation groups.

4. Set up the worm status script. This is not needed for the head, but it's required on body and tail segments for the worm to properly take damage. 
Status scripts are located in /baseParameters/statusSettings/primaryScriptSources. Change the script to "/stats/worm_primary.lua"

5. To spawn a worm, spawn its head. The head segment is the "leader" of the worm, and should be the first to be spawned. 
If you want to define the worm to be capturable, define the head as capturable.
To capture a worm, throwing a capture pod at any segment is enough, as the body segments redirect the attempt to the head.

If you have any questions, just ask me on Discord (discord.com/invite/AGCj6pmq4M)

Note: Worms are easily defeated by weapons that can hit multiple enemies. Explosive weapons will hit multiple segments at once and deal more damage.
Weapons like the Aegisalt Pistol will hit several segments at once, continuously, dealing a lot of damage.

As for the rest of the scripts...
/scripts/terra_chain.lua:
A script for a chain. It comes from vanilla, but this version is in a place that makes more sense. A copy of it is used in things like Plantera's Hooks and The Twins' tendril.
It's also modified for features such as cropping beam segments near the end, used by the Moon Lord's deathray.
To use it, you must specify it as an animation script. Put this in the monster's baseParameters to use it:
    "animationScripts" : [
      "/scripts/terra_chain.lua"
    ],
Then, you must specify what this chain is. Here's what it looks like on Plantera's Tentacles, so you can figure it out:
"chains" : [
      {
        "segmentImage" : "/monsters/boss/planteratentacle/chain.png",
        "segmentSize" : 1,
        "renderLayer" : "ForegroundEntity-2",
        "fullbright" : false,
        "sourcePart" : "beam",
        "endPart" : "beam",
        "jitter" : 0.0,
        "waveform" : {
          "movement" : 0.0,
          "amplitude" : 0.0,
          "frequency" : 1.0
        }
      }
    ],
It requires a "beam" part, and a "beam" transformation group with interpolation. Check Plantera's Tentacles on how this can be defined. 
(You can access Terraria Mod assets by downloading it and then finding its pak and unpacking it, which you should probably know how to do if you downloaded TerraLib from the Workshop)
/scripts/terra_plant.lua:
A script for a "plant", like the Man Eater.
/scripts/terra_spore.lua:
The script used by Plantera's Spores. Can be used for anything similar.
