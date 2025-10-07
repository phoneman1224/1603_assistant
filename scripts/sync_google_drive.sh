#!/usr/bin/env bash
set -Eeuo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
DRIVE_ID="1qfmD9Laq9Zj3gNGET44u3nTjQQpcQU7e"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"
TEMP_DIR="/tmp/1603_files"
BRANCH_NAME="upload-platform-files"

# Function to check dependencies
check_deps() {
    echo -e "${BLUE}[CHECK]${NC} Verifying required tools..."
    
    local missing_deps=()
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    if ! command -v pip3 &> /dev/null; then
        missing_deps+=("python3-pip")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them using your package manager:"
        echo "sudo apt install ${missing_deps[*]}  # For Ubuntu/Debian"
        echo "sudo dnf install ${missing_deps[*]}  # For Fedora"
        echo "sudo pacman -S ${missing_deps[*]}   # For Arch Linux"
        exit 1
    fi
    
    # Install required Python packages
    echo -e "${BLUE}[DEPS]${NC} Installing required Python packages..."
    pip3 install --quiet google-auth-oauthlib google-auth-httplib2 google-api-python-client
}

# Function to setup working directory
setup_workspace() {
    echo -e "${BLUE}[SETUP]${NC} Creating temporary directory..."
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    mkdir -p "$TEMP_DIR/1603_SM/"{commands,docs,schemas}
    mkdir -p "$TEMP_DIR/16034_SMX/"{commands,docs,schemas}
    
    # Copy service account credentials to temp directory
    cp "$SCRIPT_DIR/service-account.json" "$TEMP_DIR/"
    chmod 600 "$TEMP_DIR/service-account.json"
}

# Function to download files from Google Drive
download_files() {
    echo -e "${BLUE}[DOWNLOAD]${NC} Downloading files from Google Drive..."
    
    # Create Python script for Google Drive download
    cat > "$TEMP_DIR/download.py" << 'EOF'
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
import os
import io

SCOPES = ['https://www.googleapis.com/auth/drive.readonly']

def get_credentials():
    try:
        # Get the absolute path to service-account.json
        service_account_path = '/tmp/1603_files/service-account.json'
        
        print(f"Loading service account from: {service_account_path}")
        
        credentials = service_account.Credentials.from_service_account_file(
            service_account_path,
            scopes=SCOPES
        )
        
        return credentials
    except Exception as e:
        print(f"Error loading service account: {e}")
        return None

def process_folder(service, folder_id, folder_path):
    """Process a folder and its contents recursively."""
    results = service.files().list(
        q=f"'{folder_id}' in parents",
        pageSize=100,
        fields="files(id, name, mimeType)"
    ).execute()
    items = results.get('files', [])

    for item in items:
        print(f"Found item: {item['name']} ({item['mimeType']})")
        if item['mimeType'] == 'application/vnd.google-apps.folder':
            # Create subfolder
            subfolder_path = os.path.join(folder_path, item['name'])
            os.makedirs(subfolder_path, exist_ok=True)
            # Process subfolder recursively
            process_folder(service, item['id'], subfolder_path)
        else:
            download_file(service, item, folder_path)

def download_file(service, item, target_dir):
    """Download a single file from Drive."""
    try:
        # Define Google Workspace MIME types and their export formats
        GOOGLE_MIME_TYPES = {
            'application/vnd.google-apps.document': 'application/pdf',
            'application/vnd.google-apps.spreadsheet': 'application/pdf',
            'application/vnd.google-apps.presentation': 'application/pdf',
            'application/vnd.google-apps.drawing': 'application/pdf'
        }

        if item['mimeType'] in GOOGLE_MIME_TYPES:
            request = service.files().export_media(
                fileId=item['id'],
                mimeType=GOOGLE_MIME_TYPES[item['mimeType']]
            )
            filename = os.path.splitext(item['name'])[0] + '.pdf'
        else:
            request = service.files().get_media(fileId=item['id'])
            filename = item['name']

        print(f"Downloading: {filename}")
        fh = io.BytesIO()
        downloader = MediaIoBaseDownload(fh, request)
        done = False
        while done is False:
            status, done = downloader.next_chunk()

        fh.seek(0)
        filepath = os.path.join(target_dir, filename)
        with open(filepath, 'wb') as f:
            f.write(fh.read())
        print(f"Saved: {filepath}")
    except Exception as e:
        print(f"Error downloading {item['name']}: {str(e)}")

def download_from_drive(folder_id, base_path):
    """Download all files from the specified Google Drive folder."""
    print("Starting download from Google Drive...")
    creds = get_credentials()
    if not creds:
        return False
        
    try:
        print("Building Drive service...")
        service = build('drive', 'v3', credentials=creds)
        
        print(f"Processing folder {folder_id}...")
        process_folder(service, folder_id, base_path)
        return True
        
        # Define Google Workspace MIME types and their export formats
        GOOGLE_MIME_TYPES = {
            'application/vnd.google-apps.document': 'application/pdf',
            'application/vnd.google-apps.spreadsheet': 'application/pdf',
            'application/vnd.google-apps.presentation': 'application/pdf',
            'application/vnd.google-apps.drawing': 'application/pdf'
        }
        
        if not items:
            print('No files found.')
            return False
            
        # Process each file
        for item in items:
            print(f'Processing {item["name"]}...')
            
            # Determine the appropriate subfolder
            if '1603_SM' in item['name'].upper():
                platform = '1603_SM'
            else:
                platform = '16034_SMX'
                
            if item['name'].endswith(('.json')):
                subdir = 'schemas'
            elif item['name'].endswith(('.md', '.txt', '.pdf')):
                subdir = 'docs'
            else:
                subdir = 'commands'
                
            # Create target directory
            target_dir = os.path.join(base_path, platform, subdir)
            os.makedirs(target_dir, exist_ok=True)
            
            try:
                if item['mimeType'] in GOOGLE_MIME_TYPES:
                    # Handle Google Workspace files
                    request = service.files().export_media(
                        fileId=item['id'],
                        mimeType=GOOGLE_MIME_TYPES[item['mimeType']]
                    )
                    # Add .pdf extension for exported files
                    filename = os.path.splitext(item['name'])[0] + '.pdf'
                else:
                    # Handle regular files
                    request = service.files().get_media(fileId=item['id'])
                    filename = item['name']
                
                fh = io.BytesIO()
                downloader = MediaIoBaseDownload(fh, request)
                done = False
                while done is False:
                    status, done = downloader.next_chunk()
                    
                # Save the file
                fh.seek(0)
                filepath = os.path.join(target_dir, filename)
                with open(filepath, 'wb') as f:
                    f.write(fh.read())
                print(f"Downloaded: {filename}")
                    
            except Exception as e:
                print(f"Error downloading {item['name']}: {e}")
                continue
                
        return True
        
    except Exception as e:
        print(f'An error occurred: {e}')
        return False

if __name__ == '__main__':
    # Get the absolute path to the credentials file
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    credentials_path = os.path.join(repo_root, 'scripts', 'credentials.json')
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credentials_path
    
    folder_id = "1qfmD9Laq9Zj3gNGET44u3nTjQQpcQU7e"
    success = download_from_drive(folder_id, "/tmp/1603_files")
    exit(0 if success else 1)
EOF

    # Run the Python script
    if python3 "$TEMP_DIR/download.py"; then
        echo -e "${GREEN}[SUCCESS]${NC} Files downloaded successfully"
        return 0
    else
        echo -e "${RED}[ERROR]${NC} Failed to download files from Google Drive"
        return 1
    fi
}

# Function to organize files
organize_files() {
    echo -e "${BLUE}[ORGANIZE]${NC} Organizing files into repository structure..."
    
    # Create platform directories if they don't exist
    mkdir -p "$REPO_ROOT/data/platforms/1603_SM/"{commands,docs,schemas}
    mkdir -p "$REPO_ROOT/data/platforms/16034_SMX/"{commands,docs,schemas}
    
    # Copy organized files to repository
    cp -r "$TEMP_DIR/1603_SM/"* "$REPO_ROOT/data/platforms/1603_SM/"
    cp -r "$TEMP_DIR/16034_SMX/"* "$REPO_ROOT/data/platforms/16034_SMX/"
    
    # Verify files were copied
    if [ ! -f "$REPO_ROOT/data/platforms/1603_SM/commands/act_user.json" ] || \
       [ ! -f "$REPO_ROOT/data/platforms/16034_SMX/commands/rtrv_hdr.json" ]; then
        echo -e "${RED}[ERROR]${NC} Failed to copy files to repository"
        return 1
    fi
    
    # Git operations
    git add "$REPO_ROOT/data/platforms/1603_SM" "$REPO_ROOT/data/platforms/16034_SMX"
    
    if ! git diff --cached --quiet; then
        git commit -m "feat: Import platform files
        
        - Added 1603_SM example files
        - Added 16034_SMX example files
        - Organized into commands/docs/schemas structure"
        echo -e "${GREEN}[SUCCESS]${NC} Files have been organized and committed"
    else
        echo -e "${RED}[ERROR]${NC} No changes to commit"
        return 1
    fi
}

# Function to cleanup
cleanup() {
    echo -e "${BLUE}[CLEANUP]${NC} Removing temporary files..."
    rm -rf "$TEMP_DIR"
}

# Main execution
main() {
    echo -e "${GREEN}[START]${NC} Beginning Google Drive sync process..."
    
    check_deps
    setup_workspace
    download_files
    organize_files
    cleanup
    
    echo -e "${GREEN}[COMPLETE]${NC} Sync process finished successfully!"
    echo "Next steps:"
    echo "1. Review the changes in the 'upload-platform-files' branch"
    echo "2. Push the changes: git push origin $BRANCH_NAME"
    echo "3. Create a pull request on GitHub to merge into main"
}

# Run main function
main "$@"