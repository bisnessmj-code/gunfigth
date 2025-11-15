-- ================================================================================================
-- GUNFIGHT ARENA - CONFIGURATION COMPLÈTE
-- ================================================================================================
-- Ce fichier contient TOUTES les configurations modifiables du script
-- Modifiez les valeurs selon vos besoins sans toucher aux autres fichiers
-- ================================================================================================

Config = {}

-- ================================================================================================
-- DEBUG & LOGS
-- ================================================================================================
-- Active les logs de debug dans la console F8 (côté client) et console serveur
Config.Debug = true                     -- Active/désactive tous les logs de debug
Config.DebugClient = true               -- Logs côté client (F8)
Config.DebugServer = true               -- Logs côté serveur (console)
Config.DebugNUI = true                  -- Logs JavaScript (F8)
Config.DebugInstance = true             -- Logs spécifiques aux instances/buckets

-- ================================================================================================
-- SYSTÈME D'INSTANCES (ROUTING BUCKETS)
-- ================================================================================================
-- Les routing buckets permettent de créer des "dimensions" séparées
-- Les joueurs dans différents buckets ne se voient pas entre eux
Config.UseInstances = true              -- Active le système d'instance (true = joueurs invisibles entre zones)
Config.DefaultBucket = 0                -- Bucket par défaut (monde normal) = 0
Config.LobbyBucket = 0                  -- Bucket du lobby = 0 (monde normal)

-- Buckets assignés à chaque zone (chaque zone a sa propre instance)
Config.ZoneBuckets = {
    [1] = 100,  -- Zone 1 = bucket 100
    [2] = 200,  -- Zone 2 = bucket 200
    [3] = 300,  -- Zone 3 = bucket 300
    [4] = 400   -- Zone 4 = bucket 400
}

-- ================================================================================================
-- POINT D'INTERACTION (LOBBY)
-- ================================================================================================
-- Point où le joueur peut ouvrir le menu de sélection de zone
Config.InteractionPoint = vector4(-2614.140625, -749.525268, 3.600708, 269.291352)

-- Touche pour interagir (38 = E)
-- Liste des touches: https://docs.fivem.net/docs/game-references/controls/
Config.InteractKey = 38

-- Distance maximale pour voir le marqueur du lobby
Config.LobbyMarkerDistance = 50.0

-- Distance pour pouvoir interagir
Config.LobbyInteractDistance = 2.0

-- ================================================================================================
-- SPAWN DU LOBBY
-- ================================================================================================
-- Position où le joueur est téléporté quand il quitte l'arène
Config.LobbySpawn = vector3(-2614.140625, -749.525268, 3.600708)
Config.LobbySpawnHeading = 158.740158

-- ================================================================================================
-- CONFIGURATION DU MARQUEUR DU LOBBY
-- ================================================================================================
Config.LobbyCircle = {
    size = 1.5,                         -- Taille du cercle au sol
    color = { 
        r = 210,                        -- Rouge (0-255)
        g = 210,                        -- Vert (0-255)
        b = 210,                        -- Bleu (0-255)
        a = 210                         -- Alpha/Transparence (0-255)
    }
}

-- ================================================================================================
-- BLIP DU LOBBY (ICÔNE SUR LA CARTE)
-- ================================================================================================
Config.LobbyBlip = {
    enabled = true,                     -- Active/désactive le blip
    sprite = 311,                       -- Icône du blip (311 = cible)
    color = 1,                          -- Couleur (1 = rouge)
    scale = 0.8,                        -- Taille du blip
    name = "Gunfight Lobby"             -- Nom affiché
}

-- ================================================================================================
-- RÉCUPÉRATION DU NOM DE LA RESSOURCE
-- ================================================================================================
local resourceName = GetCurrentResourceName()

-- ================================================================================================
-- ZONE 1 - CONFIGURATION
-- ================================================================================================
Config.Zone1 = {
    enabled = true,                     -- Active/désactive cette zone
    
    -- Point de spawn initial
    spawn = { 
        pos = vector3(178.325272, -1687.437378, 28.850512), 
        heading = 274.960632,
        image = ("images/zone1.png"):format(resourceName)  -- Image pour l'UI
    },
    
    -- Rayon de la zone (en unités GTA)
    radius = 65.0,
    
    -- Nombre maximum de joueurs dans cette zone
    maxPlayers = 15,
    
    -- Couleur du marqueur de zone (cercle rouge)
    markerColor = {
        r = 255,
        g = 0,
        b = 0,
        a = 50
    },
    
    -- Points de respawn aléatoires (le joueur spawn à un de ces points après une mort)
    respawnPoints = {
        { pos = vector3(178.325272, -1687.437378, 29.650512), heading = 303.307098 },
        { pos = vector3(170.109894, -1725.243896, 29.279908), heading = 110.551186 },
        { pos = vector3(145.081314, -1702.087890, 29.279908), heading = 206.929122 },
        { pos = vector3(153.969238, -1652.175782, 29.279908), heading = 85.039368 },
        { pos = vector3(180.619782, -1648.931884, 29.802246), heading = 39.685040 },
        { pos = vector3(222.619782, -1674.778076, 29.313598), heading = 325.984252 },
        { pos = vector3(230.426376, -1705.134034, 29.279908), heading = 48.188972 },
        { pos = vector3(230.426376, -1705.134034, 29.279908), heading = 133.228348 },
        { pos = vector3(206.386810, -1686.197754, 29.599976), heading = 42.519684 },
        { pos = vector3(173.340652, -1659.019776, 29.802246), heading = 8.503936 }
    }
}

-- ================================================================================================
-- ZONE 2 - CONFIGURATION
-- ================================================================================================
Config.Zone2 = {
    enabled = true,
    
    spawn = { 
        pos = vector3(295.898896, 2857.450440, 42.444702), 
        heading = 277.795288,
        image = ("images/zone2.png"):format(resourceName)
    },
    
    radius = 80.0,
    maxPlayers = 15,
    
    markerColor = {
        r = 255,
        g = 0,
        b = 0,
        a = 50
    },
    
    respawnPoints = {
        { pos = vector3(295.516480, 2879.050538, 43.619018), heading = 53.858268 },
        { pos = vector3(307.463746, 2894.848388, 43.602172), heading = 14.173228 },
        { pos = vector3(327.415374, 2879.301026, 43.450562), heading = 297.637786 },
        { pos = vector3(335.248352, 2850.250488, 43.416870), heading = 189.921264 },
        { pos = vector3(306.567048, 2823.850586, 44.242432), heading = 136.062988 },
        { pos = vector3(277.648346, 2830.325196, 43.888672), heading = 45.354328 },
        { pos = vector3(270.909882, 2858.901124, 43.619018), heading = 22.677164 },
        { pos = vector3(259.107696, 2876.399902, 43.602172), heading = 76.535438 },
        { pos = vector3(267.876922, 2867.261474, 74.167724), heading = 266.456696 }
    }
}

-- ================================================================================================
-- ZONE 3 - CONFIGURATION
-- ================================================================================================
Config.Zone3 = {
    enabled = true,
    
    spawn = { 
        pos = vector3(78.131866, -390.408782, 38.333374), 
        heading = 90.0,
        image = ("images/zone3.png"):format(resourceName)
    },
    
    radius = 100.0,
    maxPlayers = 15,
    
    markerColor = {
        r = 255,
        g = 0,
        b = 0,
        a = 50
    },
    
    respawnPoints = {
        { pos = vector3(71.643960, -400.760438, 37.536254), heading = 90.0 },
        { pos = vector3(54.989010, -445.134064, 37.536254), heading = 90.0 },
        { pos = vector3(11.393406, -430.167022, 39.743530), heading = 90.0 },
        { pos = vector3(48.923076, -367.107696, 39.912110), heading = 90.0 },
        { pos = vector3(91.160446, -371.564850, 42.052002), heading = 90.0 },
        { pos = vector3(74.294510, -323.156036, 44.495240), heading = 90.0 },
        { pos = vector3(67.358246, -350.597808, 42.456420), heading = 90.0 },
        { pos = vector3(40.312088, -391.213196, 39.912110), heading = 90.0 }
    }
}

-- ================================================================================================
-- ZONE 4 - CONFIGURATION
-- ================================================================================================
Config.Zone4 = {
    enabled = true,
    
    spawn = { 
        pos = vector3(-1693.279174, -2834.571534, 430.912110), 
        heading = 0.0,
        image = ("images/zone4.png"):format(resourceName)
    },
    
    radius = 100.0,
    maxPlayers = 15,
    
    markerColor = {
        r = 255,
        g = 0,
        b = 0,
        a = 50
    },
    
    respawnPoints = {
        { pos = vector3(-1685.050538, -2834.993408, 431.114258), heading = 0.0 },
        { pos = vector3(-1673.709838, -2831.973632, 431.114258), heading = 0.0 },
        { pos = vector3(-1700.294556, -2817.507812, 431.114258), heading = 0.0 },
        { pos = vector3(-1698.013184, -2828.268066, 431.114258), heading = 0.0 },
        { pos = vector3(-1697.564820, -2826.909912, 433.759766), heading = 0.0 },
        { pos = vector3(-1692.276978, -2845.793458, 433.759766), heading = 0.0 },
        { pos = vector3(-1689.929688, -2828.545166, 430.928956), heading = 0.0 },
        { pos = vector3(-1698.237304, -2842.575928, 430.928956), heading = 0.0 }
    }
}

-- ================================================================================================
-- ARMES
-- ================================================================================================
-- Arme donnée automatiquement en entrant dans l'arène
Config.WeaponHash = "weapon_pistol50"   -- Nom de l'arme (hash)
Config.WeaponAmmo = 100                 -- Munitions données

-- Liste des armes disponibles (pour extension future)
Config.AvailableWeapons = {
    { name = "Pistol .50", hash = "weapon_pistol50", ammo = 100 },
    -- Ajoutez d'autres armes ici si besoin
}

-- ================================================================================================
-- RÉCOMPENSES
-- ================================================================================================
-- Récompense en argent pour chaque kill
Config.RewardAmount = 5000              -- $ ajoutés à la banque
Config.RewardAccount = "bank"           -- Type de compte (bank / money)

-- Bonus pour les kill streaks
Config.KillStreakBonus = {
    enabled = true,                     -- Active les bonus de série
    [3] = 1000,                         -- +1000$ à 3 kills d'affilée
    [5] = 2500,                         -- +2500$ à 5 kills d'affilée
    [10] = 5000                         -- +5000$ à 10 kills d'affilée
}

-- ================================================================================================
-- GAMEPLAY
-- ================================================================================================
-- Temps d'invincibilité après le spawn (millisecondes)
Config.InvincibilityTime = 3000         -- 3 secondes d'invincibilité

-- Effet de transparence pendant l'invincibilité
Config.SpawnAlpha = 128                 -- Transparence (0-255, 255 = opaque)
Config.SpawnAlphaDuration = 2000        -- Durée de la transparence (ms)

-- Délai de respawn après la mort (millisecondes)
Config.RespawnDelay = 5000              -- 5 secondes avant respawn

-- Stamina infinie dans l'arène
Config.InfiniteStamina = true           -- Active/désactive le sprint infini

-- ================================================================================================
-- LIMITES
-- ================================================================================================
-- Nombre maximum de joueurs total dans toutes les arènes
Config.MaxPlayersTotal = 60             -- Limite globale

-- Limite par zone (définie dans chaque Config.ZoneX.maxPlayers)

-- ================================================================================================
-- COMMANDES
-- ================================================================================================
-- Commande pour quitter l'arène manuellement
Config.ExitCommand = "quittergf"        -- /quittergf

-- Commande de test (dev uniquement)
Config.TestDeathCommand = "testmort"    -- /testmort (simule une mort)
Config.TestKillFeedCommand = "testkillfeed"  -- /testkillfeed

-- ================================================================================================
-- NOTIFICATIONS
-- ================================================================================================
-- Messages affichés aux joueurs
Config.Messages = {
    arenaFull = "L'arène est pleine.",
    enterArena = "^2Vous êtes entré dans l'arène.",
    exitArena = "^1Vous avez quitté l'arène.",
    notInArena = "Vous n'êtes pas dans l'arène.",
    playerDied = "Vous êtes mort. Réapparition effectuée.",
    killRecorded = "Kill enregistré, +$",
    accessStats = "Tu dois être dans l'arène pour accéder aux statistiques.",
    instanceCreated = "^3Instance créée pour la zone",
    instanceJoined = "^3Vous avez rejoint l'instance",
    instanceLeft = "^3Vous avez quitté l'instance"
}

-- ================================================================================================
-- STATISTIQUES & LEADERBOARD
-- ================================================================================================
-- Touche pour ouvrir le leaderboard (183 = Suppr sur le pavé numérique)
Config.LeaderboardKey = 183

-- Sauvegarde des stats en base de données
Config.SaveStatsToDatabase = true       -- Active la sauvegarde MySQL
Config.DatabaseUpdateInterval = 60      -- Sauvegarde auto toutes les X secondes (0 = désactivé)

-- Classement
Config.LeaderboardLimit = 20            -- Nombre de joueurs affichés dans le classement
Config.LeaderboardUpdateInterval = 30   -- Mise à jour du classement (secondes)

-- ================================================================================================
-- POLYZONE
-- ================================================================================================
-- Configuration des zones PolyZone
Config.UsePolyZone = true               -- Utilise PolyZone pour la détection
Config.PolyZoneDebug = false            -- Affiche les zones en jeu (debug)

-- ================================================================================================
-- AUTO-JOIN
-- ================================================================================================
-- Rejoindre automatiquement l'arène si le joueur entre dans la zone
Config.AutoJoin = true                  -- Active l'auto-join
Config.AutoJoinCheckInterval = 500      -- Intervalle de vérification (ms)

-- ================================================================================================
-- INTERFACE (NUI)
-- ================================================================================================
-- Affichage du kill feed
Config.KillFeed = {
    enabled = true,                     -- Active le kill feed
    duration = 5000,                    -- Durée d'affichage (ms)
    maxMessages = 5                     -- Nombre max de messages affichés
}

-- ================================================================================================
-- PERFORMANCE
-- ================================================================================================
-- Intervalle de rafraîchissement des threads (millisecondes)
Config.Threads = {
    deathCheck = 0,                     -- Vérification de la mort (0 = chaque frame)
    staminaReset = 0,                   -- Reset de la stamina (0 = chaque frame)
    zoneMarker = 0,                     -- Affichage du marqueur de zone
    lobbyMarker = 0,                    -- Affichage du marqueur du lobby
    zoneCheck = 500,                    -- Vérification de sortie de zone
    autoJoin = 500                      -- Vérification auto-join
}

-- ================================================================================================
-- FIN DE LA CONFIGURATION
-- ================================================================================================
print("^2[Gunfight Arena]^0 Configuration chargée avec succès!")
print("^3[Gunfight Arena]^0 Debug Mode: " .. (Config.Debug and "^2ACTIVÉ" or "^1DÉSACTIVÉ"))
print("^3[Gunfight Arena]^0 Instances: " .. (Config.UseInstances and "^2ACTIVÉES" or "^1DÉSACTIVÉES"))
