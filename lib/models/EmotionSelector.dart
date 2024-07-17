import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmotionSelector extends StatelessWidget {
  final String selectedEmotion;
  final ValueChanged<String> onEmotionSelected;
  final VoidCallback onSendMessage;
  final VoidCallback onOpenEmojiPicker;

  const EmotionSelector({
    Key? key,
    required this.selectedEmotion,
    required this.onEmotionSelected,
    required this.onSendMessage,
    required this.onOpenEmojiPicker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onOpenEmojiPicker,
          child: SvgPicture.asset(
            'assets/icons/emoji_icon.svg', // Ensure this asset exists in your project
            width: 30,
            height: 30,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 15.0),
        GestureDetector(
          onTap: onSendMessage,
          child: SvgPicture.asset(
            'assets/icons/message_icon.svg', // Ensure this asset exists in your project
            width: 30,
            height: 30,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
