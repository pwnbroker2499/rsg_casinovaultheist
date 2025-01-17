local RSGCore = exports['rsg-core']:GetCoreObjects()
local initialCooldownSeconds = 3600 -- cooldown time in seconds
local cooldownSecondsRemaining = 0 -- done to zero cooldown on restart
local lockpicked = false
local dynamiteused = false
local vault1 = false
local vault2 = false
local vault3 = false

-- lock vault doors
Citizen.CreateThread(function()
    for k,v in pairs(Config.VaultDoors) do
        Citizen.InvokeNative(0xD99229FE93B46286,v,1,1,0,0,0,0)
        Citizen.InvokeNative(0x6BAB9442830C7F53,v,1)
    end
end)

------------------------------------------------------------------------------------------------------------------------

-- lockpick door
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local pos, awayFromObject = GetEntityCoords(PlayerPedId()), true
		local object = Citizen.InvokeNative(0xF7424890E4A094C0, 2058564250, 0)
		if object ~= 0 and cooldownSecondsRemaining == 0 and lockpicked == false then
			local objectPos = GetEntityCoords(object)
			if #(pos - objectPos) < 3.0 then
				awayFromObject = false
				DrawText3Ds(objectPos.x, objectPos.y, objectPos.z + 1.0, "~g~J~w~ - Lockpick")
				if IsControlJustReleased(0, 0xF3830D8E) then -- [J]
					exports['rsg-core']:TriggerCallback('RSGCore.Functions.HasItem', function(hasItem)
						if hasItem then
							TriggerServerEvent('RSGCore:Server:RemoveItem', 'lockpick', 1)
							TriggerEvent("inventory:client:ItemBox", RSGCore.Shared.Items['lockpick'], 'remove')
							TriggerEvent('RSGCore.Shared.Items:client:openLockpick', lockpickFinish)
						else
							RSGCore.Functions.NotifyV2(9, 'You need a lockpick', 5000, 'top-right', 'error', 'circle-xmark', '#e60000')
						end
					end, { ['lockpick'] = 1 })
				end
			end
		end
		if awayFromObject then
			Citizen.Wait(1000)
		end
	end
end)

function lockpickFinish(success)
    if success then
		RSGCore.Functions.NotifyV2(9, 'Lockpick Successful', 5000, 'top-right', 'success', 'check', '#16b82f')
		Citizen.InvokeNative(0x6BAB9442830C7F53, 2058564250, 0)
		lockpicked = true
    else
        RSGCore.Functions.NotifyV2(9, 'Lockpick Unsuccessful', 5000, 'top-right', 'error', 'circle-xmark', '#e60000')
    end
end

------------------------------------------------------------------------------------------------------------------------

-- vault prompt
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local pos, awayFromObject = GetEntityCoords(PlayerPedId()), true
		local object = Citizen.InvokeNative(0xF7424890E4A094C0, 2181772801, 0)
		if object ~= 0 and cooldownSecondsRemaining == 0 and dynamiteused == false then
			local objectPos = GetEntityCoords(object)
			if #(pos - objectPos) < 3.0 then
				awayFromObject = false
				DrawText3Ds(objectPos.x, objectPos.y, objectPos.z + 1.0, "~g~J~w~ - Place Dynamite")
				if IsControlJustReleased(0, 0xF3830D8E) then -- [J]
					TriggerEvent('rsg_casinovaultheist:client:boom')
					dynamiteused = true
				end
			end
		end
		if awayFromObject then
			Citizen.Wait(1000)
		end
	end
end)

-- blow vault doors
RegisterNetEvent('rsg_casinovaultheist:client:boom')
AddEventHandler('rsg_casinovaultheist:client:boom', function()
	if cooldownSecondsRemaining == 0 then
		RSGCore.Functions.TriggerCallback('RSGCore.Functions.HasItem', function(hasItem)
			if hasItem then
				TriggerServerEvent('RSGCore:Server:RemoveItem', 'dynamite', 1)
				TriggerEvent('inventory:client:ItemBox', RSGCore.Shared.Items['dynamite'], 'remove')
				local playerPed = PlayerPedId()
				TaskStartScenarioInPlace(playerPed, GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), 5000, true, false, false, false)
				Citizen.Wait(5000)
				ClearPedTasksImmediately(PlayerPedId())
				local x,y,z = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.5, 0.0))
				local prop = CreateObject(GetHashKey("p_dynamite01x"), x, y, z, true, false, true)
				SetEntityHeading(prop, GetEntityHeading(PlayerPedId()))
				PlaceObjectOnGroundProperly(prop)
				FreezeEntityPosition(prop,true)
				RSGCore.Functions.NotifyV2(8, 'Bank Robbery', 10000, 'Explosives set, stand well back', 5000, 'top-right', 'inform', 'triangle-exclamation', '#FFD43B')
				Wait(10000)
				AddExplosion(2868.33, -1401.59, 52.37, 231.39 , 5000.0 ,true , false , 27)
				DeleteObject(prop)
				Citizen.InvokeNative(0x6BAB9442830C7F53, 2181772801, 0)
				TriggerEvent('rsg_casinovaultheist:client:policenpc')
				local alertmsg = 'Casino robbery in progress'
				TriggerEvent('rsg-lawman:server:lawmanAlert', alertmsg)
				handleCooldown()
			else
				RSGCore.Functions.NotifyV2(9, 'You need Dynamite', 5000, 'top-right', 'error', 'circle-xmark', '#e60000')
			end
		end, { ['dynamite'] = 1 })
	else
		RSGCore.Functions.NotifyV2(9, 'You can\'t do that right now', 5000, 'top-right', 'error', 'circle-xmark', '#e60000')
	end
end)

------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	RSGCore.Functions.createPrompt('vault1', vector3(2868.33, -1401.59, 52.37), 0xF3830D8E, 'Loot Vault', {
		type = 'client',
		event = 'rsg_casinovaultheist:client:checkvault',
		args = {},
	})
end)

-- loot vault1
RegisterNetEvent('rsg_casinovaultheist:client:checkvault', function()
	local player = PlayerPedId()
	SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
	if vault1 == false then
		RSGCore.Function.Progressbar("search_vault", "Stealing Gold", 10000, false, true, {
			disableMovement = false,
			disableCarMovement = false,
			disableMouse = false,
			disableCombat = true,
		}, {
			animDict = "script_ca@cachr@ig@ig4_vaultloot",
			anim = "ig13_14_grab_money_front01_player_zero",
			flags = 1,
		}, {}, {}, function() -- Done
			ClearPedTasks(player)
			SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
			TriggerServerEvent('rsg_casinovaultheist:server:reward')
			vault1 = true
		end)
	else
		RSGCore.Functions.NotifyV2(9, 'Already looted this vault', 5000, 'top-right', 'error', 'circle-xmark', '#e60000')
	end
end)

------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	RSGCore.Function.createPrompt('vault2', vector3(2866.55, -1399.98, 53.21), 0xF3830D8E, 'Loot Desk', {
		type = 'client',
		event = 'rsg_casinovaultheist:client:checkvault1',
		args = {},
	})
end)

-- loot vault2
RegisterNetEvent('rsg_casinovaultheist:client:checkvault1', function()
	local player = PlayerPedId()
	SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
	if vault2 == false then
		RSGCore.Function.Progressbar("search_desk", "Stealing Money", 10000, false, true, {
			disableMovement = false,
			disableCarMovement = false,
			disableMouse = false,
			disableCombat = true,
		}, {
			animDict = "script_ca@cachr@ig@ig4_vaultloot",
			anim = "ig13_14_grab_money_front01_player_zero",
			flags = 1,
		}, {}, {}, function() -- Done
			ClearPedTasks(player)
			SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
			TriggerServerEvent('rsg_casinovaultheist:server:reward1')
			vault2 = true
		end)
	else
		RSGCore.Functions.NotifyV2(9, 'Already looted this desk', 5000, 'top-right', 'error', 'circle-xmark', '#e60000')
	end
end)

------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	RSGCore.Function.createPrompt('vault3', vector3(2864.8, -1398.55, 52.48), 0xF3830D8E, 'Loot Table', {
		type = 'client',
		event = 'rsg_casinovaultheist:client:checkvault2',
		args = {},
	})
end)

-- loot vault3
RegisterNetEvent('rsg_casinovaultheist:client:checkvault2', function()
	local player = PlayerPedId()
	SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
	if vault3 == false then
		RSGCore.Function.Progressbar("search_table", "Stealing Nuggets", 10000, false, true, {
			disableMovement = false,
			disableCarMovement = false,
			disableMouse = false,
			disableCombat = true,
		}, {
			animDict = "script_ca@cachr@ig@ig4_vaultloot",
			anim = "ig13_14_grab_money_front01_player_zero",
			flags = 1,
		}, {}, {}, function() -- Done
			ClearPedTasks(player)
			SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
			TriggerServerEvent('rsg_casinovaultheist:server:reward2')
			vault3 = true
		end)
	else
		RSGCore.Functions.NotifyV2(9, 'Already looted this table', 5000, 'top-right', 'error', 'circle-xmark', '#e60000')
	end
end)

------------------------------------------------------------------------------------------------------------------------

function modelrequest( model )
    Citizen.CreateThread(function()
        RequestModel( model )
    end)
end

-- start mission npcs
RegisterNetEvent('rsg_casinovaultheist:client:policenpc')
AddEventHandler('rsg_casinovaultheist:client:policenpc', function()
	for z, x in pairs(Config.HeistNpcs) do
	while not HasModelLoaded( GetHashKey(Config.HeistNpcs[z]["Model"]) ) do
		Wait(500)
		modelrequest( GetHashKey(Config.HeistNpcs[z]["Model"]) )
	end
	local npc = CreatePed(GetHashKey(Config.HeistNpcs[z]["Model"]), Config.HeistNpcs[z]["Pos"].x, Config.HeistNpcs[z]["Pos"].y, Config.HeistNpcs[z]["Pos"].z, Config.HeistNpcs[z]["Heading"], true, false, 0, 0)
	while not DoesEntityExist(npc) do
		Wait(300)
	end
	if not NetworkGetEntityIsNetworked(npc) then
		NetworkRegisterEntityAsNetworked(npc)
	end
	Citizen.InvokeNative(0x283978A15512B2FE, npc, true) -- SetRandomOutfitVariation
	GiveWeaponToPed_2(npc, 0x64356159, 500, true, 1, false, 0.0)
	TaskCombatPed(npc, PlayerPedId())
	end
end)

------------------------------------------------------------------------------------------------------------------------

-- cooldown
function handleCooldown()
    cooldownSecondsRemaining = initialCooldownSeconds
    Citizen.CreateThread(function()
        while cooldownSecondsRemaining > 0 do
            Citizen.Wait(1000)
            cooldownSecondsRemaining = cooldownSecondsRemaining - 1
        end
    end)
end

------------------------------------------------------------------------------------------------------------------------

function DrawText3Ds(x, y, z, text)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str,_x,_y)
end
