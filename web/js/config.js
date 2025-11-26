const docsify = {
    name: 'Proyectos en Dassi',
    repo: '',
    subMaxLevel: 2,
    loadNavbar: false,
    auto2top: true,
    maxLevel: 4,
    loadSidebar: false,
    relativePath: true,
    coverpage: false,
    onlyCover: false,
    hideSidebar: false,
    themeColor: '#177996',
};

docsify.search = {
    paths: 'auto',
    placeholder: 'Buscar...',
    noData: 'Sin resultados',
    depth: 3
};

/**
 * Sección de Plugins
 */

const breadcrumbs = (hook) => {
    hook.beforeEach((content) => {
        // Generar breadcrumbs basados en la ruta
        const path = window.location.hash.replace('#/', '').split('/');
        let breadcrumbs = '<div class="breadcrumbs">';
        let currentPath = '';

        breadcrumbs += '<a href="#/">Inicio</a>';

        path.forEach((segment, index) => {
            if (segment && index < path.length - 1) {
                currentPath += '/' + segment;
                const name = segment.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
                breadcrumbs += ` > <a href="#${currentPath}/">${name}</a>`;
            }
        });

        breadcrumbs += '</div>\n\n';
        return breadcrumbs + content;
    })
};

// !Deprecado!
// const path_rewrite = (hook) => {
//     hook.beforeEach((content) => {
//         // Obtener el directorio actual del archivo que se está renderizando
//         const fullPath = window.location.hash.replace('#/', '');
//         const currentDir = fullPath.substring(0, fullPath.lastIndexOf('/'));

//         // Si estamos en un subdirectorio, reescribir enlaces relativos a rutas absolutas de Docsify
//         if (currentDir) {
//             content = content.replace(
//                 /\[([^\]]+)\]\((?!https?:\/\/)(?!#)(?!\/)([^)]+)\)/g,
//                 function (match, linkText, linkHref) {
//                     // Convertir enlace relativo a ruta absoluta de Docsify
//                     const absolutePath = currentDir + '/' + linkHref;
//                     console.log('Reescritura: ', linkHref, absolutePath);
//                     return '[' + linkText + '](' + absolutePath + ')';
//                 }
//             );
//         }

//     });
// }

docsify.plugins = [breadcrumbs];

