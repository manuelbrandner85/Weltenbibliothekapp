#!/usr/bin/env python3
"""
🧹 Cloudflare Database Cleanup Script
Removes all demo/test data and cleans up after livestreams
"""
import requests
import json
import sys

# Cloudflare Worker Endpoints
WORKER_BASE_URL = "https://weltenbibliothek-backend.your-subdomain.workers.dev"

def cleanup_demo_data():
    """Entferne alle Demo/Test-Daten"""
    print("🧹 Starte Demo-Daten Cleanup...")
    
    # Demo Users löschen
    demo_users = ['demo_user', 'test_user', 'guest', 'testuser']
    for username in demo_users:
        try:
            response = requests.delete(f"{WORKER_BASE_URL}/api/users/{username}")
            if response.status_code == 200:
                print(f"✅ Demo User gelöscht: {username}")
        except Exception as e:
            print(f"⚠️ Fehler bei {username}: {e}")
    
    # Test Chat-Räume löschen
    test_rooms = ['test_room', 'demo_room']
    for room_id in test_rooms:
        try:
            response = requests.delete(f"{WORKER_BASE_URL}/api/chat/rooms/{room_id}")
            if response.status_code == 200:
                print(f"✅ Test Raum gelöscht: {room_id}")
        except Exception as e:
            print(f"⚠️ Fehler bei {room_id}: {e}")
    
    print("✅ Demo-Daten Cleanup abgeschlossen")

def cleanup_ended_livestreams():
    """Bereinige beendete Livestreams"""
    print("🎥 Bereinige beendete Livestreams...")
    
    try:
        # Hole alle Live-Rooms
        response = requests.get(f"{WORKER_BASE_URL}/api/live/rooms")
        if response.status_code == 200:
            rooms = response.json()
            
            for room in rooms:
                if not room.get('is_live', False):
                    room_id = room['room_id']
                    
                    # Lösche beendeten Livestream
                    delete_response = requests.delete(
                        f"{WORKER_BASE_URL}/api/live/rooms/{room_id}"
                    )
                    
                    if delete_response.status_code == 200:
                        print(f"✅ Livestream gelöscht: {room_id}")
                    
    except Exception as e:
        print(f"❌ Fehler beim Livestream-Cleanup: {e}")
    
    print("✅ Livestream Cleanup abgeschlossen")

def cleanup_old_messages(days=7):
    """Lösche alte Nachrichten älter als X Tage"""
    print(f"💬 Lösche Nachrichten älter als {days} Tage...")
    
    try:
        response = requests.delete(
            f"{WORKER_BASE_URL}/api/chat/messages/cleanup",
            json={'days': days}
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ {result.get('deleted', 0)} alte Nachrichten gelöscht")
    except Exception as e:
        print(f"❌ Fehler beim Nachrichten-Cleanup: {e}")

def cleanup_orphaned_data():
    """Entferne verwaiste Daten (Nachrichten ohne Raum, etc.)"""
    print("🗑️ Entferne verwaiste Daten...")
    
    try:
        response = requests.post(f"{WORKER_BASE_URL}/api/cleanup/orphaned")
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Verwaiste Daten bereinigt: {result}")
    except Exception as e:
        print(f"❌ Fehler: {e}")

def main():
    print("=" * 50)
    print("🧹 Cloudflare Database Cleanup")
    print("=" * 50)
    
    # Cleanup-Operationen
    cleanup_demo_data()
    print()
    
    cleanup_ended_livestreams()
    print()
    
    cleanup_old_messages(days=7)
    print()
    
    cleanup_orphaned_data()
    print()
    
    print("=" * 50)
    print("✅ Cleanup abgeschlossen!")
    print("=" * 50)

if __name__ == "__main__":
    main()
