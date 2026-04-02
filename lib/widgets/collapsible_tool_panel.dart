import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';

/// Collapsible Tool Panel - minimierbar, Chat bleibt sichtbar
class CollapsibleToolPanel extends StatefulWidget {
  final Widget? toolWidget;
  final String toolName;
  
  const CollapsibleToolPanel({
    super.key,
    required this.toolWidget,
    required this.toolName,
  });

  @override
  State<CollapsibleToolPanel> createState() => _CollapsibleToolPanelState();
}

class _CollapsibleToolPanelState extends State<CollapsibleToolPanel> with SingleTickerProviderStateMixin {
  bool _isExpanded = false; // ⭐ Startet EINGEKLAPPT
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Will be set dynamically in build based on screen size
    _heightAnimation = Tween<double>(begin: 0.0, end: 300.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Initial collapsed (eingeklappt)
    _animationController.value = 0.0;
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final utils = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);
    
    if (widget.toolWidget == null) return const SizedBox.shrink();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle Header
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: utils.spacingMd, 
              vertical: utils.spacingMd * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[800]!, Colors.amber[900]!],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.amber.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.amberAccent,
                  size: utils.iconSizeMd,
                ),
                SizedBox(width: utils.spacingXs),
                Text(
                  widget.toolName,
                  style: textStyles.bodyMedium.copyWith(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _isExpanded ? 'Minimieren' : 'Öffnen',
                  style: textStyles.bodySmall.copyWith(
                    color: Colors.amberAccent.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Animated Tool Content
        AnimatedBuilder(
          animation: _heightAnimation,
          builder: (context, child) {
            return SizedBox(
              height: _heightAnimation.value,
              child: _isExpanded ? widget.toolWidget : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}
