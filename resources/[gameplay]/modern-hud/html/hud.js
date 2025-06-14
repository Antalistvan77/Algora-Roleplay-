// ==============================
// MODERN HUD JAVASCRIPT RENDSZER
// ==============================

class ModernHUD {
    constructor() {
        this.notifications = [];
        this.achievements = [];
        this.moneyChanges = [];
        this.experienceChanges = [];
        
        this.notificationContainer = document.getElementById('notification-container');
        this.achievementContainer = document.getElementById('achievement-container');
        this.levelUpContainer = document.getElementById('level-up-container');
        this.moneyChangeContainer = document.getElementById('money-change-container');
        this.experienceContainer = document.getElementById('experience-container');
        
        this.setupEventListeners();
    }
    
    // ==============================
    // EVENT LISTENEREK
    // ==============================
    setupEventListeners() {
        // MTA Event listenerek
        if (typeof window.mta !== 'undefined') {
            // Ha MTA környezetben vagyunk
            window.addEventListener('message', this.handleMTAMessage.bind(this));
        }
        
        // Teszt események (fejlesztés alatt)
        document.addEventListener('keydown', (e) => {
            if (e.key === 'F1') {
                this.showNotification('Teszt Notification', 'Ez egy teszt üzenet!', 'success');
            } else if (e.key === 'F2') {
                this.showMoneyChange(500, 'Teszt jutalom');
            } else if (e.key === 'F3') {
                this.showExperienceChange(50, 'Teszt tapasztalat');
            } else if (e.key === 'F4') {
                this.showLevelUp(5, 2500);
            } else if (e.key === 'F5') {
                this.showAchievement('🏆', 'Első lépések', 'Sikeresen csatlakoztál a szerverre!');
            }
        });
    }
    
    // ==============================
    // MTA ÜZENET KEZELÉS
    // ==============================
    handleMTAMessage(event) {
        const data = event.data;
        
        switch(data.type) {
            case 'notification':
                this.showNotification(data.title, data.message, data.style || 'info');
                break;
            case 'money-change':
                this.showMoneyChange(data.amount, data.reason);
                break;
            case 'experience-change':
                this.showExperienceChange(data.amount, data.reason);
                break;
            case 'level-up':
                this.showLevelUp(data.level, data.reward);
                break;
            case 'achievement':
                this.showAchievement(data.icon, data.title, data.description);
                break;
        }
    }
    
    // ==============================
    // NOTIFIKÁCIÓK
    // ==============================
    showNotification(title, message, type = 'info', duration = 5000) {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        
        notification.innerHTML = `
            <div class="notification-header">${title}</div>
            <div class="notification-content">${message}</div>
        `;
        
        this.notificationContainer.appendChild(notification);
        this.notifications.push(notification);
        
        // Automatikus eltávolítás
        setTimeout(() => {
            this.removeNotification(notification);
        }, duration);
        
        // Hangeffekt (ha van)
        this.playSound('notification');
    }
    
    removeNotification(notification) {
        notification.classList.add('fade-out');
        
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
            
            const index = this.notifications.indexOf(notification);
            if (index > -1) {
                this.notifications.splice(index, 1);
            }
        }, 500);
    }
    
    // ==============================
    // PÉNZ VÁLTOZÁSOK
    // ==============================
    showMoneyChange(amount, reason = '') {
        const moneyChange = document.createElement('div');
        moneyChange.className = `money-change ${amount > 0 ? 'positive' : 'negative'}`;
        
        const sign = amount > 0 ? '+' : '';
        const formattedAmount = this.formatNumber(Math.abs(amount));
        
        moneyChange.innerHTML = `${sign}$${formattedAmount}`;
        if (reason) {
            moneyChange.innerHTML += `<br><small>${reason}</small>`;
        }
        
        this.moneyChangeContainer.appendChild(moneyChange);
        
        // Automatikus eltávolítás
        setTimeout(() => {
            if (moneyChange.parentNode) {
                moneyChange.parentNode.removeChild(moneyChange);
            }
        }, 3000);
        
        // Hangeffekt
        this.playSound(amount > 0 ? 'money-gain' : 'money-loss');
    }
    
    // ==============================
    // TAPASZTALAT VÁLTOZÁSOK
    // ==============================
    showExperienceChange(amount, reason = '') {
        const expChange = document.createElement('div');
        expChange.className = 'experience-change';
        
        expChange.innerHTML = `+${amount} XP`;
        if (reason) {
            expChange.innerHTML += `<br><small>${reason}</small>`;
        }
        
        this.experienceContainer.appendChild(expChange);
        
        // Automatikus eltávolítás
        setTimeout(() => {
            if (expChange.parentNode) {
                expChange.parentNode.removeChild(expChange);
            }
        }, 3000);
        
        // Hangeffekt
        this.playSound('experience');
    }
    
    // ==============================
    // SZINTLÉPÉS
    // ==============================
    showLevelUp(level, reward) {
        const levelUpLevel = document.getElementById('level-up-level');
        const levelUpReward = document.getElementById('level-up-reward');
        
        levelUpLevel.textContent = `Új szint: ${level}`;
        levelUpReward.textContent = `Jutalom: $${this.formatNumber(reward)}`;
        
        this.levelUpContainer.classList.remove('hidden');
        
        // Hangeffekt
        this.playSound('level-up');
        
        // Automatikus elrejtés
        setTimeout(() => {
            this.levelUpContainer.classList.add('hidden');
        }, 4000);
    }
    
    // ==============================
    // EREDMÉNYEK/ACHIEVEMENTEK
    // ==============================
    showAchievement(icon, title, description, duration = 6000) {
        const achievement = document.createElement('div');
        achievement.className = 'achievement';
        
        achievement.innerHTML = `
            <div class="achievement-icon">${icon}</div>
            <div class="achievement-title">${title}</div>
            <div class="achievement-description">${description}</div>
        `;
        
        this.achievementContainer.appendChild(achievement);
        this.achievements.push(achievement);
        
        // Automatikus eltávolítás
        setTimeout(() => {
            this.removeAchievement(achievement);
        }, duration);
        
        // Hangeffekt
        this.playSound('achievement');
    }
    
    removeAchievement(achievement) {
        achievement.style.animation = 'fadeOut 0.5s ease-out forwards';
        
        setTimeout(() => {
            if (achievement.parentNode) {
                achievement.parentNode.removeChild(achievement);
            }
            
            const index = this.achievements.indexOf(achievement);
            if (index > -1) {
                this.achievements.splice(index, 1);
            }
        }, 500);
    }
    
    // ==============================
    // SEGÉD FUNKCIÓK
    // ==============================
    formatNumber(num) {
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }
    
    playSound(soundType) {
        // Hangeffektek lejátszása (MTA-ban implementálva)
        if (typeof window.mta !== 'undefined' && window.mta.triggerEvent) {
            window.mta.triggerEvent('playHUDSound', soundType);
        }
    }
    
    // ==============================
    // PUBLIKUS MÓDSZEREK (MTA-ból hívhatók)
    // ==============================
    static showNotification(title, message, type, duration) {
        if (window.modernHUD) {
            window.modernHUD.showNotification(title, message, type, duration);
        }
    }
    
    static showMoneyChange(amount, reason) {
        if (window.modernHUD) {
            window.modernHUD.showMoneyChange(amount, reason);
        }
    }
    
    static showExperienceChange(amount, reason) {
        if (window.modernHUD) {
            window.modernHUD.showExperienceChange(amount, reason);
        }
    }
    
    static showLevelUp(level, reward) {
        if (window.modernHUD) {
            window.modernHUD.showLevelUp(level, reward);
        }
    }
    
    static showAchievement(icon, title, description, duration) {
        if (window.modernHUD) {
            window.modernHUD.showAchievement(icon, title, description, duration);
        }
    }
    
    // ==============================
    // ÖSSZES ELEM ELREJTÉSE
    // ==============================
    hideAll() {
        this.notifications.forEach(notification => {
            this.removeNotification(notification);
        });
        
        this.achievements.forEach(achievement => {
            this.removeAchievement(achievement);
        });
        
        this.levelUpContainer.classList.add('hidden');
        
        // Pénz és tapasztalat változások törlése
        this.moneyChangeContainer.innerHTML = '';
        this.experienceContainer.innerHTML = '';
    }
    
    // ==============================
    // HUD LÁTHATÓSÁG VEZÉRLÉSE
    // ==============================
    setVisible(visible) {
        document.body.style.display = visible ? 'block' : 'none';
    }
}

// ==============================
// INICIALIZÁLÁS
// ==============================
document.addEventListener('DOMContentLoaded', () => {
    window.modernHUD = new ModernHUD();
    console.log('Modern HUD JavaScript betöltve!');
    
    // Teszt üzenet megjelenítése
    setTimeout(() => {
        window.modernHUD.showNotification(
            'HUD Rendszer', 
            'Modern HUD sikeresen betöltve! Nyomj F1-F5 gombokat a teszteléshez.', 
            'success'
        );
    }, 1000);
});

// ==============================
// GLOBÁLIS FÜGGVÉNYEK (MTA számára)
// ==============================
window.showNotification = ModernHUD.showNotification;
window.showMoneyChange = ModernHUD.showMoneyChange;
window.showExperienceChange = ModernHUD.showExperienceChange;
window.showLevelUp = ModernHUD.showLevelUp;
window.showAchievement = ModernHUD.showAchievement; 