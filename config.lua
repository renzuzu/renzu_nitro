Config = {}

Config.Mysql = 'mysql-async'
Config.weight_type = false
Config.weight = 1.5
Config.jobonly = false
Config.nitrojob = 'mechanic'

-- JOB ITEMS --
Config.nitros = {
	['50shot'] = {Power = 1.25, Torque = 1.3, value = 25000, item = 'nitro50shot', label = 'Nitro 50 lbs'}, -- 50 shot = 50hp (imaginary Horse power)
	['100shot'] = {Power = 1.5, Torque = 1.5, value = 55000, item = 'nitro100shot', label = 'Nitro 100 lbs'}, -- your lucky the 100 shot of nos didnt blow the weld in intake
	['200shot'] = {Power = 2.2, Torque = 2.3, value = 125000, item = 'nitro200shot', label = 'Nitro 200 lbs'}, -- dont fried the piston rings
}
Config.nitro_bottles = {
	['nitro_bottle'] = {tick = 0.05, weight = 30.0, label = 'Nitro Bottle 10LB'}, -- weight is not the weight of item, its the additional weight to vehicle
	['nitro_bottle2'] = {tick = 0.025, weight = 60.0, label = 'Nitro Bottle 20LB'}, -- tick is the remove value per tick, lowest are like higher LB/volume
	['nitro_bottle3'] = {tick = 0.0125, weight = 90.0, label = 'Nitro Bottle 30LB'}, -- tick is the remove value per tick, lowest are like higher LB/volume
}
-- JOB ITEMS --
Config.EnableRefilStation = true
Config.refills = 100 -- cost per tick
Config.refillstation = {
	[1] = {coord = vector3(-205.939, -1325.17, 30.216), job = 'all'}, -- if all any players can use this refill station
	-- add as many as you want, this is like a fuel station logic
}
Config.exhaust_bones = {
	"exhaust",
	"exhaust_2",
	"exhaust_3",
	"exhaust_4",
} 

Config.tailights_bone = {
	"taillight_l",
	"taillight_r",
	--"taillight_m",
}
Config.nitroasset = "core"

Config.exhaust_particle_name = "veh_backfire" -- particle name | default: "veh_backfire"
Config.trail_particle_name = "veh_light_red_trail"
Config.exhaust_flame_size = 1.3
Config.trail_size = 1.00
Config.bannedindex = -1
Config.purge_left_bone = "wheel_lf"
Config.purge_right_bone = "wheel_rf"
Config.purge_size = 1.0
Config.purge_paticle_name = "ent_sht_steam" -- particle name | default: "ent_sht_steam"

exports('nitros', function()
	return Config.nitros
end)