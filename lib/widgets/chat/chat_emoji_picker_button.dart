import 'package:flutter/material.dart';

/// Kleiner Emoji-Picker-Button fürs Chat-Input.
///
/// Öffnet ein BottomSheet mit einer kuratierten Emoji-Palette (nach
/// Kategorien gegliedert). Tippen auf ein Emoji ruft [onSelected] mit
/// dem Zeichen auf — der aufrufende Screen fügt es an die aktuelle
/// Caret-Position im TextField ein.
class ChatEmojiPickerButton extends StatelessWidget {
  const ChatEmojiPickerButton({
    super.key,
    required this.onSelected,
    this.color,
    this.size = 22,
  });

  final ValueChanged<String> onSelected;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(Icons.emoji_emotions_outlined,
          color: color ?? Colors.white70, size: size),
      tooltip: 'Emoji einfügen',
      onPressed: () async {
        final emoji = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: const Color(0xFF13132A),
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const _ChatEmojiSheet(),
        );
        if (emoji != null && emoji.isNotEmpty) onSelected(emoji);
      },
    );
  }
}

class _ChatEmojiSheet extends StatefulWidget {
  const _ChatEmojiSheet();

  @override
  State<_ChatEmojiSheet> createState() => _ChatEmojiSheetState();
}

class _ChatEmojiSheetState extends State<_ChatEmojiSheet> {
  static const _categories = <String, List<String>>{
    'Smileys': [
      '😀','😃','😄','😁','😊','🙂','😉','😍','🥰','😘','😎','🤩','🤗','🤔',
      '😏','😒','😞','😔','😟','😕','🙁','☹️','😣','😖','😫','😩','🥺','😢',
      '😭','😤','😠','😡','🤬','🤯','😳','😱','😨','😰','😥','😓','🤗','🤔',
      '🤨','😐','😑','😶','🙄','😬','🤥','😌','😴','🤤','😪','🤒','🤕','🤢',
    ],
    'Herzen': ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💘','💝','💟','💌'],
    'Gesten': ['👍','👎','👏','🙌','🙏','👐','🤲','🤝','💪','🤞','✌️','🤟','🤘','👌','🤏','👈','👉','👆','👇','✊','👊','🫶','🫰','🫵'],
    'Tiere': ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐵','🙈','🙉','🙊','🦄','🦋','🐝','🐞','🦉','🦅'],
    'Essen': ['🍎','🍊','🍋','🍌','🍉','🍇','🍓','🫐','🍑','🥭','🍍','🥝','🥑','🍅','🥕','🌽','🫑','🥦','🌶️','🥖','🧀','🍕','🍔','🍟','🍣','🍤','🍪','🍩','🍰','🎂','☕','🍵'],
    'Spirit': ['✨','🌟','💫','⭐','☀️','🌙','🪐','🔮','🌈','🕊️','🪷','🧘','🧿','🕉️','☯️','🔔','🪔','🌸','🌿','🍃','🌀','💎','🪞','🎴'],
    'Objekte': ['💡','📱','💻','📚','📖','🎧','🎵','🎶','🎸','🎹','🎮','🏆','🎁','🎉','🎊','🔥','💧','❄️','⚡','🌊','💼','📝','🖊️','🧭'],
    'Symbole': ['✅','❌','❗','❓','⚠️','🔒','🔓','🔑','♾️','🆗','💯','➡️','⬅️','⬆️','⬇️','🔄','🔃','🔁','🔂','▶️','⏸️','⏹️','🟢','🔴'],
  };

  String _selected = 'Smileys';

  @override
  Widget build(BuildContext context) {
    final emojis = _categories[_selected] ?? const <String>[];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.keys.map((cat) {
                  final active = cat == _selected;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: active,
                      onSelected: (_) => setState(() => _selected = cat),
                      selectedColor: const Color(0xFF7C4DFF),
                      backgroundColor: Colors.white10,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: emojis.length,
                itemBuilder: (_, i) {
                  final e = emojis[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).pop(e),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
