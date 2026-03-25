FROM quay.io/keycloak/keycloak:26.5.4

# Enable health checks and metrics
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Build optimised for PostgreSQL so the runtime DB matches and no re-build
# occurs on every container start ("Changes detected in configuration" warning).
ENV KC_DB=postgres

RUN /opt/keycloak/bin/kc.sh build

# Ensure proper permissions
USER root
RUN chown -R keycloak:keycloak /opt/keycloak
USER keycloak

# Expose Keycloak port
EXPOSE 8080

# Start Keycloak in optimized mode
# Configuration will come from environment variables and secrets
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start", "--optimized"]
