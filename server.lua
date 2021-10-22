

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
nitros = {}

RegisterCommand("changenitro", function(source, args, rawCommand)
  local source = source
  local xPlayer = ESX.GetPlayerFromId(source)
  local veh = GetVehiclePedIsIn(GetPlayerPed(source),false)
  print(veh,GetPlayerPed(source))
  if xPlayer.getGroup() ~= 'user' and Config.nitros[args[1]] and args[1] ~= nil and veh ~= 0 then
      plate = GetVehicleNumberPlateText(veh)
      if nitros[plate] == nil then
        nitros[plate] = {}
      end
      nitros[plate].nitro = args[1]
      nitros[plate].plate = plate
      nitros[plate].value = 100
      nitros[plate].bottle = 'nitro_bottle'
      SaveNitro(plate,args[1])
  end
end, false)

Citizen.CreateThread(function()
  local ret = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM renzu_nitro', {})
  for k,v in pairs(ret) do
    nitros[v.plate] = v
    nitros[v.plate].nitro = v.nitro
    nitros[v.plate].value = v.value
    nitros[v.plate].current = v.nitro
    nitros[v.plate].bottle = v.bottle
  end

  while true do
    for k,v in ipairs(GetAllVehicles()) do
      local plate = GetVehicleNumberPlateText(v)
      if nitros[plate] and plate == nitros[plate].plate then
        if nitros[plate].nitro and Config.nitros[nitros[plate].nitro] then
          local ent = Entity(v).state
          print(ent.nitro)
          ent.nitro = nitros[plate].nitro
          ent.nitropower = Config.nitros[ent.nitro].Power
          ent.bottle = nitros[plate].bottle
          ent.nitrovalue = ent.nitrovalue == nil and nitros[plate].value or ent.nitrovalue
          print(plate,ent.nitropower,ent.nitrovalue,ent.bottle)
        end
      end
    end
    Wait(5000)
  end
end)

function SaveNitro(plate,nitro)
    local result = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM renzu_nitro WHERE TRIM(plate) = @plate', {['@plate'] = plate})
    if result[1] == nil then
        SqlFunc(Config.Mysql,'execute','INSERT INTO renzu_nitro (plate, nitro) VALUES (@plate, @nitro)', {
            ['@plate']   = plate,
            ['@nitro']   = nitro,
        })
    elseif result[1] then
        SqlFunc(Config.Mysql,'execute','UPDATE renzu_nitro SET nitro = @nitro WHERE TRIM(plate) = @plate', {
            ['@plate'] = plate,
            ['@nitro'] = nitro,
        })
    end
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
        nitros[plate].current = nitros[plate].nitro or nitro
        nitros[plate].nitro = nitro
        nitros[plate].value = 100
        if ent.nitro then ent.nitrovalue = 100 end
        nitros[plate].bottle = ent.bottle or 'nitro_bottle'
        nitros[plate].plate = plate
        print("GAGO",nitro)
        SaveNitro(plate,v)
      end
    end)
  end
  for v, k in pairs(Config.nitro_bottles) do
    local nitroname = string.lower(v)
    print("register item", nitroname)
    ESX.RegisterUsableItem(nitroname, function(source)
      local xPlayer = ESX.GetPlayerFromId(source)
      local veh = GetVehiclePedIsIn(GetPlayerPed(source),false)
      local nitro = nitroname
      print("VOVO")
      if nitro ~= nil and veh ~= 0 then
        plate = GetVehicleNumberPlateText(veh)
        print(nitros[plate],'gago')
        if nitros[plate] ~= nil then
          nitros[plate].bottle = nitroname
          nitros[plate].value = 100
          local ent = Entity(veh).state
          if ent.nitro then ent.nitrovalue = 100 end
          xPlayer.removeInventoryItem(nitroname, 1)
          SaveNitro(plate,v)
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