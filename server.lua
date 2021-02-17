local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

sRP = {}
Tunnel.bindInterface("vrp_roubos",sRP)

vCLIENT = Tunnel.getInterface("vrp_roubos")

local ultimoAssaltoHora = {}
local recompensa = {}
local assalto = {}
local tempoAssalto = {}

local policias = nil

function sRP.startRobbery(rouboJson, setupJson)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        local v = json.decode(rouboJson)
        local setup = json.decode(setupJson)    
        for k,c in pairs(setup) do
            Wait(1)
            if k == v.type then
                policias = vRP.getUsersByPermission("policia.permissao")
                if not vRP.searchReturn(source,user_id) then
                    if #policias < c.lspd then
                        TriggerClientEvent("Notify",source,"negado", "Necessários "..c.lspd.." <b>Políciais</b> para iniciar o roubo.")
                    else
                        if sRP.isEnabledToRob(k,v["id"], c.tempoEspera) then
                            if sRP.hasNecessaryItemsToRob(user_id, c) then

                            -- TODO: Implementar sistemas da checklist...
                            local time = c.tempoEspera * 60 / 2
                            vRP.searchTimer(user_id,parseInt(time))
                            ultimoAssaltoHora[v["id"]] = os.time()
                            recompensa[user_id] = c
                            tempoAssalto[user_id] = c.tempo
                            assalto[k] = true


                            SetTimeout(c.tempo * 1000,function()
                                assalto[k] = false
                            end)
                
                            vRPclient._playAnim(source,false,{"anim@heists@ornate_bank@grab_cash_heels","grab"},true)

                            vCLIENT.iniciandoRoubo(source,v.x, v.y, v.z, c.tempo, v.h)
                                
                            sRP.avisarPolicia("Roubo em Andamento", "Assalto a "..v.type.." em andamento, verifique o ocorrido.", v.x, v.y, v.z, v.type)
                            else
                                TriggerClientEvent("Notify", source, "sucesso", "Você não conseguiu abrir o cofre, é melhor correr!")
                            end
                        else
                            local tempoRestante = sRP.getRemaningTime(k,v["id"], c.tempoEspera)
                            TriggerClientEvent("Notify", source, "sucesso", "Você ainda deve aguardar "..tempoRestante.." segundos para realizar a ação.")
                        end
                    end
                end
            end
        end
    end
end

function sRP.cancelRobbery()
    local source = source
    local user_id = vRP.getUserId(source)

    if user_id then
        for n,i in pairs(recompensa[user_id].items) do
            local pagamento = math.random(i.min,i.max)
            vRP.giveInventoryItem(user_id,n,parseInt(pagamento)/10,true)
        end

        tempoAssalto[user_id] = nil
        recompensa[user_id] = nil
        local policia = vRP.getUsersByPermission("policia.permissao")
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

function sRP.getRemaningTime(k, user_id,tempoEspera)
    local t = ((os.time() - ultimoAssaltoHora[user_id]) - tempoEspera * 60) * -1
    return t
end

function sRP.isEnabledToRob(k, user_id, tempoEspera)
    if ultimoAssaltoHora[user_id] then
        if (os.time() - ultimoAssaltoHora[user_id]) < tempoEspera * 60 then
            return false
        else
            return true
        end
    end
    return true
end

function sRP.givePayment()
    local source = source 
    local user_id = vRP.getUserId(source)
    if user_id then
        for n,i in pairs(recompensa[user_id].items) do
            local pagamento = math.random(i.min,i.max)
            vRP.giveInventoryItem(user_id,n,parseInt(pagamento),true)
        end
        recompensa[user_id] = nil
        tempoAssalto[user_id] = nil
    end
end

function sRP.hasNecessaryItemsToRob(user_id, c)
    local source = vRP.getUserSource(user_id)
    local pica = json.encode(c.itemsNecessarios)
    local picapica2 = json.decode(pica)
    if c.itemsNecessarios then
        local itensNecessarios = #c.itemsNecessarios
        local count = 0
        for k,v in pairs(c.itemsNecessarios) do
            if vRP.getInventoryItemAmount(user_id,k) >= parseInt(v.qtd) then 
                vRP.tryGetInventoryItem(user_id,k,v.qtd,true)
                return true 
            else
                TriggerClientEvent("Notify",source, "sucesso", "Você precisa de "..v.qtd.."x <b>"..vRP.itemNameList(k).."</b> para iniciar")
                return false
            end
        end
    end
    return true
end

function sRP.avisarPolicia(titulo, msg, x, y, z, name)
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