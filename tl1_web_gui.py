#!/usr/bin/env python3
"""
TL1 Assistant - Web-based GUI with Telnet Backend
A hybrid solution that provides a web interface while maintaining direct device communication
Version: 1.0.0
"""

import json
import asyncio
import telnetlib
import threading
import webbrowser
from pathlib import Path
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import socket
import sys
import time

# Version information
__version__ = "1.0.0"
__build_date__ = "2025-10-07"
__build_number__ = "001"

class TL1Backend:
    """Handles TL1 device communication via Telnet"""
    
    def __init__(self):
        self.connection = None
        self.is_connected = False
        self.host = ""
        self.port = 23
        
    def connect(self, host, port=23):
        """Connect to TL1 device"""
        try:
            self.connection = telnetlib.Telnet(host, port, timeout=10)
            self.is_connected = True
            self.host = host
            self.port = port
            return {"status": "connected", "message": f"Connected to {host}:{port}"}
        except Exception as e:
            self.is_connected = False
            return {"status": "error", "message": f"Connection failed: {str(e)}"}
    
    def disconnect(self):
        """Disconnect from TL1 device"""
        if self.connection:
            try:
                self.connection.close()
            except:
                pass
        self.is_connected = False
        self.connection = None
        return {"status": "disconnected", "message": "Disconnected"}
    
    def send_command(self, command):
        """Send TL1 command and get response"""
        if not self.is_connected or not self.connection:
            return {"status": "error", "message": "Not connected to device"}
        
        try:
            # Ensure command ends with semicolon
            if not command.strip().endswith(';'):
                command = command.strip() + ';'
            
            # Send command
            self.connection.write((command + '\n').encode('ascii'))
            
            # Read response (wait for semicolon terminator)
            response = ""
            start_time = time.time()
            while time.time() - start_time < 30:  # 30 second timeout
                try:
                    data = self.connection.read_very_eager().decode('ascii', errors='ignore')
                    response += data
                    if ';' in response:
                        break
                    time.sleep(0.1)
                except:
                    break
            
            return {
                "status": "success",
                "command": command,
                "response": response.strip(),
                "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
            }
            
        except Exception as e:
            return {"status": "error", "message": f"Command failed: {str(e)}"}

class TL1WebHandler(SimpleHTTPRequestHandler):
    """HTTP request handler for the web GUI"""
    
    def __init__(self, *args, tl1_backend=None, commands_data=None, **kwargs):
        self.tl1_backend = tl1_backend
        self.commands_data = commands_data
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle GET requests"""
        parsed_url = urlparse(self.path)
        
        if parsed_url.path == '/':
            self.serve_main_page()
        elif parsed_url.path == '/api/commands':
            self.serve_commands_api()
        elif parsed_url.path == '/api/status':
            self.serve_status_api()
        elif parsed_url.path == '/api/version':
            self.serve_version_api()
        else:
            # Serve static files (CSS, JS, etc.)
            super().do_GET()
    
    def do_POST(self):
        """Handle POST requests"""
        parsed_url = urlparse(self.path)
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        try:
            data = json.loads(post_data)
        except:
            data = {}
        
        if parsed_url.path == '/api/connect':
            self.handle_connect(data)
        elif parsed_url.path == '/api/disconnect':
            self.handle_disconnect()
        elif parsed_url.path == '/api/send_command':
            self.handle_send_command(data)
        else:
            self.send_error(404)
    
    def serve_main_page(self):
        """Serve the main HTML page"""
        html_content = self.generate_html_page()
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html_content.encode('utf-8'))
    
    def serve_commands_api(self):
        """Serve commands data as JSON API"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        # Filter commands based on query parameters
        query_params = parse_qs(urlparse(self.path).query)
        platform = query_params.get('platform', [''])[0]
        category = query_params.get('category', [''])[0]
        
        filtered_commands = self.filter_commands(platform, category)
        self.wfile.write(json.dumps(filtered_commands).encode('utf-8'))
    
    def serve_status_api(self):
        """Serve connection status"""
        status = {
            "connected": self.tl1_backend.is_connected,
            "host": self.tl1_backend.host,
            "port": self.tl1_backend.port
        }
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(status).encode('utf-8'))
    
    def serve_version_api(self):
        """Serve version information"""
        version_info = load_version_info()
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(version_info).encode('utf-8'))
    
    def handle_connect(self, data):
        """Handle connection request"""
        host = data.get('host', '')
        port = int(data.get('port', 23))
        
        result = self.tl1_backend.connect(host, port)
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(result).encode('utf-8'))
    
    def handle_disconnect(self):
        """Handle disconnection request"""
        result = self.tl1_backend.disconnect()
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(result).encode('utf-8'))
    
    def handle_send_command(self, data):
        """Handle TL1 command execution"""
        command = data.get('command', '')
        
        result = self.tl1_backend.send_command(command)
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(result).encode('utf-8'))
    
    def filter_commands(self, platform, category):
        """Filter commands by platform and category"""
        if not self.commands_data or 'commands' not in self.commands_data:
            return []
        
        commands = []
        for cmd_id, cmd_data in self.commands_data['commands'].items():
            # Platform filter
            if platform and platform not in cmd_data.get('platforms', []):
                continue
            
            # Category filter
            if category and cmd_data.get('category', '') != category:
                continue
            
            # Include full command data for proper command building
            command_info = {
                'id': cmd_id,
                'name': cmd_data.get('displayName', cmd_id),
                'displayName': cmd_data.get('displayName', cmd_id),
                'description': cmd_data.get('description', ''),
                'syntax': cmd_data.get('syntax', ''),
                'category': cmd_data.get('category', ''),
                'platforms': cmd_data.get('platforms', []),
                'requires': cmd_data.get('requires', []),
                'optional': cmd_data.get('optional', []),
                'paramSchema': cmd_data.get('paramSchema', {}),
                'examples': cmd_data.get('examples', []),
                'safety_level': cmd_data.get('safety_level', 'safe'),
                'service_affecting': cmd_data.get('service_affecting', False),
                'response_format': cmd_data.get('response_format', '')
            }
            
            commands.append(command_info)
        
        return sorted(commands, key=lambda x: x['name'])
    
    def generate_html_page(self):
        """Generate the main HTML page"""
        # Load version information
        version_info = load_version_info()
        version_str = version_info.get('version', '1.0.0')
        build_str = version_info.get('build_number', '001')
        date_str = version_info.get('build_date', '2025-10-07')
        
        return """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TL1 Assistant v""" + version_str + """</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        .header { background: #2563eb; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .header h1 { font-size: 24px; margin-bottom: 5px; }
        .header p { opacity: 0.9; }
        .header .version-info { font-size: 12px; opacity: 0.8; margin-top: 10px; }
        
        .main-grid { display: grid; grid-template-columns: 300px 1fr; gap: 20px; }
        .sidebar { background: white; border-radius: 8px; padding: 20px; height: fit-content; }
        .content { background: white; border-radius: 8px; padding: 20px; }
        
        .connection-panel { margin-bottom: 20px; padding: 15px; background: #f8f9fa; border-radius: 6px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: 500; }
        .form-group input, .form-group select { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
        
        .btn { padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; font-weight: 500; }
        .btn-primary { background: #2563eb; color: white; }
        .btn-secondary { background: #6b7280; color: white; }
        .btn-danger { background: #dc2626; color: white; }
        .btn:hover { opacity: 0.9; }
        .btn:disabled { opacity: 0.5; cursor: not-allowed; }
        
        .status { padding: 10px; border-radius: 4px; margin: 10px 0; }
        .status.connected { background: #dcfce7; color: #166534; border: 1px solid #bbf7d0; }
        .status.disconnected { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
        
        .command-tree { max-height: 400px; overflow-y: auto; }
        .tree-category { margin-bottom: 10px; }
        .tree-category h4 { padding: 8px; background: #f3f4f6; border-radius: 4px; cursor: pointer; }
        .tree-commands { padding-left: 15px; }
        .tree-command { padding: 5px 10px; cursor: pointer; border-radius: 3px; }
        .tree-command:hover { background: #e5e7eb; }
        .tree-command.selected { background: #2563eb; color: white; }
        
        .command-builder { margin-bottom: 20px; }
        .command-preview { background: #1f2937; color: #e5e7eb; padding: 15px; border-radius: 6px; font-family: 'Consolas', monospace; margin: 15px 0; }
        
        .parameter-inputs { margin: 15px 0; }
        .param-group { margin-bottom: 15px; }
        .param-group label { display: block; margin-bottom: 5px; font-weight: 500; }
        .param-group input { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
        .param-group small { color: #666; font-size: 12px; }
        
        .warning-box { background: #fef3c7; border: 1px solid #f59e0b; color: #92400e; padding: 10px; border-radius: 4px; margin: 10px 0; }
        
        .response-area { background: #1f2937; color: #e5e7eb; padding: 15px; border-radius: 6px; font-family: 'Consolas', monospace; min-height: 200px; max-height: 400px; overflow-y: auto; white-space: pre-wrap; }
        
        .platform-selector { margin-bottom: 20px; }
        
        @media (max-width: 768px) {
            .main-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 TL1 Assistant</h1>
            <p>Web-based GUI for 1603 SM/SMX Network Elements</p>
            <div class="version-info">
                Version """ + version_str + """ • 
                Build """ + build_str + """ • 
                """ + date_str + """
            </div>
        </div>
        
        <div class="main-grid">
            <div class="sidebar">
                <!-- Connection Panel -->
                <div class="connection-panel">
                    <h3>Device Connection</h3>
                    <div id="connection-status" class="status disconnected">Disconnected</div>
                    
                    <div class="form-group">
                        <label for="host">Host/IP:</label>
                        <input type="text" id="host" placeholder="192.168.1.100">
                    </div>
                    
                    <div class="form-group">
                        <label for="port">Port:</label>
                        <input type="number" id="port" value="23">
                    </div>
                    
                    <button id="connect-btn" class="btn btn-primary">Connect</button>
                    <button id="disconnect-btn" class="btn btn-secondary" disabled>Disconnect</button>
                </div>
                
                <!-- Platform Selector -->
                <div class="platform-selector">
                    <div class="form-group">
                        <label for="platform">Platform:</label>
                        <select id="platform">
                            <option value="1603 SM">1603 SM</option>
                            <option value="1603 SMX">1603 SMX</option>
                        </select>
                    </div>
                </div>
                
                <!-- Command Tree -->
                <div class="command-tree" id="command-tree">
                    <p>Loading commands...</p>
                </div>
            </div>
            
            <div class="content">
                <!-- Command Builder -->
                <div class="command-builder">
                    <h3>Command Builder</h3>
                    
                    <div id="command-form">
                        <p>Select a command from the sidebar to configure parameters...</p>
                    </div>
                    
                    <div class="command-preview" id="command-preview">
                        Select a command to build...
                    </div>
                    
                    <button id="send-command-btn" class="btn btn-primary" disabled>Send Command</button>
                </div>
                
                <!-- Response Area -->
                <div>
                    <h3>Response</h3>
                    <div class="response-area" id="response-area">
Ready to send TL1 commands...
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Global state
        let selectedCommand = null;
        let commands = {};
        let categories = {};
        
        // Initialize the application
        document.addEventListener('DOMContentLoaded', function() {
            loadCommands();
            setupEventListeners();
            updateConnectionStatus();
        });
        
        function setupEventListeners() {
            document.getElementById('connect-btn').addEventListener('click', connectToDevice);
            document.getElementById('disconnect-btn').addEventListener('click', disconnectFromDevice);
            document.getElementById('send-command-btn').addEventListener('click', sendCommand);
            document.getElementById('platform').addEventListener('change', loadCommands);
            document.getElementById('tid').addEventListener('input', updateCommandPreview);
            document.getElementById('aid').addEventListener('input', updateCommandPreview);
            document.getElementById('ctag').addEventListener('input', updateCommandPreview);
        }
        
        async function loadCommands() {
            const platform = document.getElementById('platform').value;
            try {
                const response = await fetch(`/api/commands?platform=${encodeURIComponent(platform)}`);
                const commandList = await response.json();
                
                // Group commands by category
                categories = {};
                commandList.forEach(cmd => {
                    const category = cmd.category || 'Other';
                    if (!categories[category]) {
                        categories[category] = [];
                    }
                    categories[category].push(cmd);
                    commands[cmd.id] = cmd;
                });
                
                renderCommandTree();
            } catch (error) {
                console.error('Failed to load commands:', error);
                document.getElementById('command-tree').innerHTML = '<p>Error loading commands</p>';
            }
        }
        
        function renderCommandTree() {
            const tree = document.getElementById('command-tree');
            tree.innerHTML = '';
            
            Object.keys(categories).sort().forEach(category => {
                const categoryDiv = document.createElement('div');
                categoryDiv.className = 'tree-category';
                
                const categoryHeader = document.createElement('h4');
                categoryHeader.textContent = `${category} (${categories[category].length})`;
                categoryHeader.addEventListener('click', function() {
                    const commandsDiv = categoryDiv.querySelector('.tree-commands');
                    commandsDiv.style.display = commandsDiv.style.display === 'none' ? 'block' : 'none';
                });
                
                const commandsDiv = document.createElement('div');
                commandsDiv.className = 'tree-commands';
                commandsDiv.style.display = 'none'; // Start collapsed
                
                categories[category].forEach(cmd => {
                    const cmdDiv = document.createElement('div');
                    cmdDiv.className = 'tree-command';
                    cmdDiv.textContent = cmd.name;
                    cmdDiv.addEventListener('click', function() {
                        selectCommand(cmd);
                        // Remove previous selection
                        document.querySelectorAll('.tree-command.selected').forEach(el => {
                            el.classList.remove('selected');
                        });
                        cmdDiv.classList.add('selected');
                    });
                    
                    commandsDiv.appendChild(cmdDiv);
                });
                
                categoryDiv.appendChild(categoryHeader);
                categoryDiv.appendChild(commandsDiv);
                tree.appendChild(categoryDiv);
            });
        }
        
        function selectCommand(command) {
            selectedCommand = command;
            buildCommandForm();
            updateCommandPreview();
        }
        
        function buildCommandForm() {
            const formContainer = document.getElementById('command-form');
            if (!selectedCommand) {
                formContainer.innerHTML = '<p>Select a command to configure parameters...</p>';
                return;
            }
            
            let html = `<h3>${selectedCommand.displayName}</h3>`;
            html += `<p><strong>Description:</strong> ${selectedCommand.description}</p>`;
            html += `<p><strong>Syntax:</strong> <code>${selectedCommand.syntax}</code></p>`;
            
            if (selectedCommand.examples && selectedCommand.examples.length > 0) {
                html += `<p><strong>Example:</strong> <code>${selectedCommand.examples[0]}</code></p>`;
            }
            
            html += '<div class="parameter-inputs">';
            
            // Build parameter inputs based on schema
            if (selectedCommand.paramSchema) {
                Object.entries(selectedCommand.paramSchema).forEach(([param, schema]) => {
                    const isRequired = selectedCommand.requires && 
                        (selectedCommand.requires.includes(param) || 
                         selectedCommand.requires.includes(param.toLowerCase()) ||
                         selectedCommand.requires.includes(param.toUpperCase()));
                    const isOptional = selectedCommand.optional && 
                        (selectedCommand.optional.includes(param) ||
                         selectedCommand.optional.includes(param.toLowerCase()) ||
                         selectedCommand.optional.includes(param.toUpperCase()));
                    
                    html += `<div class="param-group">`;
                    html += `<label for="param-${param.toLowerCase()}">`;
                    html += `${param}${isRequired ? '*' : ''}`;
                    html += `</label>`;
                    html += `<input type="text" id="param-${param.toLowerCase()}" `;
                    html += `placeholder="${schema.description || param}"`;
                    if (schema.maxLength) {
                        html += ` maxlength="${schema.maxLength}"`;
                    }
                    if (isRequired) {
                        html += ` required`;
                    }
                    html += ` oninput="updateCommandPreview()">`;
                    html += `<small>${schema.description || ''}</small>`;
                    html += `</div>`;
                });
            }
            
            html += '</div>';
            
            // Safety and service impact warnings
            if (selectedCommand.safety_level === 'dangerous' || selectedCommand.service_affecting) {
                html += '<div class="warning-box">';
                html += '<strong>⚠️ Warning:</strong> ';
                if (selectedCommand.safety_level === 'dangerous') {
                    html += 'This command may affect system operation. ';
                }
                if (selectedCommand.service_affecting) {
                    html += 'This command may affect active services.';
                }
                html += '</div>';
            }
            
            formContainer.innerHTML = html;
        }
        
        function updateCommandPreview() {
            if (!selectedCommand) {
                document.getElementById('command-preview').textContent = 'Select a command to build...';
                return;
            }
            
            let command = selectedCommand.syntax || selectedCommand.id;
            
            // Debug: Log the original command
            console.log('Original command:', command);
            
            // Get parameter values from form inputs
            if (selectedCommand.paramSchema) {
                Object.keys(selectedCommand.paramSchema).forEach(param => {
                    const input = document.getElementById(`param-${param.toLowerCase()}`);
                    const value = input ? input.value.trim() : '';
                    
                    // Create pattern to match lowercase placeholder in syntax
                    const lowerParam = param.toLowerCase();
                    const placeholder = `[${lowerParam}]`;
                    
                    console.log(`Processing param: ${param} -> ${lowerParam}, placeholder: ${placeholder}, value: "${value}"`);
                    
                    if (value) {
                        // Use simple string replace instead of regex
                        command = command.replaceAll(placeholder, value);
                        console.log(`After replacing ${placeholder} with ${value}: ${command}`);
                    }
                });
            }
            
            console.log('Final command:', command);
            document.getElementById('command-preview').textContent = command;
        }
        
        async function connectToDevice() {
            const host = document.getElementById('host').value;
            const port = document.getElementById('port').value;
            
            if (!host) {
                alert('Please enter a host/IP address');
                return;
            }
            
            try {
                const response = await fetch('/api/connect', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ host: host, port: parseInt(port) })
                });
                
                const result = await response.json();
                
                if (result.status === 'connected') {
                    updateConnectionStatus(true, result.message);
                } else {
                    updateConnectionStatus(false, result.message);
                }
            } catch (error) {
                updateConnectionStatus(false, 'Connection failed: ' + error.message);
            }
        }
        
        async function disconnectFromDevice() {
            try {
                const response = await fetch('/api/disconnect', { method: 'POST' });
                const result = await response.json();
                updateConnectionStatus(false, result.message);
            } catch (error) {
                console.error('Disconnect failed:', error);
            }
        }
        
        async function sendCommand() {
            if (!selectedCommand) {
                alert('Please select a command first');
                return;
            }
            
            const command = document.getElementById('command-preview').textContent;
            
            try {
                const response = await fetch('/api/send_command', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ command: command })
                });
                
                const result = await response.json();
                displayResponse(result);
            } catch (error) {
                displayResponse({ 
                    status: 'error', 
                    message: 'Failed to send command: ' + error.message 
                });
            }
        }
        
        function updateConnectionStatus(connected = false, message = '') {
            const statusEl = document.getElementById('connection-status');
            const connectBtn = document.getElementById('connect-btn');
            const disconnectBtn = document.getElementById('disconnect-btn');
            const sendBtn = document.getElementById('send-command-btn');
            
            if (connected) {
                statusEl.className = 'status connected';
                statusEl.textContent = 'Connected: ' + message;
                connectBtn.disabled = true;
                disconnectBtn.disabled = false;
                sendBtn.disabled = false;
            } else {
                statusEl.className = 'status disconnected';
                statusEl.textContent = message || 'Disconnected';
                connectBtn.disabled = false;
                disconnectBtn.disabled = true;
                sendBtn.disabled = true;
            }
        }
        
        function displayResponse(result) {
            const responseArea = document.getElementById('response-area');
            const timestamp = new Date().toLocaleString();
            
            let output = `[${timestamp}] `;
            
            if (result.status === 'success') {
                output += `Command: ${result.command}\\n`;
                output += `Response:\\n${result.response}\\n\\n`;
            } else {
                output += `Error: ${result.message}\\n\\n`;
            }
            
            responseArea.textContent += output;
            responseArea.scrollTop = responseArea.scrollHeight;
        }
        
        // Auto-update connection status
        setInterval(async function() {
            try {
                const response = await fetch('/api/status');
                const status = await response.json();
                updateConnectionStatus(status.connected, status.connected ? `${status.host}:${status.port}` : '');
            } catch (error) {
                // Ignore status check errors
            }
        }, 5000);
    </script>
</body>
</html>"""

def create_handler(tl1_backend, commands_data):
    """Create a request handler with injected dependencies"""
    def handler(*args, **kwargs):
        return TL1WebHandler(*args, tl1_backend=tl1_backend, commands_data=commands_data, **kwargs)
    return handler

def load_commands_data():
    """Load TL1 commands from JSON file"""
    commands_file = Path(__file__).parent / "data" / "commands.json"
    
    if not commands_file.exists():
        print(f"⚠️  Commands file not found: {commands_file}")
        return {}
    
    try:
        with open(commands_file, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"❌ Error loading commands: {e}")
        return {}

def load_version_info():
    """Load version information from version.json"""
    version_file = Path(__file__).parent / "version.json"
    
    default_version = {
        "version": __version__,
        "build_date": __build_date__,
        "build_number": __build_number__,
        "release_name": "Initial Release"
    }
    
    if not version_file.exists():
        return default_version
    
    try:
        with open(version_file, 'r', encoding='utf-8') as f:
            version_data = json.load(f)
            # Merge with defaults to ensure all fields exist
            return {**default_version, **version_data}
    except Exception as e:
        print(f"⚠️  Error loading version info: {e}")
        return default_version

def find_free_port(start_port=8080):
    """Find a free port starting from start_port"""
    for port in range(start_port, start_port + 100):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('localhost', port))
                return port
        except OSError:
            continue
    return None

def main():
    """Main application entry point"""
    # Load and display version information
    version_info = load_version_info()
    print("🚀 Starting TL1 Assistant Web GUI...")
    print(f"   Version: {version_info.get('version', '1.0.0')}")
    print(f"   Build: {version_info.get('build_number', '001')} ({version_info.get('build_date', '2025-10-07')})")
    print("")
    
    # Load commands data
    commands_data = load_commands_data()
    if commands_data:
        total_commands = len(commands_data.get('commands', {}))
        print(f"✅ Loaded {total_commands} TL1 commands")
    else:
        print("⚠️  No commands loaded - GUI will work but command list will be empty")
    
    # Create TL1 backend
    tl1_backend = TL1Backend()
    
    # Find free port
    port = find_free_port(8080)
    if not port:
        print("❌ Could not find a free port")
        return
    
    # Create HTTP server
    handler = create_handler(tl1_backend, commands_data)
    server = HTTPServer(('localhost', port), handler)
    
    # Start server in background thread
    server_thread = threading.Thread(target=server.serve_forever, daemon=True)
    server_thread.start()
    
    url = f"http://localhost:{port}"
    print(f"✅ TL1 Assistant started successfully!")
    print(f"🌐 Web GUI: {url}")
    print(f"📋 Features:")
    print(f"   • Web-based interface (no admin rights needed)")
    print(f"   • Direct Telnet communication to TL1 devices")
    print(f"   • {total_commands if commands_data else 0} pre-loaded TL1 commands")
    print(f"   • Platform support: 1603 SM and 1603 SMX")
    print(f"")
    print(f"🔧 Usage:")
    print(f"   1. Browser will open automatically")
    print(f"   2. Enter device IP and port (default: 23)")
    print(f"   3. Connect to your TL1 device")
    print(f"   4. Select commands and send to device")
    print(f"")
    print(f"⏹️  Press Ctrl+C to stop the server")
    
    # Open browser automatically
    try:
        webbrowser.open(url)
    except:
        print(f"🌐 Please open your browser and go to: {url}")
    
    try:
        # Keep main thread alive
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print(f"\\n🛑 Shutting down TL1 Assistant...")
        server.shutdown()
        tl1_backend.disconnect()
        print(f"✅ Server stopped")

if __name__ == "__main__":
    main()