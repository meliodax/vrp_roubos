-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- TUNNEL
-----------------------------------------------------------------------------------------------------------------------------------------
cO = {}
Tunnel.bindInterface("core_roubos",cO)
vCLIENT = Tunnel.getInterface("core_roubos")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIÁVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local ultimoAssaltoHora = {}
local checkRobbery = {}
local recompensa = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTROBBERY
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.startRobbery(rJs,sJs)
    local source = source 
    local user_id = vRP.getUserId(source) 
    if user_id then 
        local vector = json.decode(rJs)
        local setup = json.decode(sJs)
        for k,v in pairs(setup) do 
            if k == vector.type then 
                local amountCops = exports["vrp"]:getUsersByPermission("policia.permissao")
                if parseInt(#amountCops) <= parseInt(v.lspd) then
                    TriggerClientEvent("Notify",source,"aviso","Sistema indisponível no momento, tente mais tarde.",5000)
                    return false
                end

                if vRP.searchReturn(source,user_id) then 
                    return false 
                end

                local shopActived = vector.type..vector.id
                if cO.isEnabledToRob(k,shopActived, v.tempoEspera) then
                    if cO.hasNecessaryItemsToRob(user_id, v) then
                        vRP.searchTimer(user_id,parseInt(v.tempoEspera * 60 / 2))
                        ultimoAssaltoHora[shopActived] = os.time()
                        checkRobbery[source] = shopActived
                        recompensa[user_id] = v
                        vRPclient._playAnim(source,false,{"anim@heists@ornate_bank@grab_cash_heels","grab"},true)
                        vCLIENT.iniciandoRoubo(source,vector.x, vector.y, vector.z, v.tempo, vector.h)                                
                        cO.avisarPolicia("Roubo em Andamento", "Assalto a "..vector.type.." em andamento, verifique o ocorrido.", vector.x, vector.y, vector.z, vector.type)
                    end
                else
                    local tempoRestante = cO.getRemaningTime(k,shopActived, v.tempoEspera)
                    TriggerClientEvent("Notify", source, "sucesso", "Você ainda deve aguardar "..tempoRestante.." segundos para realizar a ação.")
                end
            end
        end
    end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CANCEL ROBBERY
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.cancelRobbery()
    local source = source
    local user_id = vRP.getUserId(source)

    if user_id then
        ultimoAssaltoHora[checkRobbery[source]] = nil
        checkRobbery[source] = nil
        recompensa[user_id] = nil
        local policia = exports["vrp"]:getUsersByPermission("policia.permissao")
        for l,w in pairs(policia) do
			local player = vRP.getUserSource(parseInt(w))
			local playerId = vRP.getUserId(player)
            if player then
				async(function()
				    TriggerClientEvent("NotifyPush",player,{ code = 20, title = "Ocorrência", text = "Roubo Cancelado" ..user_id, rgba = {140,35,35} })  
				end)
			end
		end
    end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETREMAININGTIME
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.getRemaningTime(_,roubo,cooldown)
    local timing = ((os.time() - ultimoAssaltoHora[roubo]) - cooldown * 60) * -1
    return timing
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECK
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.isEnabledToRob(_,roubo,cooldown)
    if ultimoAssaltoHora[roubo] then 
        if (os.time() - ultimoAssaltoHora[roubo]) < cooldown * 60 then 
            return false 
        end
    end
    return true 
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GIVEPAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.givePayment()
    local source = source 
    local user_id = vRP.getUserId(source)
    if user_id then
        for k,v in pairs(recompensa[user_id].items) do 
            vRP.giveInventoryItem(user_id,k,parseInt(math.random(i.min,i.max)))
        end
        recompensa[user_id] = nil
        checkRobbery[source] = nil
    end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECK ITEMS
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.hasNecessaryItemsToRob(user_id, c)
    local source = vRP.getUserSource(parseInt(user_id))
    if source then 
        if c.itemsNecessarios then
            for k,v in pairs(c.itemsNecessarios) do
                if vRP.getInventoryItemAmount(user_id,k) >= parseInt(v.qtd) then 
                    vRP.tryGetInventoryItem(user_id,k,v.qtd,true)
                    return true 
                else
                    TriggerClientEvent("Notify",source, "sucesso", "Você precisa de "..v.qtd.."x <b>"..exports["mlx-inventory"]:itemNameList(k).."</b> para iniciar")
                    return false
                end
            end
        end
    end
    return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CALL POLICE
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.avisarPolicia(titulo, msg, x, y, z, name)
	for l,w in pairs(policias) do
		local player = vRP.getUserSource(parseInt(w))
		if player then
			async(function()
				vRPclient.playSound(player,"Oneshot_Final","MP_MISSION_COUNTDOWN_SOUNDSET")
				TriggerClientEvent("NotifyPush",player,{ code = 20, title = "Ocorrência", text = msg,  x = x, y = y, z = z, name = "Roubo a "..name, rgba = {140,35,35} })
			end)
		end
    end
end