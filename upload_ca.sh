#!/bin/bash

# Cloudflare API Token and Zone ID
API_TOKEN="your_api_token_here"
ZONE_ID="your_zone_id_here"
API_BASE_URL="https://api.cloudflare.com/client/v4"

# Function to upload CA certificates
upload_ca_certificates() {
    local directory=$1

    if [[ ! -d "$directory" ]]; then
        echo "Error: Directory $directory does not exist."
        return 1
    fi

    echo "Uploading CA certificates from directory: $directory"
    for ca_file in "$directory"/*.pem; do
        if [[ -f "$ca_file" ]]; then
            echo "Uploading CA certificate: $ca_file"
            response=$(curl -s -X POST "$API_BASE_URL/zones/$ZONE_ID/certificate_authorities" \
                -H "Authorization: Bearer $API_TOKEN" \
                -H "Content-Type: application/json" \
                --data @"$ca_file")

            if echo "$response" | grep -q '"success":true'; then
                mtls_certificate_id=$(echo "$response" | jq -r '.result.id')
                echo "Successfully uploaded CA certificate: $ca_file"
                echo "Certificate ID: $mtls_certificate_id"
            else
                echo "Failed to upload CA certificate: $ca_file"
                echo "Response: $response"
            fi
        else
            echo "No PEM files found in the directory."
        fi
    done
}

# Function to list all hostname associations
list_hostname_associations() {
    echo "Fetching hostname associations..."
    response=$(curl -s -X GET "$API_BASE_URL/zones/$ZONE_ID/certificate_authorities/hostname_associations" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")

    if echo "$response" | grep -q '"success":true'; then
        echo "Hostname associations:"
        echo "$response" | jq '.result[] | {hostname: .hostname, mtls_certificate_id: .mtls_certificate_id}'
    else
        echo "Failed to fetch hostname associations."
        echo "Response: $response"
    fi
}

# Function to update hostname associations
update_hostname_associations() {
    local mtls_certificate_id=$1
    shift
    local hostnames=("$@")

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

# Main script logic
if [[ "$1" == "upload" && -n "$2" ]]; then
    upload_ca_certificates "$2"
elif [[ "$1" == "list" ]]; then
    list_hostname_associations
elif [[ "$1" == "update" && -n "$2" && -n "$3" ]]; then
    mtls_certificate_id=$2
    shift 2
    update_hostname_associations "$mtls_certificate_id" "$@"
else
    echo "Usage:"
    echo "  $0 upload <directory>                 # Upload all CA certificates in the specified directory"
    echo "  $0 list                               # List all hostname associations"
    echo "  $0 update <mtls_certificate_id> <hostnames...>  # Update hostname associations with hostnames and mtls_certificate_id"
fi