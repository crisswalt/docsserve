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
# Start the container (builds if needed)
docker compose up -d

# View logs
docker compose logs -f

# Stop the container
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
│   ├── Dockerfile       # nginx:latest base image
│   ├── default.conf     # Nginx configuration (serves /app on port 80)
│   └── entrypoint.sh    # Container startup script
├── web/                 # Documentation root (mounted to /app in container)
│   ├── index.html       # Docsify configuration
│   └── README.md        # Main documentation page
└──  compose.yml          # Docker Compose configuration
```

## Configuration Notes

- Nginx listens on port 80 (both IPv4 and IPv6)
- Document root: `/app` in container
- Error pages (500, 502, 503, 504) served from `/app/50x.html`
- The `.secrets` directory and `.env` file are gitignored

## Editable Files

IMPORTANT: Only the following files can be edited:
- `compose.yml` - Docker Compose configuration
- `CLAUDE.md` - This file (project instructions)
- `.env-example` - Example environment variables template
- `docker/*` - All files in the docker directory (Dockerfile, default.conf, entrypoint.sh, etc.)
- `web/index.html` - Docsify configuration page
- `web/50x.html` - Error page template

**DO NOT edit other files**, especially:
- `web/README.md` - User-managed documentation content
- Other `.md` files in `web/` - User-managed documentation pages
