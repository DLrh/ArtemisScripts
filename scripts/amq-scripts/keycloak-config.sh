#!/bin/bash web terminal/terminal

# Variables (can use args as well)
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

# Step 2: Create the Keycloak TLS secret.
echo "Creating the Keycloak TLS secret..."
oc -n "$KEYCLOAK_NAMESPACE" create secret tls keycloak-tls-secret --cert "$KEYCLOAK_CERT_PEM" --key "$KEYCLOAK_KEY_PEM"

# Step 3: Create the Keycloak server.
echo "Creating the Keycloak server..."
cat "$KEYCLOAK_YAML" | envsubst | oc -n "$KEYCLOAK_NAMESPACE" apply -f -

# Step 4: Create the "artemis-keycloak" realm.
echo "Creating the 'artemis-keycloak' realm..."
yq -p=json -oy '{"apiVersion": "k8s.keycloak.org/v2alpha1", "kind": "KeycloakRealmImport", "metadata": {"name": "artemis-keycloak"}, "spec": {"keycloakCRName": "keycloak", "realm": .}}' "$REALM_EXPORT_JSON" | oc -n "$KEYCLOAK_NAMESPACE" apply -f -

echo "Script for Keycloak completed successfully."
