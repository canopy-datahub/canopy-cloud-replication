FROM quay.io/keycloak/keycloak:26.5.4

# Enable health checks and metrics
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Use embedded H2 database (default, no external database needed)
# Note: This is suitable for development/testing. For production, use PostgreSQL.
ENV KC_DB=dev-file

# Build the optimized Keycloak distribution with required features
# Add any additional features you need here (e.g., user-storage-jpa, user-storage-ldap)
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
