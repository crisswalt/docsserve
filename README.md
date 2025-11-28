# DocsServe

**DocsServe** is a lightweight, flexible static documentation server that uses [Docsify](https://docsify.js.org/) to render Markdown files as professional documentation websites. Designed to run in Docker containers with Nginx, it offers project-based authentication and automatic index generation.

## Features

- **Optimized Nginx server**: Built on the official Nginx image for high performance
- **Docsify rendering**: Converts Markdown files into interactive documentation without compilation
- **Multi-level authentication**: Supports HTTP Basic authentication both globally and per-project
- **Hashed password support**: Compatible with Apache htpasswd formats (SHA-512, SHA-256, bcrypt)
- **Automatic index generation**: Dynamically creates the main page with links to all projects
- **Auto-navigation with breadcrumbs**: Automatic contextual navigation across all documents
- **Integrated search**: Real-time search across all documentation
- **Hot-reload**: Changes to Markdown files are instantly reflected without container restart
- **Syntax highlighting**: Code blocks with Prism.js support

## Requirements

- Docker
- Docker Compose

## Installation and Usage

### 1. Clone the repository

```bash
git clone <repository-url>
cd DocsServe
```

### 2. Configure environment variables

Create a `.env` file based on `.env-example`:

```bash
cp .env-example .env
```

Edit the `.env` file to configure environment, authentication, and exclusions:

```env
# Environment mode
ENVIRONMENT=production  # or 'development' for config hot-reload

# Global authentication (optional)
# Format: username:password (or username:hashed_password)
AUTH_GLOBAL=

# Project-based authentication (optional)
# Recommended naming: AUTH_PROJECT_[PROJECTNAME]_[USERNAME]
# Format: project-name:username:password (or project-name:username:hashed_password)
AUTH_PROJECT_MYAPP_ADMIN=myproject:admin:changeme
AUTH_PROJECT_DOCS_USER=demo-docs:user:password123

# Directory exclusions from index (optional)
EXCLUDE_DIRS_DEFAULT=web
EXCLUDE_DIRS_CUSTOM=
```

**Security Recommendation**: Use hashed passwords instead of plaintext:

```bash
# Generate SHA-512 hash (recommended)
openssl passwd -6 'yourpassword'

# Use in .env file
AUTH_PROJECT1=myproject:admin:$6$rounds=5000$salt$hashedpasswordhere
```

### 3. Add documentation

**Recommended approach**: Mount external documentation projects using Docker Compose overrides instead of placing files directly in `./web/`.

The `./web/` directory is reserved for DocsServe system files:
- `index.html` - Docsify configuration (do not edit)
- `README.md` - Auto-generated index (do not edit)
- `css/`, `js/`, `errors/` - System assets

**Do not** create project directories inside `./web/`. Instead, mount them via overrides (see step 4).

### 4. Configure custom overrides

Create custom Docker Compose overrides in the `./overrides/` directory to mount your documentation projects:

```bash
mkdir -p overrides
```

**Volume mounts** (`./overrides/compose-volumes-override.yml`):

```yaml
services:
  docs-serve:
    volumes:
      - /path/to/project1/docs:/app/project1:ro
      - /path/to/project2/docs:/app/project2:ro
      - /home/user/another-repo/documentation:/app/another-project:ro
```

**Port configuration** (optional, `./overrides/compose-ports-override.yml`):

```yaml
services:
  docs-serve:
    ports:
      - "8420:80"
```

Each documentation project should contain at least a `README.md` file at its root. The project will be accessible at `http://localhost:8420/project-name/`.

**Note**: All `*.yml` files in `./overrides/` are gitignored by default, keeping your local configuration private.

### 5. Start the server

#### Basic usage (without overrides)

```bash
docker compose up -d
```

#### With custom overrides (recommended)

If you have override files in `./overrides/`, compose them together:

```bash
docker compose -f compose.yml $(ls overrides/*.yml 2>/dev/null | sed 's/^/-f /') up -d
```

Or create a helper script:

```bash
# Start with all overrides
docker compose -f compose.yml \
  $(find overrides -name "*.yml" 2>/dev/null | xargs -I {} echo "-f {}") \
  up -d
```

#### Development mode

For development with Nginx config hot-reload:

```bash
docker compose -f compose.yml \
  -f docker/development-compose.yml \
  $(ls overrides/*.yml 2>/dev/null | sed 's/^/-f /') \
  up -d
```

The server will be available at the configured port (default: 8420 in development mode).

### 6. View logs

```bash
docker compose logs -f
```

### 7. Stop the server

```bash
docker compose down
```

**Tip**: To simplify working with overrides, create a bash alias or helper script:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias dc-docs='docker compose -f compose.yml $(ls overrides/*.yml 2>/dev/null | sed "s/^/-f /")'

# Usage
dc-docs up -d
dc-docs logs -f
dc-docs down
```

## Configuration

### Environment Modes

DocsServe supports two operation modes:

#### Production (Default)

Standard deployment mode:

```env
ENVIRONMENT=production
```

- Nginx configuration baked into the image
- Changes to `default.conf` require rebuild: `docker compose build`
- Optimized for stability
- Port mapping configured per deployment

#### Development

Development mode with hot-reload:

```env
ENVIRONMENT=development
```

- Mounts `docker/default.conf` as volume
- Nginx config changes apply with: `docker compose restart`
- No image rebuild required
- Port 8420 exposed by default
- Ideal for experimenting with configurations

### Authentication

DocsServe supports HTTP Basic authentication with both plaintext and hashed passwords.

#### Hashed Passwords (Recommended)

Generate hashed passwords using `openssl`:

```bash
# SHA-512 (recommended)
openssl passwd -6 'yourpassword'

# SHA-256
openssl passwd -5 'yourpassword'

# bcrypt (Apache compatible)
openssl passwd -apr1 'yourpassword'
```

Use the generated hash in your `.env` file:

```env
AUTH_PROJECT1=myproject:admin:$6$rounds=5000$salt$hashedpasswordhere
```

#### Global Authentication

Protects the entire site with a single user and password:

```env
AUTH_GLOBAL=username:password
# or with hashed password
AUTH_GLOBAL=username:$6$rounds=5000$salt$hashedpasswordhere
```

#### Project-Based Authentication

Protects specific projects with independent credentials:

```env
# Recommended naming convention: AUTH_PROJECT_[PROJECTNAME]_[USERNAME]
AUTH_PROJECT_MYAPP_ADMIN=myapp:admin:password
AUTH_PROJECT_API_VIEWER=api-docs:viewer:password2
AUTH_PROJECT_INTERNAL_DEVTEAM=internal:devteam:password3

# Alternative simple naming (also works, but less organized)
AUTH_PROJECT1=project-name:username:password
AUTH_PROJECT2=another-project:username2:password2
```

**Variable Naming Convention (Recommended):**
- Pattern: `AUTH_PROJECT_[PROJECTNAME]_[USERNAME]`
- Benefits: Better organization, quick searching, easier to identify projects
- Note: Any variable starting with `AUTH_PROJECT` will be processed

The `project-name` (first field in the value) must match the directory name where your documentation is mounted (e.g., `/app/myapp`).

**Note**: If `AUTH_GLOBAL` is defined, it takes priority over project-based authentication.

### Directory Exclusions

Control which directories appear in the auto-generated main index (`README.md`).

#### Default Exclusions

System directories are excluded automatically:

```env
EXCLUDE_DIRS_DEFAULT=web
```

#### Custom Exclusions

Hide specific projects from the index:

```env
EXCLUDE_DIRS_CUSTOM=secret-project ultra-confidential draft
```

**Important**: Excluded directories are still accessible directly via URL. For complete protection, combine exclusion with project authentication:

```env
# Hide from index
EXCLUDE_DIRS_CUSTOM=ultra-secret

# Protect with authentication
AUTH_PROJECT1=ultra-secret:admin:password123
```

### Port Configuration

**Recommended approach**: Create an override file in `./overrides/`:

```yaml
# ./overrides/compose-ports-override.yml
services:
  docs-serve:
    ports:
      - "8080:80"  # Change port as needed
```

Alternatively, edit:
- **Base configuration**: [compose.yml](compose.yml) (not recommended, affects all deployments)
- **Development mode**: [docker/development-compose.yml](docker/development-compose.yml) (default: 8420)

### Custom Volume Mounts

**This is the recommended way to add documentation projects** to DocsServe.

Use override files in `./overrides/` to mount external documentation projects:

```yaml
# ./overrides/compose-volumes-override.yml
services:
  docs-serve:
    volumes:
      - /path/to/external/project:/app/project-name:ro
      - /another/project/docs:/app/another-project:ro
```

**Benefits of this approach:**
- Documentation stays in its original repository
- No need to copy or duplicate files
- Changes in source repos are immediately reflected (after container restart)
- Keeps `./web/` clean and reserved for DocsServe system files
- Easy to add/remove projects without modifying core configuration

**Important**: The `:ro` (read-only) flag is recommended to prevent accidental modifications from the container.

### Nginx Customization

The Nginx configuration is located in [docker/default.conf](docker/default.conf). You can modify:

- MIME types
- Error page routes
- Timeouts and limits
- URL rewriting rules

## Project Structure

```
DocsServe/
├── docker/
│   ├── Dockerfile                  # Docker image based on nginx:latest
│   ├── default.conf                # Nginx configuration
│   ├── development-compose.yml     # Development mode override
│   └── entrypoint.sh               # Initialization script (auth + index)
├── web/                            # DocsServe system files (mounted as volume)
│   ├── index.html                  # Docsify configuration
│   ├── README.md                   # Auto-generated index (do not edit)
│   ├── css/                        # Custom styles
│   ├── js/                         # Custom JavaScript
│   └── errors/                     # Error pages (401.html, 403.html)
├── overrides/                      # Custom Docker Compose overrides (gitignored)
├── compose.yml                     # Base Docker Compose configuration
├── .env-example                    # Environment variables template
├── CLAUDE.md                       # Instructions for Claude Code
└── README.md                       # This file
```

## How It Works

### On Container Startup

1. **Authentication Configuration** ([docker/entrypoint.sh](docker/entrypoint.sh))
   - Reads `AUTH_*` environment variables
   - Supports both plaintext and hashed passwords
   - Generates `.htpasswd` files for each configuration
   - Creates dynamic Nginx configuration files in `/etc/nginx/security/`

2. **Main Index Generation** ([docker/entrypoint.sh](docker/entrypoint.sh))
   - Scans directories in `/app/`
   - Excludes directories defined in `EXCLUDE_DIRS_DEFAULT` and `EXCLUDE_DIRS_CUSTOM`
   - Excludes directories without `README.md` files
   - Extracts titles from project README.md files
   - Auto-generates `web/README.md` with links to all projects

3. **Nginx Startup**
   - Serves static files from `/app`
   - Applies authentication configurations
   - URL rewriting: `/web/*.md` files accessible as `/*.md`
   - Root redirects to `/web/`

### Docsify Rendering

- Docsify loads in the client ([web/index.html](web/index.html))
- Converts Markdown to HTML dynamically
- Generates automatic breadcrumbs based on path
- Provides real-time search without prior indexing
- Syntax highlighting with Prism.js

## Development and Customization

### Modify Appearance

Edit [web/index.html](web/index.html) to change:

- Docsify theme (`link rel="stylesheet"`)
- Site name (`name`)
- Search depth (`search.depth`)
- TOC sublevel depth (`subMaxLevel`)

### Custom Styles

Modify [web/css/main.css](web/css/main.css) for custom styling.

### Add Docsify Plugins

Add additional scripts in [web/index.html](web/index.html):

```html
<script src="https://cdn.jsdelivr.net/npm/docsify@4/lib/plugins/emoji.min.js"></script>
```

See [Docsify documentation](https://docsify.js.org/#/plugins) for more plugins.

### Build and Publish Image

```bash
docker compose build
docker tag dassi0cl/docsserve:latest dassi0cl/docsserve:v1.0.0
docker push dassi0cl/docsserve:latest
docker push dassi0cl/docsserve:v1.0.0
```

## Use Cases

- **Internal technical documentation**: Protect confidential documents with authentication
- **Team wikis**: Share knowledge in easy-to-edit Markdown format
- **Project portfolio**: Present multiple projects with organized documentation
- **User manuals**: Publish user guides with search and navigation
- **Knowledge base**: Centralize documentation from multiple areas or departments

## Troubleshooting

### Container doesn't start

Check the logs:
```bash
docker compose logs docs-serve
```

### Authentication not working

- Verify environment variables are correctly configured in `.env`
- Check format: `AUTH_PROJECT_[NAME]_[USER]=project:username:password`
  - Variable name must start with `AUTH_PROJECT`
  - Value format: `project-name:username:password`
- For hashed passwords, ensure the hash is properly escaped
- Restart container: `docker compose restart`

### Markdown changes not reflected

- Docsify loads files dynamically; refresh the browser page
- Clear browser cache if necessary
- Verify volume is mounted correctly

### 404 errors on documentation routes

- Verify a `README.md` file exists in the project directory
- Check that Markdown links use correct relative paths
- Review Nginx logs for routing issues

## Resources

- [Docsify Documentation](https://docsify.js.org/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Hub - Nginx](https://hub.docker.com/_/nginx)
- [Markdown Guide](https://www.markdownguide.org/)
- [Apache htpasswd](https://httpd.apache.org/docs/2.4/programs/htpasswd.html)

---

**Built with Nginx + Docsify**
