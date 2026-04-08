#!/usr/bin/env python3
"""
Simple Nessie Health Check
A minimal script to verify Nessie connectivity without complex API calls.
"""

import requests
import json

# Configuration  
NESSIE_URL = "http://localhost:19120/api/v1"

def main():
    print("🔍 Simple Nessie Health Check")
    print("=" * 40)
    
    try:
        # Test basic connectivity
        print("🏥 Checking Nessie health...")
        config_url = f"{NESSIE_URL}/config"
        response = requests.get(config_url, timeout=10)
        
        if response.status_code == 200:
            print("✅ Nessie API is responding")
            config = response.json()
            print(f"📋 Nessie version: {config.get('maxSupportedApiVersion', 'Unknown')}")
        else:
            print(f"❌ Nessie API error: {response.status_code}")
            return False
            
        # List references (branches/tags)
        print("\n📁 Checking references...")
        refs_url = f"{NESSIE_URL}/trees"
        response = requests.get(refs_url, timeout=10)
        
        if response.status_code == 200:
            refs = response.json()
            print(f"✅ Found {len(refs)} references:")
            for ref in refs:
                print(f"   - {ref.get('name')} ({ref.get('type')})")
        else:
            print(f"⚠️ Could not list references: {response.status_code}")
            
        # Check if main branch exists
        print("\n🌟 Checking main branch...")
        main_url = f"{NESSIE_URL}/trees/branch/main"
        response = requests.get(main_url, timeout=10)
        
        if response.status_code == 200:
            branch = response.json()
            print(f"✅ Main branch exists")
            print(f"   Hash: {branch.get('hash', 'Unknown')[:8]}...")
        else:
            print("ℹ️ Main branch not found (fresh installation)")
            
        # Try to list entries on main branch
        print("\n📋 Checking catalog entries...")
        entries_url = f"{NESSIE_URL}/trees/branch/main/entries"
        response = requests.get(entries_url, timeout=10)
        
        if response.status_code == 200:
            entries_data = response.json()
            entries = entries_data.get('entries', [])
            print(f"✅ Found {len(entries)} catalog entries")
            for entry in entries[:5]:  # Show first 5
                name_parts = entry.get('name', {}).get('elements', ['Unknown'])
                table_name = '.'.join(name_parts)
                print(f"   - {table_name}")
            if len(entries) > 5:
                print(f"   ... and {len(entries) - 5} more")
        else:
            print("ℹ️ No catalog entries found (empty catalog)")
            
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to Nessie")
        print("💡 Make sure Nessie is running:")
        print("   cd infrastructure/compose")
        print("   docker-compose up -d nessie")
        return False
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False
        
    print("\n" + "=" * 40)
    print("🎉 Nessie health check complete!")
    print(f"📍 API Endpoint: {NESSIE_URL}")
    print("🗄️ MinIO Console: http://localhost:9001")
    return True

if __name__ == "__main__":
    main()