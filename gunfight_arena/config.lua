
Config = {}

-- Point d'interaction pour ouvrir le menu des arènes (modifiable)
Config.InteractionPoint = vector4(-2614.140625, -749.525268, 3.600708, 269.291352)

-- Point de spawn du lobby (où le joueur revient en quittant l'arène)
Config.LobbySpawn = vector3(-2614.140625, -749.525268, 3.600708)
Config.LobbySpawnHeading = 158.740158

-- Configuration pour le cercle du lobby (taille et couleur)
Config.LobbyCircle = {
    size = 1.5,  -- Taille du cercle
    color = { r = 210, g = 210, b = 210, a = 210 }  -- Couleur RGBA
}

-- Récupération du nom de la ressource pour construire un chemin absolu
local resourceName = GetCurrentResourceName()

-- Zone 1 (arène)
Config.Zone1 = {
    spawn = { 
        pos = vector3(178.325272, -1687.437378, 28.850512), 
        heading = 274.960632,
        image = ("images/zone1.png"):format(resourceName)
    },
    radius = 65.0,
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

-- Zone 2 (arène)
Config.Zone2 = {
    spawn = { 
        pos = vector3(295.898896, 2857.450440, 42.444702), 
        heading = 277.795288,
        image = ("images/zone2.png"):format(resourceName)
    },
    radius = 80.0,
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

-- Zone 3 (arène)
Config.Zone3 = {
    spawn = { 
        pos = vector3(78.131866, -390.408782, 38.333374), 
        heading = 90.0,
        image = ("images/zone3.png"):format(resourceName)
    },
    radius = 100.0,
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

-- Zone 4 (nouvelle arène GF)
Config.Zone4 = {
    spawn = { 
        pos = vector3(-1693.279174, -2834.571534, 430.912110), 
        heading = 0.0,
        image = ("images/zone4.png"):format(resourceName)
    },
    radius = 100.0,
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

-- Autres paramètres généraux
Config.RewardAmount = 5000
Config.MaxPlayers = 15
Config.InvincibilityTime = 3000
Config.InteractKey = 38

