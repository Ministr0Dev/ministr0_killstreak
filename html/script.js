// Ministr0 Dev — Killstreak UI Script | discord.gg/4eh8

const killstreakContainer = document.getElementById('killstreak-container');
const killstreakTitle = document.getElementById('killstreak-title');
const killstreakSubtitle = document.getElementById('killstreak-subtitle');
const killstreakCounter = document.getElementById('killstreak-counter');
const killfeedContainer = document.getElementById('killfeed-container');
const notificationContainer = document.getElementById('notification-container');
const leaderboardContainer = document.getElementById('leaderboard-container');
const leaderboardBody = document.getElementById('leaderboard-body');

window.addEventListener('message', function(event) {
    const data = event.data;
    switch (data.type) {
        case 'SHOW_KILLSTREAK':
            killstreakTitle.textContent = data.title;
            killstreakSubtitle.textContent = data.subtitle;
            killstreakCounter.textContent = '⚡' + data.kills;
            if (data.color) {
                killstreakTitle.style.color = `rgb(${data.color.r}, ${data.color.g}, ${data.color.b})`;
                killstreakSubtitle.style.color = `rgb(${data.color.r}, ${data.color.g}, ${data.color.b})`;
            }
            killstreakContainer.classList.add('show');
            setTimeout(() => killstreakContainer.classList.remove('show'), 3000);
            break;

        case 'ADD_KILLFEED':
            const entry = document.createElement('div');
            entry.className = 'killfeed-entry';
            const badge = data.streak >= 3 ? `<span class="streak-badge">${data.streak}</span>` : '';
            entry.innerHTML = `<span><span class="killer">${data.killer}</span><span class="weapon">[${data.weapon||'???'}]</span><span class="victim">${data.victim}</span></span>${badge}`;
            killfeedContainer.appendChild(entry);
            if (killfeedContainer.children.length > 10) killfeedContainer.removeChild(killfeedContainer.firstChild);
            setTimeout(() => {
                if (entry.parentNode) {
                    entry.style.transition = 'opacity 0.5s ease';
                    entry.style.opacity = '0';
                    setTimeout(() => { if (entry.parentNode) entry.parentNode.removeChild(entry); }, 500);
                }
            }, 6000);
            break;

        case 'SHOW_NOTIFICATION':
            const notif = document.createElement('div');
            notif.className = `notification-item ${data.notifType || 'info'}`;
            notif.textContent = data.message;
            notificationContainer.appendChild(notif);
            setTimeout(() => {
                if (notif.parentNode) {
                    notif.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
                    notif.style.opacity = '0';
                    notif.style.transform = 'translateX(120%)';
                    setTimeout(() => { if (notif.parentNode) notif.parentNode.removeChild(notif); }, 300);
                }
            }, 5000);
            break;

        case 'SHOW_LEADERBOARD':
            leaderboardBody.innerHTML = '';
            if (!data.entries || data.entries.length === 0) {
                leaderboardBody.innerHTML = '<div style="text-align:center;padding:20px;color:rgba(255,255,255,0.5);">No data available yet.</div>';
            } else {
                const medals = ['🥇', '🥈', '🥉'];
                data.entries.forEach((entry, i) => {
                    const row = document.createElement('div');
                    row.className = 'lb-entry';
                    row.innerHTML = `<span class="rank">${i < 3 ? medals[i] : '#' + (i+1)}</span><span class="name">${entry.name || 'Unknown'}</span><span class="streak">${entry.best_streak || 0}</span>`;
                    leaderboardBody.appendChild(row);
                });
            }
            leaderboardContainer.classList.add('show');
            break;

        case 'HIDE_LEADERBOARD':
            leaderboardContainer.classList.remove('show');
            break;
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') leaderboardContainer.classList.remove('show');
});

console.log('Ministr0 Dev — Killstreak UI loaded. | discord.gg/4eh8');
