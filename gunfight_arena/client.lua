-- ================================================================================================
-- GUNFIGHT ARENA - CLIENT (CORRIGÉ)
-- ================================================================================================
-- Gestion côté client : UI, zones, respawn, stamina, marqueurs
-- FIX: Ajout des callbacks NUI pour libérer le focus correctement
-- ================================================================================================

-- Vérification de CircleZone (dépendance PolyZone)
if not CircleZone then
    print("^1[GF-Client ERROR]^0 CircleZone non trouvé! PolyZone est requis.")
    return
end

-- ================================================================================================
-- VARIABLES LOCALES
-- ================================================================================================
local isInArena = false                 -- Le joueur est-il dans une arène?
local showingUI = false                 -- L'UI de sélection est-elle affichée?
local arenaBlip = nil                   -- Blip de la zone d'arène
local arenaZone = nil                   -- Zone PolyZone de l'arène
local justExited = false                -- Empêche la réouverture immédiate du menu
local currentZone = nil                 -- Zone actuelle du joueur (1, 2, 3 ou 4)
local currentBucket = Config.LobbyBucket -- Bucket actuel du joueur

-- Point du lobby (interaction)
local lobbyPoint = vector3(Config.InteractionPoint.x, Config.InteractionPoint.y, Config.InteractionPoint.z)

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
-- CRÉATION DU BLIP DU LOBBY
-- ================================================================================================
if Config.LobbyBlip.enabled then
    Citizen.CreateThread(function()
        DebugLog("=== CRÉATION BLIP LOBBY ===")
        local blip = AddBlipForCoord(lobbyPoint.x, lobbyPoint.y, lobbyPoint.z)
        SetBlipSprite(blip, Config.LobbyBlip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.LobbyBlip.scale)
        SetBlipColour(blip, Config.LobbyBlip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.LobbyBlip.name)
        EndTextCommandSetBlipName(blip)
        DebugLog("Blip créé aux coordonnées: " .. lobbyPoint, "success")
        DebugLog("===========================")
    end)
end

-- ================================================================================================
-- THREAD : AFFICHAGE DU MARQUEUR ET INVITE AU LOBBY
-- ================================================================================================
Citizen.CreateThread(function()
    DebugLog("Thread marqueur lobby démarré")
    
    while true do
        Citizen.Wait(Config.Threads.lobbyMarker)
        
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local dist = #(coords - lobbyPoint)
        
        -- Affichage du marqueur si proche
        if dist < Config.LobbyMarkerDistance then
            DrawMarker(
                1,  -- Type de marqueur (cylindre)
                lobbyPoint.x, lobbyPoint.y, lobbyPoint.z - 1.0,
                0, 0, 0,  -- Direction
                0, 0, 0,  -- Rotation
                Config.LobbyCircle.size, Config.LobbyCircle.size, 1.0,  -- Échelle
                Config.LobbyCircle.color.r, Config.LobbyCircle.color.g, 
                Config.LobbyCircle.color.b, Config.LobbyCircle.color.a,
                false, true, 2, false, nil, nil, false
            )
            
            -- Interaction si très proche
            if dist < Config.LobbyInteractDistance and not justExited then
                Draw3DText(lobbyPoint.x, lobbyPoint.y, lobbyPoint.z + 1.0, "Appuyez sur [E] pour rejoindre l'arène")
                
                if IsControlJustPressed(0, Config.InteractKey) and not showingUI then
                    DebugLog("=== OUVERTURE UI ===", "ui")
                    DebugLog("Joueur a appuyé sur E", "ui")

                	-- AJOUT : Demander mise à jour des zones au serveur
                    TriggerServerEvent('gunfightarena:requestZoneUpdate')
                    
                    -- Préparation des données des zones
                    local zoneData = {}
                    for i = 1, 4 do
                        local zoneCfg = Config["Zone" .. i]
                        if zoneCfg and zoneCfg.enabled then
                            table.insert(zoneData, {
                                label = "Zone " .. i,
                                image = zoneCfg.spawn.image,
                                zone = i
                            })
                            DebugLog("Zone " .. i .. " ajoutée à l'UI", "ui")
                        end
                    end
                    
                    -- Envoi à l'interface NUI
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = "show",
                        zones = zoneData
                    })
                    showingUI = true
                    DebugLog("UI ouverte, focus activé", "success")
                    DebugLog("====================")
                end
            end
        end
    end
end)

-- ================================================================================================
-- CALLBACK NUI : FERMETURE DE L'UI
-- ================================================================================================
RegisterNUICallback('closeUI', function(data, cb)
    DebugLog("=== FERMETURE UI ===", "ui")
    SetNuiFocus(false, false)
    showingUI = false
    DebugLog("UI fermée, focus désactivé", "success")
    DebugLog("====================")
    cb('ok')
end)

-- ================================================================================================
-- CALLBACK NUI : SÉLECTION D'UNE ZONE
-- ================================================================================================
RegisterNUICallback('zoneSelected', function(data, cb)
    DebugLog("=== SÉLECTION ZONE ===", "ui")
    DebugLog("Zone sélectionnée: " .. data.zone, "ui")
    TriggerServerEvent('gunfightarena:joinRequest', data.zone)
    DebugLog("Requête envoyée au serveur", "success")
    DebugLog("======================")
    cb('ok')
end)

-- ================================================================================================
-- EVENT : REJOINDRE/RESPAWN DANS L'ARÈNE
-- ================================================================================================
RegisterNetEvent('gunfightarena:join')
AddEventHandler('gunfightarena:join', function(zoneIdentifier)
    DebugLog("=== REJOINDRE/RESPAWN ARÈNE ===")
    DebugLog("Zone identifier: " .. zoneIdentifier)
    
    local playerPed = PlayerPedId()
    local spawnData = nil

    -- Identifier = 0 : respawn aléatoire dans la zone actuelle
    if zoneIdentifier == 0 then
        if currentZone then
            DebugLog("Respawn aléatoire dans la zone actuelle: " .. currentZone)
            local respawnPoints = Config["Zone" .. currentZone].respawnPoints
            spawnData = respawnPoints[math.random(1, #respawnPoints)]
            DebugLog("Point de respawn sélectionné: " .. json.encode(spawnData))
        else
            DebugLog("Pas de zone actuelle pour le respawn!", "error")
        end
    else
        -- Nouveau spawn : mise à jour de la zone actuelle
        currentZone = zoneIdentifier
        spawnData = Config["Zone" .. zoneIdentifier].spawn
        DebugLog("Nouveau spawn dans la zone " .. zoneIdentifier)
        DebugLog("Données de spawn: " .. json.encode(spawnData))
    end

    -- Téléportation et réanimation
    if spawnData then
        DebugLog("Téléportation du joueur...")
        
        -- Réanimation native de FiveM
        NetworkResurrectLocalPlayer(spawnData.pos.x, spawnData.pos.y, spawnData.pos.z, spawnData.heading, true, false)
        ClearPedTasksImmediately(playerPed)
        SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
        
        DebugLog("Joueur réanimé", "success")
        
        -- Attribution de l'arme
        GiveWeaponToPed(playerPed, GetHashKey(Config.WeaponHash), Config.WeaponAmmo, false, true)
        SetPedAmmo(playerPed, GetHashKey(Config.WeaponHash), Config.WeaponAmmo)
        DebugLog("Arme donnée: " .. Config.WeaponHash .. " avec " .. Config.WeaponAmmo .. " munitions")
        
        -- Invincibilité temporaire et transparence
        SetEntityInvincible(playerPed, true)
        SetEntityAlpha(playerPed, Config.SpawnAlpha, false)
        DebugLog("Invincibilité activée pour " .. Config.InvincibilityTime .. "ms")
        
        Citizen.SetTimeout(Config.SpawnAlphaDuration, function()
            SetEntityAlpha(playerPed, 255, false)
            DebugLog("Transparence désactivée")
        end)
        
        Citizen.SetTimeout(Config.InvincibilityTime, function()
            SetEntityInvincible(playerPed, false)
            DebugLog("Invincibilité désactivée", "success")
        end)
    else
        DebugLog("Données de spawn introuvables!", "error")
    end

    -- Marquage comme "dans l'arène"
    isInArena = true
    TriggerEvent('esx:showNotification', Config.Messages.enterArena)

    -- Création du blip de zone
    local zoneCfg = Config["Zone" .. currentZone]
    if zoneCfg and not arenaBlip then
        DebugLog("Création du blip de zone...")
        arenaBlip = AddBlipForRadius(zoneCfg.spawn.pos, zoneCfg.radius)
        SetBlipColour(arenaBlip, 1)
        SetBlipAlpha(arenaBlip, 128)
        DebugLog("Blip de zone créé", "success")
    end
    
    -- Création de la zone PolyZone
    if zoneCfg and not arenaZone then
        DebugLog("Création de la CircleZone...")
        arenaZone = CircleZone:Create(zoneCfg.spawn.pos, zoneCfg.radius, {
            name = "gunfight_zone" .. currentZone,
            debugPoly = Config.PolyZoneDebug,
            useZ = true
        })
        DebugLog("CircleZone créée", "success")
        
        -- Thread de vérification de sortie de zone
        Citizen.CreateThread(function()
            while isInArena do
                Citizen.Wait(Config.Threads.zoneCheck)
                local playerPos = GetEntityCoords(PlayerPedId())
                if arenaZone and not arenaZone:isPointInside(playerPos) then
                    DebugLog("Joueur hors de la zone, déclenchement de la sortie", "error")
                    TriggerEvent('gunfightarena:exitZone')
                    break
                end
            end
        end)
    end

    -- Fermeture de l'UI si ouverte
    if showingUI then
        SetNuiFocus(false, false)
        showingUI = false
        DebugLog("UI fermée après le spawn", "ui")
    end
    
    DebugLog("===============================", "success")
end)

-- ================================================================================================
-- EVENT : SORTIE DE LA ZONE D'ARÈNE
-- ================================================================================================
RegisterNetEvent('gunfightarena:exitZone')
AddEventHandler('gunfightarena:exitZone', function()
    DebugLog("=== SORTIE DE ZONE ===")
    
    if isInArena then
        isInArena = false
        justExited = true
        TriggerEvent('esx:showNotification', Config.Messages.exitArena)
        
        DebugLog("Attente de 3 secondes...")
        Citizen.Wait(3000)
        
        -- Nettoyage du blip
        if arenaBlip then
            RemoveBlip(arenaBlip)
            arenaBlip = nil
            DebugLog("Blip supprimé")
        end
        
        -- Destruction de la zone
        if arenaZone then
            arenaZone:destroy()
            arenaZone = nil
            DebugLog("Zone détruite")
        end
        
        -- Retrait de l'arme
        RemoveWeaponFromPed(PlayerPedId(), GetHashKey(Config.WeaponHash))
        DebugLog("Arme retirée")
        
        -- Téléportation au lobby
        SetEntityCoords(PlayerPedId(), Config.LobbySpawn.x, Config.LobbySpawn.y, Config.LobbySpawn.z)
        if Config.LobbySpawnHeading then
            SetEntityHeading(PlayerPedId(), Config.LobbySpawnHeading)
        end
        DebugLog("Téléporté au lobby")
        
        Citizen.Wait(1000)
        justExited = false
        
        -- Clear kill feed
        SendNUIMessage({ action = "clearKillFeed" })
        DebugLog("Kill feed nettoyé")
    end
    
    DebugLog("======================", "success")
end)

-- ================================================================================================
-- EVENT : SORTIE MANUELLE (COMMANDE)
-- ================================================================================================
RegisterNetEvent('gunfightarena:exit')
AddEventHandler('gunfightarena:exit', function()
    DebugLog("=== SORTIE MANUELLE ===")
    
    if isInArena then
        isInArena = false
        TriggerEvent('esx:showNotification', Config.Messages.exitArena)
    else
        TriggerEvent('esx:showNotification', Config.Messages.notInArena)
    end
    
    -- Nettoyage
    if arenaBlip then
        RemoveBlip(arenaBlip)
        arenaBlip = nil
    end
    if arenaZone then
        arenaZone:destroy()
        arenaZone = nil
    end
    
    RemoveWeaponFromPed(PlayerPedId(), GetHashKey(Config.WeaponHash))
    SetEntityCoords(PlayerPedId(), Config.LobbySpawn.x, Config.LobbySpawn.y, Config.LobbySpawn.z)
    if Config.LobbySpawnHeading then
        SetEntityHeading(PlayerPedId(), Config.LobbySpawnHeading)
    end
    
    DebugLog("======================", "success")
end)

-- ================================================================================================
-- THREAD : GESTION DE LA MORT DANS L'ARÈNE
-- ================================================================================================
Citizen.CreateThread(function()
    DebugLog("Thread gestion mort démarré")
    
    while true do
        Citizen.Wait(Config.Threads.deathCheck)
        
        if isInArena then
            local playerPed = PlayerPedId()
            
            if IsEntityDead(playerPed) then
                DebugLog("=== JOUEUR MORT ===")
                
                local randomIndex = nil
                if currentZone then
                    local respawnPoints = Config["Zone" .. currentZone].respawnPoints
                    randomIndex = math.random(1, #respawnPoints)
                    DebugLog("Index de respawn sélectionné: " .. randomIndex)
                end

                if randomIndex then
                    -- Détection du killer
                    local killerPed = GetPedSourceOfDeath(playerPed)
                    local killerServerId = nil
                    
                    if killerPed and killerPed ~= 0 then
                        local killerPlayer = NetworkGetPlayerIndexFromPed(killerPed)
                        if killerPlayer and killerPlayer ~= -1 then
                            killerServerId = GetPlayerServerId(killerPlayer)
                            DebugLog("Killer trouvé: " .. killerServerId)
                        end
                    else
                        DebugLog("Pas de killer détecté (suicide/environnement)")
                    end
                    
                    -- Notification au serveur
                    TriggerServerEvent('gunfightarena:playerDied', randomIndex, killerServerId)
                end
                
                DebugLog("Attente de " .. Config.RespawnDelay .. "ms avant respawn")
                Citizen.Wait(Config.RespawnDelay)
                DebugLog("===================")
            end
        end
    end
end)

-- ================================================================================================
-- EVENT : SPAWN DU JOUEUR (INVINCIBILITÉ TEMPORAIRE)
-- ================================================================================================
AddEventHandler('playerSpawned', function(spawn)
    if isInArena then
        DebugLog("=== PLAYER SPAWNED ===")
        SetEntityInvincible(PlayerPedId(), true)
        DebugLog("Invincibilité activée au spawn")
        
        Citizen.SetTimeout(Config.InvincibilityTime, function()
            SetEntityInvincible(PlayerPedId(), false)
            DebugLog("Invincibilité désactivée", "success")
        end)
        DebugLog("======================")
    end
end)

-- ================================================================================================
-- THREAD : AFFICHAGE DU MARQUEUR DE ZONE
-- ================================================================================================
Citizen.CreateThread(function()
    DebugLog("Thread marqueur zone démarré")
    
    while true do
        Citizen.Wait(Config.Threads.zoneMarker)
        
        if isInArena and currentZone then
            local zoneCfg = Config["Zone" .. currentZone]
            if zoneCfg then
                DrawMarker(
                    1,  -- Cylindre
                    zoneCfg.spawn.pos.x, zoneCfg.spawn.pos.y, zoneCfg.spawn.pos.z,
                    0, 0, 0,
                    0, 0, 0,
                    zoneCfg.radius * 2, zoneCfg.radius * 2, 100.0,
                    zoneCfg.markerColor.r, zoneCfg.markerColor.g, 
                    zoneCfg.markerColor.b, zoneCfg.markerColor.a,
                    false, true, 2, false, nil, nil, false
                )
            end
        end
    end
end)

-- ================================================================================================
-- EVENT : RÉCEPTION DU KILL FEED
-- ================================================================================================
RegisterNetEvent('gunfightarena:killFeed')
AddEventHandler('gunfightarena:killFeed', function(killerName, victimName, headshot, multiplier, killerId)
    if isInArena then
        DebugLog("=== KILL FEED ===", "ui")
        DebugLog("Killer: " .. killerName, "ui")
        DebugLog("Victime: " .. victimName, "ui")
        DebugLog("Headshot: " .. tostring(headshot), "ui")
        DebugLog("Multiplier: " .. multiplier, "ui")
        
        -- Si c'est le joueur local qui a tué, restaurer sa vie
        if GetPlayerServerId(PlayerId()) == killerId then
            local playerPed = PlayerPedId()
            SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
            DebugLog("Vie restaurée pour le killer", "success")
        end

        -- Envoi à l'interface NUI
        SendNUIMessage({
            action = "killFeed",
            message = {
                killer = killerName,
                victim = victimName,
                headshot = headshot,
                multiplier = multiplier
            }
        })
        DebugLog("Message envoyé à l'UI", "success")
        DebugLog("=================")
    end
end)

-- ================================================================================================
-- COMMANDE : TEST DU KILL FEED
-- ================================================================================================
RegisterCommand(Config.TestKillFeedCommand, function(source, args, rawCommand)
    DebugLog("=== TEST KILL FEED ===", "ui")
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
    DebugLog("Message de test envoyé", "success")
    DebugLog("======================")
end, false)

-- ================================================================================================
-- THREAD : STAMINA INFINIE DANS L'ARÈNE
-- ================================================================================================
if Config.InfiniteStamina then
    Citizen.CreateThread(function()
        DebugLog("Thread stamina infinie démarré")
        
        while true do
            Citizen.Wait(Config.Threads.staminaReset)
            
            if isInArena then
                ResetPlayerStamina(PlayerId())
            end
        end
    end)
end

-- ================================================================================================
-- THREAD : OUVERTURE DU LEADERBOARD
-- ================================================================================================
Citizen.CreateThread(function()
    DebugLog("Thread leaderboard démarré")
    
    while true do
        Citizen.Wait(0)
        
        if isInArena and IsControlJustPressed(0, Config.LeaderboardKey) then
            DebugLog("=== OUVERTURE LEADERBOARD ===", "ui")
            TriggerServerEvent('gunfightarena:getStats')
            DebugLog("Requête statistiques envoyée", "ui")
            DebugLog("=============================")
        end
    end
end)

-- ================================================================================================
-- EVENT : RÉCEPTION DES STATISTIQUES
-- ================================================================================================
RegisterNetEvent('gunfightarena:statsData')
AddEventHandler('gunfightarena:statsData', function(leaderboard)
    DebugLog("=== RÉCEPTION STATS ===", "ui")
    DebugLog("Nombre d'entrées: " .. #leaderboard, "ui")
    SendNUIMessage({ action = "showStats", stats = leaderboard })
    SetNuiFocus(true, true)
    DebugLog("Leaderboard affiché, focus activé", "success")
    DebugLog("=======================")
end)

-- ================================================================================================
-- EVENT : RÉCEPTION DES STATS PERSONNELLES
-- ================================================================================================
RegisterNetEvent('gunfightarena:personalStatsData')
AddEventHandler('gunfightarena:personalStatsData', function(personalStats)
    DebugLog("=== RÉCEPTION STATS PERSONNELLES ===", "ui")
    DebugLog("Joueur: " .. personalStats.player, "ui")
    DebugLog("Kills: " .. personalStats.kills .. " | Deaths: " .. personalStats.deaths, "ui")
    DebugLog("K/D: " .. personalStats.kd, "ui")
    SendNUIMessage({ action = "showPersonalStats", stats = personalStats })
    SetNuiFocus(true, true)
    DebugLog("Stats personnelles affichées, focus activé", "success")
    DebugLog("====================================")
end)

-- ================================================================================================
-- EVENT : RÉCEPTION DU CLASSEMENT GLOBAL
-- ================================================================================================
RegisterNetEvent('gunfightarena:globalLeaderboardData')
AddEventHandler('gunfightarena:globalLeaderboardData', function(leaderboard)
    DebugLog("=== RÉCEPTION CLASSEMENT GLOBAL ===", "ui")
    DebugLog("Nombre d'entrées: " .. #leaderboard, "ui")
    SendNUIMessage({ action = "showGlobalLeaderboard", stats = leaderboard })
    SetNuiFocus(true, true)
    DebugLog("Classement global affiché, focus activé", "success")
    DebugLog("===================================")
end)

-- ================================================================================================
-- EVENT : MISE À JOUR DES JOUEURS PAR ZONE
-- ================================================================================================
RegisterNetEvent('gunfightarena:updateZonePlayers')
AddEventHandler('gunfightarena:updateZonePlayers', function(zones)
    if Config.DebugClient then
        DebugLog("=== UPDATE ZONES ===", "ui")
        for _, zone in ipairs(zones) do
            DebugLog("Zone " .. zone.zone .. ": " .. zone.players .. "/" .. zone.maxPlayers, "ui")
        end
        DebugLog("====================")
    end
    
    SendNUIMessage({
        action = "updateZonePlayers",
        zones = zones
    })
end)

-- ================================================================================================
-- THREAD : AUTO-JOIN (SI ACTIVÉ)
-- ================================================================================================
if Config.AutoJoin then
    Citizen.CreateThread(function()
        DebugLog("Thread auto-join démarré (intervalle: " .. Config.AutoJoinCheckInterval .. "ms)")
        
        while true do
            Citizen.Wait(Config.AutoJoinCheckInterval)
            
            if not isInArena then
                local playerPed = PlayerPedId()
                local playerPos = GetEntityCoords(playerPed)
                local zoneToJoin = nil
                
                -- Vérifier chaque zone
                for i = 1, 4 do
                    local zoneCfg = Config["Zone" .. i]
                    if zoneCfg and zoneCfg.enabled then
                        if #(playerPos - zoneCfg.spawn.pos) < zoneCfg.radius then
                            zoneToJoin = i
                            DebugLog("Auto-join détecté pour la zone " .. i)
                            break
                        end
                    end
                end

                if zoneToJoin then
                    TriggerServerEvent('gunfightarena:joinRequest', zoneToJoin)
                end
            end
        end
    end)
end

-- ================================================================================================
-- CALLBACK NUI : DEMANDE DE STATS PERSONNELLES
-- ================================================================================================
RegisterNUICallback('getPersonalStats', function(data, cb)
    DebugLog("=== CALLBACK STATS PERSONNELLES ===", "ui")
    TriggerServerEvent('gunfightarena:getPersonalStats')
    DebugLog("Requête envoyée au serveur", "success")
    DebugLog("===================================")
    cb('ok')
end)

-- ================================================================================================
-- CALLBACK NUI : DEMANDE DU CLASSEMENT GLOBAL
-- ================================================================================================
RegisterNUICallback('getGlobalLeaderboard', function(data, cb)
    DebugLog("=== CALLBACK CLASSEMENT GLOBAL ===", "ui")
    TriggerServerEvent('gunfightarena:getGlobalLeaderboard')
    DebugLog("Requête envoyée au serveur", "success")
    DebugLog("==================================")
    cb('ok')
end)

-- ================================================================================================
-- CALLBACK NUI : DEMANDE DU LOBBY SCOREBOARD
-- ================================================================================================
RegisterNUICallback('getLobbyScoreboard', function(data, cb)
    DebugLog("=== CALLBACK LOBBY SCOREBOARD ===", "ui")
    TriggerServerEvent('gunfightarena:getLobbyScoreboard')
    DebugLog("Requête envoyée au serveur", "success")
    DebugLog("=================================")
    cb('ok')
end)

-- ================================================================================================
-- CALLBACK NUI : FERMETURE DU LEADERBOARD (EN JEU - Touche G)
-- ================================================================================================
RegisterNUICallback('closeStatsUI', function(data, cb)
    DebugLog("=== FERMETURE LEADERBOARD ===", "ui")
    -- Libérer le focus NUI car on est EN JEU (pas dans le lobby)
    SetNuiFocus(false, false)
    DebugLog("Focus NUI libéré (retour au jeu)", "success")
    DebugLog("=============================")
    cb('ok')
end)

-- ================================================================================================
-- CALLBACK NUI : FERMETURE DES STATS PERSONNELLES (DEPUIS LE LOBBY)
-- ================================================================================================
RegisterNUICallback('closePersonalStatsUI', function(data, cb)
    DebugLog("=== FERMETURE STATS PERSONNELLES ===", "ui")
    -- NE PAS libérer le focus car on est dans le LOBBY
    -- Le focus reste actif pour pouvoir continuer à interagir avec le lobby
    DebugLog("Fenêtre fermée, focus reste actif (lobby)", "success")
    DebugLog("====================================")
    cb('ok')
end)

-- ================================================================================================
-- CALLBACK NUI : FERMETURE DU CLASSEMENT GLOBAL (DEPUIS LE LOBBY)
-- ================================================================================================
RegisterNUICallback('closeGlobalLeaderboardUI', function(data, cb)
    DebugLog("=== FERMETURE CLASSEMENT GLOBAL ===", "ui")
    -- NE PAS libérer le focus car on est dans le LOBBY
    -- Le focus reste actif pour pouvoir continuer à interagir avec le lobby
    DebugLog("Fenêtre fermée, focus reste actif (lobby)", "success")
    DebugLog("===================================")
    cb('ok')
end)

-- ================================================================================================
-- EVENT : RÉCEPTION DU LOBBY SCOREBOARD
-- ================================================================================================
RegisterNetEvent('gunfightarena:lobbyScoreboardData')
AddEventHandler('gunfightarena:lobbyScoreboardData', function(scoreboard)
    DebugLog("=== RÉCEPTION LOBBY SCOREBOARD ===", "ui")
    DebugLog("Nombre d'entrées: " .. #scoreboard, "ui")
    SendNUIMessage({ action = "showLobbyScoreboard", stats = scoreboard })
    DebugLog("Lobby scoreboard affiché", "success")
    DebugLog("==================================")
end)

-- ================================================================================================
-- THREAD : DÉTECTION DE TÉLÉPORTATION HORS DE LA ZONE
-- ================================================================================================
Citizen.CreateThread(function()
    DebugLog("Thread détection téléportation démarré")
    
    local lastPosition = nil
    
    while true do
        Citizen.Wait(1000)  -- Vérification toutes les secondes
        
        if isInArena and currentZone then
            local playerPed = PlayerPedId()
            local currentPos = GetEntityCoords(playerPed)
            
            if lastPosition then
                -- Calculer la distance parcourue en 1 seconde
                local distance = #(currentPos - lastPosition)
                
                -- Si la distance est supérieure à 500 unités, c'est une téléportation
                if distance > 500 then
                    DebugLog("=== TÉLÉPORTATION DÉTECTÉE ===", "error")
                    DebugLog("Distance parcourue: " .. distance .. " unités", "error")
                    
                    -- Vérifier si le joueur est toujours dans la zone
                    local zoneCfg = Config["Zone" .. currentZone]
                    if zoneCfg then
                        local distFromZone = #(currentPos - zoneCfg.spawn.pos)
                        
                        if distFromZone > zoneCfg.radius then
                            DebugLog("Joueur téléporté hors de la zone, sortie automatique", "error")
                            TriggerEvent('gunfightarena:exitZone')
                        else
                            DebugLog("Téléportation dans la zone, OK", "success")
                        end
                    end
                    
                    DebugLog("==============================")
                end
            end
            
            lastPosition = currentPos
        else
            lastPosition = nil
        end
    end
end)

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Wait(1000)
    DebugLog("========================================", "success")
    DebugLog("GUNFIGHT ARENA CLIENT - DÉMARRÉ", "success")
    DebugLog("Version: 2.0 - FIX FOCUS NUI", "success")
    DebugLog("Debug: " .. (Config.DebugClient and "ACTIVÉ" or "DÉSACTIVÉ"), "success")
    DebugLog("Auto-join: " .. (Config.AutoJoin and "ACTIVÉ" or "DÉSACTIVÉ"), "success")
    DebugLog("========================================", "success")
end)
