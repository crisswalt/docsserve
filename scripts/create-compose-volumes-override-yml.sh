#!/bin/bash

# Script to auto-generate overrides/compose-volumes-override.yml
# Usage:
#   ./create-compose-volumes-override-yml.sh <projects_dir> [options]

set -e

# Default values
PROJECT_PREFIX=""
EXCLUDE_PATTERNS=()
WEBHOOK_URL=""
PROJECTS_DIR=""
STRIP_PREFIX=false
STRIP_SUFFIX=false
QUIET=false
LOG_FILE=""
OUTPUT_FILE=""

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Show usage
show_usage() {
  echo "Usage: $0 <projects_dir> [options]"
  echo ""
  echo "Arguments:"
  echo "  projects_dir              (required) Directory containing project folders"
  echo ""
  echo "Options:"
  echo "  -p, --prefix PREFIX       Filter projects by prefix pattern (optional)"
  echo "                            If not specified, processes ALL directories"
  echo "  -e, --exclude PATTERN     Pattern to exclude (can be used multiple times)"
  echo "  -s, --strip-prefix        Remove the configured prefix from mount point names"
  echo "  -S, --strip-suffix        Remove suffix after last '-' from mount point names"
  echo "  -o, --output FILE         Output file path (default: auto-detect or ./overrides/...)"
  echo "  -q, --quiet               Suppress output (only show errors and changes)"
  echo "  -l, --log FILE            Write output to log file instead of stdout"
  echo "  -w, --webhook URL         Webhook URL for notifications (optional)"
  echo "  -h, --help                Show this help message"
  echo ""
  echo "Exit codes:"
  echo "  0 - Success (changes applied)"
  echo "  1 - Error"
  echo "  2 - Success (no changes needed)"
  echo ""
  echo "Examples:"
  echo "  # Process ALL directories (generic use case)"
  echo "  $0 /home/user/Projects"
  echo ""
  echo "  # Filter by prefix (Dokploy or similar)"
  echo "  $0 /home/user/Projects -p proyectos"
  echo ""
  echo "  # Dokploy with exclusions and name cleaning"
  echo "  $0 /home/user/Projects -p proyectos -e docs-server -e archived -s -S"
  echo "  # Result: proyectos-ethersens-abc123 -> /app/ethersens"
  echo ""
  echo "  # Multiple exclusions without prefix"
  echo "  $0 /home/user/Projects -e temp -e draft -e test"
  echo ""
  echo "  # Cron-friendly: quiet mode with webhook"
  echo "  $0 /home/user/Projects -p proyectos -s -S -q -w https://hooks.slack.com/..."
  echo ""
  echo "  # Cron-friendly: with logging"
  echo "  $0 /home/user/Projects -p proyectos -s -S -l /var/log/docsserve-sync.log"
  echo ""
  echo "  # Dokploy: specify output explicitly"
  echo "  $0 /etc/dokploy/compose -p proyectos -e docs-server -s -S \\"
  echo "    -o /etc/dokploy/compose/proyectos-docsserve-abc123/files/volumes-override.yml"
  echo ""
}

# Logging function
# Usage: log "message" [level]
# Levels: INFO (default), WARN, ERROR, SUCCESS
log() {
  local message="$1"
  local level="${2:-INFO}"
  local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  # Format message with timestamp for log file
  local log_msg="[$timestamp] [$level] $message"

  # Write to log file if specified
  if [ -n "$LOG_FILE" ]; then
    echo "$log_msg" >> "$LOG_FILE"
  fi

  # Output to stdout based on quiet mode and level
  if [ "$QUIET" = false ] || [ "$level" = "ERROR" ] || [ "$level" = "SUCCESS" ]; then
    if [ -z "$LOG_FILE" ]; then
      # No log file: simple output
      echo "$message"
    elif [ "$level" = "ERROR" ] || [ "$level" = "SUCCESS" ]; then
      # With log file: only show errors and success
      echo "$message"
    fi
  fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
      ;;
    -p|--prefix)
      PROJECT_PREFIX="$2"
      shift 2
      ;;
    -e|--exclude)
      EXCLUDE_PATTERNS+=("$2")
      shift 2
      ;;
    -s|--strip-prefix)
      STRIP_PREFIX=true
      shift
      ;;
    -S|--strip-suffix)
      STRIP_SUFFIX=true
      shift
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -q|--quiet)
      QUIET=true
      shift
      ;;
    -l|--log)
      LOG_FILE="$2"
      shift 2
      ;;
    -w|--webhook)
      WEBHOOK_URL="$2"
      shift 2
      ;;
    -*)
      echo "Error: Unknown option $1"
      echo ""
      show_usage
      exit 1
      ;;
    *)
      if [ -z "$PROJECTS_DIR" ]; then
        PROJECTS_DIR="$1"
      else
        echo "Error: Unexpected argument '$1'"
        echo ""
        show_usage
        exit 1
      fi
      shift
      ;;
  esac
done

# Validation
if [ -z "$PROJECTS_DIR" ]; then
  echo "Error: projects_dir argument is required."
  echo ""
  show_usage
  exit 1
fi

if [ ! -d "$PROJECTS_DIR" ]; then
  echo "Error: Directory '$PROJECTS_DIR' does not exist or is not a directory."
  exit 1
fi

# Determine output destination
if [ -n "$OUTPUT_FILE" ]; then
  # 1. Explicit output specified by user
  DESTINE="$OUTPUT_FILE"
  log "Output destination (explicit): $DESTINE" "INFO"
elif [[ "$BASE_DIR" =~ /etc/dokploy/compose/([^/]+) ]]; then
  # 2. Auto-detect Dokploy context
  DOKPLOY_PROJECT="${BASH_REMATCH[1]}"
  DESTINE="/etc/dokploy/compose/${DOKPLOY_PROJECT}/files/compose-volumes-override.yml"
  log "Auto-detected Dokploy project: $DOKPLOY_PROJECT" "INFO"
  log "Output destination (auto-detected): $DESTINE" "INFO"
else
  # 3. Default behavior (local development)
  DESTINE="${BASE_DIR}/overrides/compose-volumes-override.yml"
  log "Output destination (default): $DESTINE" "INFO"
fi

# Create temp file
OVERRIDE="$(mktemp)"

# Write header
cat > "$OVERRIDE" <<EOF
services:
  docs-serve:
    volumes:
EOF

# Find and process projects
log "Scanning for projects in: $PROJECTS_DIR"
if [ -n "$PROJECT_PREFIX" ]; then
  log "Filter: prefix='$PROJECT_PREFIX' (matching '${PROJECT_PREFIX}-*')"
else
  log "Filter: ALL directories (no prefix filter)"
fi

if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
  log "Exclusions: ${EXCLUDE_PATTERNS[*]}"
else
  log "Exclusions: none"
fi

log "Name cleaning: strip-prefix=$STRIP_PREFIX, strip-suffix=$STRIP_SUFFIX"
log ""

PROJECT_COUNT=0

# Define cascading docs paths (priority order)
DOC_PATHS=("code/docs" "docs" ".")

# Determine search pattern based on prefix
if [ -n "$PROJECT_PREFIX" ]; then
  search_pattern="${PROJECT_PREFIX}-*"
else
  search_pattern="*"
fi

# Find all directories matching the pattern
while IFS= read -r project_dir; do
  project_name="$(basename "$project_dir")"

  # Skip excluded patterns
  should_exclude=false
  for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    if [[ "$project_name" == *"$pattern"* ]]; then
      log "  [SKIP] $project_name (matches exclude pattern: $pattern)"
      should_exclude=true
      break
    fi
  done

  if [ "$should_exclude" = true ]; then
    continue
  fi

  # Search for docs in cascading paths
  docs_path=""
  docs_location=""

  for doc_subdir in "${DOC_PATHS[@]}"; do
    candidate="${project_dir}/${doc_subdir}"

    # Check if README.md exists in this location
    if [ -f "${candidate}/README.md" ]; then
      docs_path="$candidate"
      docs_location="$doc_subdir"
      break
    fi
  done

  # Skip if no docs found
  if [ -z "$docs_path" ]; then
    log "  [SKIP] $project_name (no README.md found in code/docs, docs, or root)"
    continue
  fi

  # Determine mount point name
  clean_name="$project_name"

  # Apply prefix stripping if enabled
  if [ "$STRIP_PREFIX" = true ] && [ -n "$PROJECT_PREFIX" ]; then
    clean_name="${clean_name#${PROJECT_PREFIX}-}"
  fi

  # Apply suffix stripping if enabled (remove everything after last '-')
  if [ "$STRIP_SUFFIX" = true ]; then
    clean_name="${clean_name%%-*}"
  fi

  # Add volume mount
  echo "      - ${docs_path}:/app/${clean_name}" >> "$OVERRIDE"
  log "  [ADD]  $project_name -> /app/${clean_name} (from ${docs_location})"

  PROJECT_COUNT=$((PROJECT_COUNT + 1))
done < <(find "$PROJECTS_DIR" -maxdepth 1 -type d -name "$search_pattern" ! -name "." | sort)

log ""
log "Found $PROJECT_COUNT project(s)"

# Check if destination exists and compare
if [ -f "$DESTINE" ]; then
  NEW_HASH="$(md5sum "$OVERRIDE" | awk '{print $1}')"
  OLD_HASH="$(md5sum "$DESTINE" | awk '{print $1}')"

  if [[ "$NEW_HASH" == "$OLD_HASH" ]]; then
    log "No changes detected. File not updated."
    rm -f "$OVERRIDE"
    exit 2  # Exit code 2 = no changes needed
  fi
fi

# Create overrides directory if needed
mkdir -p "$(dirname "$DESTINE")"

# Write final file
cat "$OVERRIDE" > "$DESTINE"
rm -f "$OVERRIDE"

log ""
log "✓ Created: $DESTINE" "SUCCESS"
log ""

# Show context-specific next steps
if [[ "$DESTINE" =~ /etc/dokploy/compose/([^/]+)/files/ ]]; then
  # Dokploy context
  DOKPLOY_PROJ="${BASH_REMATCH[1]}"
  log "Next steps (Dokploy):"
  log "  1. Review the generated file: cat $DESTINE"
  log "  2. Update Dokploy deployment command to:"
  log "     docker compose -p $DOKPLOY_PROJ \\"
  log "       -f compose.yml \\"
  log "       -f files/compose-volumes-override.yml \\"
  log "       up -d --build --remove-orphans"
else
  # Local development context
  log "Next steps:"
  log "  1. Review the generated file: cat $DESTINE"
  log "  2. Start DocsServe with overrides:"
  log "     docker compose -f compose.yml \$(ls overrides/*.yml 2>/dev/null | sed 's/^/-f /') up -d"
fi

# Optional: Send notification if webhook URL is provided
if [ -n "$WEBHOOK_URL" ]; then
  MESSAGE="Compose volumes override updated with $PROJECT_COUNT project(s)."
  curl -s -X POST -H 'Content-type: application/json' --data "{\"text\":\"$MESSAGE\"}" "$WEBHOOK_URL" > /dev/null 2>&1
  log "Notification sent to webhook." "SUCCESS"
fi

# Exit code 0 = changes applied
exit 0