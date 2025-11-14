if not CircleZone then
    return
end

local isInArena = false
local showingUI = false
local arenaBlip = nil
local arenaZone = nil
local justExited = false
local currentZone = nil  -- 1, 2, 3 ou 4

local lobbyPoint = vector3(Config.InteractionPoint.x, Config.InteractionPoint.y, Config.InteractionPoint.z)

-------------------------------------------------
-- Affichage de texte 3D
-------------------------------------------------
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

-------------------------------------------------
-- Création du blip du lobby
-------------------------------------------------
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(lobbyPoint.x, lobbyPoint.y, lobbyPoint.z)
    SetBlipSprite(blip, 311)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Gunfight Lobby")
    EndTextCommandSetBlipName(blip)
end)

-------------------------------------------------
-- Affichage du marqueur et de l'invite au lobby
-------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local dist = #(coords - lobbyPoint)
        
        if dist < 50.0 then
            DrawMarker(1, lobbyPoint.x, lobbyPoint.y, lobbyPoint.z - 1.0,
                0, 0, 0, 0, 0, 0,
                Config.LobbyCircle.size, Config.LobbyCircle.size, 1.0,
                Config.LobbyCircle.color.r, Config.LobbyCircle.color.g, Config.LobbyCircle.color.b, Config.LobbyCircle.color.a,
                false, true, 2, false, nil, nil, false)
            if dist < 2.0 and not justExited then
                Draw3DText(lobbyPoint.x, lobbyPoint.y, lobbyPoint.z + 1.0, "Appuyez sur [E] pour rejoindre l'arène")
                if IsControlJustPressed(0, Config.InteractKey) and not showingUI then
                    local zoneData = {
                        { label = "Zone 1", image = Config.Zone1.spawn.image, zone = 1 },
                        { label = "Zone 2", image = Config.Zone2.spawn.image, zone = 2 },
                        { label = "Zone 3", image = Config.Zone3.spawn.image, zone = 3 },
                        { label = "Zone 4", image = Config.Zone4.spawn.image, zone = 4 }
                    }
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = "show", zones = zoneData })
                    showingUI = true
                end
            end
        end
    end
end)

-------------------------------------------------
-- Fermeture de l'UI via NUI callback
-------------------------------------------------
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    showingUI = false
    cb('ok')
end)

-------------------------------------------------
-- Choix de la zone d'arène via NUI callback
-------------------------------------------------
RegisterNUICallback('zoneSelected', function(data, cb)
    TriggerServerEvent('gunfightarena:joinRequest', data.zone)
    cb('ok')
end)

-------------------------------------------------
-- Gestion de l'entrée (et respawn) dans l'arène
-------------------------------------------------
RegisterNetEvent('gunfightarena:join')
AddEventHandler('gunfightarena:join', function(zoneIdentifier)
    local playerPed = PlayerPedId()
    local spawnData = nil

    if zoneIdentifier == 0 then
        if currentZone then
            local respawnPoints = Config["Zone" .. currentZone].respawnPoints
            spawnData = respawnPoints[math.random(1, #respawnPoints)]
        end
    else
        currentZone = zoneIdentifier
        spawnData = Config["Zone" .. zoneIdentifier].spawn
    end

    if spawnData then
        NetworkResurrectLocalPlayer(spawnData.pos.x, spawnData.pos.y, spawnData.pos.z, spawnData.heading, true, false)
        ClearPedTasksImmediately(playerPed)
        SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
        GiveWeaponToPed(playerPed, GetHashKey("weapon_pistol50"), 100, false, true)
        SetPedAmmo(playerPed, GetHashKey("weapon_pistol50"), 100)
        SetEntityInvincible(playerPed, true)
        SetEntityAlpha(playerPed, 128, false)
        Citizen.SetTimeout(2000, function()
            SetEntityInvincible(playerPed, false)
            SetEntityAlpha(playerPed, 255, false)
        end)
    end

    isInArena = true
    TriggerEvent('esx:showNotification', "^2Vous êtes entré dans l'arène.")

    local zoneCfg = Config["Zone" .. currentZone]
    if not arenaBlip then
        arenaBlip = AddBlipForRadius(zoneCfg.spawn.pos, zoneCfg.radius)
        SetBlipColour(arenaBlip, 1)
        SetBlipAlpha(arenaBlip, 128)
    end
    if not arenaZone then
        arenaZone = CircleZone:Create(zoneCfg.spawn.pos, zoneCfg.radius, { name = "gunfight_zone" .. currentZone, debugPoly = false, useZ = true })
        Citizen.CreateThread(function()
            while isInArena do
                Citizen.Wait(500)
                local playerPos = GetEntityCoords(PlayerPedId())
                if arenaZone and not arenaZone:isPointInside(playerPos) then
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

-------------------------------------------------
-- Gestion de la sortie de l'arène (zone ou commande)
-------------------------------------------------
RegisterNetEvent('gunfightarena:exitZone')
AddEventHandler('gunfightarena:exitZone', function()
    if isInArena then
        isInArena = false
        justExited = true
        TriggerEvent('esx:showNotification', "^1Vous avez quitté l'arène.")
        Citizen.Wait(3000)
        if arenaBlip then
            RemoveBlip(arenaBlip)
            arenaBlip = nil
        end
        if arenaZone then
            arenaZone:destroy()
            arenaZone = nil
        end
        RemoveWeaponFromPed(PlayerPedId(), GetHashKey("weapon_pistol50"))
        SetEntityCoords(PlayerPedId(), Config.LobbySpawn.x, Config.LobbySpawn.y, Config.LobbySpawn.z)
        if Config.LobbySpawnHeading then
            SetEntityHeading(PlayerPedId(), Config.LobbySpawnHeading)
        end
        Citizen.Wait(1000)
        justExited = false
        SendNUIMessage({ action = "clearKillFeed" })
    end
end)

RegisterNetEvent('gunfightarena:exit')
AddEventHandler('gunfightarena:exit', function()
    if isInArena then
        isInArena = false
        TriggerEvent('esx:showNotification', "^1Vous avez quitté l'arène.")
    else
        TriggerEvent('esx:showNotification', "Vous n'êtes pas dans l'arène.")
    end
    if arenaBlip then
        RemoveBlip(arenaBlip)
        arenaBlip = nil
    end
    if arenaZone then
        arenaZone:destroy()
        arenaZone = nil
    end
    RemoveWeaponFromPed(PlayerPedId(), GetHashKey("weapon_pistol50"))
    SetEntityCoords(PlayerPedId(), Config.LobbySpawn.x, Config.LobbySpawn.y, Config.LobbySpawn.z)
    if Config.LobbySpawnHeading then
        SetEntityHeading(PlayerPedId(), Config.LobbySpawnHeading)
    end
end)

-------------------------------------------------
-- Gestion continue de la mort dans l'arène
-------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isInArena then
            local playerPed = PlayerPedId()
            if IsEntityDead(playerPed) then
                local randomIndex
                if currentZone then
                    local respawnPoints = Config["Zone" .. currentZone].respawnPoints
                    randomIndex = math.random(1, #respawnPoints)
                end

                if randomIndex then
                    local killerPed = GetPedSourceOfDeath(playerPed)
                    local killerServerId
                    if killerPed and killerPed ~= 0 then
                        local killerPlayer = NetworkGetPlayerIndexFromPed(killerPed)
                        if killerPlayer and killerPlayer ~= -1 then
                            killerServerId = GetPlayerServerId(killerPlayer)
                        end
                    end
                    TriggerServerEvent('gunfightarena:playerDied', randomIndex, killerServerId)
                end
                Citizen.Wait(5000)
            end
        end
    end
end)

-------------------------------------------------
-- Invincibilité temporaire lors du spawn si déjà dans l'arène
-------------------------------------------------
AddEventHandler('playerSpawned', function(spawn)
    if isInArena then
        SetEntityInvincible(PlayerPedId(), true)
        Citizen.SetTimeout(Config.InvincibilityTime, function()
            SetEntityInvincible(PlayerPedId(), false)
        end)
    end
end)

-------------------------------------------------
-- Affichage du marqueur de l'arène
-------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isInArena then
            DrawMarker(
                1,
                (currentZone == 1 and Config.Zone1.spawn.pos.x or 
                 (currentZone == 2 and Config.Zone2.spawn.pos.x or 
                  (currentZone == 3 and Config.Zone3.spawn.pos.x or 
                   (currentZone == 4 and Config.Zone4.spawn.pos.x or 0)))),
                (currentZone == 1 and Config.Zone1.spawn.pos.y or 
                 (currentZone == 2 and Config.Zone2.spawn.pos.y or 
                  (currentZone == 3 and Config.Zone3.spawn.pos.y or 
                   (currentZone == 4 and Config.Zone4.spawn.pos.y or 0)))),
                (currentZone == 1 and Config.Zone1.spawn.pos.z or 
                 (currentZone == 2 and Config.Zone2.spawn.pos.z or 
                  (currentZone == 3 and Config.Zone3.spawn.pos.z or 
                   (currentZone == 4 and Config.Zone4.spawn.pos.z or 0)))),
                0, 0, 0,
                0, 0, 0,
                (currentZone == 1 and Config.Zone1.radius or 
                 (currentZone == 2 and Config.Zone2.radius or 
                  (currentZone == 3 and Config.Zone3.radius or 
                   (currentZone == 4 and Config.Zone4.radius or 0)))) * 2,
                (currentZone == 1 and Config.Zone1.radius or 
                 (currentZone == 2 and Config.Zone2.radius or 
                  (currentZone == 3 and Config.Zone3.radius or 
                   (currentZone == 4 and Config.Zone4.radius or 0)))) * 2,
                100.0,
                255, 0, 0,
                50,
                false, true, 2, false, nil, nil, false
            )
        end
    end
end)

-------------------------------------------------
-- Affichage du Kill Feed en zone d'arène
-------------------------------------------------
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

-------------------------------------------------
-- Commande de test du kill feed
-------------------------------------------------
RegisterCommand("testkillfeed", function(source, args, rawCommand)
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
    TriggerEvent('chat:addMessage', { args = { "^2TestKillFeed :", "Message envoyé !" } })
end, false)

-------------------------------------------------
-- Maintien de la stamina maximale dans l'arène
-------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isInArena then
            ResetPlayerStamina(PlayerId())
        end
    end
end)

-------------------------------------------------
-- Ouverture du leaderboard via une touche (touche 183) en arène
-------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isInArena and IsControlJustPressed(0, 183) then
            TriggerServerEvent('gunfightarena:getStats')
        end
    end
end)

-------------------------------------------------
-- Réception et affichage du leaderboard
-------------------------------------------------
RegisterNetEvent('gunfightarena:statsData')
AddEventHandler('gunfightarena:statsData', function(leaderboard)
    SendNUIMessage({ action = "showStats", stats = leaderboard })
    SetNuiFocus(true, true)
end)

-------------------------------------------------
-- Réception des mises à jour des joueurs par zone
-------------------------------------------------
RegisterNetEvent('gunfightarena:updateZonePlayers')
AddEventHandler('gunfightarena:updateZonePlayers', function(zones)
    SendNUIMessage({
        action = "updateZonePlayers",
        zones = zones
    })
end)

-------------------------------------------------
-- Auto-join : Intégration automatique dans l'arène selon la position
-------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if not isInArena then
            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            local zoneToJoin = nil
            if #(playerPos - Config.Zone1.spawn.pos) < Config.Zone1.radius then
                zoneToJoin = 1
            elseif #(playerPos - Config.Zone2.spawn.pos) < Config.Zone2.radius then
                zoneToJoin = 2
            elseif #(playerPos - Config.Zone3.spawn.pos) < Config.Zone3.radius then
                zoneToJoin = 3
            elseif #(playerPos - Config.Zone4.spawn.pos) < Config.Zone4.radius then
                zoneToJoin = 4
            end

            if zoneToJoin then
                TriggerServerEvent('gunfightarena:joinRequest', zoneToJoin)
            end
        end
    end
end)
