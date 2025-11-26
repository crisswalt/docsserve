# DocsServe

**DocsServe** es un servidor de documentación estático ligero y flexible que utiliza [Docsify](https://docsify.js.org/) para renderizar archivos Markdown como sitios web de documentación profesional. Diseñado para ejecutarse en contenedores Docker con Nginx, ofrece autenticación por proyecto y generación automática de índices.

## Características

- **Servidor Nginx optimizado**: Basado en la imagen oficial de Nginx para alto rendimiento
- **Renderizado Docsify**: Convierte archivos Markdown en documentación interactiva sin necesidad de compilación
- **Autenticación multinivel**: Soporta autenticación HTTP Basic tanto global como por proyecto
- **Generación automática de índices**: Crea dinámicamente la página principal con enlaces a todos los proyectos, con soporte para exclusiones personalizadas
- **Auto-navegación con breadcrumbs**: Navegación contextual automática en todos los documentos
- **Búsqueda integrada**: Búsqueda en tiempo real en toda la documentación
- **Hot-reload**: Los cambios en archivos Markdown se reflejan instantáneamente sin reiniciar el contenedor
- **Listado de directorios**: Navegación visual de archivos cuando no existe un README.md

## Requisitos

- Docker
- Docker Compose

## Instalación y Uso

### 1. Clonar el repositorio

```bash
git clone <repository-url>
cd DocsServe
```

### 2. Configurar variables de entorno

Crea un archivo `.env` basado en `.env-example`:

```bash
cp .env-example .env
```

Edita el archivo `.env` para configurar el entorno, autenticación y exclusiones:

```env
# Modo de entorno
ENVIRONMENT=production  # o 'development' para hot-reload

# Autenticación global (opcional)
# Formato: usuario:contraseña
AUTH_GLOBAL=admin:secretpassword

# Autenticación por proyecto (opcional)
# Formato: nombre-proyecto:usuario:contraseña
AUTH_PROJECT_1=ethersens:user1:pass123
AUTH_PROJECT_2=demo:user2:pass456

# Exclusión de directorios del índice (opcional)
EXCLUDE_DIRS_DEFAULT=css js errors
EXCLUDE_DIRS_CUSTOM=proyecto-secreto confidencial
```

### 3. Agregar documentación

Coloca tus proyectos de documentación dentro del directorio `./web/`:

```
web/
├── index.html           # Configuración de Docsify (no editar)
├── README.md            # Generado automáticamente al iniciar
├── proyecto-1/
│   └── README.md        # Documentación del proyecto 1
└── proyecto-2/
    ├── README.md        # Documentación del proyecto 2
    └── guia.md          # Documentos adicionales
```

### 4. Iniciar el servidor

```bash
./start.sh
```

El script detectará automáticamente el modo de entorno desde `.env`:
- **Production**: Despliega el contenedor estándar
- **Development**: Habilita hot-reload para la configuración de Nginx

El servidor estará disponible en `http://localhost:8420`

### 5. Ver logs

```bash
docker compose logs -f
```

### 6. Detener el servidor

```bash
./stop.sh
```

O manualmente:

```bash
docker compose down
```

## Configuración

### Modo de Entorno

DocsServe soporta dos modos de operación:

#### Production (Producción)

Modo estándar para despliegue:

```env
ENVIRONMENT=production
```

- Configuración de Nginx compilada en la imagen
- Cambios en `default.conf` requieren rebuild: `docker compose build`
- Optimizado para estabilidad

#### Development (Desarrollo)

Modo de desarrollo con hot-reload:

```env
ENVIRONMENT=development
```

- Monta `docker/default.conf` como volumen
- Cambios en la configuración de Nginx se aplican con: `docker compose restart`
- No requiere rebuild de la imagen
- Ideal para experimentar con configuraciones

### Autenticación

DocsServe soporta dos tipos de autenticación HTTP Basic:

#### Autenticación Global

Protege todo el sitio con un único usuario y contraseña:

```env
AUTH_GLOBAL=usuario:contraseña
```

#### Autenticación por Proyecto

Protege proyectos específicos con credenciales independientes:

```env
AUTH_PROJECT_1=nombre-proyecto:usuario:contraseña
AUTH_PROJECT_2=otro-proyecto:usuario2:contraseña2
```

El `nombre-proyecto` debe coincidir con el nombre del directorio en `./web/`.

**Nota**: Si se define `AUTH_GLOBAL`, esta tiene prioridad sobre las autenticaciones por proyecto.

### Exclusión de Directorios

Puedes controlar qué directorios aparecen en el índice principal (`README.md`) generado automáticamente:

#### Exclusiones por Defecto

Los directorios del sistema se excluyen automáticamente:

```env
EXCLUDE_DIRS_DEFAULT=css js errors
```

Estos directorios contienen assets estáticos y páginas de error, no proyectos de documentación.

#### Exclusiones Personalizadas

Para ocultar proyectos específicos del índice (por ejemplo, proyectos confidenciales o en desarrollo):

```env
EXCLUDE_DIRS_CUSTOM=proyecto-secreto ultra-confidencial borrador
```

**Importante**: Los directorios excluidos siguen siendo accesibles directamente via URL si conoces la ruta (ej: `http://localhost:8420/proyecto-secreto/`). Para protegerlos completamente, combina la exclusión con autenticación por proyecto.

#### Ejemplo de Protección Completa

Para un proyecto ultra-secreto, combina exclusión + autenticación:

```env
# Excluir del índice
EXCLUDE_DIRS_CUSTOM=ultra-secreto

# Proteger con autenticación
AUTH_PROJECT_1=ultra-secreto:admin:password123
```

### Cambiar el puerto

Edita [compose.yml](compose.yml) y modifica el mapeo de puertos:

```yaml
ports:
  - "8080:80"  # Cambiar 8420 por el puerto deseado
```

### Personalizar Nginx

La configuración de Nginx se encuentra en [docker/default.conf](docker/default.conf). Puedes modificar:

- Tipos MIME
- Rutas de error
- Configuración de autoindex
- Timeouts y límites

## Estructura del Proyecto

```
DocsServe/
├── docker/
│   ├── Dockerfile                  # Imagen Docker basada en nginx:latest
│   ├── default.conf                # Configuración de Nginx
│   ├── development-compose.yml     # Override para modo development
│   └── entrypoint.sh               # Script de inicialización (genera auth + índice)
├── web/                            # Directorio de documentación (montado como volumen)
│   ├── index.html                  # Configuración de Docsify
│   ├── README.md                   # Índice principal (generado automáticamente)
│   └── [proyectos]/                # Tus proyectos de documentación
├── compose.yml                     # Configuración de Docker Compose
├── start.sh                        # Script de inicio (detecta ENVIRONMENT)
├── stop.sh                         # Script de parada
├── CLAUDE.md                       # Instrucciones para Claude Code
└── README.md                       # Este archivo
```

## Funcionamiento Interno

### Al iniciar el contenedor

1. **Configuración de autenticación** ([entrypoint.sh:4-63](docker/entrypoint.sh#L4-L63))
   - Lee variables de entorno `AUTH_*`
   - Genera archivos `.htpasswd` para cada configuración
   - Crea archivos de configuración Nginx dinámicos en `/etc/nginx/security/`

2. **Generación del índice principal** ([entrypoint.sh:78-129](docker/entrypoint.sh#L78-L129))
   - Escanea directorios en `/app/`
   - Excluye directorios definidos en `EXCLUDE_DIRS_DEFAULT` y `EXCLUDE_DIRS_CUSTOM`
   - Extrae títulos de archivos README.md de cada proyecto
   - Genera automáticamente `web/README.md` con enlaces a todos los proyectos

3. **Inicio de Nginx** ([entrypoint.sh:122](docker/entrypoint.sh#L122))
   - Sirve archivos estáticos desde `/app`
   - Aplica configuraciones de autenticación
   - Habilita autoindex para navegación de archivos

### Renderizado con Docsify

- Docsify se carga en el cliente ([web/index.html](web/index.html))
- Convierte Markdown a HTML dinámicamente
- Genera breadcrumbs automáticos basados en la ruta
- Reescribe enlaces relativos para navegación correcta entre documentos
- Proporciona búsqueda en tiempo real sin indexación previa

## Desarrollo y Personalización

### Modificar la apariencia

Edita [web/index.html](web/index.html) para cambiar:

- Tema de Docsify (`link rel="stylesheet"`)
- Nombre del sitio (`name`)
- Profundidad de búsqueda (`search.depth`)
- Nivel de subniveles en TOC (`subMaxLevel`)

### Agregar plugins de Docsify

Agrega scripts adicionales en [web/index.html](web/index.html):

```html
<script src="https://cdn.jsdelivr.net/npm/docsify@4/lib/plugins/emoji.min.js"></script>
```

Consulta la [documentación de Docsify](https://docsify.js.org/#/plugins) para más plugins.

### Construir y publicar la imagen

```bash
docker compose build
docker tag dassi0cl/docsserve:latest dassi0cl/docsserve:v1.0.0
docker push dassi0cl/docsserve:latest
docker push dassi0cl/docsserve:v1.0.0
```

## Casos de Uso

- **Documentación técnica interna**: Protege documentos confidenciales con autenticación
- **Wikis de equipo**: Comparte conocimiento en formato Markdown fácil de editar
- **Portafolio de proyectos**: Presenta múltiples proyectos con documentación organizada
- **Manuales de usuario**: Publica guías de usuario con búsqueda y navegación
- **Knowledge base**: Centraliza documentación de múltiples áreas o departamentos

## Troubleshooting

### El contenedor no inicia

Verifica los logs:
```bash
docker compose logs docs-serve
```

### No se aplica la autenticación

- Asegúrate de que las variables de entorno estén correctamente configuradas en `.env`
- Verifica que el formato sea: `AUTH_PROJECT_X=proyecto:usuario:contraseña`
- Reinicia el contenedor: `docker compose restart`

### Los cambios en Markdown no se reflejan

- Docsify carga archivos dinámicamente, refresca la página del navegador
- Si modificaste archivos dentro del contenedor, verifica que el volumen esté montado correctamente

### Error 404 en rutas de documentación

- Verifica que existe un archivo `README.md` en el directorio del proyecto
- Comprueba que los enlaces en Markdown usen rutas relativas correctas

## Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Haz fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo una licencia de código abierto. Consulta el archivo LICENSE para más detalles.

## Recursos

- [Documentación de Docsify](https://docsify.js.org/)
- [Documentación de Nginx](https://nginx.org/en/docs/)
- [Docker Hub - Nginx](https://hub.docker.com/_/nginx)
- [Guía de Markdown](https://www.markdownguide.org/)

---

**Hecho con Nginx + Docsify**
