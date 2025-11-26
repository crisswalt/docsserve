#!/bin/bash

# Crear directorio de seguridad si no existe
mkdir -p /etc/nginx/security

# Generar archivos de autenticación Basic Auth
echo "Configurando autenticación básica..."

# Limpiar archivos de configuración previos
rm -f /etc/nginx/security/*.conf
rm -f /etc/nginx/security/.htpasswd*

if [ -n "$AUTH_GLOBAL" ]; then
    username=$(echo "$AUTH_GLOBAL" | cut -d: -f1)
    password=$(echo "$AUTH_GLOBAL" | cut -d: -f2-)

    if [ -n "$username" ] && [ -n "$password" ]; then
        echo "  Configurando autenticación global"

        # Crear archivo htpasswd global
        htpasswd_file="/etc/nginx/security/.htpasswd_global"
        htpasswd -bc "$htpasswd_file" "$username" "$password"
    fi
fi

# Procesar variables de entorno AUTH_PROJECT*
for var in $(env | grep "^AUTH_PROJECT" | cut -d= -f1); do
    auth_value="${!var}"

    if [ -n "$auth_value" ]; then
        # Parsear PROJECT_NAME:username:password
        project_name=$(echo "$auth_value" | cut -d: -f1)
        username=$(echo "$auth_value" | cut -d: -f2)
        password=$(echo "$auth_value" | cut -d: -f3-)

        if [ -n "$project_name" ] && [ -n "$username" ] && [ -n "$password" ]; then
            echo "  Configurando autenticación para proyecto: $project_name"

            # Crear archivo htpasswd para este proyecto
            htpasswd_file="/etc/nginx/security/.htpasswd_${project_name}"

            # Si existe htpasswd global y no existe el del proyecto, copiarlo como base
            if [ -f "/etc/nginx/security/.htpasswd_global" ] && [ ! -f "$htpasswd_file" ]; then
                cp "/etc/nginx/security/.htpasswd_global" "$htpasswd_file"
            else
                touch "$htpasswd_file"
            fi

            htpasswd -b "$htpasswd_file" "$username" "$password"

            [ -f "/etc/nginx/security/${project_name}.conf" ] && continue

            # Crear archivo de configuración nginx para este proyecto
            cat > "/etc/nginx/security/${project_name}.conf" <<EOF
# Basic Authentication for project: ${project_name}
location ^~ /${project_name} {
    auth_basic "Restricted Access - ${project_name}";
    auth_basic_user_file ${htpasswd_file};
}
EOF
        fi
    fi
done

echo "Autenticación configurada exitosamente"
echo ""

# Construir el índice principal README.md
cat > /app/README.md <<'EOF'
# Documentación de Proyectos

Bienvenido al portal de documentación de proyectos. Aquí encontrarás toda la información técnica, análisis y recursos de los diferentes proyectos.

## Proyectos Disponibles

EOF

# Directorios a excluir por defecto (separados por espacios)
EXCLUDE_DEFAULT=${EXCLUDE_DIRS_DEFAULT:-"css js errors"}

# Directorios personalizados a excluir (separados por espacios)
EXCLUDE_CUSTOM=${EXCLUDE_DIRS_CUSTOM:-""}

# Combinar todas las exclusiones
EXCLUDE_ALL="$EXCLUDE_DEFAULT $EXCLUDE_CUSTOM"

# Función para verificar si un directorio debe ser excluido
should_exclude() {
    local dir_name="$1"
    for excluded in $EXCLUDE_ALL; do
        if [ "$dir_name" = "$excluded" ]; then
            return 0  # Verdadero, debe excluirse
        fi
    done
    return 1  # Falso, no debe excluirse
}

# Buscar directorios de proyectos (excluir directorios ocultos y archivos)
for project_dir in /app/*/; do
    # Obtener solo el nombre del directorio sin la ruta completa
    project_name=$(basename "$project_dir")

    # Verificar si el directorio debe ser excluido
    if should_exclude "$project_name"; then
        echo "  Excluyendo directorio: $project_name"
        continue
    fi

    # Ignorar directorios que no son proyectos (como archivos sueltos)
    if [ -d "$project_dir" ]; then
        # Verificar si existe un README.md en el proyecto
        if [ -f "${project_dir}README.md" ]; then
            # Leer el título del README si existe (primera línea que empieza con #)
            project_title=$(grep -m 1 "^#" "${project_dir}README.md" | sed 's/^#* *//')

            if [ -n "$project_title" ]; then
                echo "- [${project_title}](${project_name}/)" >> /app/README.md
            else
                # Si no hay título, usar el nombre del directorio
                formatted_name=$(echo "$project_name" | tr '-' ' ' | sed 's/\b\w/\u&/g')
                echo "- [${formatted_name}](${project_name}/)" >> /app/README.md
            fi
        else
            # Si no hay README, usar el nombre del directorio formateado
            formatted_name=$(echo "$project_name" | tr '-' ' ' | sed 's/\b\w/\u&/g')
            echo "- [${formatted_name}](${project_name}/)" >> /app/README.md
        fi
    fi
done

# Agregar footer
cat >> /app/README.md <<'EOF'

---

## Acerca de esta documentación

Esta documentación es generada automáticamente y servida mediante DocsServe, un servidor de documentación estático basado en Docsify.

Para más información sobre cómo agregar o modificar proyectos, contacta al equipo de desarrollo.
EOF

echo "Índice README.md generado exitosamente"
echo "Proyectos encontrados:"
ls -d /app/*/ 2>/dev/null | xargs -n 1 basename

# Iniciar nginx
exec nginx -g 'daemon off;'
