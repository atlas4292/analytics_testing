#!/usr/bin/env python3
"""
Nessie Client Example
This script demonstrates how to interact with Nessie catalog using Python.
"""

import requests
try:
    from pynessie import init
except ImportError:
    print("❌ pynessie not installed. Install with: pip install pynessie")
    exit(1)
    
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from pathlib import Path
import os

# Nessie configuration
NESSIE_URL = "http://localhost:19120/api/v1"
MINIO_ENDPOINT = "http://localhost:9000" 
MINIO_ACCESS_KEY = "minioadmin"
MINIO_SECRET_KEY = "minioadmin123"

def initialize_nessie_client():
    """Initialize Nessie catalog client."""
    try:
        # Initialize Nessie client - correct API
        nessie = init(
            NESSIE_URL
            # No auth_type parameter needed for unauthenticated access
        )
        print(f"✅ Connected to Nessie at {NESSIE_URL}")
        return nessie
    except Exception as e:
        print(f"❌ Failed to connect to Nessie: {e}")
        print("💡 Tip: Make sure Nessie is running with: docker-compose up -d nessie")
        return None

def list_branches(nessie):
    """List all branches in Nessie catalog."""
    try:
        refs_response = nessie.list_references()
        print("\n📁 Available references:")
        for ref in refs_response.references:
            print(f"  - {ref.name} ({type(ref).__name__})")
        return refs_response.references
    except Exception as e:
        print(f"❌ Failed to list references: {e}")
        return []

def create_sample_table():
    """Create a sample table for demonstration."""
    # Create sample data
    data = {
        'id': [1, 2, 3, 4, 5],
        'name': ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve'],
        'age': [25, 30, 35, 28, 32],
        'city': ['New York', 'San Francisco', 'Chicago', 'Seattle', 'Boston']
    }
    
    df = pd.DataFrame(data)
    table = pa.Table.from_pandas(df)
    
    print(f"📊 Created sample table with {len(df)} rows")
    return table

def demonstrate_nessie_features():
    """Demonstrate key Nessie features."""
    print("🔍 Nessie Data Catalog Demo")
    print("=" * 50)
    
    # Initialize client
    nessie = initialize_nessie_client()
    if not nessie:
        return
    
    # List existing branches
    branches = list_branches(nessie)
    
    # Get current branch info
    try:
        main_branch = nessie.get_reference("main")
        print(f"\n🌟 Current main branch hash: {main_branch.hash_}")
    except Exception as e:
        print(f"ℹ️ Main branch not found, this might be a fresh installation: {e}")
    
    # List catalog entries (tables/views) on main branch
    try:
        entries = nessie.list_keys("main")
        if entries.entries:
            print(f"\n📋 Found {len(entries.entries)} tables/objects in catalog:")
            for entry in entries.entries:
                name = getattr(entry, 'name', 'Unknown')
                entry_type = getattr(entry, 'type', 'Unknown')
                print(f"  - {name} ({entry_type})")
        else:
            print("\n📋 No tables found in catalog (empty or new installation)")
    except Exception as e:
        print(f"ℹ️ Could not list entries: {e}")
        print("   This is normal for a fresh Nessie installation")
    
    print("\n" + "=" * 50)
    print("✨ Nessie setup is working!")
    print(f"📍 Access Nessie API at: {NESSIE_URL}")
    print(f"🗄️ MinIO Console at: http://localhost:9001")
    print(f"📦 Nessie metadata bucket: nessie-catalog")

def check_nessie_health():
    """Check if Nessie API is accessible."""
    try:
        response = requests.get(f"{NESSIE_URL.replace('/api/v1', '')}/api/v1/config", timeout=5)
        if response.status_code == 200:
            print("✅ Nessie API is accessible")
            return True
        else:
            print(f"⚠️ Nessie API returned status: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Cannot reach Nessie API: {e}")
        print("💡 Make sure Nessie is running: docker-compose up -d nessie")
        return False

def demonstrate_with_rest_api():
    """Alternative demo using direct REST API calls."""
    print("🔄 Using direct REST API (fallback method)")
    print("=" * 50)
    
    try:
        # List references using REST API
        response = requests.get(f"{NESSIE_URL}/trees")
        if response.status_code == 200:
            refs = response.json()
            print(f"\n📁 Found {len(refs)} references:")
            for ref in refs:
                print(f"  - {ref.get('name', 'Unknown')} ({ref.get('type', 'Unknown')})")
        else:
            print(f"❌ Failed to list references: {response.status_code}")
            
        # Try to get main branch info
        response = requests.get(f"{NESSIE_URL}/trees/branch/main")
        if response.status_code == 200:
            branch_info = response.json()
            print(f"\n🌟 Main branch hash: {branch_info.get('hash', 'Unknown')}")
        else:
            print("\nℹ️ Main branch not found (fresh installation)")
            
        # Try to list entries
        response = requests.get(f"{NESSIE_URL}/trees/branch/main/entries")
        if response.status_code == 200:
            entries = response.json()
            entry_list = entries.get('entries', [])
            print(f"\n📋 Found {len(entry_list)} entries in catalog:")
            for entry in entry_list:
                name = entry.get('name', {}).get('elements', ['Unknown'])
                print(f"  - {'.'.join(name)}")
        else:
            print("\nℹ️ No entries found or branch doesn't exist yet")
            
    except Exception as e:
        print(f"❌ REST API demo failed: {e}")
        
    print("\n" + "=" * 50)
    print("✨ Nessie REST API working!")

if __name__ == "__main__":
    try:
        # Check if Nessie is running first
        if not check_nessie_health():
            exit(1)
            
        # Try pynessie first, fallback to REST API
        try:
            demonstrate_nessie_features()
        except Exception as e:
            print(f"\n⚠️ pynessie demo failed: {e}")
            print("🔄 Trying with direct REST API...")
            demonstrate_with_rest_api()
            
    except KeyboardInterrupt:
        print("\n👋 Demo interrupted by user")
    except Exception as e:
        print(f"❌ Demo failed: {e}")