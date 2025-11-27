/**
 * Dynamic Prism Loader for Docsify
 * Loads Prism language components on-demand based on detected code blocks
 */

(function () {
    // Cache de scripts cargados para evitar cargas duplicadas
    const loadedLanguages = new Set(['markup', 'css', 'clike', 'javascript']);

    // Mapeo de aliases de lenguajes a nombres de componentes Prism
    const languageAliases = {
        'js': 'javascript',
        'ts': 'typescript',
        'py': 'python',
        'sh': 'bash',
        'shell': 'bash',
        'yml': 'yaml',
        'dockerfile': 'docker',
        'html': 'markup',
        'xml': 'markup',
        'svg': 'markup',
        'c++': 'cpp',
        'c#': 'csharp',
        'cs': 'csharp',
        'rs': 'rust',
        'rb': 'ruby',
        'go': 'go',
        'java': 'java',
        'php': 'php',
        'sql': 'sql',
        'json': 'json',
        'md': 'markdown',
        'nginx': 'nginx'
    };

    // Dependencias de lenguajes (algunos lenguajes requieren otros)
    const languageDependencies = {
        'typescript': ['javascript'],
        'jsx': ['javascript'],
        'tsx': ['typescript', 'jsx'],
        'cpp': ['c'],
        'csharp': ['clike'],
        'java': ['clike'],
        'php': ['markup'],
        'markdown': ['markup']
    };

    /**
     * Normaliza el nombre del lenguaje usando aliases
     */
    function normalizeLanguage(lang) {
        if (!lang) return null;
        lang = lang.toLowerCase().trim();
        return languageAliases[lang] || lang;
    }

    /**
     * Carga un componente de Prism de forma asíncrona
     */
    function loadPrismLanguage(language) {
        return new Promise((resolve, reject) => {
            // Si ya está cargado, resolver inmediatamente
            if (loadedLanguages.has(language)) {
                resolve();
                return;
            }

            // Cargar dependencias primero
            const dependencies = languageDependencies[language] || [];
            const dependencyPromises = dependencies.map(dep => loadPrismLanguage(dep));

            Promise.all(dependencyPromises).then(() => {
                const script = document.createElement('script');
                script.src = `https://cdn.jsdelivr.net/npm/prismjs@1/components/prism-${language}.min.js`;
                script.async = true;

                script.onload = () => {
                    loadedLanguages.add(language);
                    console.log(`[Prism] Cargado: ${language}`);
                    resolve();
                };

                script.onerror = () => {
                    console.warn(`[Prism] No se pudo cargar: ${language}`);
                    reject(new Error(`Failed to load language: ${language}`));
                };

                document.body.appendChild(script);
            }).catch(reject);
        });
    }

    /**
     * Detecta los lenguajes usados en el contenido HTML
     */
    function detectLanguages(html) {
        const languages = new Set();

        // Buscar bloques de código con la clase language-*
        const codeBlockRegex = /class="lang-(\w+)"/g;
        let match;

        while ((match = codeBlockRegex.exec(html)) !== null) {
            const lang = normalizeLanguage(match[1]);
            if (lang) {
                languages.add(lang);
            }
        }

        // También buscar en el markdown antes de ser procesado (formato ```lenguaje)
        const markdownCodeRegex = /```(\w+)/g;
        while ((match = markdownCodeRegex.exec(html)) !== null) {
            const lang = normalizeLanguage(match[1]);
            if (lang) {
                languages.add(lang);
            }
        }

        return Array.from(languages);
    }

    /**
     * Plugin de Docsify para carga dinámica de Prism
     */
    window.$docsify = window.$docsify || {};
    window.$docsify.plugins = window.$docsify.plugins || [];

    window.$docsify.plugins.push(function (hook) {
        // Hook que se ejecuta después de convertir el markdown a HTML
        hook.afterEach(function (html, next) {
            const languages = detectLanguages(html);

            if (languages.length > 0) {
                console.log(`[Prism] Detectados lenguajes:`, languages);

                // Cargar todos los lenguajes detectados
                Promise.all(languages.map(lang => loadPrismLanguage(lang)))
                    .then(() => {
                        // Re-aplicar el highlighting después de cargar los lenguajes
                        next(html);

                        // Forzar re-highlight después de que el DOM se actualice
                        setTimeout(() => {
                            if (window.Prism) {
                                window.Prism.highlightAll();
                            }
                        }, 50);
                    })
                    .catch(err => {
                        console.error('[Prism] Error cargando lenguajes:', err);
                        next(html);
                    });
            } else {
                next(html);
            }
        });

        // Hook para re-aplicar highlighting después de que el DOM se actualice
        hook.doneEach(function () {
            if (window.Prism) {
                window.Prism.highlightAll();
            }
        });
    });

    console.log('[Prism] Cargador dinámico inicializado');
})();
