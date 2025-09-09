#!/usr/bin/env python3
import re
import json
import os
import sys
from pathlib import Path

def sanitize_content(content):
    """Remove PII and sensitive data from content"""
    redactions = []
    
    # Email addresses
    email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    emails_found = re.findall(email_pattern, content)
    content = re.sub(email_pattern, '[EMAIL_REDACTED]', content)
    if emails_found:
        redactions.append({"type": "email", "count": len(emails_found)})
    
    # Phone numbers
    phone_pattern = r'\b(?:\+?1[-.]?)?\(?[0-9]{3}\)?[-.]?[0-9]{3}[-.]?[0-9]{4}\b'
    phones_found = re.findall(phone_pattern, content)
    content = re.sub(phone_pattern, '[PHONE_REDACTED]', content)
    if phones_found:
        redactions.append({"type": "phone", "count": len(phones_found)})
    
    # IP addresses
    ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
    ips_found = re.findall(ip_pattern, content)
    # Don't redact localhost and common private IPs
    for ip in ips_found:
        if not ip.startswith(('127.', '192.168.', '10.', '172.')):
            content = content.replace(ip, '[IP_REDACTED]')
            redactions.append({"type": "ip_address", "count": 1})
    
    # API keys and tokens (generic patterns)
    api_key_patterns = [
        r'[aA][pP][iI][-_]?[kK][eE][yY]\s*[:=]\s*["\']?([A-Za-z0-9+/=_-]{20,})["\']?',
        r'[tT][oO][kK][eE][nN]\s*[:=]\s*["\']?([A-Za-z0-9+/=_-]{20,})["\']?',
        r'[sS][eE][cC][rR][eE][tT]\s*[:=]\s*["\']?([A-Za-z0-9+/=_-]{20,})["\']?'
    ]
    
    for pattern in api_key_patterns:
        keys_found = re.findall(pattern, content)
        content = re.sub(pattern, '[SECRET_REDACTED]', content)
        if keys_found:
            redactions.append({"type": "api_key", "count": len(keys_found)})
    
    return content, redactions

def process_directory(input_dir, output_dir):
    """Process all log files in a directory"""
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    all_redactions = {}
    
    for file_path in input_path.glob('*.log'):
        print(f"Processing {file_path.name}...")
        
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            sanitized_content, redactions = sanitize_content(content)
            
            # Save sanitized version
            output_file = output_path / f"sanitized_{file_path.name}"
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(sanitized_content)
            
            if redactions:
                all_redactions[file_path.name] = redactions
                
        except Exception as e:
            print(f"Error processing {file_path.name}: {e}")
    
    return all_redactions

if __name__ == "__main__":
    output_root = os.environ.get('OUTPUT_ROOT', '.')
    logs_dir = os.path.join(output_root, 'logs')
    sanitized_dir = os.path.join(output_root, 'sanitized')
    
    print(f"Sanitizing logs from {logs_dir} to {sanitized_dir}")
    redactions = process_directory(logs_dir, sanitized_dir)
    
    # Save redaction report
    report_path = os.path.join(output_root, 'reports', 'pii_redactions.json')
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    
    with open(report_path, 'w') as f:
        json.dump({
            "sanitization_timestamp": "2025-09-09T12:32:00Z",
            "files_processed": len(redactions),
            "redactions": redactions,
            "status": "completed"
        }, f, indent=2)
    
    print(f"Sanitization complete. Report saved to {report_path}")
