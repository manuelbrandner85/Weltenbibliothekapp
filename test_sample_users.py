#!/usr/bin/env python3
"""
TEST SCRIPT: Create Sample Users for Admin Dashboard Testing

This script creates sample users in both Materie and Energie worlds
to test the Admin Dashboard user list functionality.

WICHTIG: Dies ist nur ein TEST-SCRIPT für die Entwicklung.
In der Produktion werden User durch echte Registrierungen erstellt.
"""

import json

# Sample Users für MATERIE-Welt
materie_users = [
    {
        "userId": "materie_Weltenbibliothek",
        "username": "Weltenbibliothek",
        "role": "root_admin",
        "world": "materie",
        "createdAt": "2026-02-01T10:00:00Z",
        "lastActive": "2026-02-05T21:00:00Z"
    },
    {
        "userId": "materie_TestAdmin",
        "username": "TestAdmin",
        "role": "admin",
        "world": "materie",
        "createdAt": "2026-02-02T14:30:00Z",
        "lastActive": "2026-02-05T20:45:00Z"
    },
    {
        "userId": "materie_ForscherMax",
        "username": "ForscherMax",
        "role": "user",
        "world": "materie",
        "createdAt": "2026-02-03T09:15:00Z",
        "lastActive": "2026-02-05T19:30:00Z"
    },
    {
        "userId": "materie_WissenschaftlerAnna",
        "username": "WissenschaftlerAnna",
        "role": "user",
        "world": "materie",
        "createdAt": "2026-02-04T11:20:00Z",
        "lastActive": "2026-02-05T18:00:00Z"
    },
    {
        "userId": "materie_AnalystPeter",
        "username": "AnalystPeter",
        "role": "user",
        "world": "materie",
        "createdAt": "2026-02-05T08:45:00Z",
        "lastActive": "2026-02-05T17:15:00Z"
    }
]

# Sample Users für ENERGIE-Welt
energie_users = [
    {
        "userId": "energie_Weltenbibliothek",
        "username": "Weltenbibliothek",
        "role": "root_admin",
        "world": "energie",
        "createdAt": "2026-02-01T10:00:00Z",
        "lastActive": "2026-02-05T21:00:00Z"
    },
    {
        "userId": "energie_SpiritGuide",
        "username": "SpiritGuide",
        "role": "admin",
        "world": "energie",
        "createdAt": "2026-02-02T15:00:00Z",
        "lastActive": "2026-02-05T20:30:00Z"
    },
    {
        "userId": "energie_MysticLuna",
        "username": "MysticLuna",
        "role": "user",
        "world": "energie",
        "createdAt": "2026-02-03T10:30:00Z",
        "lastActive": "2026-02-05T19:00:00Z"
    },
    {
        "userId": "energie_ZenMaster",
        "username": "ZenMaster",
        "role": "user",
        "world": "energie",
        "createdAt": "2026-02-04T12:15:00Z",
        "lastActive": "2026-02-05T18:45:00Z"
    },
    {
        "userId": "energie_CrystalHealer",
        "username": "CrystalHealer",
        "role": "user",
        "world": "energie",
        "createdAt": "2026-02-05T09:30:00Z",
        "lastActive": "2026-02-05T17:00:00Z"
    }
]

def main():
    print("=" * 60)
    print("📊 SAMPLE USER DATA FOR ADMIN DASHBOARD TESTING")
    print("=" * 60)
    
    print("\n🔬 MATERIE-WELT USER:")
    print(json.dumps(materie_users, indent=2, ensure_ascii=False))
    
    print("\n" + "=" * 60)
    print("\n🔮 ENERGIE-WELT USER:")
    print(json.dumps(energie_users, indent=2, ensure_ascii=False))
    
    print("\n" + "=" * 60)
    print("\n✅ HINWEISE:")
    print("1. Diese Daten sind NUR für Testing/Development")
    print("2. In Produktion: User werden durch echte Registrierung erstellt")
    print("3. Backend-API muss diese User zurückgeben können")
    print("4. Cloudflare Worker: GET /api/admin/users/:world")
    print("   → sollte diese User-Liste zurückgeben")
    
    print("\n📝 BACKEND API RESPONSE FORMAT:")
    api_response = {
        "success": True,
        "world": "materie",
        "users": materie_users,
        "count": len(materie_users)
    }
    print(json.dumps(api_response, indent=2, ensure_ascii=False))
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    main()
