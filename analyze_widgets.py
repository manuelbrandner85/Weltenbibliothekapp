#!/usr/bin/env python3
"""Analyze Flutter widgets for performance optimization opportunities."""

import re
import os
from pathlib import Path
from collections import defaultdict

def analyze_widget_file(file_path):
    """Analyze a single Dart file for widget optimization opportunities."""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    issues = []
    
    # 1. Check for missing const constructors
    # Look for widgets without const but could have it
    widget_declarations = re.finditer(
        r'class\s+(\w+)\s+extends\s+(StatelessWidget|StatefulWidget)',
        content
    )
    
    for match in widget_declarations:
        widget_name = match.group(1)
        # Check if constructor is missing const
        constructor_pattern = rf'const\s+{widget_name}\('
        if not re.search(constructor_pattern, content):
            issues.append({
                'type': 'missing_const',
                'widget': widget_name,
                'severity': 'medium'
            })
    
    # 2. Check for setState() calls in StatefulWidget
    setstate_calls = len(re.findall(r'setState\s*\(', content))
    if setstate_calls > 10:
        issues.append({
            'type': 'excessive_setstate',
            'count': setstate_calls,
            'severity': 'high'
        })
    
    # 3. Check for ListView without .builder
    listview_without_builder = re.findall(
        r'ListView\s*\(',
        content
    )
    if listview_without_builder:
        # Filter out ListView.builder cases
        builder_count = len(re.findall(r'ListView\.builder', content))
        regular_count = len(listview_without_builder) - builder_count
        
        if regular_count > 0:
            issues.append({
                'type': 'listview_not_lazy',
                'count': regular_count,
                'severity': 'high'
            })
    
    # 4. Check for missing keys in lists
    list_builder_pattern = r'(ListView|GridView)\.builder'
    has_list_builder = re.search(list_builder_pattern, content)
    
    if has_list_builder:
        # Check if itemBuilder uses keys
        has_key_usage = re.search(r'key:\s*\w+', content)
        if not has_key_usage:
            issues.append({
                'type': 'missing_list_keys',
                'severity': 'medium'
            })
    
    # 5. Check for Image.network without caching
    image_network = re.findall(r'Image\.network\s*\(', content)
    if image_network:
        has_cache_config = re.search(r'cacheWidth|cacheHeight', content)
        if not has_cache_config:
            issues.append({
                'type': 'image_no_cache_config',
                'count': len(image_network),
                'severity': 'medium'
            })
    
    # 6. Check for heavy computations in build()
    if 'build(BuildContext' in content:
        # Look for sorting, filtering, mapping in build
        heavy_ops = re.findall(
            r'\.sort\(|\.where\(|\.map\(|\.toList\(|\.reduce\(',
            content
        )
        if len(heavy_ops) > 5:
            issues.append({
                'type': 'heavy_build_computation',
                'count': len(heavy_ops),
                'severity': 'high'
            })
    
    return issues


def main():
    """Main analysis function."""
    
    lib_path = Path('lib')
    all_issues = defaultdict(list)
    
    # Find all Dart files
    dart_files = list(lib_path.rglob('*.dart'))
    
    print(f"🔍 Analyzing {len(dart_files)} Dart files...\n")
    
    for dart_file in dart_files:
        issues = analyze_widget_file(dart_file)
        
        if issues:
            rel_path = str(dart_file.relative_to(lib_path))
            all_issues[rel_path] = issues
    
    # Categorize and count issues
    issue_counts = defaultdict(int)
    high_priority_files = []
    
    for file_path, issues in all_issues.items():
        high_severity = any(issue['severity'] == 'high' for issue in issues)
        if high_severity:
            high_priority_files.append(file_path)
        
        for issue in issues:
            issue_counts[issue['type']] += 1
    
    # Print summary
    print("=" * 70)
    print("📊 PERFORMANCE OPTIMIZATION OPPORTUNITIES")
    print("=" * 70)
    print()
    
    print("🎯 ISSUE SUMMARY:")
    for issue_type, count in sorted(issue_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"  • {issue_type}: {count} occurrences")
    print()
    
    print(f"🔥 HIGH PRIORITY FILES: {len(high_priority_files)}")
    print()
    
    # Show top 10 high priority files
    print("📁 TOP HIGH PRIORITY FILES:")
    for i, file_path in enumerate(high_priority_files[:10], 1):
        issues = all_issues[file_path]
        high_issues = [i for i in issues if i['severity'] == 'high']
        print(f"  {i}. {file_path}")
        for issue in high_issues[:3]:  # Show first 3 high issues
            issue_desc = issue['type']
            if 'count' in issue:
                issue_desc += f" ({issue['count']}x)"
            print(f"     - {issue_desc}")
    print()
    
    # Recommendations
    print("💡 OPTIMIZATION STRATEGY:")
    print("  1. Fix high-severity issues first (setState, ListView, heavy computations)")
    print("  2. Add const constructors where possible")
    print("  3. Implement image caching configuration")
    print("  4. Add keys to list items for better reconciliation")
    print("  5. Move heavy computations outside build() methods")
    print()
    
    print(f"📈 TOTAL FILES WITH ISSUES: {len(all_issues)}/{len(dart_files)}")
    print(f"🎯 ESTIMATED OPTIMIZATION TIME: {len(high_priority_files) * 0.5:.1f}h")

if __name__ == '__main__':
    main()
