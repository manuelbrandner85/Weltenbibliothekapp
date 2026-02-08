#!/usr/bin/env python3
"""
Test echte Genspark API
"""

import asyncio
from api_client import GensparkAPIClient

async def test_websearch():
    """Teste WebSearch API"""
    print("=" * 60)
    print("TEST: WebSearch API")
    print("=" * 60)
    
    try:
        async with GensparkAPIClient() as client:
            results = await client.websearch(
                query="Ukraine Krieg",
                allowed_domains=["reuters.com", "spiegel.de"],
                max_results=3,
            )
            
            print(f"\n✅ SUCCESS: {len(results)} Ergebnisse")
            for i, result in enumerate(results, 1):
                print(f"\n{i}. {result.get('title')}")
                print(f"   URL: {result.get('url')}")
                print(f"   Snippet: {result.get('snippet', '')[:100]}...")
            
            return results
            
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return None

async def test_crawler(url: str):
    """Teste Crawler API"""
    print("\n" + "=" * 60)
    print("TEST: Crawler API")
    print("=" * 60)
    
    try:
        async with GensparkAPIClient() as client:
            result = await client.crawl(url=url)
            
            print(f"\n✅ SUCCESS:")
            print(f"   Title: {result.get('title')}")
            print(f"   Text Length: {len(result.get('text', ''))} chars")
            print(f"   Text Preview: {result.get('text', '')[:200]}...")
            
            return result
            
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return None

async def main():
    """Hauptfunktion"""
    
    # Test 1: WebSearch
    search_results = await test_websearch()
    
    # Test 2: Crawler (erste URL aus WebSearch)
    if search_results and len(search_results) > 0:
        first_url = search_results[0].get('url')
        await test_crawler(first_url)
    
    print("\n" + "=" * 60)
    print("TESTS ABGESCHLOSSEN")
    print("=" * 60)

if __name__ == '__main__':
    asyncio.run(main())
