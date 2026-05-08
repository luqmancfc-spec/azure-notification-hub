#!/bin/bash

# --- 1. Variables ---
# We use a random suffix to ensure the Namespace name is globally unique
UNIQUE_ID=$RANDOM
RESOURCE_GROUP="rg-notifications-${UNIQUE_ID}"
LOCATION="eastus"
NH_NAMESPACE="nh-namespace-${UNIQUE_ID}"
NH_NAME="my-notification-hub"

echo "🚀 Starting deployment for: ${RESOURCE_GROUP}"

# --- 2. Deployment Steps ---

# Create the Resource Group
echo "Creating Resource Group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Create the Notification Hub Namespace
echo "Creating Notification Hub Namespace..."
az notification-hub namespace create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$NH_NAMESPACE" \
    --location "$LOCATION" \
    --sku Free

# Create the Notification Hub
echo "Creating Notification Hub..."
az notification-hub create \
    --resource-group "$RESOURCE_GROUP" \
    --namespace-name "$NH_NAMESPACE" \
    --name "$NH_NAME" \
    --location "$LOCATION"

echo "✅ Deployment Complete!"
echo "Resource Group: $RESOURCE_GROUP"
echo "Namespace: $NH_NAMESPACE"