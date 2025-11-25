import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Pour images
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart'; // AJOUTÉ: Pour compression vidéo
import 'package:rent_house/Models/conversation.dart';
import 'package:rent_house/Models/message.dart';
import 'package:rent_house/Providers/messages_provider.dart';
import 'package:rent_house/Services/messages_service.dart';
import 'dart:io';

class ChatDetailsPage extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailsPage({super.key, required this.conversation});

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  ChewieController? _chewieController; // Pour playback vidéo

  @override
  void initState() {
    super.initState();
    context.read<MessagesProvider>().selectConversation(widget.conversation.id);
    context.read<MessagesProvider>().markAsRead(widget.conversation.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    context.read<MessagesProvider>().clearSelectedConversation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    bool isMe(message) => message.senderId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.otherUserName),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appel non implémenté')),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User bloqué')),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'block', child: Text('Bloquer')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessagesProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = provider.currentMessages;
                if (messages.isEmpty) {
                  return const Center(
                      child:
                          Text('Aucun message. Commencez la conversation !'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message, isMe(message));
                  },
                );
              },
            ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final bubbleColor = isMe ? Colors.blue[100] : Colors.grey[200];
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                widget.conversation.otherUserName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.type == MessageType.video ||
                      message.type == MessageType.mixed)
                    _buildVideoPlayer(message.videoUrl!),
                  if (message.type == MessageType.image ||
                      message.type == MessageType.mixed)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: message.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  if (message.type == MessageType.mixed)
                    const SizedBox(height: 8),
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                currentUserId.isNotEmpty ? currentUserId[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    _chewieController ??= ChewieController(
      videoPlayerController:
          VideoPlayerController.networkUrl(Uri.parse(videoUrl)),
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      materialProgressColors: ChewieProgressColors(
        playedColor: Theme.of(context).colorScheme.primary,
      ),
    );

    return SizedBox(
      height: 200,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isUploading)
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
          if (_isUploading) const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: _isUploading ? const SizedBox() : const Icon(Icons.photo),
                onPressed: _isUploading
                    ? null
                    : () => _pickMedia(ImageSource.gallery, isVideo: false),
              ),
              IconButton(
                icon: _isUploading
                    ? const SizedBox()
                    : const Icon(Icons.videocam),
                onPressed: _isUploading
                    ? null
                    : () => _pickMedia(ImageSource.gallery, isVideo: true),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Tapez un message...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24))),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  maxLines: null,
                  enabled: !_isUploading,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isUploading ? null : _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo}) async {
    final pickedFile = await _picker.pickVideo(source: source) ??
        await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    final originalFile = File(pickedFile.path);
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    File fileToUpload = originalFile;
    if (isVideo) {
      // Compression vidéo basique avec FFmpeg (resize + bitrate)
      final session = await FFmpegKit.execute(
        '-i ${originalFile.path} -vf scale=640:480 -b:v 1000k -r 30 ${originalFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      final returnCode = await session.getReturnCode();
      if (returnCode != null && returnCode.isValueSuccess()) {
        fileToUpload = File(
            '${originalFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4');
        debugPrint('Vidéo compressée avec succès');
      } else {
        debugPrint('Compression vidéo échouée, upload original');
      }
    } else {
      // Compression image (comme avant)
      final compressedFileGeneric =
          await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        '${originalFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        quality: 85,
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
      );
      final File? compressedFile = compressedFileGeneric as File?;
      fileToUpload = compressedFile ?? originalFile;
    }

    // Upload
    final messagesService = MessagesService();
    String? url;
    if (isVideo) {
      url = await messagesService
          .uploadMessageVideo(fileToUpload, widget.conversation.id, (progress) {
        if (mounted) setState(() => _uploadProgress = progress);
      });
    } else {
      url = await messagesService
          .uploadMessageImage(fileToUpload, widget.conversation.id, (progress) {
        if (mounted) setState(() => _uploadProgress = progress);
      });
    }

    setState(() => _isUploading = false);

    if (url != null) {
      final success = await _sendMessage(
          imageUrl: isVideo ? null : url, videoUrl: isVideo ? url : null);
      if (success) _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'upload')),
      );
    }
  }

  Future<bool> _sendMessage({String? imageUrl, String? videoUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null && videoUrl == null) return false;
    final success = await context.read<MessagesProvider>().sendMessage(
          widget.conversation.id,
          text,
          imageUrl: imageUrl,
          videoUrl: videoUrl,
        );

    if (success) {
      _messageController.clear();
      _scrollToBottom();
      return true;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.read<MessagesProvider>().errorMessage ??
                  'Erreur d\'envoi')),
        );
        context.read<MessagesProvider>().clearError();
      }
      return false;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final date = timestamp;
    final now = DateTime.now();
    if (date.difference(now).inDays.abs() < 1) {
      return MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(date));
    }
    return '${date.day}/${date.month}';
  }
}
