#!/usr/bin/env python3
"""
🔧 RECHERCHE INTEGRATION PATCH SCRIPT

Automatically inserts the new production-ready widgets into recherche_tab_mobile.dart

Usage:
    python3 apply_recherche_patch.py

Requirements:
    - File exists: lib/screens/materie/recherche_tab_mobile.dart
    - Imports already added (lines 22-40)
    - State variables already added (lines 61-62)
"""

import os
import sys

# Patch to insert
WIDGET_PATCH = '''
          // 🆕 NEW PRODUCTION-READY WIDGETS
          if (_productionResult != null) ...[
            const SizedBox(height: 32),
            const Divider(color: Colors.white24, thickness: 2),
            const SizedBox(height: 32),
            
            _buildSectionHeader('🎯 PRODUCTION-READY ANALYSE'),
            const SizedBox(height: 16),
            
            // Result Summary Card
            ResultSummaryCard(result: _productionResult!),
            
            const SizedBox(height: 24),
            
            // Facts List
            if (_productionResult!.facts.isNotEmpty) ...[
              _buildSectionHeader('📌 FAKTEN'),
              const SizedBox(height: 8),
              FactsList(facts: _productionResult!.facts),
              const SizedBox(height: 24),
            ],
            
            // Sources List
            if (_productionResult!.sources.isNotEmpty) ...[
              _buildSectionHeader('📚 QUELLEN'),
              const SizedBox(height: 8),
              SourcesList(sources: _productionResult!.sources),
              const SizedBox(height: 24),
            ],
            
            // Perspectives View
            if (_productionResult!.perspectives.isNotEmpty) ...[
              _buildSectionHeader('👁️ PERSPEKTIVEN'),
              const SizedBox(height: 8),
              PerspectivesView(perspectives: _productionResult!.perspectives),
              const SizedBox(height: 24),
            ],
            
            // Rabbit Hole View
            if (_productionResult!.rabbitLayers.isNotEmpty) ...[
              _buildSectionHeader('🕳️ RABBIT HOLE'),
              const SizedBox(height: 8),
              RabbitHoleView(layers: _productionResult!.rabbitLayers),
              const SizedBox(height: 24),
            ],
          ],
'''

def apply_patch():
    """Apply the widget patch to recherche_tab_mobile.dart"""
    
    file_path = 'lib/screens/materie/recherche_tab_mobile.dart'
    
    # Check if file exists
    if not os.path.exists(file_path):
        print(f'❌ ERROR: File not found: {file_path}')
        print('   Make sure you are in the flutter_app directory')
        return False
    
    print(f'📖 Reading {file_path}...')
    
    # Read file
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    print(f'   → Total lines: {len(lines)}')
    
    # Find insertion point (after KI-generiert disclaimer, before closing ])
    # Search pattern: line with "style: const TextStyle(color: Colors.orange, fontSize: 12),"
    # followed by closing Container, then closing if block
    
    insertion_line = None
    for i in range(len(lines) - 10):
        # Look for the KI disclaimer block
        if "style: const TextStyle(color: Colors.orange, fontSize: 12)," in lines[i]:
            # Check next few lines for closing brackets
            for j in range(i+1, min(i+10, len(lines))):
                if lines[j].strip() == '],':
                    # This should be the closing of the if (_analyse!.istKiGeneriert) block
                    insertion_line = j
                    break
            if insertion_line:
                break
    
    if not insertion_line:
        print('❌ ERROR: Could not find insertion point')
        print('   Looking for: if (_analyse!.istKiGeneriert) block')
        return False
    
    print(f'✅ Found insertion point at line {insertion_line + 1}')
    
    # Check if patch already applied
    for i in range(max(0, insertion_line - 50), min(len(lines), insertion_line + 50)):
        if 'PRODUCTION-READY ANALYSE' in lines[i]:
            print('⚠️  WARNING: Patch already applied!')
            print('   Skipping...')
            return True
    
    # Insert patch after the found line
    new_lines = lines[:insertion_line + 1] + [WIDGET_PATCH] + lines[insertion_line + 1:]
    
    # Create backup
    backup_path = file_path + '.pre_patch_backup'
    print(f'💾 Creating backup: {backup_path}')
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    
    # Write patched file
    print(f'✍️  Writing patched file...')
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    print(f'✅ PATCH APPLIED SUCCESSFULLY!')
    print(f'   → New total lines: {len(new_lines)}')
    print(f'   → Added lines: {len(new_lines) - len(lines)}')
    print(f'')
    print(f'🧪 NEXT STEPS:')
    print(f'   1. Run: flutter analyze lib/screens/materie/recherche_tab_mobile.dart')
    print(f'   2. If errors: restore backup with:')
    print(f'      mv {backup_path} {file_path}')
    print(f'   3. Restart Flutter app to see changes')
    
    return True

if __name__ == '__main__':
    print('🔧 RECHERCHE INTEGRATION PATCH SCRIPT')
    print('=' * 60)
    print('')
    
    # Check if in correct directory
    if not os.path.exists('lib'):
        print('❌ ERROR: Not in Flutter project directory')
        print('   Please run this script from /home/user/flutter_app')
        sys.exit(1)
    
    success = apply_patch()
    
    print('')
    print('=' * 60)
    
    if success:
        print('✅ PATCH COMPLETED')
        sys.exit(0)
    else:
        print('❌ PATCH FAILED')
        sys.exit(1)
