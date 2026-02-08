import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/cloudflare_api_service.dart';

/// 🗳️ POLL WIDGET
/// Abstimmungen/Umfragen im Chat
class PollWidget extends StatefulWidget {
  final Map<String, dynamic> poll;
  final String currentUserId;
  final String currentUsername;
  final Color worldColor;
  final Function(String pollId, int optionIndex)? onVote; // 🔔 Vote Callback
  
  const PollWidget({
    super.key,
    required this.poll,
    required this.currentUserId,
    required this.currentUsername,
    this.worldColor = Colors.purple,
    this.onVote,
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  final CloudflareApiService _api = CloudflareApiService();
  int? _myVote;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _checkMyVote();
  }

  void _checkMyVote() {
    // Check if user already voted
    final votes = widget.poll['votes'] as List<dynamic>? ?? [];
    for (var vote in votes) {
      if (vote['user_id'] == widget.currentUserId) {
        setState(() => _myVote = vote['option_index']);
        break;
      }
    }
  }

  Future<void> _vote(int optionIndex) async {
    if (_isVoting) return;
    
    setState(() => _isVoting = true);
    
    try {
      await _api.voteOnPoll(
        pollId: widget.poll['id'],
        userId: widget.currentUserId,
        username: widget.currentUsername,
        optionIndex: optionIndex,
      );
      
      if (mounted) {
        setState(() {
          _myVote = optionIndex;
          _isVoting = false;
        });
        
        widget.onVote?.call(widget.poll['id'], optionIndex); // 🔔 Notify parent
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Stimme abgegeben!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Vote error: $e');
      if (mounted) {
        setState(() => _isVoting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.poll['question'] ?? 'Umfrage';
    final options = List<String>.from(widget.poll['options'] ?? []);
    final votes = widget.poll['votes'] as List<dynamic>? ?? [];
    
    // Calculate total votes
    final totalVotes = votes.fold<int>(
      0,
      (sum, vote) => sum + (vote['count'] as int? ?? 0),
    );
    
    // Calculate vote counts per option
    final voteCounts = List<int>.filled(options.length, 0);
    for (var vote in votes) {
      final optionIndex = vote['option_index'] as int?;
      final count = vote['count'] as int? ?? 0;
      if (optionIndex != null && optionIndex < voteCounts.length) {
        voteCounts[optionIndex] = count;
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.worldColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.poll, color: widget.worldColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Umfrage von ${widget.poll['username']}',
                      style: TextStyle(
                        color: widget.worldColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Options
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final voteCount = voteCounts[index];
            final percentage = totalVotes > 0 
                ? (voteCount / totalVotes * 100).toStringAsFixed(0) 
                : '0';
            final isSelected = _myVote == index;
            
            return GestureDetector(
              onTap: _isVoting ? null : () => _vote(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? widget.worldColor.withValues(alpha: 0.3) 
                      : Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? widget.worldColor 
                        : Colors.grey[700]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Progress bar background
                    if (_myVote != null)
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: totalVotes > 0 ? voteCount / totalVotes : 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.worldColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    
                    // Option content
                    Row(
                      children: [
                        if (isSelected)
                          Icon(Icons.check_circle, 
                            color: widget.worldColor, 
                            size: 20,
                          ),
                        if (isSelected) const SizedBox(width: 8),
                        
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        
                        if (_myVote != null)
                          Text(
                            '$voteCount ($percentage%)',
                            style: TextStyle(
                              color: widget.worldColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: 8),
          
          // Footer
          Text(
            _myVote != null 
                ? '$totalVotes ${totalVotes == 1 ? 'Stimme' : 'Stimmen'}' 
                : 'Noch keine Stimmen',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog zum Erstellen einer Umfrage
class CreatePollDialog extends StatefulWidget {
  final String room;
  final String userId;
  final String username;
  final Color worldColor;
  final VoidCallback? onPollCreated; // 🔔 CALLBACK
  
  const CreatePollDialog({
    super.key,
    required this.room,
    required this.userId,
    required this.username,
    this.worldColor = Colors.purple,
    this.onPollCreated,
  });

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final CloudflareApiService _api = CloudflareApiService();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isCreating = false;

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _createPoll() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Frage eingeben'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final options = _optionControllers
        .map((ctrl) => ctrl.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mindestens 2 Optionen erforderlich'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isCreating = true);
    
    try {
      final pollId = await _api.createPoll(
        room: widget.room,
        userId: widget.userId,
        username: widget.username,
        question: question,
        options: options,
      );
      
      if (pollId != null && mounted) {
        widget.onPollCreated?.call(); // 🔔 Notify parent
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Umfrage erstellt!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Create poll error: $e');
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var ctrl in _optionControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          Icon(Icons.poll, color: widget.worldColor),
          const SizedBox(width: 8),
          const Text('Umfrage erstellen', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _questionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Frage',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.worldColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.worldColor, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Antwort-Optionen:',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            ..._optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final ctrl = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: widget.worldColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: widget.worldColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeOption(index),
                      ),
                  ],
                ),
              );
            }),
            
            if (_optionControllers.length < 6)
              TextButton.icon(
                onPressed: _addOption,
                icon: Icon(Icons.add, color: widget.worldColor),
                label: Text(
                  'Option hinzufügen',
                  style: TextStyle(color: widget.worldColor),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createPoll,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.worldColor,
            foregroundColor: Colors.white,
          ),
          child: _isCreating 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Erstellen'),
        ),
      ],
    );
  }
}
