#!/bin/bash

# Cloudflare API Token and Zone ID
#
API_TOKEN=""
ZONE_ID=""
API_BASE_URL="https://api.cloudflare.com/client/v4"
ACCOUNT_ID=""



# Function to upload mTLS certificates
upload_mtls_certificates() {
    local directory=$1

    if [[ ! -d "$directory" ]]; then
        echo "Error: Directory $directory does not exist."
        return 1
    fi

    echo "Uploading mTLS certificates from directory: $directory"
    for cert_file in "$directory"/*.crt; do
        if [[ -f "$cert_file" ]]; then
            echo "Uploading mTLS certificate: $cert_file"
certificates_content=$(cat "$cert_file" | sed ':a;N;$!ba;s/\n/\\n/g')
            payload=$(jq -n --argjson ca true --arg certificates "$certificates_content" --arg name "$(basename "$cert_file" .crt)" \
                '{ca: $ca, certificates: $certificates, name: $name}')
            echo "Payload: $payload"
            # Use curl to upload the mTLS certificate
               response=$(curl -s -X POST "$API_BASE_URL/accounts/$ACCOUNT_ID/mtls_certificates" \
                -H "Authorization: Bearer $API_TOKEN" \
                -H "Content-Type: application/json" \
                -d "$payload")

            if echo "$response" | grep -q '"success":true'; then
                mtls_certificate_id=$(echo "$response" | jq -r '.result.id')
                echo "Successfully uploaded mTLS certificate: $cert_file"
                echo "Certificate ID: $mtls_certificate_id"
            else
                echo "Failed to upload mTLS certificate: $cert_file"
                echo "Response: $response"
            fi
        else
            echo "No .crt files found in the directory."
        fi
    done
}

# Function to list all mTLS certificates
list_mtls_certificates() {
    echo "Listing all mTLS certificates..."
    response=$(curl -s -X GET "$API_BASE_URL/accounts/$ACCOUNT_ID/mtls_certificates" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")

    if echo "$response" | grep -q '"success":true'; then
        echo "mTLS certificates:"
        echo "$response" | jq '.result[] | {id: .id, name: .name, created_on: .created_on}'
    else
        echo "Failed to list mTLS certificates."
        echo "Response: $response"
    fi
}

# Function to list all hostname associations
list_hostname_associations() {
    local mtls_certificate_id=$1

    if [[ -z "$mtls_certificate_id" ]]; then
        echo "Error: mtls_certificate_id is required."
        return 1
    fi

    echo "Fetching hostname associations for mtls_certificate_id: $mtls_certificate_id..."
    response=$(curl -s -G -X GET "$API_BASE_URL/zones/$ZONE_ID/certificate_authorities/hostname_associations" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data-urlencode "mtls_certificate_id=$mtls_certificate_id")

    if echo "$response" | grep -q '"success":true'; then
        echo "Hostname associations:"

        if echo "$response" | jq -e '.result.hostnames' > /dev/null; then
            echo "$response" | jq '.result.hostnames[]'
        else
            echo "No hostnames found."
            echo "Response: $response"
        fi
    else
        echo "Failed to fetch hostname associations."
        echo "Response: $response"
    fi
}

# Function to update hostname associations
update_hostname_associations() {
    local mtls_certificate_id=$1
    shift
    local hostnames=($@)

    if [[ -z "$mtls_certificate_id" || ${#hostnames[@]} -eq 0 ]]; then
        echo "Error: mtls_certificate_id and hostnames are required."
        return 1
    fi

    echo "Updating hostname associations for mtls_certificate_id: $mtls_certificate_id"
    payload=$(jq -n --arg id "$mtls_certificate_id" --argjson hostnames "$(printf '%s\n' "${hostnames[@]}" | jq -R . | jq -s .)" \
        '{mtls_certificate_id: $id, hostnames: $hostnames}')

    response=$(curl -s -X PUT "$API_BASE_URL/zones/$ZONE_ID/certificate_authorities/hostname_associations" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "$payload")

    if echo "$response" | grep -q '"success":true'; then
        echo "Successfully updated hostname associations."
    else
        echo "Failed to update hostname associations."
        echo "Response: $response"
    fi
}

# Function to delete an mTLS certificate
delete_mtls_certificate() {
    local mtls_certificate_id=$1

    if [[ -z "$mtls_certificate_id" ]]; then
        echo "Error: mtls_certificate_id is required."
        return 1
    fi

    echo "Deleting mTLS certificate with ID: $mtls_certificate_id..."
    response=$(curl -s -X DELETE "$API_BASE_URL/accounts/$ACCOUNT_ID/mtls_certificates/$mtls_certificate_id" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")

    if echo "$response" | grep -q '"success":true'; then
        echo "Successfully deleted mTLS certificate with ID: $mtls_certificate_id."
    else
        echo "Failed to delete mTLS certificate with ID: $mtls_certificate_id."
        echo "Response: $response"
    fi
}

# Function to delete hostname associations
delete_hostname_associations() {
    local mtls_certificate_id=$1

    if [[ -z "$mtls_certificate_id" ]]; then
        echo "Error: mtls_certificate_id is required."
        return 1
    fi

    echo "Deleting  hostname associations for mtls_certificate_id: $mtls_certificate_id"
    payload=$(jq -n --arg id "$mtls_certificate_id" '{mtls_certificate_id: $id, hostnames: []}')

    response=$(curl -s -X PUT "$API_BASE_URL/zones/$ZONE_ID/certificate_authorities/hostname_associations" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "$payload")

    if echo "$response" | grep -q '"success":true'; then
        echo "Successfully deleted all hostname associations."
    else
        echo "Failed to delete hostname associations."
        echo "Response: $response"
    fi
}

# Menu for the functions in the script
menu() {
    echo "Select an option:"
    echo "1) Upload mTLS certificates"
    echo "2) List all mTLS certificates"
    echo "3) List hostname associations"
    echo "4) Update hostname associations"
    echo "5) Delete hostname associations"
    echo "6) Delete an mTLS certificate"
    echo "7) Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            read -p "Enter the directory containing mTLS certificates: " directory
            upload_mtls_certificates "$directory"
            ;;
        2)
            list_mtls_certificates
            ;;
        3)
            read -p "Enter the mTLS certificate ID: " mtls_certificate_id
            list_hostname_associations "$mtls_certificate_id"
            ;;
        4)
            read -p "Enter the mTLS certificate ID: " mtls_certificate_id
            read -p "Enter the hostnames (space-separated): " -a hostnames
            update_hostname_associations "$mtls_certificate_id" "${hostnames[@]}"
            ;;
        5)
            read -p "Enter the mTLS certificate ID: " mtls_certificate_id
            read -p "Enter the hostnames to delete (space-separated): " -a hostnames
            delete_hostname_associations "$mtls_certificate_id" "${hostnames[@]}"
            ;;
        6)
            read -p "Enter the mTLS certificate ID to delete: " mtls_certificate_id
            delete_mtls_certificate "$mtls_certificate_id"
            ;;
        7)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            menu
            ;;
    esac
}

# Main script logic
menu
