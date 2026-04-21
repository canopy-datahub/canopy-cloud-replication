FROM quay.io/keycloak/keycloak:26.5.4

# Enable health checks and metrics
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Build optimised for PostgreSQL so the runtime DB matches and no re-build
# occurs on every container start ("Changes detected in configuration" warning).
ENV KC_DB=postgres

# Copy custom Canopy theme
COPY ./themes/canopy /opt/keycloak/themes/canopy

# Realm-import template. The entrypoint wrapper substitutes @@PUBLIC_HOSTNAME@@
# with the runtime KC_HOSTNAME and writes the rendered JSON to
# /opt/keycloak/data/import/ before kc.sh start --import-realm picks it up.
COPY ./realm-import /opt/keycloak/realm-template

# Entrypoint wrapper (sed-renders templates, then execs kc.sh).
COPY ./entrypoint.sh /opt/keycloak/entrypoint.sh

RUN /opt/keycloak/bin/kc.sh build

# Ensure proper permissions (keycloak user needs to read the template dir
# and write the rendered files into data/import).
USER root
RUN chmod +x /opt/keycloak/entrypoint.sh \
    && chown -R keycloak:keycloak /opt/keycloak
USER keycloak

# Expose Keycloak port
EXPOSE 8080

# Wrapper renders realm-import templates, then starts Keycloak optimised with
# --import-realm. Import is idempotent — skipped if the CANOPY realm already
# exists in the DB, so safe on container restart.
ENTRYPOINT ["/opt/keycloak/entrypoint.sh"]
CMD ["start", "--optimized", "--import-realm"]
