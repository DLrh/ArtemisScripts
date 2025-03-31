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

# Step 5: Wait for Keycloak to initialize (sleep for 60 seconds).
echo "Waiting 60 seconds for Keycloak to initialize..."
sleep 60

# Step 5: Retrieve Keycloak initial admin credentials.
echo "Retrieving Keycloak initial admin credentials..."
ADMIN_USERNAME=$(oc -n "$KEYCLOAK_NAMESPACE" get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 --decode)
ADMIN_PASSWORD=$(oc -n "$KEYCLOAK_NAMESPACE" get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 --decode)

echo "Keycloak Admin Username: $ADMIN_USERNAME"
echo "Keycloak Admin Password: $ADMIN_PASSWORD"

# Step 6: Set KC_CLIENT_SECRET
export KC_CLIENT_SECRET="<insert_secret_here>"

echo "Keycloak client secret set to: $KC_CLIENT_SECRET"

echo "Script for keycloack config completed successfully."
