-- ================================================================================================
-- GUNFIGHT ARENA - CLIENT v3.4 (AVEC MESSAGE D'AIDE)
-- ================================================================================================
-- ✅ CORRECTION : Suppression des notifications spam
-- ✅ Seulement kill feed + récompense visible
-- ✅ NOUVEAU : Message d'aide en haut à gauche
-- ================================================================================================

if not CircleZone then
    print("^1[GF-Client ERROR]^0 CircleZone non trouvé! PolyZone est requis.")
    return
end

-- ================================================================================================
-- VARIABLES LOCALES
-- ================================================================================================
local isInArena = false
local showingUI = false
local arenaBlip = nil
local arenaZone = nil
local justExited = false
local currentZone = nil
local currentBucket = Config.LobbyBucket
local lobbyPed = nil

-- ================================================================================================
-- FONCTION : LOG DEBUG CLIENT
-- ================================================================================================
local function DebugLog(message, type)
    if not Config.DebugClient then return end
    
    local prefix = "^6[GF-Client]^0"
    if type == "error" then
        prefix = "^1[GF-Client ERROR]^0"
    elseif type == "success" then
        prefix = "^2[GF-Client OK]^0"
    elseif type == "ui" then
        prefix = "^4[GF-UI]^0"
    elseif type == "instance" then
        prefix = "^5[GF-Instance]^0"
    elseif type == "ped" then
        prefix = "^3[GF-PED]^0"
    elseif type == "weapon" then
        prefix = "^7[GF-WEAPON]^0"
    end
    
    print(prefix .. " " .. message)
end

-- ================================================================================================
-- FONCTION : AFFICHAGE DE TEXTE 3D
-- ================================================================================================
function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- ================================================================================================
-- 🆕 FONCTION : AFFICHER LE MESSAGE D'AIDE
-- ================================================================================================
local function DrawHelpMessage()
    if not Config.HelpMessage.enabled then return end
    
    local cfg = Config.HelpMessage
    
    -- Mesurer la taille du texte pour le fond
    SetTextFont(cfg.font)
    SetTextScale(cfg.scale, cfg.scale)
    SetTextProportional(1)
    
    -- Préparer le texte pour mesurer sa largeur
    BeginTextCommandGetWidth("STRING")
    AddTextComponentSubstringPlayerName(cfg.text)
    local textWidth = EndTextCommandGetWidth(true)
    
    -- Calculer la hauteur du texte (approximation basée sur le nombre de lignes)
    local lines = 1
    for _ in string.gmatch(cfg.text, "~n~") do
        lines = lines + 1
    end
    local textHeight = (cfg.scale * 0.0185) * lines
    
    -- Dessiner le fond si activé
    if cfg.backgroundColor.enabled then
        local bgX = cfg.position.x + (textWidth / 2)
        local bgY = cfg.position.y + (textHeight / 2)
        local bgWidth = textWidth + (cfg.padding.horizontal * 2)
        local bgHeight = textHeight + (cfg.padding.vertical * 2)
        
        DrawRect(
            bgX,
            bgY,
            bgWidth,
            bgHeight,
            cfg.backgroundColor.r,
            cfg.backgroundColor.g,
            cfg.backgroundColor.b,
            cfg.backgroundColor.a
        )
    end
    
    -- Dessiner le texte
    SetTextFont(cfg.font)
    SetTextScale(cfg.scale, cfg.scale)
    SetTextProportional(1)
    SetTextColour(cfg.color.r, cfg.color.g, cfg.color.b, cfg.color.a)
    SetTextEntry("STRING")
    SetTextJustification(0) -- Alignement à gauche
    AddTextComponentSubstringPlayerName(cfg.text)
    DrawText(cfg.position.x, cfg.position.y)
end

-- ================================================================================================
-- 🆕 THREAD : AFFICHAGE DU MESSAGE D'AIDE EN JEU
-- ================================================================================================
Citizen.CreateThread(function()
    DebugLog("Thread message d'aide démarré")
    
    while true do
        Citizen.Wait(Config.Threads.helpMessage)
        
        if isInArena and Config.HelpMessage.enabled then
            DrawHelpMessage()
        end
    end
end)

-- ================================================================================================
-- CRÉATION DU BLIP DU LOBBY
-- ================================================================================================
if Config.LobbyBlip.enabled then
    Citizen.CreateThread(function()
        DebugLog("Création blip lobby")
        local blip = AddBlipForCoord(Config.LobbyPed.pos.x, Config.LobbyPed.pos.y, Config.LobbyPed.pos.z)
        SetBlipSprite(blip, Config.LobbyBlip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.LobbyBlip.scale)
        SetBlipColour(blip, Config.LobbyBlip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.LobbyBlip.name)
        EndTextCommandSetBlipName(blip)
        DebugLog("Blip créé", "success")
    end)
end

-- ================================================================================================
-- CRÉATION DU PED DU LOBBY
-- ================================================================================================
Citizen.CreateThread(function()
    if not Config.LobbyPed.enabled then
        DebugLog("PED du lobby désactivé", "ped")
        return
    end
    
    DebugLog("Création PED lobby", "ped")
    
    local modelHash = GetHashKey(Config.LobbyPed.model)
    RequestModel(modelHash)
    
    while not HasModelLoaded(modelHash) do
        DebugLog("Chargement modèle...", "ped")
        Citizen.Wait(100)
    end
    
    DebugLog("Modèle chargé", "success")
    
    lobbyPed = CreatePed(4, modelHash, Config.LobbyPed.pos.x, Config.LobbyPed.pos.y, Config.LobbyPed.pos.z, Config.LobbyPed.heading, false, true)
    
    SetEntityAlpha(lobbyPed, 255, false)
    SetEntityAsMissionEntity(lobbyPed, true, true)
    SetPedFleeAttributes(lobbyPed, 0, 0)
    SetPedDiesWhenInjured(lobbyPed, false)
    SetPedKeepTask(lobbyPed, true)
    SetBlockingOfNonTemporaryEvents(lobbyPed, Config.LobbyPed.blockevents)
    
    if Config.LobbyPed.frozen then
        FreezeEntityPosition(lobbyPed, true)
    end
    
    if Config.LobbyPed.invincible then
        SetEntityInvincible(lobbyPed, true)
    end
    
    if Config.LobbyPed.scenario and Config.LobbyPed.scenario ~= "" then
        TaskStartScenarioInPlace(lobbyPed, Config.LobbyPed.scenario, 0, true)
    end
    
    SetModelAsNoLongerNeeded(modelHash)
    DebugLog("PED créé avec succès", "success")
end)

-- ================================================================================================
-- THREAD : INTERACTION AVEC LE PED
-- ================================================================================================
Citizen.CreateThread(function()
    DebugLog("Thread interaction PED démarré")
    
    while true do
        Citizen.Wait(Config.Threads.pedInteraction)
        
        if not Config.LobbyPed.enabled or not lobbyPed or not DoesEntityExist(lobbyPed) then
            Citizen.Wait(1000)
            goto continue
        end
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local pedCoords = GetEntityCoords(lobbyPed)
        local dist = #(playerCoords - pedCoords)
        
        if dist < Config.PedInteractDistance and not justExited and not isInArena then
            Draw3DText(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, "Appuyez sur [E] pour rejoindre l'arène")
            
            if IsControlJustPressed(0, Config.InteractKey) and not showingUI then
                DebugLog("Ouverture UI", "ui")
                
                TriggerServerEvent('gunfightarena:requestZoneUpdate')
                
                local zoneData = {}
                for i = 1, 4 do
                    local zoneCfg = Config["Zone" .. i]
                    if zoneCfg and zoneCfg.enabled then
                        table.insert(zoneData, {
                            label = "Zone " .. i,
                            image = zoneCfg.image,
                            zone = i
                        })
                    end
                end
                
                SetNuiFocus(true, true)
                SendNUIMessage({
                    action = "show",
                    zones = zoneData
                })
                showingUI = true
                DebugLog("UI ouverte", "success")
            end
        end
        
        ::continue::
    end
end)

-- ================================================================================================
-- CALLBACK NUI : FERMETURE UI
-- ================================================================================================
RegisterNUICallback('closeUI', function(data, cb)
    DebugLog("Fermeture UI", "ui")
    SetNuiFocus(false, false)
    showingUI = false
    cb('ok')
end)

-- ================================================================================================
-- CALLBACK NUI : SÉLECTION ZONE
-- ================================================================================================
RegisterNUICallback('zoneSelected', function(data, cb)
    DebugLog("Zone sélectionnée: " .. data.zone, "ui")
    TriggerServerEvent('gunfightarena:joinRequest', data.zone)
    cb('ok')
end)

-- ================================================================================================
-- EVENT : REJOINDRE/RESPAWN ARÈNE (SANS NOTIFICATIONS)
-- ================================================================================================
RegisterNetEvent('gunfightarena:join')
AddEventHandler('gunfightarena:join', function(zoneIdentifier)
    DebugLog("Rejoindre/Respawn zone: " .. zoneIdentifier)
    
    local playerPed = PlayerPedId()
    local spawnData = nil

    if zoneIdentifier == 0 then
        if currentZone then
            local respawnPoints = Config["Zone" .. currentZone].respawnPoints
            spawnData = respawnPoints[math.random(1, #respawnPoints)]
        end
    else
        currentZone = zoneIdentifier
        local respawnPoints = Config["Zone" .. zoneIdentifier].respawnPoints
        spawnData = respawnPoints[math.random(1, #respawnPoints)]
    end

    if spawnData then
        NetworkResurrectLocalPlayer(spawnData.pos.x, spawnData.pos.y, spawnData.pos.z, spawnData.heading, true, false)
        ClearPedTasksImmediately(playerPed)
        SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
        
        -- ✅ Attribution de l'arme via le bridge
        DebugLog("Attribution de l'arme via le bridge", "weapon")
        InventoryBridge.GiveWeapon(Config.WeaponHash, Config.WeaponAmmo)
        
        SetEntityInvincible(playerPed, true)
        SetEntityAlpha(playerPed, Config.SpawnAlpha, false)
        
        Citizen.SetTimeout(Config.SpawnAlphaDuration, function()
            SetEntityAlpha(playerPed, 255, false)
        end)
        
        Citizen.SetTimeout(Config.InvincibilityTime, function()
            SetEntityInvincible(playerPed, false)
        end)
    end

    isInArena = true

    local zoneCfg = Config["Zone" .. currentZone]
    if zoneCfg and not arenaBlip then
        arenaBlip = AddBlipForRadius(zoneCfg.center, zoneCfg.radius)
        SetBlipColour(arenaBlip, 1)
        SetBlipAlpha(arenaBlip, 128)
    end
    
    if zoneCfg and not arenaZone then
        arenaZone = CircleZone:Create(zoneCfg.center, zoneCfg.radius, {
            name = "gunfight_zone" .. currentZone,
            debugPoly = Config.PolyZoneDebug,
            useZ = true
        })
        
        Citizen.CreateThread(function()
            while isInArena do
                Citizen.Wait(Config.Threads.zoneCheck)
                local playerPos = GetEntityCoords(PlayerPedId())
                if arenaZone and not arenaZone:isPointInside(playerPos) then
                    DebugLog("Joueur hors zone, sortie automatique", "error")
                    TriggerEvent('gunfightarena:exitZone')
                    break
                end
            end
        end)
    end

    if showingUI then
        SetNuiFocus(false, false)
        showingUI = false
    end
end)

-- ================================================================================================
-- EVENT : SORTIE DE ZONE (SANS NOTIFICATIONS)
-- ================================================================================================
RegisterNetEvent('gunfightarena:exitZone')
AddEventHandler('gunfightarena:exitZone', function()
    DebugLog("=== SORTIE DE ZONE ===")
    
    if isInArena then
        TriggerServerEvent('gunfightarena:leaveArena')
        DebugLog("Notification serveur envoyée (nettoyage instance)", "success")
        
        isInArena = false
        justExited = true
        
        Citizen.Wait(3000)
        
        if arenaBlip then
            RemoveBlip(arenaBlip)
            arenaBlip = nil
        end
        
        if arenaZone then
            arenaZone:destroy()
            arenaZone = nil
        end
        
        -- ✅ Retrait de l'arme via le bridge
        DebugLog("Retrait de l'arme via le bridge", "weapon")
        InventoryBridge.RemoveWeapon(Config.WeaponHash)
        
        SetEntityCoords(PlayerPedId(), Config.LobbySpawn.x, Config.LobbySpawn.y, Config.LobbySpawn.z)
        if Config.LobbySpawnHeading then
            SetEntityHeading(PlayerPedId(), Config.LobbySpawnHeading)
        end
        
        currentZone = nil
        
        Citizen.Wait(1000)
        justExited = false
        
        SendNUIMessage({ action = "clearKillFeed" })
    end
    
    DebugLog("======================", "success")
end)

-- ================================================================================================
-- EVENT : SORTIE MANUELLE (SANS NOTIFICATIONS)
-- ================================================================================================
RegisterNetEvent('gunfightarena:exit')
AddEventHandler('gunfightarena:exit', function()
    DebugLog("Sortie manuelle")
    
    if isInArena then
        isInArena = false
    end
    
    if arenaBlip then
        RemoveBlip(arenaBlip)
        arenaBlip = nil
    end
    if arenaZone then
        arenaZone:destroy()
        arenaZone = nil
    end
    
    -- ✅ Retrait de l'arme via le bridge
    DebugLog("Retrait de l'arme via le bridge", "weapon")
    InventoryBridge.RemoveWeapon(Config.WeaponHash)
    
    SetEntityCoords(PlayerPedId(), Config.LobbySpawn.x, Config.LobbySpawn.y, Config.LobbySpawn.z)
    if Config.LobbySpawnHeading then
        SetEntityHeading(PlayerPedId(), Config.LobbySpawnHeading)
    end
    
    currentZone = nil
end)

-- ================================================================================================
-- THREAD : GESTION MORT (SANS NOTIFICATIONS)
-- ================================================================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Threads.deathCheck)
        
        if isInArena then
            local playerPed = PlayerPedId()
            
            if IsEntityDead(playerPed) then
                local randomIndex = nil
                if currentZone then
                    local respawnPoints = Config["Zone" .. currentZone].respawnPoints
                    randomIndex = math.random(1, #respawnPoints)
                end

                if randomIndex then
                    local killerPed = GetPedSourceOfDeath(playerPed)
                    local killerServerId = nil
                    
                    if killerPed and killerPed ~= 0 then
                        local killerPlayer = NetworkGetPlayerIndexFromPed(killerPed)
                        if killerPlayer and killerPlayer ~= -1 then
                            killerServerId = GetPlayerServerId(killerPlayer)
                        end
                    end
                    
                    TriggerServerEvent('gunfightarena:playerDied', randomIndex, killerServerId)
                end
                
                Citizen.Wait(Config.RespawnDelay)
            end
        end
    end
end)

-- ================================================================================================
-- THREAD : MARQUEUR ZONE
-- ================================================================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Threads.zoneMarker)
        
        if isInArena and currentZone then
            local zoneCfg = Config["Zone" .. currentZone]
            if zoneCfg then
                DrawMarker(
                    1,
                    zoneCfg.center.x, zoneCfg.center.y, zoneCfg.center.z,
                    0, 0, 0,
                    0, 0, 0,
                    zoneCfg.radius * 2, zoneCfg.radius * 2, 100.0,
                    zoneCfg.markerColor.r, zoneCfg.markerColor.g, 
                    zoneCfg.markerColor.b, zoneCfg.markerColor.a,
                    false, true, 2, false, nil, nil, false)
            end
        end
    end
end)

-- ================================================================================================
-- EVENT : KILL FEED
-- ================================================================================================
RegisterNetEvent('gunfightarena:killFeed')
AddEventHandler('gunfightarena:killFeed', function(killerName, victimName, headshot, multiplier, killerId)
    if isInArena then
        if GetPlayerServerId(PlayerId()) == killerId then
            local playerPed = PlayerPedId()
            SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
        end

        SendNUIMessage({
            action = "killFeed",
            message = {
                killer = killerName,
                victim = victimName,
                headshot = headshot,
                multiplier = multiplier
            }
        })
    end
end)

-- ================================================================================================
-- COMMANDE : TEST KILL FEED
-- ================================================================================================
RegisterCommand(Config.TestKillFeedCommand, function()
    local fakeMessage = {
        killer = "TestKiller" .. math.random(1, 10),
        victim = "TestVictim" .. math.random(1, 10),
        headshot = (math.random() > 0.5),
        multiplier = math.random(1, 5)
    }
    SendNUIMessage({
        action = "killFeed",
        message = fakeMessage
    })
end, false)

-- ================================================================================================
-- THREAD : STAMINA INFINIE
-- ================================================================================================
if Config.InfiniteStamina then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.Threads.staminaReset)
            
            if isInArena then
                ResetPlayerStamina(PlayerId())
            end
        end
    end)
end

-- ================================================================================================
-- THREAD : LEADERBOARD (TOUCHE G - STATS DE SESSION ZONE ACTUELLE)
-- ================================================================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if isInArena and IsControlJustPressed(0, Config.LeaderboardKey) then
            TriggerServerEvent('gunfightarena:getZoneStats', currentZone)
        end
    end
end)

-- ================================================================================================
-- EVENTS : STATISTIQUES
-- ================================================================================================
RegisterNetEvent('gunfightarena:statsData')
AddEventHandler('gunfightarena:statsData', function(leaderboard)
    SendNUIMessage({ action = "showStats", stats = leaderboard })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('gunfightarena:personalStatsData')
AddEventHandler('gunfightarena:personalStatsData', function(personalStats)
    SendNUIMessage({ action = "showPersonalStats", stats = personalStats })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('gunfightarena:globalLeaderboardData')
AddEventHandler('gunfightarena:globalLeaderboardData', function(leaderboard)
    SendNUIMessage({ action = "showGlobalLeaderboard", stats = leaderboard })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('gunfightarena:updateZonePlayers')
AddEventHandler('gunfightarena:updateZonePlayers', function(zones)
    SendNUIMessage({
        action = "updateZonePlayers",
        zones = zones
    })
end)

RegisterNetEvent('gunfightarena:lobbyScoreboardData')
AddEventHandler('gunfightarena:lobbyScoreboardData', function(scoreboard)
    SendNUIMessage({ action = "showLobbyScoreboard", stats = scoreboard })
end)

-- ================================================================================================
-- CALLBACKS NUI : STATS
-- ================================================================================================
RegisterNUICallback('getPersonalStats', function(data, cb)
    TriggerServerEvent('gunfightarena:getPersonalStats')
    cb('ok')
end)

RegisterNUICallback('getGlobalLeaderboard', function(data, cb)
    TriggerServerEvent('gunfightarena:getGlobalLeaderboard')
    cb('ok')
end)

RegisterNUICallback('getLobbyScoreboard', function(data, cb)
    TriggerServerEvent('gunfightarena:getLobbyScoreboard')
    cb('ok')
end)

RegisterNUICallback('closeStatsUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closePersonalStatsUI', function(data, cb)
    cb('ok')
end)

RegisterNUICallback('closeGlobalLeaderboardUI', function(data, cb)
    cb('ok')
end)

-- ================================================================================================
-- NETTOYAGE
-- ================================================================================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if lobbyPed and DoesEntityExist(lobbyPed) then
        DeleteEntity(lobbyPed)
    end
end)

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Wait(1000)
    print("^2[Gunfight Arena v3.4-Help]^0 Client démarré")
    print("^3[Gunfight Arena v3.4-Help]^0 Notifications spam supprimées")
    print("^3[Gunfight Arena v3.4-Help]^0 Touche G: Stats de zone en cours")
    print("^3[Gunfight Arena v3.4-Help]^0 Message d'aide: " .. (Config.HelpMessage.enabled and "ACTIVÉ" or "DÉSACTIVÉ"))
end)
