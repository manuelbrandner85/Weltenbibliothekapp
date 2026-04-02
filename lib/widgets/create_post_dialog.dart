import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:image_picker/image_picker.dart';
import '../models/community_post.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';
import '../services/cloudflare_api_service.dart';

/// Dialog zum Erstellen eines neuen Community-Posts mit Media-Upload
class CreatePostDialog extends StatefulWidget {
  final WorldType worldType;
  
  const CreatePostDialog({
    super.key,
    required this.worldType,
  });
  
  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  final UserService _userService = UserService();
  final CloudflareApiService _cloudflareService = CloudflareApiService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isPosting = false;
  bool _isUploadingMedia = false;
  XFile? _selectedMedia;
  String? _mediaType; // 'image' or 'video'
  String? _uploadedMediaUrl; // R2 Storage URL after upload
  
  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
  
  Future<void> _pickMedia(String mediaType) async {
    try {
      setState(() => _isUploadingMedia = true);
      
      XFile? file;
      if (mediaType == 'Bild') {
        // Pick image from gallery
        file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 85,
        );
        _mediaType = 'image';
      } else if (mediaType == 'Video') {
        // Pick video from gallery
        file = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 2),
        );
        _mediaType = 'video';
      }
      
      if (file != null) {
        // Upload to R2 Storage
        final bytes = await file.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        
        if (kDebugMode) {
          debugPrint('📤 Uploading media: $fileName (${bytes.length} bytes)');
        }
        
        final user = await _userService.getCurrentUser();
        final result = await _cloudflareService.uploadMedia(
          fileBytes: bytes,
          fileName: fileName,
          mediaType: _mediaType!,
          worldType: widget.worldType.name,
          username: user.username,
        );
        
        setState(() {
          _selectedMedia = file;
          _uploadedMediaUrl = result['media_url'];
          _isUploadingMedia = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Media erfolgreich hochgeladen!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isUploadingMedia = false);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Media upload error: $e');
      }
      setState(() => _isUploadingMedia = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upload fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // TODO: Review unused method: _showMediaUploadInfoDialog
  // void _showMediaUploadInfoDialog(String mediaType) {
    // showDialog(
      // context: context,
      // builder: (context) => AlertDialog(
        // title: Row(
          // children: [
            // Icon(
              // mediaType == 'Bild' ? Icons.image : Icons.videocam,
              // color: widget.worldType == WorldType.materie ? Colors.blue : Colors.purple,
            // ),
            // const SizedBox(width: 12),
            // Text('$mediaType hochladen'),
          // ],
        // ),
        // content: Column(
          // mainAxisSize: MainAxisSize.min,
          // crossAxisAlignment: CrossAxisAlignment.start,
          // children: [
            // const Text(
              // 'Media-Upload wird vorbereitet!',
              // style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            // ),
            // const SizedBox(height: 16),
            // const Text('🎯 Geplante Features:'),
            // const SizedBox(height: 8),
            // _buildFeatureItem('📸 Bilder direkt hochladen (JPG, PNG)'),
            // _buildFeatureItem('🎥 Videos teilen (MP4, max 2 Min)'),
            // _buildFeatureItem('✂️ Bild-Editor (Crop, Filter, Text)'),
            // _buildFeatureItem('☁️ Cloudflare R2 Storage'),
            // const SizedBox(height: 16),
            // Container(
              // padding: const EdgeInsets.all(12),
              // decoration: BoxDecoration(
                // color: Colors.blue.withValues(alpha: 0.1),
                // borderRadius: BorderRadius.circular(8),
              // ),
              // child: const Row(
                // children: [
                  // Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  // SizedBox(width: 8),
                  // Expanded(
                    // child: Text(
                      // 'Aktuell: Text-Posts funktionieren bereits! Media-Upload folgt bald.',
                      // style: TextStyle(fontSize: 12),
                    // ),
                  // ),
                // ],
              // ),
            // ),
          // ],
        // ),
        // actions: [
          // TextButton(
            // onPressed: () => Navigator.of(context).pop(),
            // child: const Text('Verstanden'),
          // ),
          // ElevatedButton(
            // onPressed: () {
              // Navigator.of(context).pop();
              // Text-Post erstellen
            // },
            // style: ElevatedButton.styleFrom(
              // backgroundColor: widget.worldType == WorldType.materie 
                  // ? Colors.blue 
                  // : Colors.purple,
            // ),
            // child: const Text('Text-Post erstellen'),
          // ),
        // ],
      // ),
    // );
  // }
  
  // TODO: Review unused method: _buildFeatureItem
  // Widget _buildFeatureItem(String text) {
    // return Padding(
      // padding: const EdgeInsets.symmetric(vertical: 4),
      // child: Row(
        // children: [
          // const Icon(Icons.check_circle, size: 16, color: Colors.green),
          // const SizedBox(width: 8),
          // Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        // ],
      // ),
    // );
  // }
  
  void _removeMedia() {
    setState(() {
      _selectedMedia = null;
      _mediaType = null;
      _uploadedMediaUrl = null;
    });
  }
  
  Future<void> _createPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Text ein')),
      );
      return;
    }
    
    setState(() => _isPosting = true);
    
    try {
      // Get current user
      final user = await _userService.getCurrentUser();
      
      // Parse tags
      final tagsText = _tagsController.text.trim();
      final tags = tagsText.isEmpty 
          ? <String>[]
          : tagsText.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      
      // Create post (with optional media)
      await _communityService.createPost(
        username: user.username,
        content: content,
        tags: tags,
        worldType: widget.worldType,
        authorAvatar: user.avatar,
        mediaUrl: _uploadedMediaUrl,  // 🆕 R2 Storage URL
        mediaType: _mediaType,        // 🆕 'image' or 'video'
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Post erfolgreich erstellt!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  widget.worldType == WorldType.materie 
                      ? Icons.public 
                      : Icons.psychology,
                  color: widget.worldType == WorldType.materie 
                      ? Colors.blue 
                      : Colors.purple,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Neuer Post in ${widget.worldType == WorldType.materie ? "Materie" : "Energie"}-Welt',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Content input
            TextField(
              controller: _contentController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Was möchtest du teilen?',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            
            // Media Upload Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.image,
                        size: 20,
                        color: widget.worldType == WorldType.materie 
                            ? Colors.blue 
                            : Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Medien hinzufügen',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Media preview or upload button
                  if (_isUploadingMedia)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              'Wird hochgeladen...',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_selectedMedia != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _mediaType == 'image' ? Icons.image : Icons.video_library,
                            size: 40,
                            color: widget.worldType == WorldType.materie 
                                ? Colors.blue 
                                : Colors.purple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _mediaType == 'image' ? '📸 Bild hochgeladen' : '🎥 Video hochgeladen',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedMedia!.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.withValues(alpha: 0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_uploadedMediaUrl != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '✅ Bereit zum Posten',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green.withValues(alpha: 0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _removeMedia,
                            tooltip: 'Entfernen',
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickMedia('Bild'),
                            icon: const Icon(Icons.photo_camera, size: 20),
                            label: const Text('Bild'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickMedia('Video'),
                            icon: const Icon(Icons.videocam, size: 20),
                            label: const Text('Video'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Tags input
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (mit Komma getrennt)',
                hintText: 'z.B. Forschung, Geopolitik',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isPosting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isPosting ? null : _createPost,
                  icon: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isPosting ? 'Wird gepostet...' : 'Posten'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.worldType == WorldType.materie 
                        ? Colors.blue 
                        : Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
