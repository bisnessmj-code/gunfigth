// ================================
// GLOBAL VARIABLES
// ================================
let currentZoneData = [];
let lobbyLeaderboardCache = [];

// ================================
// EVENT LISTENER - NUI MESSAGES
// ================================
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'show':
            if (data.zones && data.zones.length > 0) {
                currentZoneData = data.zones;
            }
            showUI();
            break;
        case 'showStats':
            showStats(data.stats);
            break;
        case 'showPersonalStats':
            showPersonalStats(data.stats);
            break;
        case 'showGlobalLeaderboard':
            showGlobalLeaderboard(data.stats);
            break;
        case 'showLobbyScoreboard':
            // Mettre à jour SEULEMENT la sidebar, pas le popup
            displayLobbyLeaderboard(data.stats);
            break;
        case 'killFeed':
            addKillFeedMessage(data.message);
            break;
        case 'updateZonePlayers':
            updateZonePlayers(data.zones);
            break;
        case 'clearKillFeed':
            clearKillFeed();
            break;
        default:
            console.log("Action inconnue:", data.action);
    }
});

// ================================
// DOM READY - BUTTON LISTENERS
// ================================
document.addEventListener('DOMContentLoaded', () => {
    // Close button for zone selection
    const closeBtn = document.getElementById('close-btn');
    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            closeUI();
        });
    }

    // Close button for leaderboard
    const statsCloseBtn = document.getElementById('stats-close-btn');
    if (statsCloseBtn) {
        statsCloseBtn.addEventListener('click', () => {
            closeStatsUI();
        });
    }

    // Personal Stats button
    const personalStatsBtn = document.getElementById('personal-stats-btn');
    if (personalStatsBtn) {
        personalStatsBtn.addEventListener('click', () => {
            console.log("Demande stats personnelles");
            postNUIMessage('getPersonalStats', {});
        });
    }

    // View full leaderboard button
    const viewFullBtn = document.getElementById('view-full-leaderboard');
    if (viewFullBtn) {
        viewFullBtn.addEventListener('click', () => {
            console.log("Ouverture classement complet depuis sidebar");
            // Toujours charger le classement complet depuis le serveur
            postNUIMessage('getGlobalLeaderboard', {});
        });
    }

    // Close button for personal stats
    const personalStatsCloseBtn = document.getElementById('personal-stats-close-btn');
    if (personalStatsCloseBtn) {
        personalStatsCloseBtn.addEventListener('click', () => {
            closePersonalStatsUI();
        });
    }

    // Close button for global leaderboard
    const globalLeaderboardCloseBtn = document.getElementById('global-leaderboard-close-btn');
    if (globalLeaderboardCloseBtn) {
        globalLeaderboardCloseBtn.addEventListener('click', () => {
            closeGlobalLeaderboardUI();
        });
    }

    // ESC key to close UIs
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            const arenaUI = document.getElementById('arena-ui');
            const statsUI = document.getElementById('stats-ui');
            const personalStatsUI = document.getElementById('personal-stats-ui');
            const globalLeaderboardUI = document.getElementById('global-leaderboard-ui');
            
            if (arenaUI && arenaUI.style.display === 'flex') {
                closeUI();
            }
            if (statsUI && statsUI.style.display === 'flex') {
                closeStatsUI();
            }
            if (personalStatsUI && personalStatsUI.style.display === 'flex') {
                closePersonalStatsUI();
            }
            if (globalLeaderboardUI && globalLeaderboardUI.style.display === 'flex') {
                closeGlobalLeaderboardUI();
            }
        }
    });

    // Test mode for kill feed (only in browser testing)
    if (window.location.search.indexOf("testMode=true") !== -1) {
        console.log("Test mode activé - Kill feed automatique");
        setInterval(() => {
            const fakeMessage = {
                killer: "TestKiller" + Math.floor(Math.random() * 10),
                victim: "TestVictim" + Math.floor(Math.random() * 10),
                headshot: Math.random() > 0.5,
                multiplier: Math.floor(Math.random() * 5) + 1
            };
            addKillFeedMessage(fakeMessage);
        }, 3000);
    }
});

// ================================
// ZONE SELECTION UI
// ================================
function showUI() {
    const arenaUI = document.getElementById('arena-ui');
    const zoneList = document.getElementById('zone-list');
    
    if (!arenaUI || !zoneList) {
        console.error("Elements UI non trouvés");
        return;
    }

    // Clear existing content
    zoneList.innerHTML = "";

    // Build zone cards
    currentZoneData.forEach((zone, index) => {
        const card = document.createElement('div');
        card.className = "zone-card";
        card.setAttribute("data-zone", zone.zone);
        card.style.animationDelay = `${index * 0.1}s`;

        const maxPlayers = zone.maxPlayers || 15;
        const currentPlayers = zone.players || 0;
        const isFull = currentPlayers >= maxPlayers;

        card.innerHTML = `
            <img class="zone-image" src="${zone.image || 'images/default.png'}" alt="${zone.label || 'Zone ' + zone.zone}">
            <div class="zone-info">
                <div class="zone-text">${zone.label || 'Zone ' + zone.zone}</div>
                <div class="zone-players">
                    <span class="players-count">${currentPlayers}/${maxPlayers}</span>
                    <span class="zone-status ${isFull ? 'full' : ''}">${isFull ? 'FULL' : 'ACTIVE'}</span>
                </div>
            </div>
        `;

        // Click event - only if not full
        if (!isFull) {
            card.addEventListener('click', () => {
                selectZone(zone.zone);
            });
        } else {
            card.style.opacity = '0.5';
            card.style.cursor = 'not-allowed';
        }

        zoneList.appendChild(card);
    });

    // Show UI with animation
    arenaUI.style.display = 'flex';
    
    // Charger le classement dans la sidebar du lobby
    console.log("Chargement du classement lobby sidebar...");
    postNUIMessage('getLobbyScoreboard', {});
}

function closeUI() {
    const arenaUI = document.getElementById('arena-ui');
    if (arenaUI) {
        arenaUI.style.display = 'none';
    }
    
    // CRITICAL: Send callback to Lua to release NUI focus
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).then(() => {
        console.log("UI fermée, focus libéré");
    }).catch(err => {
        console.error("Erreur lors de la fermeture de l'UI:", err);
    });
}

function selectZone(zoneNumber) {
    console.log("Zone sélectionnée:", zoneNumber);
    
    // Send zone selection to Lua
    fetch(`https://${GetParentResourceName()}/zoneSelected`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ zone: zoneNumber })
    }).then(() => {
        console.log("Sélection de zone envoyée");
        // Close UI after selection
        closeUI();
    }).catch(err => {
        console.error("Erreur lors de la sélection de la zone:", err);
    });
}

// ================================
// UPDATE ZONE PLAYERS COUNT
// ================================
function updateZonePlayers(zones) {
    console.log("Mise à jour des zones:", zones);
    currentZoneData = zones;

    const arenaUI = document.getElementById('arena-ui');
    if (arenaUI && arenaUI.style.display === 'flex') {
        // Update existing cards if UI is open
        zones.forEach((zone) => {
            const card = document.querySelector(`.zone-card[data-zone="${zone.zone}"]`);
            if (card) {
                const maxPlayers = zone.maxPlayers || 15;
                const currentPlayers = zone.players || 0;
                const isFull = currentPlayers >= maxPlayers;

                const playersCount = card.querySelector('.players-count');
                const status = card.querySelector('.zone-status');

                if (playersCount) {
                    playersCount.textContent = `${currentPlayers}/${maxPlayers}`;
                }

                if (status) {
                    status.textContent = isFull ? 'FULL' : 'ACTIVE';
                    status.classList.toggle('full', isFull);
                }

                // Update card interactivity
                if (isFull) {
                    card.style.opacity = '0.5';
                    card.style.cursor = 'not-allowed';
                    card.onclick = null;
                } else {
                    card.style.opacity = '1';
                    card.style.cursor = 'pointer';
                    card.onclick = () => selectZone(zone.zone);
                }
            }
        });
    }
}

// ================================
// LEADERBOARD UI
// ================================
function showStats(stats) {
    const statsUI = document.getElementById('stats-ui');
    const statsList = document.getElementById('stats-list');
    
    if (!statsUI || !statsList) {
        console.error("Elements stats non trouvés");
        return;
    }

    // Clear existing content
    statsList.innerHTML = "";

    // Build stats rows
    stats.forEach((item, index) => {
        const row = document.createElement('div');
        row.className = "stats-row";
        row.style.animationDelay = `${index * 0.05}s`;

        const rank = index + 1;
        
        // Convertir kd en nombre
        const kdValue = parseFloat(item.kd) || 0;

        row.innerHTML = `
            <div class="stats-col rank-col">
                <div class="rank-badge">${rank}</div>
            </div>
            <div class="stats-col player-col">${item.player || 'Inconnu'}</div>
            <div class="stats-col kills-col">${item.kills || 0}</div>
            <div class="stats-col deaths-col">${item.deaths || 0}</div>
            <div class="stats-col kd-col">${kdValue.toFixed(2)}</div>
        `;

        statsList.appendChild(row);
    });

    // Show UI with animation
    statsUI.style.display = 'flex';
}

function closeStatsUI() {
    const statsUI = document.getElementById('stats-ui');
    if (statsUI) {
        statsUI.style.display = 'none';
    }
    
	// Libérer le focus NUI
    postNUIMessage('closeStatsUI', {});
    // NE PAS libérer le focus ici - juste fermer la fenêtre des stats
    console.log("Stats UI fermée");
}

// ================================
// PERSONAL STATS UI
// ================================
function showPersonalStats(stats) {
    console.log("Affichage des stats personnelles:", stats);
    
    const personalStatsUI = document.getElementById('personal-stats-ui');
    if (!personalStatsUI) {
        console.error("Element 'personal-stats-ui' non trouvé");
        return;
    }

    // Mettre à jour le nom du joueur
    const playerNameEl = document.getElementById('personal-player-name');
    if (playerNameEl) {
        playerNameEl.textContent = stats.player || "VOTRE PROFIL";
    }

    // Convertir kd en nombre
    const kdValue = parseFloat(stats.kd) || 0;

    // Mettre à jour les cartes de stats
    const elements = {
        'personal-kills': stats.kills || 0,
        'personal-deaths': stats.deaths || 0,
        'personal-kd': kdValue.toFixed(2),
        'personal-streak': stats.best_streak || 0,
        'personal-headshots': stats.headshots || 0,
        'personal-playtime': formatPlaytime(stats.total_playtime || 0)
    };

    for (const [id, value] of Object.entries(elements)) {
        const el = document.getElementById(id);
        if (el) {
            el.textContent = value;
        }
    }

    // Mettre à jour les stats de session
    const sessionKills = document.getElementById('session-kills');
    if (sessionKills) sessionKills.textContent = stats.session_kills || 0;

    const sessionDeaths = document.getElementById('session-deaths');
    if (sessionDeaths) sessionDeaths.textContent = stats.session_deaths || 0;

    const currentStreak = document.getElementById('current-streak');
    if (currentStreak) currentStreak.textContent = stats.current_streak || 0;

    // Afficher l'UI
    personalStatsUI.style.display = 'flex';
}

function closePersonalStatsUI() {
    const personalStatsUI = document.getElementById('personal-stats-ui');
    if (personalStatsUI) {
        personalStatsUI.style.display = 'none';
    }
    postNUIMessage('closePersonalStatsUI', {});
    // NE PAS libérer le focus ici - juste fermer la fenêtre des stats
    console.log("Stats personnelles fermées");
}

// ================================
// GLOBAL LEADERBOARD UI
// ================================
function showGlobalLeaderboard(stats) {
    console.log("Affichage du classement global:", stats);
    
    const globalLeaderboardUI = document.getElementById('global-leaderboard-ui');
    const leaderboardList = document.getElementById('global-leaderboard-list');
    
    if (!globalLeaderboardUI || !leaderboardList) {
        console.error("Elements de classement global non trouvés");
        return;
    }

    // Clear existing content
    leaderboardList.innerHTML = "";

    // Build leaderboard rows
    stats.forEach((item) => {
        const row = document.createElement('div');
        row.className = "stats-row";
        row.style.animationDelay = `${item.rank * 0.05}s`;

        // Convertir kd en nombre
        const kdValue = parseFloat(item.kd) || 0;

        row.innerHTML = `
            <div class="stats-col rank-col">
                <div class="rank-badge">${item.rank}</div>
            </div>
            <div class="stats-col player-col">${item.player || 'Inconnu'}</div>
            <div class="stats-col kills-col">${item.kills || 0}</div>
            <div class="stats-col deaths-col">${item.deaths || 0}</div>
            <div class="stats-col headshots-col">${item.headshots || 0}</div>
            <div class="stats-col streak-col">${item.best_streak || 0}</div>
            <div class="stats-col kd-col">${kdValue.toFixed(2)}</div>
        `;

        leaderboardList.appendChild(row);
    });

    // Show UI with animation
    globalLeaderboardUI.style.display = 'flex';
}

function closeGlobalLeaderboardUI() {
    const globalLeaderboardUI = document.getElementById('global-leaderboard-ui');
    if (globalLeaderboardUI) {
        globalLeaderboardUI.style.display = 'none';
    }
    postNUIMessage('closeGlobalLeaderboardUI', {});
    // NE PAS libérer le focus ici - juste fermer la fenêtre du classement
    console.log("Classement global fermé");
}

// ================================
// LOBBY LEADERBOARD SIDEBAR
// ================================
function displayLobbyLeaderboard(stats) {
    console.log("Affichage lobby leaderboard:", stats);
    const lobbyList = document.getElementById('lobby-leaderboard-list');
    if (!lobbyList) return;

    // Sauvegarder en cache
    lobbyLeaderboardCache = stats;

    // Clear
    lobbyList.innerHTML = '';

    // Top 10 seulement
    const top10 = stats.slice(0, 10);

    if (top10.length === 0) {
        lobbyList.innerHTML = `
            <div class="leaderboard-loading">
                <p style="text-align: center; color: var(--text-secondary);">
                    Aucun classement disponible.<br>
                    Soyez le premier à jouer !
                </p>
            </div>
        `;
        return;
    }

    top10.forEach((player) => {
        const entry = document.createElement('div');
        entry.className = 'lobby-leaderboard-entry';
        entry.style.animationDelay = `${player.rank * 0.05}s`;

        // Convertir kd en nombre
        const kdValue = parseFloat(player.kd) || 0;

        entry.innerHTML = `
            <div class="lobby-rank">${player.rank}</div>
            <div class="lobby-player-info">
                <div class="lobby-player-name">${player.player || 'Inconnu'}</div>
                <div class="lobby-player-stats">
                    <div class="lobby-stat">
                        <span class="lobby-stat-label">K:</span>
                        <span class="lobby-stat-value">${player.kills || 0}</span>
                    </div>
                    <div class="lobby-stat">
                        <span class="lobby-stat-label">D:</span>
                        <span class="lobby-stat-value">${player.deaths || 0}</span>
                    </div>
                </div>
            </div>
            <div class="lobby-kd">${kdValue.toFixed(2)}</div>
        `;

        lobbyList.appendChild(entry);
    });

    console.log(`Lobby leaderboard affiché: ${top10.length} entrées`);
}

// ================================
// KILL FEED
// ================================
function addKillFeedMessage(message) {
    const killfeedUI = document.getElementById('killfeed-ui');
    if (!killfeedUI) {
        console.error("Element killfeed-ui non trouvé");
        return;
    }

    const messageDiv = document.createElement('div');
    messageDiv.className = 'killfeed-message';

    // Build message content
    let iconHTML = '';
    if (message.headshot) {
        iconHTML = `<div class="kill-icon headshot">💀</div>`;
    } else {
        iconHTML = `<div class="kill-icon">⚔️</div>`;
    }

    let multiplierHTML = '';
    if (message.multiplier && message.multiplier > 1) {
        multiplierHTML = `<div class="kill-multiplier">x${message.multiplier}</div>`;
    }

    messageDiv.innerHTML = `
        ${iconHTML}
        <div class="kill-text">
            <span class="kill-killer">${message.killer}</span>
            <span> a éliminé </span>
            <span class="kill-victim">${message.victim}</span>
        </div>
        ${multiplierHTML}
    `;

    killfeedUI.appendChild(messageDiv);

    // Auto-remove after 5 seconds
    setTimeout(() => {
        if (messageDiv.parentNode) {
            messageDiv.remove();
        }
    }, 5000);
}

function clearKillFeed() {
    const killfeedUI = document.getElementById('killfeed-ui');
    if (killfeedUI) {
        killfeedUI.innerHTML = '';
    }
}

// ================================
// UTILITY FUNCTIONS
// ================================
function formatPlaytime(seconds) {
    if (seconds < 60) {
        return seconds + 's';
    } else if (seconds < 3600) {
        return Math.floor(seconds / 60) + 'min';
    } else {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours + 'h' + (minutes > 0 ? ' ' + minutes + 'min' : '');
    }
}

function postNUIMessage(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(err => console.error(`Erreur lors de l'envoi du message ${action}:`, err));
}

function GetParentResourceName() {
    if (window.location.hostname === 'localhost' || window.location.hostname === '' || window.location.hostname === '127.0.0.1') {
        return 'gunfight_arena'; // Fallback for testing
    }
    
    const pathArray = window.location.pathname.split('/');
    const resourceIndex = pathArray.findIndex(part => part === 'html') - 1;
    if (resourceIndex >= 0 && pathArray[resourceIndex]) {
        return pathArray[resourceIndex];
    }
    
    return 'gunfight_arena';
}

// ESC key to close UIs
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const arenaUI = document.getElementById('arena-ui');
        const statsUI = document.getElementById('stats-ui');
        const personalStatsUI = document.getElementById('personal-stats-ui');
        const globalLeaderboardUI = document.getElementById('global-leaderboard-ui');
        
        if (arenaUI && arenaUI.style.display === 'flex') {
            closeUI();
        } else if (statsUI && statsUI.style.display === 'flex') {
            closeStatsUI();
        } else if (personalStatsUI && personalStatsUI.style.display === 'flex') {
            closePersonalStatsUI();
        } else if (globalLeaderboardUI && globalLeaderboardUI.style.display === 'flex') {
            closeGlobalLeaderboardUI();
        }
    }
});
// ================================
// CONSOLE INFO
// ================================
console.log('%c🎮 Gunfight Arena UI Loaded', 'color: #00fff7; font-size: 16px; font-weight: bold;');
console.log('%cDeveloped with ❤️ for FiveM', 'color: #8892b0; font-size: 12px;');
console.log('Resource Name:', GetParentResourceName());