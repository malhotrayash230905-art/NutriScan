const chat = {
    init() {
        this.input = document.getElementById('chat-input');
        this.sendBtn = document.getElementById('send-btn');
        this.history = document.getElementById('chat-history');

        this.bindEvents();
    },

    bindEvents() {
        if (!this.input || !this.sendBtn) return;

        this.sendBtn.addEventListener('click', () => this.sendMessage());
        this.input.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.sendMessage();
        });
    },

    sendMessage() {
        const text = this.input.value.trim();
        if (!text) return;

        // Add user message
        this.addMessage(text, 'user');
        this.input.value = '';

        // Simulate AI thinking and typing
        this.showTyping();

        setTimeout(() => {
            this.removeTyping();
            this.generateMockResponse(text);
        }, 1500);
    },

    addMessage(text, sender) {
        const msgDiv = document.createElement('div');
        msgDiv.className = `message ${sender}`;

        const avatar = sender === 'user' ? '<i class="bx bx-user"></i>' : '<i class="bx bx-bot"></i>';

        msgDiv.innerHTML = `
            <div class="avatar">${avatar}</div>
            <div class="bubble">${text}</div>
        `;

        this.history.appendChild(msgDiv);
        this.scrollToBottom();
    },

    showTyping() {
        const typingDiv = document.createElement('div');
        typingDiv.className = `message ai typing-indicator`;
        typingDiv.id = 'typing';
        typingDiv.innerHTML = `
            <div class="avatar"><i class="bx bx-bot"></i></div>
            <div class="bubble">...</div>
        `;
        this.history.appendChild(typingDiv);
        this.scrollToBottom();
    },

    removeTyping() {
        const typingDiv = document.getElementById('typing');
        if (typingDiv) typingDiv.remove();
    },

    generateMockResponse(userText) {
        const responses = [
            "Based on your recent report, I recommend increasing your water intake and eating more leafy greens to boost your iron levels.",
            "That's a great question. Balancing macronutrients is key. Since you're on a slight caloric deficit, prioritize protein to maintain muscle mass.",
            "I've updated your daily recommendations. I've added a Omega-3 supplement reminder for you.",
            "Remember to log your meals so I can give you the most accurate feedback!"
        ];
        const randomResponse = responses[Math.floor(Math.random() * responses.length)];
        this.addMessage(randomResponse, 'ai');
    },

    scrollToBottom() {
        this.history.scrollTop = this.history.scrollHeight;
    }
};

document.addEventListener('DOMContentLoaded', () => {
    chat.init();
});
