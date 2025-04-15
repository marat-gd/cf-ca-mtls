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

        echo "$response" | jq '.result.hostnames[]'
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

# Main script logic
if [[ "$1" == "upload" && -n "$2" ]]; then
    upload_mtls_certificates "$2"
elif [[ "$1" == "list-mtls" ]]; then
    list_mtls_certificates
elif [[ "$1" == "list-hostnames" && -n "$2" ]]; then
    list_hostname_associations "$2"
elif [[ "$1" == "update" && -n "$2" && -n "$3" ]]; then
    mtls_certificate_id=$2
    shift 2
    update_hostname_associations "$mtls_certificate_id" "$@"
elif [[ "$1" == "delete" && -n "$2" ]]; then
    delete_mtls_certificate "$2"
else
    echo "Usage:"
    echo "  $0 upload <directory>                 # Upload all mTLS certificates in the specified directory"
    echo "  $0 list-mtls                          # List all mTLS certificates"
    echo "  $0 list-hostnames <mtls_certificate_id> # List all hostname associations for the specified mTLS certificate ID"
    echo "  $0 update <mtls_certificate_id> <hostnames...>  # Update hostname associations with hostnames and mtls_certificate_id"
    echo "  $0 delete <mtls_certificate_id>       # Delete the specified mTLS certificate ID"
fi
