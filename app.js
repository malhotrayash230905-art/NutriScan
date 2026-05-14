const app = {
    init() {
        this.cacheDOM();
        this.bindEvents();
        this.checkAuth();
    },

    cacheDOM() {
        this.navItems = document.querySelectorAll('.nav-item:not(#logout-btn)');
        this.views = document.querySelectorAll('.view');
        this.loginScreen = document.getElementById('login-screen');
        this.mainApp = document.getElementById('main-app');
        this.loginForm = document.getElementById('login-form');
        this.logoutBtn = document.getElementById('logout-btn');
        this.emailInput = document.getElementById('email');

        this.userNameElements = {
            sidebar: document.getElementById('user-sidebar-name'),
            dashboard: document.getElementById('dashboard-name'),
            avatar: document.getElementById('user-avatar'),
            chat: document.querySelector('#chat-welcome-msg .bubble')
        };
        
        this.vegToggle = document.getElementById('veg-toggle');
        this.vegMeals = document.querySelectorAll('.veg-meal');
        this.nonVegMeals = document.querySelectorAll('.non-veg-meal');
        
        this.inputHeight = document.getElementById('input-height');
        this.inputWeight = document.getElementById('input-weight');
        this.displayBmi = document.getElementById('display-bmi');
        this.macroElements = document.querySelectorAll('.meal-macros');
    },

    bindEvents() {
        this.navItems.forEach(item => {
            item.addEventListener('click', () => {
                const target = item.getAttribute('data-target');
                this.switchView(target);
            });
        });

        if (this.loginForm) {
            this.loginForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.login();
            });
        }

        if (this.logoutBtn) {
            this.logoutBtn.addEventListener('click', () => this.logout());
        }

        if (this.vegToggle) {
            this.vegToggle.addEventListener('change', (e) => {
                this.updateDietPlan(e.target.checked);
            });
        }
        
        if (this.inputHeight && this.inputWeight) {
            const updateMetrics = () => {
                let h = parseFloat(this.inputHeight.value);
                let w = parseFloat(this.inputWeight.value);
                if (isNaN(h) || h <= 0) h = 180;
                if (isNaN(w) || w <= 0) w = 75;
                
                const bmi = w / Math.pow(h/100, 2);
                if (this.displayBmi) this.displayBmi.textContent = bmi.toFixed(1);
                
                this.updateDietQuantity(w);
            };
            
            this.inputHeight.addEventListener('input', updateMetrics);
            this.inputWeight.addEventListener('input', updateMetrics);
        }
    },

    updateDietPlan(isVeg) {
        if (isVeg) {
            this.nonVegMeals.forEach(meal => meal.classList.add('hidden'));
            this.vegMeals.forEach(meal => meal.classList.remove('hidden'));
        } else {
            this.vegMeals.forEach(meal => meal.classList.add('hidden'));
            this.nonVegMeals.forEach(meal => meal.classList.remove('hidden'));
        }
    },
    
    updateDietQuantity(weight) {
        const ratio = weight / 75.0;
        
        if (this.macroElements) {
            this.macroElements.forEach(el => {
                const baseKcal = parseFloat(el.getAttribute('data-base-kcal')) || 0;
                const basePro = parseFloat(el.getAttribute('data-base-pro')) || 0;
                const baseQty = parseFloat(el.getAttribute('data-base-qty')) || 0;
                const unit = el.getAttribute('data-base-unit') || '';
                
                const kcal = Math.round(baseKcal * ratio);
                const pro = Math.round(basePro * ratio);
                const qty = Math.round(baseQty * ratio);
                
                const statsSpan = el.querySelector('.macro-stats');
                const qtySpan = el.querySelector('.macro-qty');
                
                if (statsSpan) statsSpan.textContent = `${kcal} kcal • ${pro}g Protein`;
                if (qtySpan) qtySpan.textContent = `Quantity: ${qty} ${unit}`;
            });
        }
    },

    checkAuth() {
        const isAuth = localStorage.getItem('nutri_auth') === 'true';
        if (isAuth) {
            const name = localStorage.getItem('nutri_user_name') || 'Shaurya';
            this.updateUserNames(name);
            this.showApp();
        } else {
            this.showLogin();
        }
    },

    login() {
        const email = this.emailInput ? this.emailInput.value.trim() : '';
        let name = email.split('@')[0];
        if (!name) name = "User";
        // Capitalize the first letter
        name = name.charAt(0).toUpperCase() + name.slice(1);

        localStorage.setItem('nutri_auth', 'true');
        localStorage.setItem('nutri_user_name', name);
        this.updateUserNames(name);

        this.loginForm.querySelector('button').innerHTML = "<i class='bx bx-loader-alt bx-spin'></i>";

        // Simulating network delay before hiding login
        setTimeout(() => {
            this.showApp();
            this.loginForm.querySelector('button').innerHTML = "Sign In";
        }, 800);
    },

    updateUserNames(name) {
        if (this.userNameElements.sidebar) this.userNameElements.sidebar.textContent = name;
        if (this.userNameElements.dashboard) this.userNameElements.dashboard.textContent = name;
        if (this.userNameElements.avatar) {
            this.userNameElements.avatar.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=0D8ABC&color=fff`;
        }
        if (this.userNameElements.chat) {
            this.userNameElements.chat.innerHTML = `Hello ${name}! I've reviewed your latest health metrics. How can I help you today?`;
        }
    },

    logout() {
        localStorage.removeItem('nutri_auth');
        this.switchView('dashboard'); // Reset view for next login
        this.showLogin();
    },

    showLogin() {
        this.loginScreen.classList.remove('hidden');
        this.mainApp.classList.add('hidden');
    },

    showApp() {
        this.loginScreen.classList.add('hidden');
        this.mainApp.classList.remove('hidden');
    },

    switchView(targetId) {
        // Update Nav
        this.navItems.forEach(item => {
            if (item.getAttribute('data-target') === targetId) {
                item.classList.add('active');
            } else {
                item.classList.remove('active');
            }
        });

        // Update View
        this.views.forEach(view => {
            if (view.id === targetId) {
                view.classList.add('active');
            } else {
                view.classList.remove('active');
            }
        });
    }
};

document.addEventListener('DOMContentLoaded', () => {
    app.init();
});
