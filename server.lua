

ESX = exports['es_extended']:getSharedObject()
nitros = {}

RegisterCommand("changenitro", function(source, args, rawCommand)
  local source = source
  local xPlayer = ESX.GetPlayerFromId(source)
  local veh = GetVehiclePedIsIn(GetPlayerPed(source),false)
  if xPlayer.getGroup() ~= 'user' and Config.nitros[args[1]] and args[1] ~= nil and veh ~= 0 then
      plate = GetVehicleNumberPlateText(veh)
      if nitros[plate] == nil then
        nitros[plate] = {}
      end
      nitros[plate].nitro = args[1]
      nitros[plate].plate = plate
      nitros[plate].bottle = args[2] and Config.nitro_bottles[args[2]] or 'nitro_bottle3'
      nitros[plate].value = 100
      local ent = Entity(veh).state
      ent:set('nitro', nitros[plate], true)
      SaveNitro(nitros[plate])
  end
end, false)

GetNitroType = function(type)
  for k,v in pairs(Config.nitros) do
    if v.item == type then
      return k
    end
  end
  return false
end

AddNitro = function(net,type)
  local vehicle = NetworkGetEntityFromNetworkId(net)
  local nitro = GetNitroType(type)
  if not DoesEntityExist(vehicle) or not nitro then return end
  local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
  if nitros[plate] == nil then
    nitros[plate] = {}
  end
  nitros[plate].nitro = nitro
  nitros[plate].plate = plate
  nitros[plate].bottle = 'nitro_bottle3'
  nitros[plate].value = 100
  local ent = Entity(vehicle).state
  ent:set('nitro', nitros[plate], true)
  SaveNitro(nitros[plate])
end

exports('AddNitro', AddNitro)
RegisterNetEvent('renzu_nitro:AddNitro', AddNitro)

Citizen.CreateThread(function()
  local ret = json.decode(GetResourceKvpString('renzu_nitro') or '[]') or {}
  for k,v in pairs(ret) do
    nitros[v.plate] = v
    nitros[v.plate].nitro = v.nitro
    nitros[v.plate].value = v.value
    nitros[v.plate].bottle = v.bottle
  end

  for k,v in ipairs(GetAllVehicles()) do
    local plate = GetVehicleNumberPlateText(v)
    if nitros[plate] and plate == nitros[plate].plate then
      if nitros[plate].nitro and Config.nitros[nitros[plate].nitro] then
        local ent = Entity(v).state
        ent:set('nitro', nitros[plate], true)
      end
    end
  end
end)

function SaveNitro(nitro)
    local data = json.decode(GetResourceKvpString('renzu_nitro') or '[]') or {}
    data[nitro.plate] = nitro
    SetResourceKvp('renzu_nitro',json.encode(data))
end

function SqlFunc(plugin,type,query,var)
	local wait = promise.new()
    if type == 'fetchAll' and plugin == 'mysql-async' then
		    MySQL.Async.fetchAll(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'execute' and plugin == 'mysql-async' then
        MySQL.Async.execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'execute' and plugin == 'ghmattisql' then
        exports['ghmattimysql']:execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'fetchAll' and plugin == 'ghmattisql' then
        exports.ghmattimysql:execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'execute' and plugin == 'oxmysql' then
        exports.oxmysql:execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'fetchAll' and plugin == 'oxmysql' then
		exports['oxmysql']:fetch(query, var, function(result)
			wait:resolve(result)
		end)
    end
	return Citizen.Await(wait)
end

function firstToUpper(str)
  return (str:gsub("^%l", string.upper))
end

Citizen.CreateThread(function()
  c = 0
  for v, k in pairs(Config.nitros) do
    c = c + 1
    local nitroname = string.lower(v)
    local label = string.upper(v)
    foundRow = SqlFunc(Config.Mysql,'fetchAll',"SELECT * FROM items WHERE name = @name", {
      ['@name'] = "nitro"..nitroname..""
    })
    if foundRow[1] == nil then
      local weight = 'limit'
      if Config.weight_type then
        SqlFunc(Config.Mysql,'execute',"INSERT INTO items (name, label, weight) VALUES (@name, @label, @weight)", {
          ['@name'] = "nitro"..nitroname.."",
          ['@label'] = ""..firstToUpper(nitroname).." Nitro",
          ['@weight'] = Config.weight
        })
        print("Inserting "..nitroname.."")
      else
        SqlFunc(Config.Mysql,'execute',"INSERT INTO items (name, label) VALUES (@name, @label)", {
          ['@name'] = "nitro"..nitroname.."",
          ['@label'] = ""..firstToUpper(nitroname).." Nitro",
        })
        print("Inserting "..nitroname.."")
      end
    end
  end
  while ESX == nil do Wait(10) end
  for v, k in pairs(Config.nitros) do
    local nitroname = string.lower(v)
    print("register item", v)
    ESX.RegisterUsableItem("nitro"..nitroname.."", function(source)
      local xPlayer = ESX.GetPlayerFromId(source)
      if Config.jobonly and xPlayer.job.name ~= tostring(Config.nitrojob) then print("not mech") return end
      xPlayer.removeInventoryItem("nitro"..nitroname.."", 1)
      local veh = GetVehiclePedIsIn(GetPlayerPed(source),false)
      local nitro = nitroname
      if nitro ~= nil and veh ~= 0 then
        plate = GetVehicleNumberPlateText(veh)
        if nitros[plate] == nil then
          nitros[plate] = {}
        end
        local ent = Entity(veh).state
        nitros[plate].nitro = nitro
        nitros[plate].value = 100
        nitros[plate].bottle = ent.nitro and ent.nitro.bottle or 'nitro_bottle'
        nitros[plate].plate = plate
        ent:set('nitro', nitros[plate], true)
        SaveNitro(nitros[plate])
      end
    end)
  end
  for v, k in pairs(Config.nitro_bottles) do
    local bottle = string.lower(v)
    ESX.RegisterUsableItem(bottle, function(source)
      local xPlayer = ESX.GetPlayerFromId(source)
      local veh = GetVehiclePedIsIn(GetPlayerPed(source),false)
      if bottle ~= nil and veh ~= 0 then
        plate = GetVehicleNumberPlateText(veh)
        if nitros[plate] ~= nil then
          nitros[plate].plate = plate
          nitros[plate].bottle = bottle
          nitros[plate].value = 100
          local ent = Entity(veh).state
          ent:set('nitro', nitros[plate], true)
          xPlayer.removeInventoryItem(bottle, 1)
          SaveNitro(nitros[plate])
        end
      end
    end)
  end
  print(" NITRO LOADED ")
end)

RegisterServerEvent("renzu_nitro:nitro_flame")
AddEventHandler("renzu_nitro:nitro_flame", function(entity,coords)
	TriggerClientEvent("renzu_nitro:nitro_flame", -1, entity,coords)
end)

RegisterServerEvent("renzu_nitro:nitro_flame_stop")
AddEventHandler("renzu_nitro:nitro_flame_stop", function(entity,coords)
	TriggerClientEvent("renzu_nitro:nitro_flame_stop", -1, entity,coords)
end)

AddEventHandler('entityCreated', function(entity)
  local entity = entity
  Wait(1000)
  if DoesEntityExist(entity) and GetEntityPopulationType(entity) == 7 and GetEntityType(entity) == 2 then
    local plate = GetVehicleNumberPlateText(entity)
    if nitros[plate] and nitros[plate].nitro then
      local ent = Entity(entity).state
      ent.nitro = nitros[plate]
    end
  end
end)

AddEventHandler('entityRemoved', function(entity)
  local entity = entity
  if GetEntityPopulationType(entity) == 7 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
    local ent = Entity(entity).state
    if ent.nitro then
      local plate = GetVehicleNumberPlateText(entity)
      nitros[plate].value = ent.nitro.value
      nitros[plate].nitro = ent.nitro.nitro
      nitros[plate].bottle = ent.nitro.bottle
      SaveNitro(nitros[plate])
    end
  end
end)
