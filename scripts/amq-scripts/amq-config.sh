#!/bin/bash web terminal/terminal

# Variables (can use args as well)
export KC_DOMAIN="<insert_domain_here>"
export HUB01_DOMAIN="<insert_domain_here>"
export SPOKE01_DOMAIN="<insert_domain_here>"
export SPOKE02_DOMAIN="<insert_domain_here>"
export SPOKE03_DOMAIN="<insert_domain_here>"
KEYCLOAK_NAMESPACE="keycloak"
POSTGRESQL_YAML="./keycloak/postgresql.yaml"
KEYCLOAK_CERT_PEM="./keycloak/tls/certificate.pem"
KEYCLOAK_KEY_PEM="./keycloak/tls/key.pem"
KEYCLOAK_YAML="./keycloak/keycloak.yaml"
REALM_EXPORT_JSON="./keycloak/realm-export.json"

# Step 1: Create PostgreSQL DB and credentials secret.
echo "Creating PostgreSQL DB and credentials secret..."
oc -n "$KEYCLOAK_NAMESPACE" apply -f "$POSTGRESQL_YAML"
oc -n "$KEYCLOAK_NAMESPACE" create secret generic keycloak-db-secret --from-literal=username=admin --from-literal=password=admin

# Wait for DB and secret creation (sleep for 10 seconds).
echo "Waiting 10 seconds for Keycloak to initialize..."
sleep 10

# Step 2: Create the Keycloak TLS secret.
echo "Creating the Keycloak TLS secret..."
oc -n "$KEYCLOAK_NAMESPACE" create secret tls keycloak-tls-secret --cert "$KEYCLOAK_CERT_PEM" --key "$KEYCLOAK_KEY_PEM"

# Step 3: Create the Keycloak server.
echo "Creating the Keycloak server..."
cat "$KEYCLOAK_YAML" | envsubst | oc -n "$KEYCLOAK_NAMESPACE" apply -f -

# Wait for KC server (sleep for 15 seconds).
echo "Waiting 15 seconds for Keycloak to initialize..."
sleep 15

# Step 4: Create the "artemis-keycloak" realm.
echo "Creating the 'artemis-keycloak' realm..."
yq -p=json -oy '{"apiVersion": "k8s.keycloak.org/v2alpha1", "kind": "KeycloakRealmImport", "metadata": {"name": "artemis-keycloak"}, "spec": {"keycloakCRName": "keycloak", "realm": .}}' "$REALM_EXPORT_JSON" | oc -n "$KEYCLOAK_NAMESPACE" apply -f -

# Wait for Keycloak to initialize (sleep for 30 seconds).
echo "Waiting 60 seconds for Keycloak to initialize..."
sleep 30

# Step 5: Retrieve Keycloak initial admin credentials.
echo "Retrieving Keycloak initial admin credentials..."
ADMIN_USERNAME=$(oc -n "$KEYCLOAK_NAMESPACE" get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 --decode)
ADMIN_PASSWORD=$(oc -n "$KEYCLOAK_NAMESPACE" get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 --decode)

echo "Keycloak Admin Username: $ADMIN_USERNAME"
echo "Keycloak Admin Password: $ADMIN_PASSWORD"

# Step 6: Set KC_CLIENT_SECRET
export KC_CLIENT_SECRET="<insert_secret_here>"

echo "Keycloak client secret set to: $KC_CLIENT_SECRET"

echo "Keycloak Script execution completed successfully."

echo "Script execution started for Promestheus/Grafana."

# Create/configure the Prometheus server. These steps must be completed as cluster-admin.
oc -n metrics apply -f "./prometheus/prometheus-additional-scrape-secret.yaml"
oc -n metrics apply -f "./prometheus/prometheus.yaml"

oc -n metrics create secret generic hub-01-broker-auth --from-literal=user=admin --from-literal=password=admin
oc -n metrics apply -f "./prometheus/hub-01-broker-service-monitor.yaml"

oc -n metrics create secret generic hub-02-broker-auth --from-literal=user=admin --from-literal=password=admin
oc -n metrics apply -f "./prometheus/hub-02-broker-service-monitor.yaml"

oc -n metrics create secret generic spoke-01-broker-auth --from-literal=user=admin --from-literal=password=admin
oc -n metrics apply -f "./prometheus/spoke-01-broker-service-monitor.yaml"
# End cluster-admin steps.

#
# Create/configure the Grafana server.
oc -n metrics apply -f "./grafana/grafana.yaml"
oc -n metrics expose service grafana-service
oc -n metrics apply -f "./grafana/prometheus-datasource.yaml"
oc -n metrics apply -f './grafana/grafana-*-dashboard.yaml'

echo "Script execution completed for Promestheus/Grafana."
