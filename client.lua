customnitro = {}
PlayerData = {}
ESX = exports['es_extended']:getSharedObject()
PlayerData = ESX.GetPlayerData()

function SetNitroBoostScreenEffectsEnabled(enabled)
	if enabled then
	  SetTimecycleModifier("RaceTurboFlash")
	  SetExtraTimecycleModifier("rply_motionblur")
	  SetExtraTimecycleModifierStrength(0.8)
	  SetTimecycleModifierStrength(0.8)
	else
	  StopGameplayCamShaking(true)
	  SetTransitionTimecycleModifier('default', 0.75)
	end
end

pressed = false
local show = false

AddStateBagChangeHandler('nitro' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
	Wait(0)
	if not value then return end
    local net = tonumber(bagName:gsub('entity:', ''), 10)
    local vehicle = NetworkGetEntityFromNetworkId(net)
	local ent = Entity(vehicle).state
	local plate = GetVehicleNumberPlateText(vehicle)
	customnitro[plate] = value
	if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
		NitroLoop(vehicle)
	end
end)

AddEventHandler('gameEventTriggered', function (name, args) -- only game build >= 2189
	if name == 'CEventNetworkPlayerEnteredVehicle' then
		if args[1] == PlayerId() then
			local plate = GetVehicleNumberPlateText(args[2])
			if customnitro[plate] and DoesEntityExist(args[2]) then
				refresh = true
				Wait(2500)
				NitroLoop(args[2])
			end
		end
	end
	--print(name)
end)

local innitrovehicle = false
NitroLoop = function(vehicle)
	if innitrovehicle then return end
	innitrovehicle = true
	local cacheState = {}
	if vehicle ~= 0 then
		local plate = GetVehicleNumberPlateText(vehicle)
		if customnitro[plate] then
			local nitro = Config.nitros[customnitro[plate].nitro]
			local default = {fMass = GetVehicleHandlingFloat(vehicle , "CHandlingData","fMass")}
			ToggleVehicleMod(vehicle,18,true)
			local sound = false
			local soundofnitro = nil
			local customized = false
			local boost = 0
			local oldgear = 1
			local cd = 0
			local rpm = GetVehicleCurrentRpm(vehicle)
			local gear = GetVehicleCurrentGear(vehicle)
			local maxvol = 0.4
			local ent = Entity(vehicle).state
			while customnitro[plate] ~= nil and customnitro[plate] ~= 'Default' and ent.nitro and ent.nitro.value and ent.nitro.value >= 1 do
				vehicle = GetVehiclePedIsIn(PlayerPedId())
				if not show and ent.nitro.value >= 1 then
					SendNUIMessage({
						type = "show",
						val = 'block'
					})
					show = true
					SendNUIMessage({
						type = "update",
						val = ent.nitro.value
					})
				end
				nitro = Config.nitros[customnitro[plate].nitro]
				customnitro[plate] = ent.nitro
				if IsControlPressed(0, 21) then
					local ent = Entity(vehicle).state
					local hasturbo = ent.turbo
					local nitro_val = ent.nitro.value
					local bottle = ent.nitro.bottle
					cacheState = {nitrovalue = nitro_val, turbo = hasturbo, bottle = bottle}
					if not pressed then
						ent = Entity(vehicle).state
						ent:set('nitroenable', true, true)
						if ent.fMass == nil then
							ent:set('fMass', default.fMass, true)
						end
						if ent.fMass and Config.nitro_bottles[cacheState.bottle] then
							SetVehicleHandlingFloat(vehicle , "CHandlingData","fMass", ent.fMass + Config.nitro_bottles[cacheState.bottle].weight)
						end
						pressed = true
						if not IsVehicleStopped(vehicle) then
							if boost == 0 then
								SetNitroBoostScreenEffectsEnabled(true)
							end
						end
						TriggerServerEvent("renzu_nitro:nitro_flame", VehToNet(vehicle ), GetEntityCoords(vehicle ))
						SetNitroBoostScreenEffectsEnabled(true)
					end
					Citizen.CreateThread(function()
						while IsControlPressed(0, 21) do
							Wait(200)
							SendNUIMessage({
								type = "update",
								val = cacheState.nitrovalue
							})
						end
						return
					end)
					while IsControlPressed(0, 21) and cacheState.nitrovalue >= 0 do
						if nitro.Torque > boost then
							boost = boost + 0.01
						end
						cd = cd + 10
						rpm = GetVehicleCurrentRpm(vehicle)
						gear = GetVehicleCurrentGear(vehicle)
						SetVehicleTurboPressure(vehicle , boost + nitro.Power * rpm)
						if GetVehicleTurboPressure(vehicle) >= nitro.Power and not cacheState.turbo then
							SetVehicleCheatPowerIncrease(vehicle,nitro.Power * GetVehicleTurboPressure(vehicle))
							--Citizen.InvokeNative(0xC8E9B6B71B8E660D, vehicle, true, 2.5, 100.1, 4.0, false)
							--Citizen.InvokeNative(0xC8E9B6B71B8E660D, vehicle, false, 0.0, 0.0, 0.0, false)
						end
						cacheState.nitrovalue = cacheState.nitrovalue - Config.nitro_bottles[cacheState.bottle].tick
						if not sound then
							sound = true
							soundofnitro = PlaySoundFromEntity(GetSoundId(), "Flare", vehicle , "DLC_HEISTS_BIOLAB_FINALE_SOUNDS", 0, 0)
						end
						if cacheState.nitrovalue <= 0 then
							break
						end
						Wait(0)
					end
					if pressed and IsControlJustReleased(0, 21) or cacheState.nitrovalue <= 0 then
						Citizen.InvokeNative(0xC8E9B6B71B8E660D, vehicle, false, 0.0, 0.0, 0.0, false)
						Wait(100)
						ent = Entity(vehicle).state
						customnitro[plate].value = cacheState.nitrovalue
						ent:set('nitro', customnitro[plate], true)
						ent:set('nitroenable', false, true)
						TriggerServerEvent("renzu_nitro:nitro_flame_stop", VehToNet(vehicle ), GetEntityCoords(vehicle ))
						pressed = false
						ClearExtraTimecycleModifier()
						ClearTimecycleModifier()
						RemoveParticleFxFromEntity(vehicle )
						local vehcoords = GetEntityCoords(vehicle )
						Citizen.Wait(1)
						--RemoveParticleFxInRange(vehcoords.x,vehcoords.y,vehcoords.z,100.0)
						light_trail_isfuck = false
						purgefuck[VehToNet(vehicle )] = false
						collectgarbage()
					end
				else
					if boost > 0 then
						SetNitroBoostScreenEffectsEnabled(false)
						ClearTimecycleModifier()
						ClearExtraTimecycleModifier()
					end
					boost = 0
					StopSound(soundofnitro)
					ReleaseSoundId(soundofnitro)
					sound = false
					vehicle = GetVehiclePedIsIn(PlayerPedId())
					if customnitro[plate].nitro == 'Default' then
						break
					end
					nitro = Config.nitros[customnitro[plate].nitro]
					if vehicle == 0 then
						innitrovehicle = false
						break
					end
					Wait(100)
				end
				pressed = false
				customized = true
			end
			StopSound(soundofnitro)
			ReleaseSoundId(soundofnitro)
			innitrovehicle = false
			if customized then
				SendNUIMessage({
					type = "show",
					val = 'none'
				})
				show = false
				Wait(1000)
			end
		end
	end
end

purgeshit = {}
purgefuck = {}
lightshit = {}
flametable = {}
RegisterNetEvent("renzu_nitro:nitro_flame_stop")
AddEventHandler("renzu_nitro:nitro_flame_stop", function(c_veh,coords)
		if purgefuck[c_veh] ~= nil then
			purgefuck[c_veh] = false
		end
		for k,v in pairs(purgeshit) do
			if k == c_veh then
				for k2,v2 in pairs(v) do
					StopParticleFxLooped(k2, 1)
					RemoveParticleFx(k2, true)
					k2 = nil
				end
				k = nil
			end
		end
		for k,v in pairs(lightshit) do
			if k == c_veh then
				for k2,v2 in pairs(v) do
					StopParticleFxLooped(k2, 1)
					RemoveParticleFx(k2, true)
					k2 = nil
				end
				k = nil
			end
		end
		RemoveParticleFxFromEntity(NetToVeh(c_veh))
end)

local ongoing_nitro = {}
RegisterNetEvent("renzu_nitro:nitro_flame")
AddEventHandler("renzu_nitro:nitro_flame", function(c_veh,coords)
	if #(coords - GetEntityCoords(PlayerPedId())) < 50 then
		ongoing_nitro[c_veh] = true
		if not HasNamedPtfxAssetLoaded(Config.nitroasset) then
			RequestNamedPtfxAsset(Config.nitroasset)
			while not HasNamedPtfxAssetLoaded(Config.nitroasset) do
				Wait(1)
			end
		end
		if GetEntitySpeed(NetToVeh(c_veh)) * 3.6 > 5 then
			local vehicle = NetToVeh(c_veh)
			for _,bones in pairs(Config.tailights_bone) do
				UseParticleFxAssetNextCall(Config.nitroasset)
				lightrailparticle = StartParticleFxLoopedOnEntityBone(Config.trail_particle_name, vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, GetEntityBoneIndexByName(vehicle, bones), Config.trail_size, false, false, false)
				SetParticleFxLoopedEvolution(lightrailparticle, "speed", 1.00, false)
				if lightshit[c_veh] == nil then
					lightshit[c_veh] = {}
				end
				table.insert(lightshit[c_veh], lightrailparticle)
			end
			local ent = Entity(vehicle)
			SetNitroBoostScreenEffectsEnabled(false)
			RequestNamedPtfxAsset('veh_xs_vehicle_mods')
			while not HasNamedPtfxAssetLoaded('veh_xs_vehicle_mods') do Wait(1) print("loading") end
			while GetVehicleThrottleOffset(vehicle) > 0.1 and ent.state.nitroenable or ent.state.nitroenable do
			-- 	ent = Entity(vehicle)
			SetVehicleBoostActive(vehicle , 1)
			Citizen.InvokeNative(0xC8E9B6B71B8E660D, vehicle, true, 2.0, 5.0, 0.1, true)
			SetVehicleRocketBoostPercentage(vehicle,100)
			SetVehicleRocketBoostRefillTime(vehicle,0.1)
			SetVehicleRocketBoostActive(vehicle,true)
			Wait(150)
			Citizen.InvokeNative(0xC8E9B6B71B8E660D, vehicle, false, 0.0, 0.0, 0.0, false)
			SetVehicleBoostActive(vehicle , 0)
			end
			Citizen.InvokeNative(0xC8E9B6B71B8E660D, vehicle, false, 0.0, 0.0, 0.0, false)
			RemoveParticleFxFromEntity(vehicle )
			ongoing_nitro[c_veh] = false
		else
			if not purgefuck[c_veh] then
				local vehicle = NetToVeh(c_veh)
				purgefuck[c_veh] = true
				local index = GetEntityBoneIndexByName(vehicle, Config.purge_left_bone)
				local bone_position = GetWorldPositionOfEntityBone(vehicle, index)
				local particle_location = GetOffsetFromEntityGivenWorldCoords(vehicle, bone_position.x, bone_position.y, bone_position.z)
				UseParticleFxAssetNextCall(Config.nitroasset)
				purge1 = StartParticleFxLoopedOnEntity(Config.purge_paticle_name,vehicle,particle_location.x + 0.03, particle_location.y + 0.1, particle_location.z+0.2, 20.0, 0.0, 0.5,Config.purge_size,false,false,false)
																																												---20.0, 0.0, 0.5,config.purge_size,false,false,false)
				SetVehicleBoostActive(vehicle, 1, 0)
				SetVehicleBoostActive(vehicle, 0, 0)
				if purgeshit[c_veh] == nil then
					purgeshit[c_veh] = {}
				end
				table.insert(purgeshit[c_veh], purge1)
				local index = GetEntityBoneIndexByName(vehicle, Config.purge_right_bone)
				local bone_position = GetWorldPositionOfEntityBone(vehicle, index)
				local particle_location = GetOffsetFromEntityGivenWorldCoords(vehicle, bone_position.x, bone_position.y, bone_position.z)
				UseParticleFxAssetNextCall(Config.nitroasset)
				purge2 = StartParticleFxLoopedOnEntity(Config.purge_paticle_name,vehicle,particle_location.x - 0.03, particle_location.y + 0.1, particle_location.z+0.2, 20.0, 0.0, 0.5,Config.purge_size,false,false,false)
				table.insert(purgeshit[c_veh], purge2)
				while purgefuck[c_veh] do
					Wait(55)
					SetVehicleBoostActive(vehicle, 1, 0)
					SetVehicleBoostActive(vehicle, 0, 0)
				end
			end
		end
	end
end)


function ShowFloatingHelpNotification(msg, coords, disablemarker, i)
    AddTextEntry('FloatingHelpNotificationsc'..i, msg)
    SetFloatingHelpTextWorldPosition(1, coords+vector3(0,0,0.3))
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp('FloatingHelpNotificationsc'..i)
    EndTextCommandDisplayHelp(2,0, 0, -1)
end

local markers = {}
local drawsleep = 1
function DrawInteraction(i,v,reqdist,msg,event,server,var,disablemarker)
    local i = i
    if not markers[i] and i ~= nil then
        Citizen.CreateThread(function()
            markers[i] = true
            --local reqdist = reqdist[2]
            local coord = v
            local dist = #(GetEntityCoords(PlayerPedId()) - coord)
			local ent = Entity(GetVehiclePedIsIn(PlayerPedId())).state
            while dist < reqdist[2] do
                drawsleep = 1
                dist = #(GetEntityCoords(PlayerPedId()) - coord)
                DrawMarker(36, coord.x,coord.y,coord.z-0.2, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 0.7, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
                --print(i)
                if dist < reqdist[1] then ShowFloatingHelpNotification(msg, coord, disablemarker , i) end
                if dist < reqdist[1] and IsControlJustReleased(1, 51) and ent.bottle and Config.nitro_bottles[ent.bottle] and Config.nitro_bottles[ent.bottle].tick then
                    ShowFloatingHelpNotification(msg, coord, disablemarker , i)
					local refill = nil
					local val = ent.nitro.value < 0 and 0 or ent.nitro.value
					local tick = 0
					while val < 10 do
						val = val + Config.nitro_bottles[ent.bottle].tick
						Wait(0)
						tick = tick + 0.1
						--print(tick)
					end
					Citizen.CreateThread(function()
                    	refill = exports.renzu_progressbar:CreateProgressBar(tick,'<i class="fas fa-tools"></i>')
					end)
					while refill == nil do Wait(0) DisableAllControlActions(0) end
					ent.nitro.value = ent.nitro.value
					ent:set('nitro', ent.nitro, true)
					EnableAllControlActions(1)
					SendNUIMessage({
						type = "update",
						val = ent.nitro.value
					})
                    Wait(1000)
                    break
                end
                Wait(drawsleep)
            end
            ClearAllHelpMessages()
            markers[i] = false
        end)
    end
end

CreateThread(function()
    while PlayerData.job == nil do Wait(100) end
    Wait(500)
    while true do
		local mycoord = GetEntityCoords(PlayerPedId())
		local inveh = IsPedInAnyVehicle(PlayerPedId())
		for k,v in pairs(Config.refillstation) do
			local vec = v.coord
			local req_dis = v.Dist
			local dist = #(vec - mycoord)
			if dist < 9 and v.job == 'all' or dist < 9 and v.job == PlayerData.job.name then
				if IsPedInAnyVehicle(PlayerPedId()) then
					msg = 'Press [E] Refill Nitro'
				else
					msg = 'Nitro Station '
				end
				DrawInteraction(k,vec,{3,9},msg,'opengarage',false,false,false,false)
			end
		end
		Wait(1000)
	end
end)