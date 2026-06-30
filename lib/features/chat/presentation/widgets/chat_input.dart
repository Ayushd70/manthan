import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/features/voice/application/voice_controller.dart';

/// Composer for chat: text field, image attachments, voice, and send/stop.
class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({
    required this.onSend,
    required this.onStop,
    required this.isGenerating,
    this.allowImages = false,
    super.key,
  });

  /// Called with the message text and any attached image bytes.
  final void Function(String text, List<Uint8List> images) onSend;

  /// Called to cancel an in-flight generation.
  final VoidCallback onStop;

  /// Whether a response is currently streaming.
  final bool isGenerating;

  /// Whether image attachment is offered (multimodal model loaded).
  final bool allowImages;

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<Uint8List> _images = <Uint8List>[];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    setState(() {
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes != null) _images.add(bytes);
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty && _images.isEmpty) return;
    widget.onSend(text, List<Uint8List>.from(_images));
    _controller.clear();
    setState(_images.clear);
    _focusNode.requestFocus();
  }

  Future<void> _toggleMic() async {
    final voice = ref.read(voiceControllerProvider.notifier);
    final state = ref.read(voiceControllerProvider);
    if (state.isListening) {
      await voice.stop();
      return;
    }
    await voice.start(
      onFinal: (text) {
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
        _focusNode.requestFocus();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mirror partial transcripts into the field while listening.
    ref.listen(voiceControllerProvider, (previous, next) {
      if (next.isListening && next.transcript.isNotEmpty) {
        _controller.text = next.transcript;
        _controller.selection = TextSelection.collapsed(
          offset: next.transcript.length,
        );
      }
    });
    final isListening = ref.watch(
      voiceControllerProvider.select((s) => s.isListening),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_images.isNotEmpty)
              _AttachmentPreview(
                images: _images,
                onRemove: (i) => setState(() => _images.removeAt(i)),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (widget.allowImages)
                  IconButton(
                    onPressed: widget.isGenerating ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    tooltip: 'Attach image',
                  ),
                IconButton(
                  onPressed: widget.isGenerating ? null : _toggleMic,
                  icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                  color: isListening ? theme.colorScheme.error : null,
                  tooltip: isListening ? 'Stop dictation' : 'Dictate',
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Message Manthan…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(
                  isGenerating: widget.isGenerating,
                  onSend: _send,
                  onStop: widget.onStop,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isGenerating,
    required this.onSend,
    required this.onStop,
    required this.color,
  });

  final bool isGenerating;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: isGenerating ? onStop : onSend,
      icon: Icon(
        isGenerating ? Icons.stop_rounded : Icons.arrow_upward_rounded,
      ),
      tooltip: isGenerating ? 'Stop' : 'Send',
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.images, required this.onRemove});

  final List<Uint8List> images;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            return Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    images[i],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => onRemove(i),
                    child: const CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
