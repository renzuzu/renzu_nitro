# renzu_nitro
- Advanced Vehicle Nitro System

# Feats
- Multiple Nitro Kits
- Multiple Nitro Bottle (volume)
- Fully Sync Particles (optimized)
- Fully Sync Nitro Datas ( State Bags ) One Sync Only!

# Install
- Installation:
- Drag renzu_nitro to your resource folder and start at server.cfg
- Import nitro.sql
- ensure enginesound
- Usage: 
- use item inside vehicle
- /giveitem 1 nitro100shot 1 (100 Shots) (available 50,100,200)
- /giveitem 1 nitro_bottle 1

# ITEMS
- nitro_bottle, nitrobottle2, nitrobottle3
- nitro100shot, nitro50shot, nitro200shot

# Refill Station Sample
```
Config.refillstation = {
	[1] = {coord = vector3(-216.4362487793,-1324.8597412109,30.606903076172), job = 'all'}, -- if all any players can use this refill station
	-- add as many as you want, this is like a fuel station logic
}
```

# How to refill nitro
- use nitro station
- use nitro_bottle

# dependency 
- ESX
- renzu_progressbar
- ONE SYNC
