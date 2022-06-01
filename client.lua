ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
  TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
  Citizen.Wait(0)
    end
end)

-- Tirarse al Suelo --

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		if IsControlPressed(2, 303) then
			ragdol = 1 end
			if ragdol == 1 then
		SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
		TriggerEvent('esx:showNotification', "Pulsa Y para levantarte", "ERROR")
		Citizen.Wait(10000)
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsControlPressed(2, 246) then
			ragdol = 0 end
			if ragdol == 1 then
		SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
		end
	end
end)
-- Agacharse --

local agacharse = false
Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(1)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsEntityDead(ped) then 
            DisableControlAction(0,36,true)  
            if not IsPauseMenuActive() then 
                if IsDisabledControlJustPressed(0,36) then 
                    RequestAnimSet("move_ped_crouched")
                    RequestAnimSet("move_ped_crouched_strafing")
                    if agacharse == true then 
                        ResetPedMovementClipset(ped,0.55)
                        ResetPedStrafeClipset(ped)
                        agacharse = false 
                    elseif agacharse == false then
                        SetPedMovementClipset(ped,"move_ped_crouched",0.55)
                        SetPedStrafeClipset(ped,"move_ped_crouched_strafing")
                        agacharse = true 
                    end 
                end
            end 
        end 
    end
end)

-- Señalar con la mano --

local mp_pointing = false
local keyPressed = false

local function startPointing()
    local ped = PlayerPedId()
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do
        Wait(0)
    end
    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
    Citizen.InvokeNative(0x2D537BA194896636, ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")
end

local function stopPointing()
    local ped = PlayerPedId()
    Citizen.InvokeNative(0xD01015C7316AE176, ped, "Stop")
    if not IsPedInjured(ped) then
        ClearPedSecondaryTask(ped)
    end
    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
    ClearPedSecondaryTask(PlayerPedId())
end

local once = true
local oldval = false
local oldvalped = false

Citizen.CreateThread(function()
    while true do
        Wait(0)

        if once then
            once = false
        end

        if not keyPressed then
            if IsControlPressed(0, 29) and not mp_pointing and IsPedOnFoot(PlayerPedId()) then
                Wait(200)
                if not IsControlPressed(0, 29) then
                    keyPressed = true
                    startPointing()
                    mp_pointing = true
                else
                    keyPressed = true
                    while IsControlPressed(0, 29) do
                        Wait(50)
                    end
                end
            elseif (IsControlPressed(0, 29) and mp_pointing) or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
                keyPressed = true
                mp_pointing = false
                stopPointing()
            end
        end

        if keyPressed then
            if not IsControlPressed(0, 29) then
                keyPressed = false
            end
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) and not mp_pointing then
            stopPointing()
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) then
            if not IsPedOnFoot(PlayerPedId()) then
                stopPointing()
            else
                local ped = PlayerPedId()
                local camPitch = GetGameplayCamRelativePitch()
                if camPitch < -70.0 then
                    camPitch = -70.0
                elseif camPitch > 42.0 then
                    camPitch = 42.0
                end
                camPitch = (camPitch + 70.0) / 112.0

                local camHeading = GetGameplayCamRelativeHeading()
                local cosCamHeading = Cos(camHeading)
                local sinCamHeading = Sin(camHeading)
                if camHeading < -180.0 then
                    camHeading = -180.0
                elseif camHeading > 180.0 then
                    camHeading = 180.0
                end
                camHeading = (camHeading + 180.0) / 360.0

                local blocked = 0
                local nn = 0

                local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
                nn,blocked,coords,coords = GetRaycastResult(ray)

                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)

            end
        end
    end
end)

-- Caminar herido --

local hurt = false
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if GetEntityHealth(PlayerPedId()) <= 159 then
            setHurt()
        elseif hurt and GetEntityHealth(PlayerPedId()) > 160 then
            setNotHurt()
        end
    end
end)

function setHurt()
    hurt = true
    RequestAnimSet("move_m@injured")
    SetPedMovementClipset(PlayerPedId(), "move_m@injured", true)
end

function setNotHurt()
    hurt = false
    ResetPedMovementClipset(PlayerPedId())
    ResetPedWeaponMovementClipset(PlayerPedId())
    ResetPedStrafeClipset(PlayerPedId())
end
-- Levantar las manos --

local handsup = false
local cabeca = false

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		local ped = PlayerPedId()
		DisableControlAction(0, 36, true)
		if not IsPedInAnyVehicle(ped) then
			RequestAnimSet("move_ped_crouched")
			RequestAnimSet("move_ped_crouched_strafing")
			if IsControlJustPressed(1, 323) then
				local dict = "missminuteman_1ig_2"
				RequestAnimDict(dict)
				while not HasAnimDictLoaded(dict) do
					Citizen.Wait(100)
				end

				if handsup == false then
					ClearPedTasks(PlayerPedId())
					TaskPlayAnim(PlayerPedId(), dict, "handsup_enter", 8.0, 8.0, -1, 50, 0, false, false, false)
					handsup = true
					TriggerServerEvent("tac_thief:update", handsup)
				elseif cabeca == false then
					while not HasAnimDictLoaded("random@arrests@busted") do
						RequestAnimDict("random@arrests@busted")
						Citizen.Wait(5)
					end
				cabeca = true
				TaskPlayAnim(PlayerPedId(), "random@arrests@busted", "idle_c", 8.0, 8.0, -1, 50, 0, false, false, false)
				else
					cabeca = false
					handsup = false
					TriggerServerEvent("tac_thief:update", handsup)
					ClearPedTasks(PlayerPedId())
				end
			end
		end
	end
end)

-- Cruzar los brazos --

Citizen.CreateThread(function()
    local dict = "amb@world_human_hang_out_street@female_arms_crossed@base"
    
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(100)
	end
    local handsup = false
	while true do
		Citizen.Wait(0)
		if IsControlJustPressed(1, 47) then --Start holding g
            if not handsup then
                TaskPlayAnim(PlayerPedId(), dict, "base", 8.0, 8.0, -1, 50, 0, false, false, false)
                handsup = true
            else
                handsup = false
                ClearPedTasks(PlayerPedId())
            end
        end
    end
end)
	
	

-- Quitar NPCs ---

DensityMultiplier = 0.5
Citizen.CreateThread(function()
	while true do
	    Citizen.Wait(0)
	    SetVehicleDensityMultiplierThisFrame(DensityMultiplier)
	    SetPedDensityMultiplierThisFrame(DensityMultiplier)
	    SetRandomVehicleDensityMultiplierThisFrame(DensityMultiplier)
	    SetParkedVehicleDensityMultiplierThisFrame(DensityMultiplier)
	    SetScenarioPedDensityMultiplierThisFrame(DensityMultiplier, DensityMultiplier)
	end
end)

-- Quitar NPCs Policiales --

Citizen.CreateThread(function()
    while true do
    Citizen.Wait(0)
    local playerPed = PlayerPedId()
    local playerLocalisation = GetEntityCoords(playerPed)
    ClearAreaOfCops(playerLocalisation.x, playerLocalisation.y, playerLocalisation.z, 500.0)
    end
    end)

-- NPCs No dropean armas --

function SetWeaponDrops()
    local handle, ped = FindFirstPed()
    local finished = false 

    repeat 
        if not IsEntityDead(ped) then
            SetPedDropsWeaponsWhenDead(ped, false) 
        end
        finished, ped = FindNextPed(handle)
    until not finished

    EndFindPed(handle)
end

Citizen.CreateThread(function()
    while true do
        SetWeaponDrops()
        Citizen.Wait(500)
    end
end)


-- NPC NO DISPARAN y ELIMINACIÓN DE ARMAS A NPC --

Citizen.CreateThread(function()
    while true do
      Citizen.Wait(1)
      RemoveAllPickupsOfType(0xDF711959)
      RemoveAllPickupsOfType(0xF9AFB48F)
      RemoveAllPickupsOfType(0xA9355DCD)
    end
  end)

  local relationshipTypes = {
	'GANG_1',
	'GANG_2',
	'GANG_9',
	'GANG_10',
	'AMBIENT_GANG_LOST',
	'AMBIENT_GANG_MEXICAN',
	'AMBIENT_GANG_FAMILY',
	'AMBIENT_GANG_BALLAS',
	'AMBIENT_GANG_MARABUNTE',
	'AMBIENT_GANG_CULT',
	'AMBIENT_GANG_SALVA',
	'AMBIENT_GANG_WEICHENG',
	'AMBIENT_GANG_HILLBILLY',
	'DEALER',
	'COP',
	'PRIVATE_SECURITY',
	'SECURITY_GUARD',
	'ARMY',
	'MEDIC',
	'FIREMAN',
	'HATES_PLAYER',
	'NO_RELATIONSHIP',
	'SPECIAL',
	'MISSION2',
	'MISSION3',
	'MISSION4',
	'MISSION5',
	'MISSION6',
	'MISSION7',
	'MISSION8'
}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5000)

		for _, group in ipairs(relationshipTypes) do
			SetRelationshipBetweenGroups(1, GetHashKey('PLAYER'), GetHashKey(group)) -- could be removed
			SetRelationshipBetweenGroups(1, GetHashKey(group), GetHashKey('PLAYER'))
		end
	end
end)
  
-- QUITAR ARMAS VEHÍCULOS POLICIALES --

Citizen.CreateThread(function()

	local id = PlayerId()
	
	while true do
	
		Citizen.Wait(1)
	
		DisablePlayerVehicleRewards(id)
	
	end
	end)

-- Dejar K.O --

local knockedOut = false
local wait = 15
local count = 60

Citizen.CreateThread(function()
	while true do
		Wait(1)
		local myPed = PlayerPedId()
		if IsPedInMeleeCombat(myPed) then
			if GetEntityHealth(myPed) < 115 then
				SetPlayerInvincible(PlayerId(), true)
				SetPedToRagdoll(myPed, 1000, 1000, 0, 0, 0, 0)
				ShowNotification("~r~You were knocked out!")
				wait = 15
				knockedOut = true
				SetEntityHealth(myPed, 116)
			end
		end
		if knockedOut == true then
			SetPlayerInvincible(PlayerId(), true)
			DisablePlayerFiring(PlayerId(), true)
			SetPedToRagdoll(myPed, 1000, 1000, 0, 0, 0, 0)
			ResetPedRagdollTimer(myPed)
			
			if wait >= 0 then
				count = count - 1
				if count == 0 then
					count = 60
					wait = wait - 1
					SetEntityHealth(myPed, GetEntityHealth(myPed)+4)
				end
			else
				SetPlayerInvincible(PlayerId(), false)
				knockedOut = false
			end
		end
	end
end)

function ShowNotification(text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, false)
end

-- Daño armas --

Citizen.CreateThread(function()
    while true do
	N_0x4757f00bc6323cfe(GetHashKey("WEAPON_UNARMED"), 0.1)  --Puños
    	Wait(0)
    	N_0x4757f00bc6323cfe(GetHashKey("WEAPON_NIGHTSTICK"), 0.1)  -- Porra Policial
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_KNIFE"), 0.1)  -- Cuchillo
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_SWITCHBLADE"), 0.1)  -- Navaja
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_DAGGER"), 0.1)  -- Daga
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_MACHETE"), 0.1)  -- Machete
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_BAT"), 0.1)  -- Bate de Beisbol
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_BOTTLE"), 0.1)  -- Botella
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_CROWBAR"), 0.1)  -- PALANCA
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_FLASHLIGHT"), 0.1)  -- Linterna
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_GOLFCLUB"), 0.1)  -- Palo de Golf
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_HUMMER"), 0.1)  -- Martillo
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_HATCHET"), 0.1)  -- Hacha
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_battleaxe"), 0.1)  -- Hacha de Batalla
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_STONE_HATCHET"), 0.1)  -- Hacha de Combate
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_KNUCKLE"), 0.1)  -- Puños Americanos
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_POOLCUE"), 0.1)  -- Palo
    	Wait(0)
		N_0x4757f00bc6323cfe(GetHashKey("WEAPON_WRENCH"), 0.1)  -- Llave de tubo
    	Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
	local ped = PlayerPedId()
        if IsPedArmed(ped, 6) then
	   DisableControlAction(1, 140, true)
       	   DisableControlAction(1, 141, true)
           DisableControlAction(1, 142, true)
        end
    end
end)

-- Resetear Voz  --

RegisterCommand('rvoz', function()
	NetworkClearVoiceChannel()
	NetworkSessionVoiceLeave()
	Wait(50)
	NetworkSetVoiceActive(false)
	MumbleClearVoiceTarget(2)
	Wait(1000)
	MumbleSetVoiceTarget(2)
	NetworkSetVoiceActive(true)
	ESX.ShowNotification('Chat de voz reiniciado.')
  end)	

-- Resetear PJ y Limpiar Sangre del PJ --

RegisterCommand("sangre", function(source, args, rawCommand)
	reloadSkin()
  end)
  
  -- Command /rskin
  RegisterCommand("rskin", function(source, args, rawCommand)
	reloadSkin()
  end)
  
  function reloadSkin()
	ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
	local model = nil
		 
	if skin.sex == 0 then
	  model = GetHashKey("mp_m_freemode_01")
	else
	  model = GetHashKey("mp_f_freemode_01")
	end
  
	RequestModel(model)
  
	SetPlayerModel(PlayerId(), model)
	SetModelAsNoLongerNeeded(model)
  
	TriggerEvent('skinchanger:loadSkin', skin)
	TriggerEvent('esx:restoreLoadout')
	end)
  end

-- Quitar Q --

Citizen.CreateThread(function()
    while false do
      s = 1000
      if not IsPauseMenuActive() then
        s = 5
        DisableControlAction(0,44,true)
      else
        s = 100
      end
      Citizen.Wait(s)
    end
  end)
  
  RegisterCommand('QU',
    function()
      DisableControlAction(0,44,true)
    end
  )
  
  RegisterKeyMapping('QU','','keyboard','Q')

-- TH --

local hostageAllowedWeapons = {
	"WEAPON_PISTOL",
	"WEAPON_COMBATPISTOL",
	"WEAPON_SNSPISTOL",
	"WEAPON_PISTOL50",
	"WEAPON_HEAVYPISTOL",
	"WEAPON_APPISTOL",
	"WEAPON_VINTAGEPISTOL",
	"WEAPON_MACHINEPISTOL",
	"WEAPON_MICROSMG",
	"WEAPON_DOUBLEACTION",
	"WEAPON_KNIFE",
	"WEAPON_BOTTLE",
	"WEAPON_SWITCHBLADE",
}

local holdingHostageInProgress = false
local takeHostageAnimNamePlaying = ""
local takeHostageAnimDictPlaying = ""
local takeHostageControlFlagPlaying = 0

RegisterCommand("th",function()
	takeHostage()
end)

function takeHostage()
	ClearPedSecondaryTask(PlayerPedId())
	DetachEntity(PlayerPedId(), true, false)
	for i=1, #hostageAllowedWeapons do
		if HasPedGotWeapon(PlayerPedId(), GetHashKey(hostageAllowedWeapons[i]), false) then
			if GetAmmoInPedWeapon(PlayerPedId(), GetHashKey(hostageAllowedWeapons[i])) > 0 then
				canTakeHostage = true 
				foundWeapon = GetHashKey(hostageAllowedWeapons[i])
				break
			end 					
		end
	end

	if not canTakeHostage then 
		TriggerEvent('esx:showNotification', "No posees ninguna arma", "ERROR")
	end

	if not holdingHostageInProgress and canTakeHostage then		
		local player = PlayerPedId()	
		--lib = 'misssagrab_inoffice'
		--anim1 = 'hostage_loop'
		--lib2 = 'misssagrab_inoffice'
		--anim2 = 'hostage_loop_mrk'
		lib = 'anim@gangops@hostage@'
		anim1 = 'perp_idle'
		lib2 = 'anim@gangops@hostage@'
		anim2 = 'victim_idle'
		distans = 0.11 --Higher = closer to camera
		distans2 = -0.24 --higher = left
		height = 0.0
		spin = 0.0		
		length = 100000
		controlFlagMe = 49
		controlFlagTarget = 49
		animFlagTarget = 50
		attachFlag = true 
		local closestPlayer = GetClosestPlayer(2)
		target = GetPlayerServerId(closestPlayer)
		if closestPlayer ~= -1 and closestPlayer ~= nil then
			SetCurrentPedWeapon(PlayerPedId(), foundWeapon, true)
			holdingHostageInProgress = true
			holdingHostage = true 
			TriggerServerEvent('cmg3_animations:sync', closestPlayer, lib,lib2, anim1, anim2, distans, distans2, height,target,length,spin,controlFlagMe,controlFlagTarget,animFlagTarget,attachFlag)
		else
			TriggerEvent('esx:showNotification', "Nadie cerca", "ERROR")
		end 
	end
	canTakeHostage = false 
end 

RegisterNetEvent('cmg3_animations:syncTarget')
AddEventHandler('cmg3_animations:syncTarget', function(target, animationLib, animation2, distans, distans2, height, length,spin,controlFlag,animFlagTarget,attach)
	local playerPed = PlayerPedId()
	local targetPed = GetPlayerPed(GetPlayerFromServerId(target))
	if holdingHostageInProgress then 
		holdingHostageInProgress = false 
	else 
		holdingHostageInProgress = true
	end
	beingHeldHostage = true 
	RequestAnimDict(animationLib)

	while not HasAnimDictLoaded(animationLib) do
		Citizen.Wait(10)
	end
	if spin == nil then spin = 180.0 end
	if attach then 
		AttachEntityToEntity(PlayerPedId(), targetPed, 0, distans2, distans, height, 0.5, 0.5, spin, false, false, false, false, 2, false)
	else 
	end
	
	if controlFlag == nil then controlFlag = 0 end
	
	if animation2 == "victim_fail" then 
		SetEntityHealth(PlayerPedId(),0)
		DetachEntity(PlayerPedId(), true, false)
		TaskPlayAnim(playerPed, animationLib, animation2, 8.0, -8.0, length, controlFlag, 0, false, false, false)
		beingHeldHostage = false 
		holdingHostageInProgress = false 
	elseif animation2 == "shoved_back" then 
		holdingHostageInProgress = false 
		DetachEntity(PlayerPedId(), true, false)
		TaskPlayAnim(playerPed, animationLib, animation2, 8.0, -8.0, length, controlFlag, 0, false, false, false)
		beingHeldHostage = false 
	else
		TaskPlayAnim(playerPed, animationLib, animation2, 8.0, -8.0, length, controlFlag, 0, false, false, false)	
	end
	takeHostageAnimNamePlaying = animation2
	takeHostageAnimDictPlaying = animationLib
	takeHostageControlFlagPlaying = controlFlag
end)

RegisterNetEvent('cmg3_animations:syncMe')
AddEventHandler('cmg3_animations:syncMe', function(animationLib, animation,length,controlFlag,animFlag)
	local playerPed = PlayerPedId()
	ClearPedSecondaryTask(PlayerPedId())
	RequestAnimDict(animationLib)
	while not HasAnimDictLoaded(animationLib) do
		Citizen.Wait(10)
	end
	if controlFlag == nil then controlFlag = 0 end
	TaskPlayAnim(playerPed, animationLib, animation, 8.0, -8.0, length, controlFlag, 0, false, false, false)
	takeHostageAnimNamePlaying = animation
	takeHostageAnimDictPlaying = animationLib
	takeHostageControlFlagPlaying = controlFlag
	if animation == "perp_fail" then 
		SetPedShootsAtCoord(PlayerPedId(), 0.0, 0.0, 0.0, 0)
		holdingHostageInProgress = false 
	end
	if animation == "shove_var_a" then 
		Wait(900)
		ClearPedSecondaryTask(PlayerPedId())
		holdingHostageInProgress = false 
	end
end)

RegisterNetEvent('cmg3_animations:cl_stop')
AddEventHandler('cmg3_animations:cl_stop', function()
	holdingHostageInProgress = false
	beingHeldHostage = false 
	holdingHostage = false 
	ClearPedSecondaryTask(PlayerPedId())
	DetachEntity(PlayerPedId(), true, false)
end)

Citizen.CreateThread(function()
	while true do
		if holdingHostage or beingHeldHostage then 
			while not IsEntityPlayingAnim(PlayerPedId(), takeHostageAnimDictPlaying, takeHostageAnimNamePlaying, 3) do
				TaskPlayAnim(PlayerPedId(), takeHostageAnimDictPlaying, takeHostageAnimNamePlaying, 8.0, -8.0, 100000, takeHostageControlFlagPlaying, 0, false, false, false)
				Citizen.Wait(0)
			end
		end
		Wait(0)
	end
end)

function GetPlayers()
    local players = {}

	for _, i in ipairs(GetActivePlayers()) do
        table.insert(players, i)
    end

    return players
end

function GetClosestPlayer(radius)
    local players = GetPlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local ply = PlayerPedId()
    local plyCoords = GetEntityCoords(ply, 0)

    for index,value in ipairs(players) do
        local target = GetPlayerPed(value)
        if(target ~= ply) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
            local distance = GetDistanceBetweenCoords(targetCoords['x'], targetCoords['y'], targetCoords['z'], plyCoords['x'], plyCoords['y'], plyCoords['z'], true)
            if(closestDistance == -1 or closestDistance > distance) then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end
	if closestDistance <= radius then
		return closestPlayer
	else
		return nil
	end
end

Citizen.CreateThread(function()
	while true do 
		if holdingHostage then
			if IsEntityDead(PlayerPedId()) then	
				holdingHostage = false
				holdingHostageInProgress = false 
				local closestPlayer = GetClosestPlayer(2)
				target = GetPlayerServerId(closestPlayer)
				TriggerServerEvent("cmg3_animations:stop",target)
				Wait(100)
				releaseHostage()
			end 
			DisableControlAction(0,24,true) -- disable attack
			DisableControlAction(0,25,true) -- disable aim
			DisableControlAction(0,47,true) -- disable weapon
			DisableControlAction(0,58,true) -- disable weapon
			DisablePlayerFiring(PlayerPedId(),true)
			local playerCoords = GetEntityCoords(PlayerPedId())
			DrawText3D(playerCoords.x,playerCoords.y,playerCoords.z,"[~g~G~w~] para liberar. [~r~H~w~] para matar")
			if IsDisabledControlJustPressed(0,47) then --release	
				holdingHostage = false
				holdingHostageInProgress = false 
				local closestPlayer = GetClosestPlayer(2)
				target = GetPlayerServerId(closestPlayer)
				TriggerServerEvent("cmg3_animations:stop",target)
				Wait(100)
				releaseHostage()
			elseif IsDisabledControlJustPressed(0,74) then --kill 			
				holdingHostage = false
				holdingHostageInProgress = false 		
				local closestPlayer = GetClosestPlayer(2)
				target = GetPlayerServerId(closestPlayer)
				TriggerServerEvent("cmg3_animations:stop",target)				
				killHostage()
			end
		end
		if beingHeldHostage then 
			DisableControlAction(0,21,true) -- disable sprint
			DisableControlAction(0,24,true) -- disable attack
			DisableControlAction(0,25,true) -- disable aim
			DisableControlAction(0,47,true) -- disable weapon
			DisableControlAction(0,58,true) -- disable weapon
			DisableControlAction(0,263,true) -- disable melee
			DisableControlAction(0,264,true) -- disable melee
			DisableControlAction(0,257,true) -- disable melee
			DisableControlAction(0,140,true) -- disable melee
			DisableControlAction(0,141,true) -- disable melee
			DisableControlAction(0,142,true) -- disable melee
			DisableControlAction(0,143,true) -- disable melee
			DisableControlAction(0,75,true) -- disable exit vehicle
			DisableControlAction(27,75,true) -- disable exit vehicle  
			DisableControlAction(0,22,true) -- disable jump
			DisableControlAction(0,32,true) -- disable move up
			DisableControlAction(0,268,true)
			DisableControlAction(0,33,true) -- disable move down
			DisableControlAction(0,269,true)
			DisableControlAction(0,34,true) -- disable move left
			DisableControlAction(0,270,true)
			DisableControlAction(0,35,true) -- disable move right
			DisableControlAction(0,271,true)
		end
		Wait(0)
	end
end)

function DrawText3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(0.19, 0.19)
        SetTextFont(0)
        SetTextProportional(1)
        -- SetTextScale(0.0, 0.55)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 55)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

function releaseHostage()
	local player = PlayerPedId()	
	lib = 'reaction@shove'
	anim1 = 'shove_var_a'
	lib2 = 'reaction@shove'
	anim2 = 'shoved_back'
	distans = 0.11 --Higher = closer to camera
	distans2 = -0.24 --higher = left
	height = 0.0
	spin = 0.0		
	length = 100000
	controlFlagMe = 120
	controlFlagTarget = 0
	animFlagTarget = 1
	attachFlag = false
	local closestPlayer = GetClosestPlayer(2)
	target = GetPlayerServerId(closestPlayer)
	if closestPlayer ~= 0 then
		TriggerServerEvent('cmg3_animations:sync', closestPlayer, lib,lib2, anim1, anim2, distans, distans2, height,target,length,spin,controlFlagMe,controlFlagTarget,animFlagTarget,attachFlag)
	end
end 

function killHostage()
	local player = PlayerPedId()	
	lib = 'anim@gangops@hostage@'
	anim1 = 'perp_fail'
	lib2 = 'anim@gangops@hostage@'
	anim2 = 'victim_fail'
	distans = 0.11 --Higher = closer to camera
	distans2 = -0.24 --higher = left
	height = 0.0
	spin = 0.0		
	length = 0.2
	controlFlagMe = 168
	controlFlagTarget = 0
	animFlagTarget = 1
	attachFlag = false
	local closestPlayer = GetClosestPlayer(2)
	target = GetPlayerServerId(closestPlayer)
	if target ~= 0 then
		TriggerServerEvent('cmg3_animations:sync', closestPlayer, lib,lib2, anim1, anim2, distans, distans2, height,target,length,spin,controlFlagMe,controlFlagTarget,animFlagTarget,attachFlag)
	end	
end 

function drawNativeNotification(text)
    SetTextComponentFormat('STRING')
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Animación sacar armas --

local weaponsFull = {
	'WEAPON_KNIFE',
	'WEAPON_HAMMER',
	'WEAPON_BAT',
	'WEAPON_GOLFCLUB',
	'WEAPON_CROWBAR',
	'WEAPON_BOTTLE',
	'WEAPON_DAGGER',
	'WEAPON_HATCHET',
	'WEAPON_MACHETE',
	'WEAPON_BATTLEAXE',
	'WEAPON_POOLCUE',
	'WEAPON_WRENCH',
	'WEAPON_PISTOL',
	'WEAPON_COMBATPISTOL',
	'WEAPON_PISTOL50',
	'WEAPON_REVOLVER',
	'WEAPON_SNSPISTOL',
	'WEAPON_HEAVYPISTOL',
	'WEAPON_VINTAGEPISTOL',
	'WEAPON_MICROSMG',
	'WEAPON_ASSAULTSMG',
	'WEAPON_MINISMG',
	'WEAPON_MACHINEPISTOL',
	'WEAPON_COMBATPDW',
	'WEAPON_SAWNOFFSHOTGUN',
	'WEAPON_COMPACTRIFLE',
	'WEAPON_GUSENBERG',
	'WEAPON_SMOKEGRENADE',
	'WEAPON_BZGAS',
	'WEAPON_MOLOTOV',
	'WEAPON_FLAREGUN',
	'WEAPON_MARKSMANPISTOL',
	'WEAPON_DBSHOTGUN',
	'WEAPON_DOUBLEACTION',
}

local weaponsHolster = {
	'WEAPON_PISTOL',
	'WEAPON_COMBATPISTOL',
	'WEAPON_SNSPISTOL',
	'WEAPON_HEAVYPISTOL',
	'WEAPON_VINTAGEPISTOL',
	'WEAPON_PISTOL50',
	'WEAPON_DOUBLEACTION',
	'WEAPON_REVOLVER',
	'WEAPON_FLAREGUN',
}

local weaponsLarge = {
	"WEAPON_ASSAULTRIFLE",
	"WEAPON_PUMPSHOTGUN",
	"WEAPON_CARBINERIFLE",
	"WEAPON_SMG",
	"WEAPON_PUMPSHOTGUN_MK2",
	"WEAPON_CARBINERIFLE_MK2",
	"WEAPON_GUSENBERG",
	"WEAPON_MG",
	"WEAPON_ADVANCEDRIFLE",
	"WEAPON_SNIPERRIFLE",
	"WEAPON_COMPACTRIFLE",
	"WEAPON_COMBATPDW",
	"WEAPON_ASSAULTRIFLE_MK2",
	"WEAPON_COMBATMG_MK2",
	"WEAPON_MUSKET",
	"WEAPON_SPECIALCARBINE",
	"WEAPON_SMG_MK2",
	"WEAPON_SPECIALCARBINE_MK2",
}

local SETTINGS = {
	back_bone = 24816,
	x = 0.3, 
	y = -0.15,  
	z = -0.10,  
	x_rotation = 180.0,
	y_rotation = 145.0,
	z_rotation = 0.0,
	compatable_weapon_hashes = {
			-- assault rifles:
			["w_sg_pumpshotgunmk2"] = GetHashKey("WEAPON_PUMPSHOTGUN_MK2"),
			["w_ar_carbineriflemk2"] = GetHashKey("WEAPON_CARBINERIFLE_MK2"),
			["w_ar_assaultrifle"] = GetHashKey("WEAPON_ASSAULTRIFLE"),
			["w_sg_pumpshotgun"] = GetHashKey("WEAPON_PUMPSHOTGUN"),
			["w_ar_carbinerifle"] = GetHashKey("WEAPON_CARBINERIFLE"),
			["w_ar_assaultrifle_smg"] = GetHashKey("WEAPON_COMPACTRIFLE"),
			["w_sb_smg"] = GetHashKey("WEAPON_SMG"),
			["w_sb_pdw"] = GetHashKey("WEAPON_COMBATPDW"),
			["w_mg_mg"] = GetHashKey("WEAPON_MG"),
			["w_sb_gusenberg"] = GetHashKey("WEAPON_GUSENBERG"),
			["w_ar_advancedrifle"] = GetHashKey("WEAPON_ADVANCEDRIFLE"),
			["w_sr_sniperrifle"] = GetHashKey("WEAPON_SNIPERRIFLE"),
			["w_ar_assaultriflemk2"] = GetHashKey("WEAPON_ASSAULTRIFLE_MK2"),
			["w_mg_combatmgmk2"] = GetHashKey("WEAPON_COMBATMG_MK2"),
			["w_ar_musket"] = GetHashKey("WEAPON_MUSKET"),
			["w_ar_specialcarbine"] = GetHashKey("WEAPON_SPECIALCARBINE"),
			["w_sb_smgmk2"] = GetHashKey("WEAPON_SMG_MK2"),
			["w_ar_specialcarbinemk2"] = GetHashKey("WEAPON_SPECIALCARBINE_MK2"),
	}
}

local attached_weapons = {}
local holstered  = true
local PlayerData = {}
local ESX        = nil

local hasWeapon 			= false
local currWeapon 	    = GetHashKey("WEAPON_UNARMED")
local animateTrunk 		= false
local hasWeaponH  		= false
local hasWeaponL      = false
local weaponL         = GetHashKey("WEAPON_UNARMED")
local has_weapon_on_back = false
local racking         = false
local holster 				= 0
local blocked 				= false
local sex 						= 0
local holsterButton 	= 20
local handOnHolster 	= false
local holsterHold			= false
local ped							= nil
 
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

 Citizen.CreateThread(function()
	local newWeapon = GetHashKey("WEAPON_UNARMED")
	while true do
		Citizen.Wait(1)
		ped = PlayerPedId()
		if DoesEntityExist( ped ) and not IsEntityDead( ped ) and not IsPedInAnyVehicle(ped, true) then
			newWeapon = GetSelectedPedWeapon(ped)
			if newWeapon ~= currWeapon then
				if checkWeaponLarge(ped, newWeapon) then
					if hasWeaponL then
						holsterWeaponL(ped, currWeapon)
					elseif holster >= 1 and holster <= 4 then
						if hasWeapon then
							if hasWeaponH then
								holsterWeaponH(ped, currWeapon)
							else
								holsterWeapon(ped, currWeapon)
							end
						end
					else
						if hasWeapon then
							holsterWeapon(ped, currWeapon)
						end
					end
					drawWeaponLarge(ped, newWeapon)
				elseif holster >= 1 and holster <= 4 then
					if hasWeaponL then
						holsterWeaponL()
					elseif hasWeaponH then
						holsterWeaponH(ped, currWeapon)
					elseif hasWeapon then
						holsterWeapon(ped, currWeapon)
					end
					if checkWeaponHolster(ped, newWeapon) then
						drawWeaponH(ped, newWeapon)
					else
						drawWeapon(ped, newWeapon)
					end
				else
					if hasWeaponL then
						holsterWeaponL()
					elseif hasWeapon then
						holsterWeapon(ped, currWeapon)
					end
					drawWeapon(ped, newWeapon)
				end
				currWeapon = newWeapon
			end
		else
			hasWeapon = false
			hasWeaponH = false
		end
		if racking then
			rackWeapon()
		end
	end
end)

function drawWeaponLarge(ped, newWeapon)
	------Check if weapon is on back -------
	if has_weapon_on_back and newWeapon == weaponL then
		drawWeaponOnBack()
		has_weapon_on_back = false
		return
	end

	local door = isNearDoor()
	if PlayerData.job.name == 'police' and (door == 'driver' or door == 'passenger') then
		blocked = true
		local coordA = GetEntityCoords(ped, 1)
		local coordB = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
		local vehicle = getVehicleInDirection(coordA, coordB)
		if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
			if door == 'driver' then
				SetVehicleDoorOpen(vehicle, 0, false, false)
			elseif door == 'passenger' then
				SetVehicleDoorOpen(vehicle, 1, false, false)
			end
		end
		removeWeaponOnBack()
		startAnim("mini@repair", "fixing_a_ped")
		SetCurrentPedWeapon(ped, newWeapon, true)
		blocked = false
		if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
			if door == 'driver' then
				SetVehicleDoorShut(vehicle, 0, false, false)
			elseif door == 'passenger' then
				SetVehicleDoorShut(vehicle, 1, false, false)
			end
		end
		weaponL = newWeapon
		hasWeaponL = true
	elseif not isNearTrunk() then
		SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
		ESX.ShowNotification('You need to be at a trunk to draw that weapon!')
	else
		blocked = true
		removeWeaponOnBack()
		startAnim("mini@repair", "fixing_a_ped")
		blocked = false
		local coordA = GetEntityCoords(ped, 1)
		local coordB = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
		local vehicle = getVehicleInDirection(coordA, coordB)
		if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
			SetVehicleDoorShut(vehicle, 5, false, false)
		end
		weaponL = newWeapon
		hasWeaponL = true
	end
end

function checkWeaponLarge(ped, newWeapon)
	for i = 1, #weaponsLarge do
		if GetHashKey(weaponsLarge[i]) == newWeapon then
			return true
		end
	end
	return false
end

function startAnim(lib, anim)
	RequestAnimDict(lib)
	while not HasAnimDictLoaded( lib) do
		Citizen.Wait(1)
	end

	TaskPlayAnim(ped, lib ,anim ,8.0, -8.0, -1, 0, 0, false, false, false )
	if PlayerData.job.name == 'police' then
		Citizen.Wait(2000)
	else
		Citizen.Wait(4000)
	end
	ClearPedTasksImmediately(ped)
end

function holsterWeaponL()
	SetCurrentPedWeapon(ped, weaponL, true)
	pos = GetEntityCoords(ped, true)
	rot = GetEntityHeading(ped)
	blocked = true
	TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "outro", pos, 0, 0, rot, 8.0, 3.0, -1, 50, 0.125, 0, 0)
	Citizen.Wait(500)
	SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
	placeWeaponOnBack()
	Citizen.Wait(1500)
	ClearPedTasks(ped)
	blocked = false
	SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
	hasWeaponL = false
end

function drawWeaponOnBack()
	pos = GetEntityCoords(ped, true)
	rot = GetEntityHeading(ped)
	blocked = true
	loadAnimDict( "reaction@intimidation@1h" )
	TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "intro", pos, 0, 0, rot, 8.0, 3.0, -1, 50, 0.325, 0, 0)
	removeWeaponOnBack()
	SetCurrentPedWeapon(ped, weaponL, true)
	Citizen.Wait(2000)
	ClearPedTasks(ped)
	blocked = false
	hasWeaponL = true
end

function removeWeaponOnBack()
	print("REMOVING WEAPON MODEL FROM BACK")
	has_weapon_on_back = false
end

function placeWeaponOnBack()
	print("PLACING WEAPON MODEL ON BACK")
	has_weapon_on_back = true
end

RegisterCommand('rack', function()
	SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
	racking = true
end, false)

function rackWeapon()
	local door = isNearDoor()
	if PlayerData.job.name == 'police' and (door == 'driver' or door == 'passenger') then
		blocked = true
		local coordA = GetEntityCoords(ped, 1)
		local coordB = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
		local vehicle = getVehicleInDirection(coordA, coordB)
		if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
			if door == 'driver' then
				SetVehicleDoorOpen(vehicle, 0, false, false)
			elseif door == 'passenger' then
				SetVehicleDoorOpen(vehicle, 1, false, false)
			end
		end
		removeWeaponOnBack()
		startAnim("mini@repair", "fixing_a_ped")
		blocked = false
		if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
			if door == 'driver' then
				SetVehicleDoorShut(vehicle, 0, false, false)
			elseif door == 'passenger' then
				SetVehicleDoorShut(vehicle, 1, false, false)
			end
		end
		WeaponL = GetHashKey("WEAPON_UNARMED")
		
	elseif isNearTrunk() then
		blocked = true
		removeWeaponOnBack()
		startAnim("mini@repair", "fixing_a_ped")
		blocked = false
		local coordA = GetEntityCoords(ped, 1)
		local coordB = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
		local vehicle = getVehicleInDirection(coordA, coordB)
		if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
			SetVehicleDoorShut(vehicle, 5, false, false)
		end
		WeaponL = GetHashKey("WEAPON_UNARMED")
		hasWeaponL = false
	else
		ESX.ShowNotification('You need to be at a trunk to put away your weapon!')
	end
	racking = false
end

Citizen.CreateThread(function()
  while true do
			local me = PlayerPedId()
			Citizen.Wait(10)
      for wep_name, wep_hash in pairs(SETTINGS.compatable_weapon_hashes) do
          if weaponL == wep_hash and has_weapon_on_back and HasPedGotWeapon(me, wep_hash, false) then
              if not attached_weapons[wep_name] then
                  AttachWeapon(wep_name, wep_hash, SETTINGS.back_bone, SETTINGS.x, SETTINGS.y, SETTINGS.z, SETTINGS.x_rotation, SETTINGS.y_rotation, SETTINGS.z_rotation, isMeleeWeapon(wep_name))
              end
          end
      end
      for name, attached_object in pairs(attached_weapons) do
          -- equipped? delete it from back:
          if not has_weapon_on_back then -- equipped or not in weapon wheel
            DeleteObject(attached_object.handle)
            attached_weapons[name] = nil
          end
      end
  Wait(0)
  end
end)

function AttachWeapon(attachModel,modelHash,boneNumber,x,y,z,xR,yR,zR, isMelee)
	local bone = GetPedBoneIndex(PlayerPedId(), boneNumber)
	RequestModel(attachModel)
	while not HasModelLoaded(attachModel) do
		Wait(100)
	end

  attached_weapons[attachModel] = {
    hash = modelHash,
    handle = CreateObject(GetHashKey(attachModel), 1.0, 1.0, 1.0, true, true, false)
  }

  if isMelee then x = 0.11 y = -0.14 z = 0.0 xR = -75.0 yR = 185.0 zR = 92.0 end -- reposition for melee items
  if attachModel == "prop_ld_jerrycan_01" then x = x + 0.3 end
	AttachEntityToEntity(attached_weapons[attachModel].handle, PlayerPedId(), bone, x, y, z, xR, yR, zR, 1, 1, 0, 0, 2, 1)
end

function isMeleeWeapon(wep_name)
    if wep_name == "prop_golf_iron_01" then
        return true
    elseif wep_name == "w_me_bat" then
        return true
    elseif wep_name == "prop_ld_jerrycan_01" then
      return true
    else
        return false
    end
end

function isNearTrunk()
	local coordA = GetEntityCoords(ped, 1)
	local coordB = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
	local vehicle = getVehicleInDirection(coordA, coordB)
	if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
		local trunkpos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "boot"))
		local lTail = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "taillight_l"))
		local rTail = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "taillight_r"))
		local playerpos = GetEntityCoords(ped, 1)
		local distanceToTrunk = GetDistanceBetweenCoords(trunkpos, playerpos, 1)
		local distanceToLeftT = GetDistanceBetweenCoords(lTail, playerpos, 1)
		local distanceToRightT = GetDistanceBetweenCoords(rTail, playerpos, 1)
		if distanceToTrunk < 1.5 then
			SetVehicleDoorOpen(vehicle, 5, false, false)
			return true
		elseif distanceToLeftT < 1.5 and distanceToRightT < 1.5 then
			SetVehicleDoorOpen(vehicle, 5, false, false)
			return true
		else
			return
		end
	end
end

function isNearDoor()
	local coordA = GetEntityCoords(ped, 1)
	local coordB = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
	local vehicle = getVehicleInDirection(coordA, coordB)
	if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
		local dDoor = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "door_dside_f"))
		local pDoor = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "door_pside_f"))
		local playerpos = GetEntityCoords(ped, 1)
		local distanceToDriverDoor = GetDistanceBetweenCoords(dDoor, playerpos, 1)
		local distanceToPassengerDoor = GetDistanceBetweenCoords(pDoor, playerpos, 1)
		if distanceToDriverDoor < 2.0 then
			return 'driver'
		elseif distanceToPassengerDoor < 2.0 then
			return 'passenger'
		else
			return
		end
	end
end

function getVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, ped, 0)
	local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

function checkWeaponHolster(ped, newWeapon)
	for i = 1, #weaponsHolster do
		if GetHashKey(weaponsHolster[i]) == newWeapon then
			return true
		end
	end
	return false
end

function holsterWeaponH(ped, currentWeapon)
	blocked = true
	SetCurrentPedWeapon(ped, currentWeapon, true)
	loadAnimDict("reaction@intimidation@cop@unarmed")
	TaskPlayAnim(ped, "reaction@intimidation@cop@unarmed", "outro", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
	addWeaponHolster()
	Citizen.Wait(200)
	SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
	Citizen.Wait(1000)
	ClearPedTasks(ped)
	hasWeapon = false
	hasWeaponH = false
	blocked = false
end

function drawWeaponH(ped, newWeapon)
	blocked = true
	loadAnimDict("rcmjosh4")
  loadAnimDict("weapons@pistol@")
	loadAnimDict("reaction@intimidation@cop@unarmed")
	if not handOnHolster then
		SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
		TaskPlayAnim(ped, "reaction@intimidation@cop@unarmed", "intro", 8.0, 2.0, -1, 50, 2.0, 0, 0, 0 )
		Citizen.Wait(300)
	end
	while holsterHold do
		Citizen.Wait(1)
	end
	TaskPlayAnim(ped, "rcmjosh4", "josh_leadout_cop2", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
	SetCurrentPedWeapon(ped, newWeapon, true)
	removeWeaponHolster()
	if not handOnHolster then
		Citizen.Wait(300)
	end
  ClearPedTasks(ped)
	hasWeaponH = true
	hasWeapon = true
	handOnHolster = false
	blocked = false
end

function removeWeaponHolster()
	if holster == 1 then
		SetPedComponentVariation(ped, 7, 2, 0, 0)
	elseif holster == 2 then
		SetPedComponentVariation(ped, 7, 5, 0, 0)
	elseif holster == 3 then
		if sex == 0 then
			SetPedComponentVariation(ped, 8, 18, 0, 1)
		else
			SetPedComponentVariation(ped, 8, 10, 0, 1)
		end
	elseif holster == 4 then
		SetPedComponentVariation(ped, 7, 3, 0, 0)
	end
end

function addWeaponHolster()
	if holster == 1 then
		SetPedComponentVariation(ped, 7, 8, 0, 0)
	elseif holster == 2 then
		SetPedComponentVariation(ped, 7, 6, 0, 0)
	elseif holster == 3 then
		if sex == 0 then
			SetPedComponentVariation(ped, 8, 16, 0, 1)
		else
			SetPedComponentVariation(ped, 8, 9, 0, 1)
		end
	elseif holster == 4 then
		SetPedComponentVariation(ped, 7, 1, 0, 0)
	end
end

function holsterWeapon(ped, currentWeapon)
	if checkWeaponLarge(ped, currentWeapon) then
		placeWeaponOnBack()
	elseif checkWeapon(ped, currentWeapon) then
		SetCurrentPedWeapon(ped, currentWeapon, true)
		pos = GetEntityCoords(ped, true)
		rot = GetEntityHeading(ped)
		blocked = true
		TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "outro", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.125, 0, 0)
		Citizen.Wait(500)
		SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
		Citizen.Wait(1500)
		ClearPedTasks(ped)
		blocked = false
	end
	hasWeapon = false
end

function drawWeapon(ped, newWeapon)
	if newWeapon == GetHashKey("WEAPON_UNARMED") then
		return
	end
	if checkWeapon(ped, newWeapon) then
		pos = GetEntityCoords(ped, true)
		rot = GetEntityHeading(ped)
		blocked = true
		loadAnimDict( "reaction@intimidation@1h" )
		TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "intro", GetEntityCoords(ped, true), 0, 0, rot, 8.0, 3.0, -1, 50, 0.325, 0, 0)
		SetCurrentPedWeapon(ped, newWeapon, true)
		Citizen.Wait(600)
		ClearPedTasks(ped)
		blocked = false
	else
		SetCurrentPedWeapon(ped, newWeapon, true)
	end
	handOnHolster = false
	hasWeapon = true

end

function checkWeapon(ped, newWeapon)
	for i = 1, #weaponsFull do
		if GetHashKey(weaponsFull[i]) == newWeapon then
			return true
		end
	end
	return false
end

Citizen.CreateThread( function()

	while true do
		Citizen.Wait(0)
		if (IsControlJustPressed(0,holsterButton)) then
			local ped2 = GetPlayerPed( -1 )
			if ( DoesEntityExist( ped2 ) and not IsEntityDead( ped2 )) and not IsPedInAnyVehicle(ped2, true) then
				loadAnimDict( "move_m@intimidation@cop@unarmed" )
				if ( IsEntityPlayingAnim( ped2, "move_m@intimidation@cop@unarmed", "idle", 3 ) ) then
						ClearPedSecondaryTask(ped2)
						SetCurrentPedWeapon(ped2, GetHashKey("WEAPON_UNARMED"), true)
						handOnHolster = false
				else
						TaskPlayAnim(ped2, "move_m@intimidation@cop@unarmed", "idle", 8.0, 2.5, -1, 49, 0, 0, 0, 0 )
						SetCurrentPedWeapon(ped2, GetHashKey("WEAPON_UNARMED"), true)
						handOnHolster = true
						holsterHold = true
						Citizen.Wait(1000)
						holsterHold = false
				end    
			end
		end
	end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
            if blocked then
                DisableControlAction(1, 25, true )
                DisableControlAction(1, 140, true)
                DisableControlAction(1, 141, true)
                DisableControlAction(1, 142, true)
                DisableControlAction(1, 23, true)
				DisableControlAction(1, 37, true) (TAB)
				DisableControlAction(1, 182, true)  
				DisablePlayerFiring(ped, true) 
            end
    end
end)

function loadAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Citizen.Wait(5)
	end
end

--ARMAS EN LA ESPALDA
local fuera = true
local si = false

function playAnim(animDict, animName, duration)
	  RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do Citizen.Wait(0) end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1.0, duration, 49, 1, false, true, false)
    RemoveAnimDict(animDict)
end



local SETTINGS = {
  back_bone = 24816,
  x = 0.15,
  y = -0.15,
  z = -0.01,
  x_rotation = 0.0,
  y_rotation = -165.0,
  z_rotation = 0.0,
  compatable_weapon_hashes = {
    -- melee:
    --["prop_golf_iron_01"] = 1141786504, -- positioning still needs work
    ["w_me_bat"] = -1786099057,
    -- assault rifles:
    ["w_ar_carbinerifle"] = -2084633992,
    ["w_ar_carbineriflemk2"] = GetHashKey("WEAPON_CARBINERIFLE_Mk2"),
    ["w_ar_assaultrifle"] = -1074790547,
    ["w_ar_specialcarbine"] = -1063057011,
    ["w_ar_bullpuprifle"] = 2132975508,
    ["w_ar_advancedrifle"] = -1357824103,
    -- sub machine guns:
    ["w_sb_microsmg"] = 324215364,
    ["w_sb_assaultsmg"] = -270015777,
    ["w_sb_smg"] = 736523883,
    ["w_sb_smgmk2"] = GetHashKey("WEAPON_SMGMk2"),
    ["w_sb_gusenberg"] = 1627465347,
    -- sniper rifles:
    ["w_sr_sniperrifle"] = 100416529,
    -- shotguns:
    ["w_sg_assaultshotgun"] = -494615257,
    ["w_sg_bullpupshotgun"] = -1654528753,
    ["w_sg_pumpshotgun"] = 487013001,
    ["w_ar_musket"] = -1466123874,
    ["w_sg_heavyshotgun"] = GetHashKey("WEAPON_HEAVYSHOTGUN"),
    -- ["w_sg_sawnoff"] = 2017895192 don't show, maybe too small?
    -- launchers:
    ["w_lr_firework"] = 2138347493
  }
}

local SETTINGS2 = {
  back_bone = 11816,
  x = -0.005,
  y = -0.13,
  z = 0.12,
  x_rotation = 190.0,
  y_rotation = 190.0,
  z_rotation = 180.0,
  compatable_weapon_hashes = {
    ["w_pi_pistol"] = GetHashKey("WEAPON_PISTOL"),
    ["w_pi_combatpistol"] = GetHashKey("WEAPON_COMBATPISTOL"),
    ["w_pi_50pistol"] = GetHashKey("WEAPON_50PISTOL"),
    ["w_pi_heavypistol"] = GetHashKey("WEAPON_HEAVYPISTOL"),
  }
}

local armasmochila = {
  "weapon_bat",
  "weapon_carbinerifle",
  "weapon_carbineriflemk2",
  "weapon_assaultrifle",
  "weapon_specialcarbine",
  "weapon_bullpuprifle",
  "weapon_advancedrifle",
  "weapon_assaultsmg",
  "weapon_smg",
  "weapon_smgmk2",
  "weapon_gusenberg",
  "weapon_sniperrifle",
  "weapon_assaultshotgun",
  "weapon_bullpupshotgun",
  "weapon_pumpshotgun",
  "weapon_musket",
  "weapon_heavyshotgun"
}


local SETTINGS3 = {
  back_bone = 11816,
  x = -0.15,
  y = -0.14,
  z = -0.12,
  x_rotation = 0.0,
  y_rotation = 90.0,
  z_rotation = 0.0,
  compatable_weapon_hashes = {
    ["w_me_knife_01"] = GetHashKey("WEAPON_KNIFE"),
  }
}


local attached_weapons = {}


RegisterCommand('armas', function()
  local conmochila = false

  local ped = PlayerPedId()

  for i = 1, #armasmochila, 1 do
    if HasPedGotWeapon(ped, GetHashKey(armasmochila[i])) then
      conmochila = true
    end
  end
  
  if IsPedArmed(ped, -1) then
    ESX.ShowNotification('No hagas esto si tienes un arma en la mano')
  else


    if conmochila then

      TriggerEvent('skinchanger:getSkin', function(skin) plySkin = skin; end)
      if (plySkin["bags_1"] ~= 0 or plySkin["bags_2"] ~= 0) then

          if fuera then
            oculto = true
            fuera = false
            ExecuteCommand('do se le veria esconder sus armas en la mochila')
            playAnim('reaction@intimidation@1h', 'outro', 1500)

          else
            fuera = true
            oculto = false
            ExecuteCommand('do se le veria sacar sus armas de la mochila')
            playAnim('reaction@intimidation@1h', 'intro', 1500)
            Citizen.Wait(1400)

              for wep_name2, wep_hash2 in pairs(SETTINGS.compatable_weapon_hashes) do
                if HasPedGotWeapon(ped, wep_hash2, false) then
                  AttachWeapon(wep_name2, wep_hash2, SETTINGS.back_bone, SETTINGS.x, SETTINGS.y, SETTINGS.z, SETTINGS.x_rotation, SETTINGS.y_rotation, SETTINGS.z_rotation, isMeleeWeapon(wep_name2))
                end
              end

            for wep_name3, wep_hash3 in pairs(SETTINGS2.compatable_weapon_hashes) do
              if HasPedGotWeapon(ped, wep_hash3, false) then
                AttachWeapon(wep_name3, wep_hash3, SETTINGS2.back_bone, SETTINGS2.x, SETTINGS2.y, SETTINGS2.z, SETTINGS2.x_rotation, SETTINGS2.y_rotation, SETTINGS2.z_rotation, isMeleeWeapon(wep_name3))
              end
            end

            for wep_name4, wep_hash4 in pairs(SETTINGS3.compatable_weapon_hashes) do
              if HasPedGotWeapon(ped, wep_hash4, false) then
                AttachWeapon(wep_name4, wep_hash4, SETTINGS3.back_bone, SETTINGS3.x, SETTINGS3.y, SETTINGS3.z, SETTINGS3.x_rotation, SETTINGS3.y_rotation, SETTINGS3.z_rotation, isMeleeWeapon(wep_name4))
              end
            end


          end

      else
        ESX.ShowNotification('Necesitas una mochila para guardar las armas')
      end

    else

        if fuera then
          oculto = true
          fuera = false
          ExecuteCommand('do se le veria esconder sus armas entre la ropa')
          playAnim('reaction@intimidation@1h', 'outro', 1500)

        else
          fuera = true
          oculto = false
          ExecuteCommand('do se le veria sacar sus armas de la ropa')
          playAnim('reaction@intimidation@1h', 'intro', 1500)
          Citizen.Wait(1400)

            for wep_name2, wep_hash2 in pairs(SETTINGS.compatable_weapon_hashes) do
              if HasPedGotWeapon(ped, wep_hash2, false) then
                AttachWeapon(wep_name2, wep_hash2, SETTINGS.back_bone, SETTINGS.x, SETTINGS.y, SETTINGS.z, SETTINGS.x_rotation, SETTINGS.y_rotation, SETTINGS.z_rotation, isMeleeWeapon(wep_name2))
              end
            end

          for wep_name3, wep_hash3 in pairs(SETTINGS2.compatable_weapon_hashes) do
            if HasPedGotWeapon(ped, wep_hash3, false) then
              AttachWeapon(wep_name3, wep_hash3, SETTINGS2.back_bone, SETTINGS2.x, SETTINGS2.y, SETTINGS2.z, SETTINGS2.x_rotation, SETTINGS2.y_rotation, SETTINGS2.z_rotation, isMeleeWeapon(wep_name3))
            end
          end

          for wep_name4, wep_hash4 in pairs(SETTINGS3.compatable_weapon_hashes) do
            if HasPedGotWeapon(ped, wep_hash4, false) then
              AttachWeapon(wep_name4, wep_hash4, SETTINGS3.back_bone, SETTINGS3.x, SETTINGS3.y, SETTINGS3.z, SETTINGS3.x_rotation, SETTINGS3.y_rotation, SETTINGS3.z_rotation, isMeleeWeapon(wep_name4))
            end
          end

    end
  end

  end
end)


Citizen.CreateThread(function()
  while true do

    Wait(1000)

    local me = PlayerPedId()
    
    for wep_name, wep_hash in pairs(SETTINGS.compatable_weapon_hashes) do
      if fuera then
        if HasPedGotWeapon(me, wep_hash, false) then
            if not attached_weapons[wep_name] then
                AttachWeapon(wep_name, wep_hash, SETTINGS.back_bone, SETTINGS.x, SETTINGS.y, SETTINGS.z, SETTINGS.x_rotation, SETTINGS.y_rotation, SETTINGS.z_rotation, isMeleeWeapon(wep_name))
            end
          end
        end
    end

    for wep_name2, wep_hash2 in pairs(SETTINGS2.compatable_weapon_hashes) do
      if fuera then
        if HasPedGotWeapon(me, wep_hash2, false) then
            if not attached_weapons[wep_name2] then
                AttachWeapon(wep_name2, wep_hash2, SETTINGS2.back_bone, SETTINGS2.x, SETTINGS2.y, SETTINGS2.z, SETTINGS2.x_rotation, SETTINGS2.y_rotation, SETTINGS2.z_rotation, isMeleeWeapon(wep_name2))
            end
          end
        end
    end

    for wep_name3, wep_hash3 in pairs(SETTINGS3.compatable_weapon_hashes) do
      if fuera then
        if HasPedGotWeapon(me, wep_hash3, false) then
            if not attached_weapons[wep_name3] then
                AttachWeapon(wep_name3, wep_hash3, SETTINGS3.back_bone, SETTINGS3.x, SETTINGS3.y, SETTINGS3.z, SETTINGS3.x_rotation, SETTINGS3.y_rotation, SETTINGS3.z_rotation, isMeleeWeapon(wep_name3))
            end
          end
        end
    end

    for name, attached_object in pairs(attached_weapons) do

        if GetSelectedPedWeapon(me) ==  attached_object.hash or not HasPedGotWeapon(me, attached_object.hash, false) then -- equipped or not in weapon wheel
          DeleteObject(attached_object.handle)
          attached_weapons[name] = nil
        elseif oculto then
          DetachEntity(attached_object.handle)
          DeleteObject(attached_object.handle)
        end
    end
  end
  
end)

function AttachWeapon(attachModel,modelHash,boneNumber,x,y,z,xR,yR,zR, isMelee)
    local bone = GetPedBoneIndex(PlayerPedId(), boneNumber)
    RequestModel(attachModel)

    while not HasModelLoaded(attachModel) do
      Wait(100)
    end

  attached_weapons[attachModel] = {
    hash = modelHash,
    handle = CreateObject(GetHashKey(attachModel), 1.0, 1.0, 1.0, true, true, false)
  }

    if isMelee then x = 0.11 y = -0.14 z = 0.0 xR = -75.0 yR = 185.0 zR = 92.0 end -- reposition for melee items
    if attachModel == "prop_ld_jerrycan_01" then x = x + 0.3 end

      AttachEntityToEntity(attached_weapons[attachModel].handle, PlayerPedId(), bone, x, y, z, xR, yR, zR, 1, 1, 0, 0, 2, 1)
end


function QuitarArmasAtras()
  for name, attached_object in pairs(attached_weapons) do
    attached_weapons[name] = nil
    DeleteObject(attached_object.handle)
  end
end

RegisterNetEvent('armasatras:quitararmas')
AddEventHandler('armasatras:quitararmas', function()
    QuitarArmasAtras()
end)



function isMeleeWeapon(wep_name)
  if wep_name == "prop_golf_iron_01" then
      return true
  elseif wep_name == "w_me_bat" then
      return true
  elseif wep_name == "prop_ld_jerrycan_01" then
    return true
  else
      return false
  end
end

--- NO CULATAZOS
Citizen.CreateThread(function()
  local pausa1 = 500
  while true do
    Citizen.Wait(pausa1)

    pausa1 = 500

    local ped = PlayerPedId()

    if IsPedArmed(ped, 6) then
      pausa1 = 0
      DisableControlAction(1, 140, true)
      DisableControlAction(1, 141, true)
      DisableControlAction(1, 142, true)
    end

    if oculto then
      pausa1 = 0
      DisableControlAction(0, 37, true)
      DisableControlAction(0, 157, true)
      DisableControlAction(0, 158, true)
    end
    
  end
end)

-- /conducir --
local disableShuffle = true

function disableSeatShuffle(flag)
	disableShuffle = flag
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)

		if IsPedInAnyVehicle(PlayerPedId(), false) and disableShuffle then
			if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), 0) == PlayerPedId() then
				if GetIsTaskActive(PlayerPedId(), 165) then
					SetPedIntoVehicle(PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(), false), 0)
				end
			end
		end
		
	end
end)

RegisterNetEvent("SeatShuffle")
AddEventHandler("SeatShuffle", function()
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		disableSeatShuffle(false)
		Citizen.Wait(10000)
		disableSeatShuffle(true)
	else
		CancelEvent()
	end
end)

RegisterCommand("conducir", function(source, args, raw)
	TriggerEvent("SeatShuffle")
end, false)