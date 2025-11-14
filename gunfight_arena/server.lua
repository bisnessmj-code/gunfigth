local ESX = exports['es_extended']:getSharedObject()

-- Tables de suivi
local arenaPlayers = {}    -- Suivi des joueurs présents dans l'arène (clé = source)
local PlayerStats = {}     -- Stats (kills, deaths) par joueur (clé = source)
local killStreaks = {}     -- Kill streak par joueur (clé = source)

-- Suivi des zones
local playerZone = {}      -- Zone dans laquelle se trouve chaque joueur (1, 2, 3 ou 4)
local zonePlayerCounts = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }

-------------------------------------------------
-- Fonction utilitaire pour compter les éléments d'une table
-------------------------------------------------
local function tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

-------------------------------------------------
-- Mise à jour des informations des zones et envoi aux clients
-------------------------------------------------
local function updateZonePlayers()
    local zonesData = {
        {
            zone = 1,
            players = zonePlayerCounts[1] or 0,
            maxPlayers = (Config.Zone1 and Config.Zone1.maxPlayers) or 15
        },
        {
            zone = 2,
            players = zonePlayerCounts[2] or 0,
            maxPlayers = (Config.Zone2 and Config.Zone2.maxPlayers) or 15
        },
        {
            zone = 3,
            players = zonePlayerCounts[3] or 0,
            maxPlayers = (Config.Zone3 and Config.Zone3.maxPlayers) or 15
        },
        {
            zone = 4,
            players = zonePlayerCounts[4] or 0,
            maxPlayers = (Config.Zone4 and Config.Zone4.maxPlayers) or 15
        }
    }

    TriggerClientEvent('gunfightarena:updateZonePlayers', -1, zonesData)
end

-------------------------------------------------
-- Commande pour quitter l'arène
-------------------------------------------------
RegisterCommand('quittergf', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        arenaPlayers[source] = nil
        local zone = playerZone[source]
        if zone then
            zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
            playerZone[source] = nil
            updateZonePlayers()
        end
        TriggerClientEvent('esx:showNotification', source, "Vous avez quitté l'arène.")
        TriggerClientEvent('gunfightarena:exit', source)
    end
end, false)

-------------------------------------------------
-- Gestion de la demande de rejoindre l'arène
-------------------------------------------------
RegisterNetEvent('gunfightarena:joinRequest')
AddEventHandler('gunfightarena:joinRequest', function(zoneNumber)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if tablelength(arenaPlayers) >= Config.MaxPlayers then
        TriggerClientEvent('esx:showNotification', src, "L'arène est pleine.")
        return
    end

    arenaPlayers[src] = true
    playerZone[src] = zoneNumber

    zonePlayerCounts[zoneNumber] = (zonePlayerCounts[zoneNumber] or 0) + 1

    updateZonePlayers()

    if zoneNumber >= 1 and zoneNumber <= 4 then
        TriggerClientEvent('gunfightarena:join', src, zoneNumber)
    end
end)

-------------------------------------------------
-- Gestion de la mort d'un joueur et du Kill Feed
-------------------------------------------------
RegisterNetEvent('gunfightarena:playerDied')
AddEventHandler('gunfightarena:playerDied', function(respawnIndex, killerId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        local stats = GetPlayerStats(src)
        stats.deaths = stats.deaths + 1
        TriggerClientEvent('esx:showNotification', src, "Vous êtes mort. Réapparition effectuée.")
        TriggerClientEvent('gunfightarena:join', src, 0)
    end

    if killerId and killerId ~= src then
        local killer = ESX.GetPlayerFromId(killerId)
        if killer then
            killStreaks[killerId] = (killStreaks[killerId] or 0) + 1
            local killerStats = GetPlayerStats(killerId)
            killerStats.kills = killerStats.kills + 1
            killer.addAccountMoney('bank', Config.RewardAmount)
            TriggerClientEvent('esx:showNotification', killerId, "Kill enregistré, +$" .. Config.RewardAmount)
            
            local killerName = killer.getName()
            local victimName = xPlayer and xPlayer.getName() or "Inconnu"
            local headshot = false
            local multiplier = killStreaks[killerId]
            TriggerClientEvent('gunfightarena:killFeed', -1, killerName, victimName, headshot, multiplier, killerId)
        end
    end

    killStreaks[src] = 0
end)

-------------------------------------------------
-- Déconnexion d'un joueur
-------------------------------------------------
AddEventHandler('playerDropped', function(reason)
    local src = source
    arenaPlayers[src] = nil
    local zone = playerZone[src]
    if zone then
        zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
        playerZone[src] = nil
        updateZonePlayers()
    end
end)

-------------------------------------------------
-- Gestion des statistiques (kills et deaths)
-------------------------------------------------
function GetPlayerStats(id)
    if not PlayerStats[id] then
        PlayerStats[id] = {kills = 0, deaths = 0}
    end
    return PlayerStats[id]
end

-------------------------------------------------
-- Récupération et affichage du leaderboard
-------------------------------------------------
RegisterNetEvent('gunfightarena:getStats')
AddEventHandler('gunfightarena:getStats', function()
    local src = source
    if not arenaPlayers[src] then
        TriggerClientEvent('esx:showNotification', src, "Tu dois être dans l'arène pour accéder aux statistiques.")
        return
    end

    local leaderboard = {}
    for id, stats in pairs(PlayerStats) do
        local xPlayer = ESX.GetPlayerFromId(id)
        local playerName = xPlayer and xPlayer.getName() or "Inconnu"
        table.insert(leaderboard, {
            player = playerName,
            kills = stats.kills,
            deaths = stats.deaths,
            kd = (stats.deaths > 0 and (stats.kills / stats.deaths) or stats.kills)
        })
    end
    table.sort(leaderboard, function(a, b) return a.kd > b.kd end)
    TriggerClientEvent('gunfightarena:statsData', src, leaderboard)
end)
