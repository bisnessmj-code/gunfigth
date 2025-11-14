Gunfight Arena
Gunfight Arena est un mini-jeu pour FiveM basé sur ESX qui permet aux joueurs de s'affronter dans des zones dédiées. Le script gère l'entrée dans l'arène, la réanimation (avec invincibilité et effet de transparence post-spawn), l'attribution automatique d'une arme (weapon_pistol50) lors du spawn, le retrait de l'arme en quittant l'arène et une remise en continu de la stamina pour permettre un sprint illimité.

Fonctionnalités
Interface de sélection de zone :
Le joueur peut choisir entre deux zones d'arène via une interface NUI.

Réanimation et protection post-spawn :
Utilisation de NetworkResurrectLocalPlayer pour réanimer le joueur, avec invincibilité et effet de transparence pendant 2 secondes afin d'éviter le spawn kill.

Gestion d'arme automatique :
Le joueur reçoit automatiquement le weapon_pistol50 (avec 100 munitions) dès qu'il entre dans l'arène et le perd lorsqu'il quitte.

Remise en continu de la stamina :
La stamina est constamment réinitialisée pendant que le joueur est dans l'arène, permettant un sprint permanent.

Gestion des morts et respawn :
Si le joueur meurt dans l'arène, le script déclenche un respawn après un délai, lui attribue une récompense en argent et le téléporte à un point de respawn aléatoire selon la zone.

Installation
Dépendances requises :

es_extended
PolyZone (pour la gestion des zones)
mysql-async (pour la connexion à la base de données)
Installation du script :

Placez le dossier gunfight_arena dans le dossier resources de votre serveur FiveM.
Vérifiez que tous les fichiers suivants se trouvent dans le dossier :
fxmanifest.lua
config.lua
client.lua
custom_revive.lua
server.lua
Le dossier html (contenant index.html, style.css, script.js et les images)
Configuration :

Ouvrez le fichier config.lua et ajustez les paramètres (points d'interaction, spawn du lobby, paramètres des zones, récompense, nombre maximum de joueurs, etc.) selon vos besoins.
Démarrage :

Ajoutez la ressource dans votre server.cfg :
ruby
Copier
ensure gunfight_arena
Utilisation
Rejoindre l'arène :
Rendez-vous sur le point d'interaction (défini dans config.lua) où vous verrez un marqueur et un texte invitant à rejoindre l'arène. Appuyez sur la touche E pour ouvrir le menu de sélection de zone.

Sélection de zone :
Choisissez entre Zone 1 et Zone 2 via l'interface NUI. Le joueur sera téléporté à la position de spawn de la zone choisie et recevra le weapon_pistol50 automatiquement.

Respawn et protection :
En cas de mort dans l'arène, le joueur sera réanimé (avec invincibilité et transparence pendant 2 secondes) et recevra une récompense bancaire définie dans config.lua.

Stamina infinie :
Pendant que vous êtes dans l'arène, votre stamina est continuellement réinitialisée, permettant un sprint permanent.

Quitter l'arène :
Utilisez la commande /zone pour quitter l'arène ou sortez de la zone définie. Dans ce cas, le script retire automatiquement le weapon_pistol50 et vous téléporte au lobby.

Test de simulation de mort :
Pour tester la réanimation, vous pouvez utiliser la commande /testmort (disponible dans custom_revive.lua) pour simuler la mort de votre personnage.

Personnalisation
Modification des zones :
Vous pouvez modifier les points de spawn, les zones de respawn et le rayon des arènes directement dans le fichier config.lua.

Arme attribuée :
L'arme par défaut attribuée est weapon_pistol50. Pour utiliser une autre arme, modifiez la clé dans le code du client (GiveWeaponToPed et RemoveWeaponFromPed).

Effets visuels post-spawn :
L'effet de transparence est appliqué en définissant l'alpha du joueur à 128 pendant 2 secondes. Vous pouvez ajuster cette valeur et la durée selon vos préférences.

Invincibilité temporaire :
Le délai d'invincibilité après le spawn est de 2000 ms. Vous pouvez le modifier dans client.lua ou via le paramètre Config.InvincibilityTime dans config.lua.

Dépannage
PolyZone non chargé :
Assurez-vous que la ressource PolyZone est démarrée et que les chemins dans le fxmanifest sont corrects.

ESX non reconnu :
Vérifiez que es_extended est installé et que la ligne shared_script '@es_extended/imports.lua' est présente dans le fxmanifest.

Aucun spawn ou réapparition :
Vérifiez que les coordonnées dans config.lua sont correctes et que le joueur se trouve bien dans la zone de l'arène.

Commandes de test non fonctionnelles :
Assurez-vous d'utiliser la console F8 pour exécuter les commandes côté client (ex. /testmort).

Credits
Auteur : kichta
Basé sur ESX et PolyZone : Merci aux développeurs d'ESX et PolyZone pour leurs outils et ressources.
