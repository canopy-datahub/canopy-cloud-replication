#!/bin/sh
# Renders realm-import templates with the current KC_HOSTNAME, then hands off
# to the Keycloak CLI. Keeps the baked-in image environment-agnostic: the same
# image can boot on dev / test / prod / raw ALB URL by changing KC_HOSTNAME.
set -eu

TEMPLATE_DIR="/opt/keycloak/realm-template"
IMPORT_DIR="/opt/keycloak/data/import"

if [ -d "${TEMPLATE_DIR}" ]; then
    if [ -z "${KC_HOSTNAME:-}" ]; then
        echo "ERROR: KC_HOSTNAME is not set — cannot render realm-import templates" >&2
        exit 1
    fi
    mkdir -p "${IMPORT_DIR}"
    rendered=0
    for f in "${TEMPLATE_DIR}"/*.json; do
        [ -e "$f" ] || continue
        dest="${IMPORT_DIR}/$(basename "$f")"
        sed "s|@@PUBLIC_HOSTNAME@@|${KC_HOSTNAME}|g" "$f" > "$dest"
        echo "Rendered realm-import: ${f} → ${dest} (KC_HOSTNAME=${KC_HOSTNAME})"
        rendered=$((rendered + 1))
    done
    echo "Realm-import: ${rendered} file(s) rendered."
fi

exec /opt/keycloak/bin/kc.sh "$@"
