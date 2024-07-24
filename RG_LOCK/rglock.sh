#!/bin/bash

# Function to prompt user for input
prompt_for_input() {
  read -p "Enter your Azure subscription ID: " SUBSCRIPTION_ID
  read -p "Enter the resource group name: " RESOURCE_GROUP
  read -p "Do you want to add or remove a lock? (add/remove): " ACTION
  
  if [ "$ACTION" == "add" ]; then
    read -p "Enter the new lock name: " LOCK_NAME
    LOCK_LEVEL="ReadOnly"  # Default lock level for add action
  elif [ "$ACTION" == "remove" ]; then
    echo "Fetching existing lock names for resource group $RESOURCE_GROUP..."
  else
    echo "Invalid action. Use 'add' to create a lock or 'remove' to delete a lock."
    exit 1
  fi
}

# Function to set the subscription
set_subscription() {
  az account set --subscription $SUBSCRIPTION_ID
}

# Function to add lock
add_lock() {
  az lock create --name $LOCK_NAME --resource-group $RESOURCE_GROUP --lock-type $LOCK_LEVEL
  echo "Lock $LOCK_NAME added to resource group $RESOURCE_GROUP."
}

# Function to get existing locks
get_existing_locks() {
  az lock list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Type:lockType}" --output table
}

# Function to remove lock
remove_lock() {
  existing_locks=$(az lock list --resource-group $RESOURCE_GROUP --query "[].name" --output tsv)
  
  if [ -z "$existing_locks" ]; then
    echo "No locks found in resource group $RESOURCE_GROUP."
    exit 1
  else
    echo "Existing locks in resource group $RESOURCE_GROUP:"
    get_existing_locks
    
    for lock_name in $existing_locks; do
      read -p "Do you want to remove the lock '$lock_name'? (Yes/No): " confirm
      if [ "$confirm" == "Yes" ]; then
        az lock delete --name $lock_name --resource-group $RESOURCE_GROUP
        echo "Lock $lock_name removed from resource group $RESOURCE_GROUP."
      fi
    done
  fi
}

# Main logic
prompt_for_input
set_subscription

if [ "$ACTION" == "add" ]; then
  add_lock
elif [ "$ACTION" == "remove" ]; then
  remove_lock
fi
