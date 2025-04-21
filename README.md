# Cloudflare mTLS Management Script

This script provides a set of functions to manage mTLS certificates and hostname associations in Cloudflare using the Cloudflare API. It allows you to upload, list, update, and delete mTLS certificates and their associated hostnames.

## Features

1. **Upload mTLS Certificates**:
   - Upload `.crt` files from a specified directory to Cloudflare.

2. **List mTLS Certificates**:
   - Retrieve and display all mTLS certificates in your Cloudflare account.

3. **List Hostname Associations**:
   - Fetch and display hostname associations for a specific mTLS certificate.

4. **Update Hostname Associations**:
   - Add or update hostname associations for a specific mTLS certificate.

5. **Delete Hostname Associations**:
   - Remove all hostname associations for a specific mTLS certificate.

6. **Delete mTLS Certificates**:
   - Delete a specific mTLS certificate from Cloudflare.

## Prerequisites

- **Cloudflare API Token**: Ensure you have a valid API token with the necessary permissions.
- **Zone ID**: The Zone ID of your Cloudflare account.
- **Account ID**: The Account ID of your Cloudflare account.
- **jq**: The script uses `jq` for JSON processing. Install it using:
  ```bash
  brew install jq
  ```

## Usage

1. **Run the Script**:
   ```bash
   ./cf_manage_mtls.sh
   ```

2. **Select an Option**:
   - The script provides a menu with the following options:
     1. Upload mTLS certificates
     2. List all mTLS certificates
     3. List hostname associations
     4. Update hostname associations
     5. Delete hostname associations
     6. Delete an mTLS certificate
     7. Exit

3. **Follow Prompts**:
   - Enter the required inputs (e.g., directory path, certificate ID, hostnames) as prompted by the script.

## Example Commands

### Upload mTLS Certificates
```bash
Enter the directory containing mTLS certificates: /path/to/certificates
```

### List mTLS Certificates
```bash
Listing all mTLS certificates...
```

### Update Hostname Associations
```bash
Enter the mTLS certificate ID: <certificate_id>
Enter the hostnames (space-separated): example.com api.example.com
```

## Response Examples

### Upload mTLS Certificates
**Command:**
```bash
Enter the directory containing mTLS certificates: /path/to/certificates
```
**Response:**
```
Uploading certificate: cert1.crt
Uploading certificate: cert2.crt
All certificates uploaded successfully.
```

### List mTLS Certificates
**Command:**
```bash
Listing all mTLS certificates...
```
**Response:**
```
Certificate ID: abc123
Certificate Name: cert1
Expiration Date: 2025-12-31

Certificate ID: def456
Certificate Name: cert2
Expiration Date: 2026-01-15
```

### List Hostname Associations
**Command:**
```bash
Enter the mTLS certificate ID: abc123
```
**Response:**
```
Hostnames associated with certificate ID abc123:
- example.com
- api.example.com
```

### Update Hostname Associations
**Command:**
```bash
Enter the mTLS certificate ID: abc123
Enter the hostnames (space-separated): example.com api.example.com
```
**Response:**
```
Updating hostnames for certificate ID abc123...
Hostnames updated successfully.
```

### Delete Hostname Associations
**Command:**
```bash
Enter the mTLS certificate ID: abc123
```
**Response:**
```
Deleting all hostnames associated with certificate ID abc123...
All hostnames deleted successfully.
```

### Delete mTLS Certificates
**Command:**
```bash
Enter the mTLS certificate ID to delete: abc123
```
**Response:**
```
Deleting certificate ID abc123...
Certificate deleted successfully.
```

## Notes

- Ensure the `.crt` files are in the specified directory before uploading.
- The script uses the `sed` command to format certificate content for JSON payloads.
- API responses are processed using `jq` for better readability.

## Security

- **API Token**: The API token is hardcoded in the script. Ensure the script is stored securely and restrict access to it.
- **Sensitive Data**: Avoid sharing the script with sensitive data (e.g., API token, Account ID) publicly.

## Troubleshooting

- **Error: Directory does not exist**:
  - Ensure the directory path is correct and contains `.crt` files.

- **Failed to upload mTLS certificate**:
  - Check the API token, Account ID, and Zone ID for correctness.
  - Verify the `.crt` file format.

- **Dependencies**:
  - Ensure `jq` is installed and accessible in your system's PATH.

## License

This script is provided "as is" without warranty of any kind. Use it at your own risk.
