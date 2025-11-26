# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DocsServe is a static documentation server that uses Docsify to render Markdown files as HTML documentation sites. The application runs in a Docker container using Nginx as the web server.

## Architecture

- **Docker**: The application is containerized using nginx:latest as the base image
- **Nginx**: Serves static files from the `/app` directory (mapped to `./web` on host)
- **Docsify**: JavaScript-based documentation framework that renders Markdown files client-side

The web content is mounted as a volume (`./web:/app`) allowing live updates without rebuilding the container.

## Development Commands

### Running the Application

```bash
# Start the container (auto-detects ENVIRONMENT from .env)
./start.sh

# View logs
docker compose logs -f

# Stop the container
./stop.sh
```

The application supports two environment modes:

- **Production** (default): Standard deployment with nginx config baked into image
- **Development**: Mounts `docker/default.conf` as volume for hot-reload

Set via `.env`:
```env
ENVIRONMENT=development  # or 'production'
```

### Manual Docker Compose Commands

If you need to run Docker Compose manually:

```bash
# Production mode
docker compose up -d

# Development mode (with config hot-reload)
docker compose -f compose.yml -f docker/development-compose.yml up -d

# Stop
docker compose down
```

### Working with Documentation

Documentation files are placed in the `./web` directory:
- `index.html` - Main Docsify configuration
- `README.md` - Home page content (auto-loaded by Docsify)
- Additional `.md` files - Documentation pages referenced via Docsify navigation

The Docsify instance is configured with:
- Sidebar navigation (loadSidebar: true)
- Search functionality
- Auto-generated paths
- Subheading levels up to 2

### Docker Image

The image is published as `dassi0cl/docsserve:latest`. To rebuild:

```bash
docker compose build
```

## File Structure

```
.
├── docker/
│   ├── Dockerfile                  # nginx:latest base image
│   ├── default.conf                # Nginx configuration (serves /app on port 80)
│   ├── development-compose.yml     # Docker Compose override for development mode
│   └── entrypoint.sh               # Container startup script
├── web/                            # Documentation root (mounted to /app in container)
│   ├── index.html                  # Docsify configuration
│   └── README.md                   # Main documentation page
├── compose.yml                     # Docker Compose configuration (base)
├── start.sh                        # Startup script (detects ENVIRONMENT)
└── stop.sh                         # Shutdown script
```

## Configuration Notes

- Nginx listens on port 80 (both IPv4 and IPv6)
- Document root: `/app` in container
- Error pages (500, 502, 503, 504) served from `/app/50x.html`
- The `.secrets` directory and `.env` file are gitignored

### Environment Variables

Configure the application using a `.env` file (see `.env-example` for template):

**Environment Mode:**
- `ENVIRONMENT` - Deployment mode: `production` (default) or `development`
  - `production`: Nginx config baked into image, requires rebuild for changes
  - `development`: Nginx config mounted as volume, allows hot-reload with `docker compose restart`

**Authentication:**
- `AUTH_PROJECT*` - Project-specific Basic Auth (format: `PROJECT_NAME:username:password`)
- `AUTH_GLOBAL` - Global authentication for all paths (optional)

**Directory Exclusions:**
- `EXCLUDE_DIRS_DEFAULT` - System directories excluded from README.md index (default: `css js errors`)
- `EXCLUDE_DIRS_CUSTOM` - Custom directories to exclude (space-separated, e.g., `secret-project confidential`)

The README.md index is auto-generated on container startup and excludes directories defined in these variables.

## Editable Files

IMPORTANT: Only the following files can be edited:
- `compose.yml` - Docker Compose configuration
- `docker/development-compose.yml` - Development mode override
- `start.sh` - Startup script
- `stop.sh` - Shutdown script
- `CLAUDE.md` - This file (project instructions)
- `.env-example` - Example environment variables template
- `docker/*` - All files in the docker directory (Dockerfile, default.conf, entrypoint.sh, etc.)
- `web/index.html` - Docsify configuration page
- `web/50x.html` - Error page template

**DO NOT edit other files**, especially:
- `web/README.md` - User-managed documentation content (auto-generated on startup)
- Other `.md` files in `web/` - User-managed documentation pages
