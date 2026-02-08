import 'package:flutter/material.dart';

/// Tool Overlay Dialog - Öffnet Tool als Fullscreen Overlay
class ToolOverlayDialog extends StatelessWidget {
  final Widget toolWidget;
  final String toolName;
  final IconData toolIcon;
  final Color toolColor;

  const ToolOverlayDialog({
    super.key,
    required this.toolWidget,
    required this.toolName,
    required this.toolIcon,
    required this.toolColor,
  });

  static void show(
    BuildContext context, {
    required Widget toolWidget,
    required String toolName,
    required IconData toolIcon,
    required Color toolColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ToolOverlayDialog(
        toolWidget: toolWidget,
        toolName: toolName,
        toolIcon: toolIcon,
        toolColor: toolColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: toolColor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header mit Drag-Handle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [toolColor, toolColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tool Title
                    Row(
                      children: [
                        Icon(toolIcon, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            toolName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tool Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: toolWidget,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
