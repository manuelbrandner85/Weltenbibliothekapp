import 'package:flutter/material.dart';
import '../services/complete_content_repository.dart';

/// 🎨 DYNAMIC SCREEN RENDERER
/// Rendert KOMPLETTE Screens aus JSON-Definition
/// KEINE hardcoded UI-Elemente
/// 
/// Unterstützt:
/// - Dynamic AppBar
/// - Dynamic Tabs
/// - Dynamic Buttons
/// - Dynamic Text
/// - Dynamic Input Fields
/// - Dynamic Empty States
/// - Dynamic Tools/Features
class DynamicScreenRenderer extends StatefulWidget {
  final String worldId;
  final String screenId;
  
  const DynamicScreenRenderer({
    super.key,
    required this.worldId,
    required this.screenId,
  });

  @override
  State<DynamicScreenRenderer> createState() => _DynamicScreenRendererState();
}

class _DynamicScreenRendererState extends State<DynamicScreenRenderer> {
  final _repository = CompleteContentRepository.instance;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to content updates
    _repository.addListener(_onContentUpdate);
  }
  
  @override
  void dispose() {
    _repository.removeListener(_onContentUpdate);
    super.dispose();
  }
  
  void _onContentUpdate() {
    if (mounted) {
      setState(() {
        // Rebuild UI with new content
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load screen config from repository
    final screenConfig = _repository.getScreen(widget.worldId, widget.screenId);
    
    if (screenConfig == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Screen nicht gefunden')),
        body: const Center(child: Text('Screen-Konfiguration fehlt')),
      );
    }
    
    return Scaffold(
      appBar: _buildAppBar(screenConfig),
      body: _buildBody(screenConfig),
    );
  }

  /// Build Dynamic AppBar from config
  PreferredSizeWidget _buildAppBar(Map<String, dynamic> screenConfig) {
    final appBarConfig = screenConfig['appbar'];
    
    if (appBarConfig == null) {
      return AppBar(title: const Text('Untitled'));
    }
    
    return AppBar(
      backgroundColor: _getColorFromConfig(_repository.theme?['card_color']),
      automaticallyImplyLeading: appBarConfig['show_back_button'] ?? true,
      title: Text(
        appBarConfig['title'] ?? 'Untitled',
        style: _getTextStyle(_repository.typography?['heading2']),
      ),
      actions: _buildAppBarActions(appBarConfig['actions']),
    );
  }

  /// Build Dynamic AppBar Actions
  List<Widget>? _buildAppBarActions(List<dynamic>? actionsConfig) {
    if (actionsConfig == null || actionsConfig.isEmpty) return null;
    
    final actions = <Widget>[];
    
    for (final actionConfig in actionsConfig) {
      final action = _buildAction(actionConfig);
      if (action != null) {
        actions.add(action);
      }
    }
    
    return actions.isNotEmpty ? actions : null;
  }

  /// Build single action button
  Widget? _buildAction(Map<String, dynamic> config) {
    final type = config['type'];
    final icon = config['icon'];
    final tooltip = config['tooltip'];
    final action = config['action'];
    final visibleFor = config['visible_for'];
    
    // Check visibility
    if (visibleFor != null && visibleFor is List) {
      // TODO: Check user role
      // For now, show all actions
    }
    
    if (type == 'icon_button') {
      return IconButton(
        icon: Icon(_getIcon(icon)),
        tooltip: tooltip,
        onPressed: () => _executeAction(action),
      );
    }
    
    return null;
  }

  /// Build Dynamic Body
  Widget _buildBody(Map<String, dynamic> screenConfig) {
    final screenType = screenConfig['type'];
    
    switch (screenType) {
      case 'chat':
        return _buildChatBody(screenConfig);
      case 'tool':
        return _buildToolBody(screenConfig);
      case 'research':
        return _buildResearchBody(screenConfig);
      case 'divination':
        return _buildDivinationBody(screenConfig);
      default:
        return Center(
          child: Text('Screen Type "$screenType" not implemented'),
        );
    }
  }

  /// Build Chat Screen Body
  Widget _buildChatBody(Map<String, dynamic> screenConfig) {
    final tabs = screenConfig['tabs'] ?? [];
    final inputArea = screenConfig['input_area'];
    final emptyState = screenConfig['empty_state'];
    
    return Column(
      children: [
        // Tabs
        if (tabs.isNotEmpty)
          Container(
            height: 50,
            color: _getColorFromConfig(_repository.theme?['card_color']),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return _buildTab(tab);
              },
            ),
          ),
        
        // Messages Area
        Expanded(
          child: _buildEmptyState(emptyState),
        ),
        
        // Input Area
        if (inputArea != null)
          _buildInputArea(inputArea),
      ],
    );
  }

  /// Build Tab
  Widget _buildTab(Map<String, dynamic> tabConfig) {
    final name = tabConfig['name'] ?? 'Unnamed';
    final icon = tabConfig['icon'] ?? '📌';
    final enabled = tabConfig['enabled'] ?? true;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 20,
              color: enabled ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Empty State
  Widget _buildEmptyState(Map<String, dynamic>? emptyStateConfig) {
    if (emptyStateConfig == null) {
      return const Center(child: Text('No content'));
    }
    
    final title = emptyStateConfig['title'] ?? '';
    final subtitle = emptyStateConfig['subtitle'] ?? '';
    final icon = emptyStateConfig['icon'] ?? 'chat_bubble_outline';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIcon(icon),
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: _getTextStyle(_repository.typography?['heading2']),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: _getTextStyle(_repository.typography?['caption']),
          ),
        ],
      ),
    );
  }

  /// Build Input Area
  Widget _buildInputArea(Map<String, dynamic> inputAreaConfig) {
    final placeholder = inputAreaConfig['placeholder'] ?? '';
    final maxLength = inputAreaConfig['max_length'] ?? 5000;
    final buttons = inputAreaConfig['buttons'] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: _getColorFromConfig(_repository.theme?['card_color']),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _getColorFromConfig(_repository.theme?['background_color']),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Buttons
          ...buttons.map((btnConfig) => _buildInputButton(btnConfig)),
        ],
      ),
    );
  }

  /// Build Input Button
  Widget _buildInputButton(Map<String, dynamic> buttonConfig) {
    final icon = buttonConfig['icon'];
    final tooltip = buttonConfig['tooltip'];
    final action = buttonConfig['action'];
    
    return IconButton(
      icon: Icon(_getIcon(icon)),
      tooltip: tooltip,
      onPressed: () => _executeAction(action),
    );
  }

  /// Build Tool Body
  Widget _buildToolBody(Map<String, dynamic> screenConfig) {
    final content = screenConfig['content'];
    
    if (content == null) {
      return const Center(child: Text('Tool content missing'));
    }
    
    final title = content['title'] ?? '';
    final subtitle = content['subtitle'] ?? '';
    final buttons = content['buttons'] ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _getTextStyle(_repository.typography?['heading1']),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: _getTextStyle(_repository.typography?['body']),
          ),
          const SizedBox(height: 24),
          // Buttons
          ...buttons.map((btnConfig) => _buildToolButton(btnConfig)),
        ],
      ),
    );
  }

  /// Build Tool Button
  Widget _buildToolButton(Map<String, dynamic> buttonConfig) {
    final label = buttonConfig['label'] ?? '';
    final tooltip = buttonConfig['tooltip'] ?? '';
    final action = buttonConfig['action'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => _executeAction(action),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getColorFromConfig(_repository.theme?['primary_color']),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Text(label),
      ),
    );
  }

  /// Build Research Body (placeholder)
  Widget _buildResearchBody(Map<String, dynamic> screenConfig) {
    return const Center(child: Text('Research Screen - TODO'));
  }

  /// Build Divination Body (placeholder)
  Widget _buildDivinationBody(Map<String, dynamic> screenConfig) {
    return const Center(child: Text('Divination Screen - TODO'));
  }

  /// Execute Action
  void _executeAction(String? action) {
    if (action == null) return;
    
    debugPrint('🎬 Action: $action');
    
    // TODO: Implement action handling
    switch (action) {
      case 'send_message':
        debugPrint('Send message');
        break;
      case 'record_voice':
        debugPrint('Record voice');
        break;
      case 'attach_file':
        debugPrint('Attach file');
        break;
      case 'open_search':
        debugPrint('Open search');
        break;
      case 'toggle_edit_mode':
        debugPrint('Toggle edit mode');
        break;
      default:
        debugPrint('Unknown action: $action');
    }
  }

  /// Get Icon from string
  IconData _getIcon(String? iconName) {
    if (iconName == null) return Icons.help_outline;
    
    switch (iconName) {
      case 'search':
        return Icons.search;
      case 'edit':
        return Icons.edit;
      case 'send':
        return Icons.send;
      case 'mic':
        return Icons.mic;
      case 'attach_file':
        return Icons.attach_file;
      case 'chat_bubble_outline':
        return Icons.chat_bubble_outline;
      default:
        return Icons.help_outline;
    }
  }

  /// Get Color from config string
  Color? _getColorFromConfig(String? colorString) {
    if (colorString == null) return null;
    
    try {
      // Remove # if present
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Get TextStyle from config
  TextStyle? _getTextStyle(Map<String, dynamic>? styleConfig) {
    if (styleConfig == null) return null;
    
    final fontSize = (styleConfig['font_size'] as num?)?.toDouble();
    final fontWeight = _getFontWeight(styleConfig['font_weight']);
    final color = _getColorFromConfig(styleConfig['color']);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Get FontWeight from string
  FontWeight? _getFontWeight(String? weightString) {
    if (weightString == null) return null;
    
    switch (weightString) {
      case 'bold':
        return FontWeight.bold;
      case 'normal':
        return FontWeight.normal;
      case 'light':
        return FontWeight.w300;
      default:
        return FontWeight.normal;
    }
  }
}
