#!/bin/bash web terminal/terminal

# Variables (can use args as well)
ARTEMIS_NAMESPACE="artemis"
BROKER_KEYSTORE="./artemis/tls/spoke-01-broker-keystore.jks"
BROKER_TRUSTSTORE="./artemis/tls/spoke-01-broker-truststore.jks"
KEYSTORE_PASSWORD="password"
TRUSTSTORE_PASSWORD="password"
KEYCLOAK_BEARER_TOKEN_TEMPLATE="./artemis/keycloak-bearer-token.template.json"
KEYCLOAK_DIRECT_ACCESS_TEMPLATE="./artemis/keycloak-direct-access.template.json"
KEYCLOAK_JS_CLIENT_TEMPLATE="./artemis/keycloak-js-client.template.json"
LOGIN_CONFIG="./artemis/login.config"
BROKER_PROPERTIES_TEMPLATE="./artemis/spoke-01-broker.template.properties"
BROKER_YAML="./artemis/spoke-01-broker.yaml"
TEMP_DIR="./artemis/tmp/spoke-01"

# Step 1: Create the Artemis TLS secret.
echo "Creating Artemis TLS secret..."
oc -n "$ARTEMIS_NAMESPACE" create secret generic broker-tls-secret \
  --from-file=broker.ks="$BROKER_KEYSTORE" \
  --from-file=client.ts="$BROKER_TRUSTSTORE" \
  --from-literal=keyStorePassword="$KEYSTORE_PASSWORD" \
  --from-literal=trustStorePassword="$TRUSTSTORE_PASSWORD"

# Step 2: Create the OIDC JaaS configuration secret.
echo "Creating OIDC JaaS configuration secret..."
export TRUSTSTORE_PATH="/etc/broker-tls-secret-volume/client.ts"

# Generate the Keycloak config files using envsubst
mkdir -p "$TEMP_DIR"

cat "$KEYCLOAK_BEARER_TOKEN_TEMPLATE" | envsubst > "$TEMP_DIR/keycloak-bearer-token.json"
cat "$KEYCLOAK_DIRECT_ACCESS_TEMPLATE" | envsubst > "$TEMP_DIR/keycloak-direct-access.json"
cat "$KEYCLOAK_JS_CLIENT_TEMPLATE" | envsubst > "$TEMP_DIR/keycloak-js-client.json"

# Create the secret for OIDC JaaS configuration
oc -n "$ARTEMIS_NAMESPACE" create secret generic oidc-jaas-config \
  --from-file=login.config="$LOGIN_CONFIG" \
  --from-file=_keycloak-js-client.json="$TEMP_DIR/keycloak-js-client.json" \
  --from-file=_keycloak-direct-access.json="$TEMP_DIR/keycloak-direct-access.json" \
  --from-file=_keycloak-bearker-token.json="$TEMP_DIR/keycloak-bearer-token.json"

# Step 3: Create the brokerProperties secret.
echo "Creating the brokerProperties secret..."
cat "$BROKER_PROPERTIES_TEMPLATE" | envsubst > "$TEMP_DIR/spoke-01-broker.properties"

oc -n "$ARTEMIS_NAMESPACE" create secret generic spoke-01-broker-bp \
  --from-file=broker.properties="$TEMP_DIR/spoke-01-broker.properties"

# Step 4: Create the Artemis broker cluster.
echo "Creating the Artemis broker cluster..."
oc -n "$ARTEMIS_NAMESPACE" apply -f "$BROKER_YAML"

echo "Script for AMQ Spoke01 completed successfully."
