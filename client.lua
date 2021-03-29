-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
cO = {}
Tunnel.bindInterface("core_roubos",cO)
vSERVER = Tunnel.getInterface("core_roubos")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local andamento = false
local segundos = 0
-----------------------------------------------------------------------------------------------------------------------------------------
-- START THREAD
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		local oInfinity = 1000
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		for k,v in pairs(Config.roubos) do
			local distance = #(coords - vector3(v.x,v.y,v.z))
			if distance <= 5 and not andamento then
				oInfinity = 4
				if distance <= 1.2 then
					drawTxt("PRESSIONE  ~b~G~w~  PARA INICIAR O ROUBO",4,0.5,0.93,0.50,255,255,255,180)
					if IsControlJustPressed(0,47) and not IsPedInAnyVehicle(ped) then
						if GetEntityModel(ped) == GetHashKey("mp_m_freemode_01") or GetEntityModel(ped) == GetHashKey("mp_f_freemode_01") then
							vSERVER.startRobbery(json.encode(v), json.encode(Config.setup))
						end
					end
				end
			end
		end
		Citizen.Wait(oInfinity)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREAD ANDAMENTO
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		local oInfinity = 500
		local ped = PlayerPedId()
		if andamento and not IsPedInAnyVehicle(ped) then
			oInfinity = 4
			drawTxt("APERTE ~r~M~w~ PARA CANCELAR O ROUBO EM ANDAMENTO",4,0.5,0.91,0.36,255,255,255,30)
			drawTxt("RESTAM ~g~"..segundos.." SEGUNDOS ~w~PARA TERMINAR",4,0.5,0.93,0.50,255,255,255,180)
			if IsControlJustPressed(0,244) or GetEntityHealth(ped) <= 100 then
				andamento = false
				ClearPedTasks(ped)
				vSERVER.cancelRobbery()
				TriggerEvent('cancelando',false)
			end
		end
		Citizen.Wait(oInfinity)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INICIANDO ROUBO
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.iniciandoRoubo(x,y,z,secs,head)
	segundos = secs
	andamento = true
	SetEntityHeading(PlayerPedId(),head)
	SetEntityCoords(PlayerPedId(),x,y,z-1,false,false,false,false)
	SetPedComponentVariation(PlayerPedId(),5,45,0,2)
	SetCurrentPedWeapon(PlayerPedId(),GetHashKey("WEAPON_UNARMED"),true)
	TriggerEvent('cancelando',true)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREAD
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		if andamento and not IsPedInAnyVehicle(PlayerPedId()) then
			segundos = segundos - 1
			if segundos <= 0 then
				andamento = false
				vSERVER.givePayment()
				ClearPedTasks(PlayerPedId())
				TriggerEvent('cancelando',false)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function drawTxt(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end