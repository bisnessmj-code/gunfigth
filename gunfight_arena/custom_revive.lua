-- custom_revive.lua 

-- Utilisation de l'export pour récupérer ESX (double sécurité)
ESX = exports["es_extended"]:getSharedObject()

local deathHandled = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        -- Gérer la réanimation uniquement si le joueur est dans l'arène
        if isInArena then
            local playerPed = PlayerPedId()
            if IsEntityDead(playerPed) and not deathHandled then
                deathHandled = true
                -- Attendre 5 secondes pour laisser le temps aux animations (délai augmenté)
                Citizen.Wait(5000)
                if IsEntityDead(playerPed) then
                    -- Arrêter toute animation en cours pour éviter le déclenchement de l'animation ESX
                    ClearPedTasksImmediately(playerPed)
                    if currentZone == 1 then
                        local randomIndex = math.random(1, #Config.Zone1.respawnPoints)
                        TriggerServerEvent('gunfightarena:playerDied', randomIndex)
                    elseif currentZone == 2 then
                        local randomIndex = math.random(1, #Config.Zone2.respawnPoints)
                        TriggerServerEvent('gunfightarena:playerDied', randomIndex)
                    else
                        -- En cas de problème avec currentZone, forcer le retour au lobby
                        TriggerEvent('gunfightarena:exit')
                    end
                end
                -- Délai supplémentaire pour éviter plusieurs déclenchements
                Citizen.Wait(3000)
                deathHandled = false
            end
        end
        Citizen.Wait(0)
    end
end)

print("custom_revive.lua chargé avec succès.")

