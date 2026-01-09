#!/usr/bin/env python3
"""
🧪 Simple Test HTTP Server for OChat Flutter App
================================================

This is a temporary test server to verify the Flutter app can connect to the backend
while we fix the Rust backend compilation issues.

Usage:
    python test_server.py
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import uuid
from datetime import datetime
from urllib.parse import urlparse, parse_qs
import re

class OChatTestHandler(BaseHTTPRequestHandler):
    """Simple HTTP request handler for testing OChat endpoints"""
    
    def do_GET(self):
        """Handle GET requests"""
        try:
            # Parse the URL
            parsed_url = urlparse(self.path)
            path = parsed_url.path
            
            # Set CORS headers
            self.send_cors_headers()
            
            # Route the request
            if path == '/api/v1/health':
                self.handle_health()
            elif path == '/api/v1/test':
                self.handle_test()
            elif re.match(r'/api/v1/test/conversations/[^/]+', path):
                self.handle_test_conversations(path)
            elif re.match(r'/api/v1/test/messages/[^/]+', path):
                self.handle_test_messages(path)
            else:
                self.send_error(404, "Endpoint not found")
                
        except Exception as e:
            print(f"Error handling GET request: {e}")
            self.send_error(500, f"Internal server error: {e}")
    
    def do_POST(self):
        """Handle POST requests"""
        try:
            # Parse the URL
            parsed_url = urlparse(self.path)
            path = parsed_url.path
            
            # Set CORS headers
            self.send_cors_headers()
            
            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode('utf-8')
            data = json.loads(body) if body else {}
            
            # Route the request
            if path == '/api/v1/test/send':
                self.handle_test_send_message(data)
            else:
                self.send_error(404, "Endpoint not found")
                
        except Exception as e:
            print(f"Error handling POST request: {e}")
            self.send_error(500, f"Internal server error: {e}")
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_cors_headers()
        self.send_response(200)
        self.end_headers()
    
    def send_cors_headers(self):
        """Send CORS headers for cross-origin requests"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Content-Type', 'application/json')
    
    def handle_health(self):
        """Handle health check endpoint"""
        response = {
            "status": "healthy",
            "service": "ochat-test-server",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        self.send_response(200)
        self.send_cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(response).encode())
    
    def handle_test(self):
        """Handle test endpoint"""
        response = {
            "message": "Test endpoint working!",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        self.send_response(200)
        self.send_cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(response).encode())
    
    def handle_test_conversations(self, path):
        """Handle test conversations endpoint"""
        # Extract user ID from path
        user_id = path.split('/')[-1]
        
        response = {
            "conversations": [
                {
                    "id": str(uuid.uuid4()),
                    "name": "Test Conversation",
                    "participants": [user_id],
                    "last_message": {
                        "text": "Hello!",
                        "timestamp": datetime.utcnow().isoformat() + "Z"
                    },
                    "unread_count": 0
                }
            ]
        }
        self.send_response(200)
        self.send_cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(response).encode())
    
    def handle_test_messages(self, path):
        """Handle test messages endpoint"""
        # Extract conversation ID from path
        conversation_id = path.split('/')[-1]
        
        response = {
            "messages": [
                {
                    "id": str(uuid.uuid4()),
                    "conversation_id": conversation_id,
                    "sender_id": "user1",
                    "text": "Hello! This is a test message.",
                    "timestamp": datetime.utcnow().isoformat() + "Z",
                    "status": "read"
                }
            ]
        }
        self.send_response(200)
        self.send_cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(response).encode())
    
    def handle_test_send_message(self, data):
        """Handle test send message endpoint"""
        response = {
            "message": {
                "id": str(uuid.uuid4()),
                "conversation_id": data.get("conversation_id", "unknown"),
                "sender_id": data.get("sender_id", "user1"),
                "text": data.get("text", ""),
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "status": "sent"
            },
            "status": "success"
        }
        self.send_response(200)
        self.send_cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(response).encode())
    
    def log_message(self, format, *args):
        """Custom logging to avoid the default log format"""
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {format % args}")

def run_server(port=8080):
    """Run the test HTTP server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, OChatTestHandler)
    print(f"🧪 OChat Test Server running on http://localhost:{port}")
    print(f"📡 Available endpoints:")
    print(f"   GET  /api/v1/health")
    print(f"   GET  /api/v1/test")
    print(f"   GET  /api/v1/test/conversations/{{userId}}")
    print(f"   GET  /api/v1/test/messages/{{conversationId}}")
    print(f"   POST /api/v1/test/send")
    print(f"🔄 Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
        httpd.server_close()

if __name__ == '__main__':
    run_server() 