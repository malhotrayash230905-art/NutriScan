const scanner = {
    init() {
        this.optCamera = document.getElementById('opt-camera');
        this.optFiles = document.getElementById('opt-files');
        this.scannerActions = document.getElementById('scanner-actions');
        this.scanResults = document.getElementById('scan-results');

        if (!this.scannerActions) return;
        this.bindEvents();
    },

    bindEvents() {
        if (this.optCamera) {
            this.optCamera.addEventListener('click', () => {
                const input = document.createElement('input');
                input.type = 'file';
                input.accept = 'image/*';
                input.capture = 'environment';
                input.onchange = e => {
                    if (e.target.files[0]) {
                        this.simulateScan(e.target.files[0].name);
                    }
                };
                input.click();
            });
        }

        if (this.optFiles) {
            this.optFiles.addEventListener('click', () => {
                const input = document.createElement('input');
                input.type = 'file';
                input.accept = 'application/pdf, image/*';
                input.onchange = e => {
                    if (e.target.files[0]) {
                        this.simulateScan(e.target.files[0].name);
                    }
                };
                input.click();
            });
        }
    },

    simulateScan(filename) {
        this.scannerActions.innerHTML = `
            <div class="upload-area" style="width: 100%;">
                <i class='bx bx-loader-alt bx-spin'></i>
                <h3>Analyzing...</h3>
                <p>Extracting health biomarkers from ${filename}</p>
            </div>
        `;

        setTimeout(() => {
            this.scannerActions.classList.add('hidden');
            this.showResults();
        }, 2500);
    },

    showResults() {
        this.scanResults.classList.remove('hidden');
        this.scanResults.innerHTML = `
            <div class="results-header" style="margin-bottom: 1.5rem;">
                <h3><i class='bx bx-check-circle text-green'></i> Analysis Complete</h3>
                <p>We've successfully extracted key metrics from your report.</p>
            </div>
            
            <div style="display: grid; gap: 1rem; margin-bottom: 2rem;">
                <div class="glass-panel" style="padding: 1rem; border-left: 4px solid var(--accent-orange);">
                    <h4>Vitamin D Level</h4>
                    <p style="font-size: 1.2rem; font-weight: 600;">Suboptimal (22 ng/mL)</p>
                    <small>Recommendation: Increase sunlight exposure and consumption of fortified foods.</small>
                </div>
                <div class="glass-panel" style="padding: 1rem; border-left: 4px solid var(--accent-green);">
                    <h4>Fasting Glucose</h4>
                    <p style="font-size: 1.2rem; font-weight: 600;">Normal (85 mg/dL)</p>
                    <small>Recommendation: Maintain current carbohydrate intake.</small>
                </div>
            </div>
            
            <button class="btn btn-primary" onclick="app.switchView('nutrition')">View Updated Diet Plan</button>
        `;
    }
};

document.addEventListener('DOMContentLoaded', () => {
    scanner.init();
});
