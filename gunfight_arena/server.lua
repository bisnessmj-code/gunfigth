-- ================================================================================================
-- GUNFIGHT ARENA - SERVER
-- ================================================================================================
-- Gestion côté serveur : instances, joueurs, statistiques, récompenses
-- ================================================================================================

local ESX = exports['es_extended']:getSharedObject()

-- ================================================================================================
-- TABLES DE SUIVI
-- ================================================================================================
local arenaPlayers = {}         -- Joueurs dans l'arène : [source] = true
local playerZone = {}           -- Zone de chaque joueur : [source] = zoneNumber (1-4)
local playerBucket = {}         -- Bucket de chaque joueur : [source] = bucketId
local zonePlayerCounts = {      -- Nombre de joueurs par zone
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0
}
local PlayerStats = {}          -- Statistiques : [source] = {kills, deaths}
local killStreaks = {}          -- Kill streaks : [source] = nombre
local playerJoinTime = {}       -- Heure d'entrée dans l'arène : [source] = timestamp

-- Cache du classement global
local globalLeaderboard = {}
local lastLeaderboardUpdate = 0

-- ================================================================================================
-- FONCTION : LOG DEBUG SERVEUR
-- ================================================================================================
local function DebugLog(message, type)
    if not Config.DebugServer then return end
    
    local prefix = "^3[GF-Server]^0"
    if type == "error" then
        prefix = "^1[GF-Server ERROR]^0"
    elseif type == "success" then
        prefix = "^2[GF-Server OK]^0"
    elseif type == "instance" then
        prefix = "^5[GF-Instance]^0"
    elseif type == "database" then
        prefix = "^6[GF-Database]^0"
    end
    
    print(prefix .. " " .. message)
end

-- ================================================================================================
-- FONCTIONS DE BASE DE DONNÉES
-- ================================================================================================

-- Charger les stats d'un joueur depuis la base de données
local function LoadPlayerStats(identifier, callback)
    if not Config.SaveStatsToDatabase then
        DebugLog("Base de données désactivée", "database")
        callback({kills = 0, deaths = 0, headshots = 0, best_streak = 0, total_playtime = 0})
        return
    end
    
    DebugLog("=== CHARGEMENT STATS BDD ===", "database")
    DebugLog("Identifier: " .. identifier, "database")
    
    MySQL.Async.fetchAll('SELECT * FROM gunfight_stats WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            DebugLog("Stats trouvées dans la BDD", "success")
            DebugLog("Kills: " .. result[1].kills .. " | Deaths: " .. result[1].deaths, "database")
            callback(result[1])
        else
            DebugLog("Aucune stat trouvée, création d'une nouvelle entrée", "database")
            -- Créer une nouvelle entrée
            MySQL.Async.execute('INSERT INTO gunfight_stats (identifier, kills, deaths, headshots, best_streak, total_playtime) VALUES (@identifier, 0, 0, 0, 0, 0)', {
                ['@identifier'] = identifier
            }, function(rowsChanged)
                DebugLog("Nouvelle entrée créée dans la BDD", "success")
                callback({kills = 0, deaths = 0, headshots = 0, best_streak = 0, total_playtime = 0})
            end)
        end
    end)
    DebugLog("============================", "database")
end

-- Sauvegarder les stats d'un joueur
local function SavePlayerStats(identifier, stats)
    if not Config.SaveStatsToDatabase then return end
    
    DebugLog("=== SAUVEGARDE STATS BDD ===", "database")
    DebugLog("Identifier: " .. identifier, "database")
    DebugLog("Kills: " .. stats.kills .. " | Deaths: " .. stats.deaths, "database")
    
    MySQL.Async.execute([[
        UPDATE gunfight_stats 
        SET kills = @kills, 
            deaths = @deaths, 
            headshots = @headshots, 
            best_streak = @best_streak,
            total_playtime = @total_playtime,
            last_played = NOW()
        WHERE identifier = @identifier
    ]], {
        ['@identifier'] = identifier,
        ['@kills'] = stats.kills,
        ['@deaths'] = stats.deaths,
        ['@headshots'] = stats.headshots or 0,
        ['@best_streak'] = stats.best_streak or 0,
        ['@total_playtime'] = stats.total_playtime or 0
    }, function(rowsChanged)
        if rowsChanged > 0 then
            DebugLog("Stats sauvegardées avec succès", "success")
        else
            DebugLog("Erreur lors de la sauvegarde", "error")
        end
    end)
    DebugLog("============================", "database")
end

-- Récupérer le classement global
local function GetGlobalLeaderboard(callback)
    if not Config.SaveStatsToDatabase then
        DebugLog("Base de données désactivée", "database")
        callback({})
        return
    end
    
    DebugLog("=== RÉCUPÉRATION CLASSEMENT ===", "database")
    
    MySQL.Async.fetchAll([[
        SELECT 
            identifier,
            kills,
            deaths,
            headshots,
            best_streak,
            CASE 
                WHEN deaths > 0 THEN ROUND(kills / deaths, 2)
                ELSE kills
            END as kd_ratio
        FROM gunfight_stats
        ORDER BY kd_ratio DESC, kills DESC
        LIMIT @limit
    ]], {
        ['@limit'] = Config.LeaderboardLimit
    }, function(result)
        DebugLog("Classement récupéré: " .. #result .. " entrées", "success")
        
        -- Récupérer les noms des joueurs
        local leaderboard = {}
        for i, data in ipairs(result) do
            -- Essayer de récupérer le nom du joueur depuis ESX
            local playerName = "Joueur #" .. i
            
            -- Chercher si le joueur est connecté
            for _, playerId in ipairs(GetPlayers()) do
                local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
                if xPlayer and xPlayer.identifier == data.identifier then
                    playerName = xPlayer.getName()
                    break
                end
            end
            
            table.insert(leaderboard, {
                rank = i,
                player = playerName,
                kills = data.kills,
                deaths = data.deaths,
                headshots = data.headshots,
                best_streak = data.best_streak,
                kd = data.kd_ratio
            })
        end
        
        callback(leaderboard)
    end)
    DebugLog("===============================", "database")
end

-- Mettre à jour le classement global en cache
local function UpdateGlobalLeaderboard()
    GetGlobalLeaderboard(function(leaderboard)
        globalLeaderboard = leaderboard
        lastLeaderboardUpdate = os.time()
        DebugLog("Cache du classement mis à jour", "success")
    end)
end

-- ================================================================================================
-- FONCTION : COMPTER LES ÉLÉMENTS D'UNE TABLE
-- ================================================================================================
local function tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

-- ================================================================================================
-- FONCTION : OBTENIR LES STATISTIQUES D'UN JOUEUR
-- ================================================================================================
function GetPlayerStats(id)
    if not PlayerStats[id] then
        PlayerStats[id] = {
            kills = 0,
            deaths = 0,
            headshots = 0,
            best_streak = 0,
            total_playtime = 0
        }
        DebugLog("Stats créées en mémoire pour le joueur " .. id, "success")
        
        -- Charger depuis la BDD si activé
        if Config.SaveStatsToDatabase then
            local xPlayer = ESX.GetPlayerFromId(id)
            if xPlayer then
                LoadPlayerStats(xPlayer.identifier, function(dbStats)
                    PlayerStats[id].kills = dbStats.kills
                    PlayerStats[id].deaths = dbStats.deaths
                    PlayerStats[id].headshots = dbStats.headshots or 0
                    PlayerStats[id].best_streak = dbStats.best_streak or 0
                    PlayerStats[id].total_playtime = dbStats.total_playtime or 0
                    DebugLog("Stats chargées depuis la BDD pour joueur " .. id, "success")
                end)
            end
        end
    end
    return PlayerStats[id]
end

-- ================================================================================================
-- FONCTION : ASSIGNER UN BUCKET (INSTANCE) À UN JOUEUR
-- ================================================================================================
local function SetPlayerInstance(source, bucketId)
    if not Config.UseInstances then
        DebugLog("Instances désactivées dans la config", "error")
        return
    end
    
    DebugLog("=== ASSIGNATION D'INSTANCE ===", "instance")
    DebugLog("Joueur: " .. source, "instance")
    DebugLog("Ancien bucket: " .. (playerBucket[source] or "aucun"), "instance")
    DebugLog("Nouveau bucket: " .. bucketId, "instance")
    
    -- Assignation du routing bucket
    SetPlayerRoutingBucket(source, bucketId)
    
    -- Assignation de l'entité (PED) au même bucket
    local playerPed = GetPlayerPed(source)
    SetEntityRoutingBucket(playerPed, bucketId)
    
    -- Sauvegarde du bucket actuel
    playerBucket[source] = bucketId
    
    DebugLog("Bucket assigné avec succès: " .. bucketId, "success")
    DebugLog("==============================", "instance")
end

-- ================================================================================================
-- FONCTION : RETIRER UN JOUEUR DE SON INSTANCE (RETOUR AU MONDE NORMAL)
-- ================================================================================================
local function RemovePlayerFromInstance(source)
    if not Config.UseInstances then return end
    
    DebugLog("=== RETRAIT D'INSTANCE ===", "instance")
    DebugLog("Joueur: " .. source, "instance")
    DebugLog("Bucket actuel: " .. (playerBucket[source] or "aucun"), "instance")
    
    -- Retour au bucket par défaut (monde normal)
    SetPlayerInstance(source, Config.LobbyBucket)
    
    DebugLog("Joueur retourné au lobby (bucket " .. Config.LobbyBucket .. ")", "success")
    DebugLog("==========================", "instance")
end

-- ================================================================================================
-- FONCTION : MISE À JOUR DES INFORMATIONS DES ZONES (NUI)
-- ================================================================================================
local function updateZonePlayers()
    DebugLog("=== MISE À JOUR DES ZONES ===")
    
    local zonesData = {}
    
    for i = 1, 4 do
        local zoneCfg = Config["Zone" .. i]
        if zoneCfg and zoneCfg.enabled then
            table.insert(zonesData, {
                zone = i,
                players = zonePlayerCounts[i] or 0,
                maxPlayers = zoneCfg.maxPlayers or Config.MaxPlayers
            })
            DebugLog("Zone " .. i .. ": " .. (zonePlayerCounts[i] or 0) .. "/" .. (zoneCfg.maxPlayers or 15) .. " joueurs")
        end
    end
    
    -- Envoi aux clients
    TriggerClientEvent('gunfightarena:updateZonePlayers', -1, zonesData)
    DebugLog("Données des zones envoyées aux clients", "success")
    DebugLog("=============================")
end

-- ================================================================================================
-- COMMANDE : QUITTER L'ARÈNE
-- ================================================================================================
RegisterCommand(Config.ExitCommand, function(source, args, rawCommand)
    DebugLog("=== COMMANDE QUITTER ===")
    DebugLog("Joueur " .. source .. " utilise /" .. Config.ExitCommand)
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        DebugLog("Joueur ESX non trouvé", "error")
        return
    end
    
    if arenaPlayers[source] then
        DebugLog("Joueur dans l'arène, traitement de la sortie...")
        
        -- Retirer des tables de suivi
        arenaPlayers[source] = nil
        local zone = playerZone[source]
        
        if zone then
            DebugLog("Zone du joueur: " .. zone)
            zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
            DebugLog("Nouveau compte zone " .. zone .. ": " .. zonePlayerCounts[zone])
            playerZone[source] = nil
        end
        
        -- Retirer de l'instance
        RemovePlayerFromInstance(source)
        
        -- Reset kill streak
        killStreaks[source] = 0
        
        -- Mise à jour
        updateZonePlayers()
        
        TriggerClientEvent('esx:showNotification', source, Config.Messages.exitArena)
        TriggerClientEvent('gunfightarena:exit', source)
        
        DebugLog("Joueur sorti avec succès", "success")
    else
        DebugLog("Joueur pas dans l'arène", "error")
        TriggerClientEvent('esx:showNotification', source, Config.Messages.notInArena)
    end
    
    DebugLog("========================")
end, false)

-- ================================================================================================
-- EVENT : DEMANDE DE REJOINDRE UNE ZONE
-- ================================================================================================
RegisterNetEvent('gunfightarena:joinRequest')
AddEventHandler('gunfightarena:joinRequest', function(zoneNumber)
    local src = source
    
    DebugLog("=== DEMANDE DE REJOINDRE ZONE ===")
    DebugLog("Joueur: " .. src)
    DebugLog("Zone demandée: " .. zoneNumber)
    
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        DebugLog("Joueur ESX non trouvé", "error")
        return
    end
    
    -- Vérifier que la zone existe et est activée
    local zoneCfg = Config["Zone" .. zoneNumber]
    if not zoneCfg or not zoneCfg.enabled then
        DebugLog("Zone " .. zoneNumber .. " n'existe pas ou est désactivée", "error")
        TriggerClientEvent('esx:showNotification', src, "Cette zone n'est pas disponible.")
        return
    end
    
    -- Vérifier la limite de joueurs dans la zone
    local maxPlayers = zoneCfg.maxPlayers or Config.MaxPlayers
    if zonePlayerCounts[zoneNumber] >= maxPlayers then
        DebugLog("Zone pleine: " .. zonePlayerCounts[zoneNumber] .. "/" .. maxPlayers, "error")
        TriggerClientEvent('esx:showNotification', src, Config.Messages.arenaFull)
        return
    end
    
    -- Si le joueur est déjà dans une zone, le retirer
    if playerZone[src] then
        local oldZone = playerZone[src]
        DebugLog("Joueur déjà dans la zone " .. oldZone .. ", retrait...")
        zonePlayerCounts[oldZone] = math.max((zonePlayerCounts[oldZone] or 1) - 1, 0)
    end
    
    -- Ajouter le joueur à l'arène
    arenaPlayers[src] = true
    playerZone[src] = zoneNumber
    zonePlayerCounts[zoneNumber] = (zonePlayerCounts[zoneNumber] or 0) + 1
    
    -- Enregistrer l'heure d'entrée pour le calcul du temps de jeu
    playerJoinTime[src] = os.time()
    DebugLog("Heure d'entrée enregistrée: " .. playerJoinTime[src])
    
    DebugLog("Joueur ajouté à la zone " .. zoneNumber)
    DebugLog("Nombre de joueurs dans zone " .. zoneNumber .. ": " .. zonePlayerCounts[zoneNumber])
    
    -- Assigner l'instance (bucket) de la zone
    if Config.UseInstances then
        local bucketId = Config.ZoneBuckets[zoneNumber]
        if bucketId then
            DebugLog("Assignation au bucket " .. bucketId .. " pour la zone " .. zoneNumber)
            SetPlayerInstance(src, bucketId)
            TriggerClientEvent('esx:showNotification', src, Config.Messages.instanceJoined .. " " .. zoneNumber)
        else
            DebugLog("Bucket non trouvé pour la zone " .. zoneNumber, "error")
        end
    end
    
    -- Initialiser les stats si nécessaire
    GetPlayerStats(src)
    
    -- Reset kill streak
    killStreaks[src] = 0
    
    -- Mise à jour des zones
    updateZonePlayers()
    
    -- Téléporter le joueur
    TriggerClientEvent('gunfightarena:join', src, zoneNumber)
    TriggerClientEvent('esx:showNotification', src, Config.Messages.enterArena)
    
    DebugLog("Joueur " .. src .. " a rejoint la zone " .. zoneNumber .. " avec succès", "success")
    DebugLog("=================================")
end)

-- ================================================================================================
-- EVENT : MORT D'UN JOUEUR DANS L'ARÈNE
-- ================================================================================================
RegisterNetEvent('gunfightarena:playerDied')
AddEventHandler('gunfightarena:playerDied', function(respawnIndex, killerId)
    local src = source
    
    DebugLog("=== MORT D'UN JOUEUR ===")
    DebugLog("Victime: " .. src)
    DebugLog("Killer ID: " .. tostring(killerId or "aucun"))
    DebugLog("Index respawn: " .. tostring(respawnIndex))
    
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        DebugLog("Victime ESX non trouvée", "error")
        return
    end
    
    -- Statistiques de la victime
    local stats = GetPlayerStats(src)
    stats.deaths = stats.deaths + 1
    DebugLog("Stats victime - Deaths: " .. stats.deaths)
    
    -- Reset kill streak de la victime
    killStreaks[src] = 0
    DebugLog("Kill streak victime réinitialisé")
    
    -- Sauvegarder les stats de la victime
    if Config.SaveStatsToDatabase then
        SavePlayerStats(xPlayer.identifier, stats)
    end
    
    -- Notifier la victime
    TriggerClientEvent('esx:showNotification', src, Config.Messages.playerDied)
    
    -- Respawn de la victime
    TriggerClientEvent('gunfightarena:join', src, 0)  -- 0 = respawn aléatoire
    
    -- Traitement du killer
    if killerId and killerId ~= src then
        DebugLog("=== TRAITEMENT DU KILLER ===")
        local killer = ESX.GetPlayerFromId(killerId)
        
        if killer then
            -- Kill streak
            killStreaks[killerId] = (killStreaks[killerId] or 0) + 1
            DebugLog("Kill streak du killer: " .. killStreaks[killerId])
            
            -- Statistiques
            local killerStats = GetPlayerStats(killerId)
            killerStats.kills = killerStats.kills + 1
            
            -- Mettre à jour le meilleur streak
            if killStreaks[killerId] > killerStats.best_streak then
                killerStats.best_streak = killStreaks[killerId]
                DebugLog("Nouveau meilleur streak: " .. killerStats.best_streak, "success")
            end
            
            DebugLog("Stats killer - Kills: " .. killerStats.kills)
            
            -- Sauvegarder les stats du killer
            if Config.SaveStatsToDatabase then
                SavePlayerStats(killer.identifier, killerStats)
            end
            
            -- Récompense de base
            local reward = Config.RewardAmount
            killer.addAccountMoney(Config.RewardAccount, reward)
            DebugLog("Récompense de base: $" .. reward)
            
            -- Bonus kill streak
            if Config.KillStreakBonus.enabled then
                local bonus = Config.KillStreakBonus[killStreaks[killerId]]
                if bonus then
                    killer.addAccountMoney(Config.RewardAccount, bonus)
                    DebugLog("Bonus kill streak (" .. killStreaks[killerId] .. "x): $" .. bonus, "success")
                    TriggerClientEvent('esx:showNotification', killerId, "^2KILL STREAK x" .. killStreaks[killerId] .. "! Bonus: $" .. bonus)
                    reward = reward + bonus
                end
            end
            
            TriggerClientEvent('esx:showNotification', killerId, Config.Messages.killRecorded .. reward)
            
            -- Kill Feed
            local killerName = killer.getName()
            local victimName = xPlayer.getName()
            local headshot = false  -- À implémenter avec WeaponDamageEvent si besoin
            local multiplier = killStreaks[killerId]
            
            DebugLog("Envoi du kill feed - Killer: " .. killerName .. ", Victime: " .. victimName)
            TriggerClientEvent('gunfightarena:killFeed', -1, killerName, victimName, headshot, multiplier, killerId)
        else
            DebugLog("Killer ESX non trouvé", "error")
        end
    else
        DebugLog("Pas de killer (suicide ou autre)")
    end
    
    DebugLog("========================")
end)

-- ================================================================================================
-- EVENT : DÉCONNEXION D'UN JOUEUR
-- ================================================================================================
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    DebugLog("=== DÉCONNEXION JOUEUR ===")
    DebugLog("Joueur: " .. src)
    DebugLog("Raison: " .. reason)
    
    if arenaPlayers[src] then
        DebugLog("Joueur était dans l'arène")
        
        -- Calculer et sauvegarder le temps de jeu
        if playerJoinTime[src] and Config.SaveStatsToDatabase then
            local playTime = os.time() - playerJoinTime[src]
            DebugLog("Temps de jeu cette session: " .. playTime .. " secondes")
            
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                local stats = GetPlayerStats(src)
                stats.total_playtime = (stats.total_playtime or 0) + playTime
                SavePlayerStats(xPlayer.identifier, stats)
            end
        end
        
        arenaPlayers[src] = nil
        
        local zone = playerZone[src]
        if zone then
            DebugLog("Zone: " .. zone)
            zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
            DebugLog("Nouveau compte: " .. zonePlayerCounts[zone])
            playerZone[src] = nil
        end
        
        -- Nettoyage du bucket
        if playerBucket[src] then
            DebugLog("Nettoyage du bucket: " .. playerBucket[src])
            playerBucket[src] = nil
        end
        
        -- Nettoyage stats temporaires
        killStreaks[src] = nil
        playerJoinTime[src] = nil
        
        updateZonePlayers()
    else
        DebugLog("Joueur n'était pas dans l'arène")
    end
    
    DebugLog("==========================")
end)

-- ================================================================================================
-- EVENT : RÉCUPÉRATION DES STATISTIQUES (LEADERBOARD)
-- ================================================================================================
RegisterNetEvent('gunfightarena:getStats')
AddEventHandler('gunfightarena:getStats', function()
    local src = source
    
    DebugLog("=== DEMANDE STATISTIQUES ===")
    DebugLog("Joueur: " .. src)
    
    if not arenaPlayers[src] then
        DebugLog("Joueur pas dans l'arène", "error")
        TriggerClientEvent('esx:showNotification', src, Config.Messages.accessStats)
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
    
    -- Tri par K/D décroissant
    table.sort(leaderboard, function(a, b) return a.kd > b.kd end)
    
    DebugLog("Nombre d'entrées dans le leaderboard: " .. #leaderboard)
    TriggerClientEvent('gunfightarena:statsData', src, leaderboard)
    DebugLog("Statistiques envoyées au joueur", "success")
    DebugLog("============================")
end)

-- ================================================================================================
-- EVENT : RÉCUPÉRATION DES STATS PERSONNELLES
-- ================================================================================================
RegisterNetEvent('gunfightarena:getPersonalStats')
AddEventHandler('gunfightarena:getPersonalStats', function()
    local src = source
    
    DebugLog("=== DEMANDE STATS PERSONNELLES ===")
    DebugLog("Joueur: " .. src)
    
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        DebugLog("Joueur ESX non trouvé", "error")
        return
    end
    
    if Config.SaveStatsToDatabase then
        LoadPlayerStats(xPlayer.identifier, function(dbStats)
            -- Inclure aussi les stats de session
            local sessionStats = GetPlayerStats(src)
            local personalStats = {
                player = xPlayer.getName(),
                kills = dbStats.kills,
                deaths = dbStats.deaths,
                headshots = dbStats.headshots,
                best_streak = dbStats.best_streak,
                total_playtime = dbStats.total_playtime,
                kd = (dbStats.deaths > 0 and (dbStats.kills / dbStats.deaths) or dbStats.kills),
                current_streak = killStreaks[src] or 0,
                session_kills = sessionStats.kills - dbStats.kills,
                session_deaths = sessionStats.deaths - dbStats.deaths
            }
            
            DebugLog("Stats personnelles envoyées", "success")
            TriggerClientEvent('gunfightarena:personalStatsData', src, personalStats)
        end)
    else
        -- Mode sans BDD : stats de session uniquement
        local stats = GetPlayerStats(src)
        local personalStats = {
            player = xPlayer.getName(),
            kills = stats.kills,
            deaths = stats.deaths,
            headshots = stats.headshots or 0,
            best_streak = stats.best_streak or 0,
            total_playtime = 0,
            kd = (stats.deaths > 0 and (stats.kills / stats.deaths) or stats.kills),
            current_streak = killStreaks[src] or 0,
            session_kills = stats.kills,
            session_deaths = stats.deaths
        }
        
        DebugLog("Stats personnelles envoyées (mode sans BDD)", "success")
        TriggerClientEvent('gunfightarena:personalStatsData', src, personalStats)
    end
    
    DebugLog("===================================")
end)

-- ================================================================================================
-- EVENT : RÉCUPÉRATION DU CLASSEMENT GLOBAL
-- ================================================================================================
RegisterNetEvent('gunfightarena:getGlobalLeaderboard')
AddEventHandler('gunfightarena:getGlobalLeaderboard', function()
    local src = source
    
    DebugLog("=== DEMANDE CLASSEMENT GLOBAL ===")
    DebugLog("Joueur: " .. src)
    
    -- Vérifier si le cache est récent
    if os.time() - lastLeaderboardUpdate > Config.LeaderboardUpdateInterval then
        DebugLog("Cache expiré, mise à jour...")
        UpdateGlobalLeaderboard()
        Citizen.Wait(1000)  -- Attendre la mise à jour
    end
    
    if #globalLeaderboard > 0 then
        DebugLog("Envoi du classement global (" .. #globalLeaderboard .. " entrées)")
        TriggerClientEvent('gunfightarena:globalLeaderboardData', src, globalLeaderboard)
    else
        DebugLog("Classement global vide, récupération forcée...")
        GetGlobalLeaderboard(function(leaderboard)
            TriggerClientEvent('gunfightarena:globalLeaderboardData', src, leaderboard)
        end)
    end
    
    DebugLog("=================================")
end)

-- ================================================================================================
-- EVENT : RÉCUPÉRATION DU LOBBY SCOREBOARD
-- ================================================================================================
RegisterNetEvent('gunfightarena:getLobbyScoreboard')
AddEventHandler('gunfightarena:getLobbyScoreboard', function()
    local src = source
    
    DebugLog("=== DEMANDE LOBBY SCOREBOARD ===")
    DebugLog("Joueur: " .. src)
    
    -- Utiliser le cache si récent, sinon recharger
    if os.time() - lastLeaderboardUpdate > Config.LeaderboardUpdateInterval then
        DebugLog("Cache expiré, mise à jour...")
        UpdateGlobalLeaderboard()
        Citizen.Wait(500)
    end
    
    -- Envoyer le classement (limité à 10 pour le lobby)
    if #globalLeaderboard > 0 then
        DebugLog("Envoi du lobby scoreboard (" .. math.min(#globalLeaderboard, 10) .. " entrées)")
        TriggerClientEvent('gunfightarena:lobbyScoreboardData', src, globalLeaderboard)
    else
        DebugLog("Classement vide, récupération...")
        GetGlobalLeaderboard(function(leaderboard)
            TriggerClientEvent('gunfightarena:lobbyScoreboardData', src, leaderboard)
        end)
    end
    
    DebugLog("================================")
end)

-- ================================================================================================
-- COMMANDE : DEBUG INFO (ADMIN)
-- ================================================================================================
RegisterCommand('gfdebug', function(source, args, rawCommand)
    if source == 0 then return end  -- Console uniquement
    
    print("\n^3========== GUNFIGHT ARENA DEBUG ==========^0")
    print("^2Joueurs dans l'arène:^0")
    for src, _ in pairs(arenaPlayers) do
        local zone = playerZone[src] or "aucune"
        local bucket = playerBucket[src] or "aucun"
        print("  - Joueur " .. src .. " | Zone: " .. zone .. " | Bucket: " .. bucket)
    end
    
    print("\n^2Compteurs de zones:^0")
    for i = 1, 4 do
        print("  - Zone " .. i .. ": " .. (zonePlayerCounts[i] or 0) .. " joueurs")
    end
    
    print("\n^2Kill Streaks actifs:^0")
    for src, streak in pairs(killStreaks) do
        if streak > 0 then
            print("  - Joueur " .. src .. ": " .. streak .. "x")
        end
    end
    
    print("\n^2Configuration:^0")
    print("  - Instances activées: " .. tostring(Config.UseInstances))
    print("  - Debug activé: " .. tostring(Config.DebugServer))
    print("  - Max joueurs total: " .. Config.MaxPlayersTotal)
    print("^3==========================================^0\n")
end, true)  -- true = admin uniquement

-- ================================================================================================
-- THREAD : MISE À JOUR AUTOMATIQUE DU CLASSEMENT GLOBAL
-- ================================================================================================
if Config.SaveStatsToDatabase and Config.LeaderboardUpdateInterval > 0 then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.LeaderboardUpdateInterval * 1000)
            UpdateGlobalLeaderboard()
        end
    end)
end

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Wait(1000)
    DebugLog("========================================", "success")
    DebugLog("GUNFIGHT ARENA SERVER - DÉMARRÉ", "success")
    DebugLog("Version: 2.0 avec instances", "success")
    DebugLog("Debug: " .. (Config.DebugServer and "ACTIVÉ" or "DÉSACTIVÉ"), "success")
    DebugLog("Instances: " .. (Config.UseInstances and "ACTIVÉES" or "DÉSACTIVÉES"), "success")
    DebugLog("Base de données: " .. (Config.SaveStatsToDatabase and "ACTIVÉE" or "DÉSACTIVÉE"), "success")
    DebugLog("========================================", "success")
    
    -- Charger le classement global au démarrage
    if Config.SaveStatsToDatabase then
        DebugLog("Chargement initial du classement global...")
        UpdateGlobalLeaderboard()
    end
end)

-- ================================================================================================
-- EVENT : DEMANDE DE MISE À JOUR DES ZONES
-- ================================================================================================
RegisterNetEvent('gunfightarena:requestZoneUpdate')
AddEventHandler('gunfightarena:requestZoneUpdate', function()
    DebugLog("=== DEMANDE MISE À JOUR ZONES ===")
    DebugLog("Joueur: " .. source)
    updateZonePlayers()
    DebugLog("=================================")
end)

-- ================================================================================================
-- COMMANDE ADMIN : FORCER LA SORTIE D'UN JOUEUR DE L'ARÈNE
-- ================================================================================================
RegisterCommand('gfkick', function(source, args, rawCommand)
    if source == 0 then  -- Console uniquement ou vérifiez les permissions admin
        local targetId = tonumber(args[1])
        
        if not targetId then
            print("^1Usage: /gfkick [playerID]^0")
            return
        end
        
        if arenaPlayers[targetId] then
            DebugLog("=== KICK FORCÉ DU JOUEUR " .. targetId .. " ===", "error")
            
            -- Retirer de l'arène
            arenaPlayers[targetId] = nil
            local zone = playerZone[targetId]
            
            if zone then
                zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
                playerZone[targetId] = nil
            end
            
            RemovePlayerFromInstance(targetId)
            killStreaks[targetId] = 0
            updateZonePlayers()
            
            TriggerClientEvent('gunfightarena:exit', targetId)
            TriggerClientEvent('esx:showNotification', targetId, "^1Vous avez été retiré de l'arène par un administrateur.")
            
            print("^2Joueur " .. targetId .. " retiré de l'arène^0")
        else
            print("^1Le joueur " .. targetId .. " n'est pas dans l'arène^0")
        end
    end
end, true)
