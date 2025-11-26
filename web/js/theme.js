// Sistema de tema oscuro
function toggleTheme() {
    const html = document.documentElement;
    const body = document.body;
    const currentTheme = html.classList.contains('dark') ? 'dark' : 'light';
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';

    if (newTheme === 'dark') {
        html.classList.add('dark');
        body.classList.add('dark');
        document.getElementById('theme-icon').textContent = '☀️';
    } else {
        html.classList.remove('dark');
        body.classList.remove('dark');
        document.getElementById('theme-icon').textContent = '🌙';
    }

    // Guardar preferencia
    localStorage.setItem('theme', newTheme);

    // Forzar repaint para asegurar que los estilos se apliquen
    void document.body.offsetHeight;
}

// Cargar tema guardado al iniciar
(function () {
    const savedTheme = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const html = document.documentElement;
    const body = document.body;

    if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
        html.classList.add('dark');
        body.classList.add('dark');
        document.getElementById('theme-icon').textContent = '☀️';
    } else {
        html.classList.remove('dark');
        body.classList.remove('dark');
        document.getElementById('theme-icon').textContent = '🌙';
    }
})();
