// Variable globale pour stocker les informations de zones mises à jour par le serveur
let currentZoneData = [];

// Écoute des messages envoyés par le parent via SendNUIMessage
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'show':
            // Si des données sont fournies, on met à jour currentZoneData.
            if (data.zones && data.zones.length > 0) {
                currentZoneData = data.zones;
            }
            showUI();
            break;
        case 'showStats':
            showStats(data.stats);
            break;
        case 'killFeed':
            addKillFeedMessage(data.message);
            break;
        case 'updateZonePlayers':
            updateZonePlayers(data.zones);
            break;
        default:
            console.log("Action inconnue :", data.action);
    }
});

document.addEventListener('DOMContentLoaded', () => {
    // Bouton pour fermer l'UI de sélection de zone
    const closeBtn = document.getElementById('close-btn');
    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            closeUI();
        });
    } else {
        console.error("Bouton close-btn non trouvé dans le DOM");
    }

    // Bouton pour fermer le leaderboard
    const statsCloseBtn = document.getElementById('stats-close-btn');
    if (statsCloseBtn) {
        statsCloseBtn.addEventListener('click', () => {
            document.getElementById('stats-ui').style.display = "none";
            fetch(`https://${GetParentResourceName()}/closeUI`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({})
            }).catch(err => console.error("Erreur lors de la fermeture du leaderboard :", err));
        });
    } else {
        console.error("Bouton stats-close-btn non trouvé dans le DOM");
    }

    // Mode test pour le kill feed (ajoute un message fictif toutes les 5 secondes)
    if (window.location.search.indexOf("testMode=true") !== -1) {
        setInterval(() => {
            const fakeMessage = {
                killer: "TestKiller" + Math.floor(Math.random() * 10),
                victim: "TestVictim" + Math.floor(Math.random() * 10),
                headshot: Math.random() > 0.5,
                multiplier: Math.floor(Math.random() * 5) + 1
            };
            addKillFeedMessage(fakeMessage);
        }, 5000);
    }
});

/**
 * Met à jour currentZoneData avec les données de zones reçues.
 * Si l'UI est ouverte, met à jour directement les cartes affichées.
 * @param {Array} zones - Données mises à jour des zones.
 */
function updateZonePlayers(zones) {
    console.log("updateZonePlayers appelé avec zones :", zones);
    currentZoneData = zones;

    const arenaUI = document.getElementById('arena-ui');
    if (arenaUI && arenaUI.style.display === "block") {
        zones.forEach((zone) => {
            const card = document.querySelector(`.zone-card[data-zone="${zone.zone}"]`);
            if (card) {
                const playersInfo = card.querySelector('.zone-players');
                if (playersInfo) {
                    playersInfo.textContent = `${zone.players}/${zone.maxPlayers || 15} joueurs`;
                    console.log(`Zone ${zone.zone} mise à jour : ${playersInfo.textContent}`);
                }
            }
        });
    } else {
        console.log("UI fermée : les données sont stockées pour affichage ultérieur.");
    }
}

/**
 * Affiche l'UI de sélection de zone en utilisant les données stockées dans currentZoneData.
 */
function showUI() {
    const zoneList = document.getElementById('zone-list');
    if (!zoneList) {
        console.error("Element 'zone-list' non trouvé");
        return;
    }
    zoneList.innerHTML = "";

    // Utilise currentZoneData pour construire les cartes
    currentZoneData.forEach((zone) => {
        const card = document.createElement('div');
        card.className = "zone-card";
        card.setAttribute("data-zone", zone.zone);

        const img = document.createElement('img');
        img.className = "zone-image";
        img.src = zone.image ? zone.image : "images/default.png";

        const text = document.createElement('div');
        text.className = "zone-text";
        text.textContent = zone.label ? zone.label : `Zone ${zone.zone}`;

        const playersInfo = document.createElement('div');
        playersInfo.className = "zone-players";
        playersInfo.textContent = `${zone.players !== undefined ? zone.players : 0}/${zone.maxPlayers !== undefined ? zone.maxPlayers : 15} joueurs`;

        card.appendChild(img);
        card.appendChild(text);
        card.appendChild(playersInfo);

        // Au clic, on envoie la sélection de la zone au parent
        card.addEventListener('click', () => {
            fetch(`https://${GetParentResourceName()}/zoneSelected`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({ zone: zone.zone })
            })
            .then(() => closeUI())
            .catch(err => console.error("Erreur lors de la sélection de la zone :", err));
        });
        
        zoneList.appendChild(card);
    });

    document.getElementById('arena-ui').style.display = "block";
}

/**
 * Ferme l'UI de sélection de zone et notifie le parent.
 */
function closeUI() {
    document.getElementById('arena-ui').style.display = "none";
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).catch(err => console.error("Erreur lors de la fermeture de l'UI :", err));
}

/**
 * Affiche le leaderboard à partir des statistiques reçues.
 * @param {Array} stats - Tableau des statistiques des joueurs.
 */
function showStats(stats) {
    const statsList = document.getElementById('stats-list');
    if (!statsList) {
        console.error("Element 'stats-list' non trouvé");
        return;
    }
    statsList.innerHTML = "";

    stats.forEach((item) => {
        const card = document.createElement('div');
        card.className = "stats-card";
        const text = document.createElement('div');
        text.className = "stats-text";
        text.innerHTML = `Player: ${item.player}<br>Kills: ${item.kills}<br>Deaths: ${item.deaths}<br>KD: ${item.kd.toFixed(2)}`;
        card.appendChild(text);
        statsList.appendChild(card);
    });
    document.getElementById('stats-ui').style.display = "block";
}

/**
 * Ajoute un message dans le kill feed (visible 5 secondes) à partir des informations fournies.
 * @param {Object} message - Objet contenant les informations du kill feed.
 */
function addKillFeedMessage(message) {
    const killfeedUI = document.getElementById('killfeed-ui');
    if (!killfeedUI) {
        console.error("Element 'killfeed-ui' non trouvé");
        return;
    }
    const messageDiv = document.createElement('div');
    messageDiv.className = 'killfeed-message';

    if (message.headshot) {
        const iconSpan = document.createElement('span');
        iconSpan.className = 'icon';
        iconSpan.innerHTML = '&#x1F480;'; // Icône tête de mort
        messageDiv.appendChild(iconSpan);
    }

    const textSpan = document.createElement('span');
    textSpan.textContent = `${message.killer} a tué ${message.victim}`;
    messageDiv.appendChild(textSpan);

    if (message.multiplier && message.multiplier > 1) {
        const multiplierSpan = document.createElement('span');
        multiplierSpan.className = 'multiplier';
        multiplierSpan.textContent = `x${message.multiplier}`;
        messageDiv.appendChild(multiplierSpan);
    }

    killfeedUI.appendChild(messageDiv);

    // Supprime le message après 5 secondes
    setTimeout(() => {
        messageDiv.remove();
    }, 5000);
}
