import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg package
import 'package:takenow/widgets/post_user_card.dart';
import 'package:takenow/screens/viewAlbumScreen.dart'; // Import trang ViewAlbum

class ViewPhotoScreen extends StatefulWidget {
  const ViewPhotoScreen({Key? key}) : super(key: key);

  @override
  State<ViewPhotoScreen> createState() => _ViewPhotoScreenState();
}

class _ViewPhotoScreenState extends State<ViewPhotoScreen> {
  String selectedEmotion = '';
  PageController _pageController = PageController();
  List<DocumentSnapshot>? _posts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F2E2E),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('post_image')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Center(child: CircularProgressIndicator());
            default:
              _posts = snapshot.data?.docs;
              return Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: _posts?.length ?? 0,
                      itemBuilder: (context, index) {
                        DocumentSnapshot document = _posts![index];
                        String imageUrl = document['imageUrl'];
                        String caption = document['caption'];

                        return Center(
                          child: PostUserCard(
                            imageUrl: imageUrl,
                            caption: caption,
                            pageController: _pageController,
                            index: index,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                      height:
                          10.0), // Khoảng cách giữa PageView và thanh emotion
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewAlbumScreen(),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                              left: 20.0, bottom: 50), // Thêm margin bottom
                          child: SvgPicture.asset(
                            'assets/icons/darhboard.svg',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(
                          width: 20.0), // Khoảng cách giữa SVG và thanh emotion
                      Expanded(
                        child: EmotionSelector(
                          selectedEmotion: selectedEmotion,
                          onEmotionSelected: onEmotionSelected,
                        ),
                      ),
                    ],
                  ),
                ],
              );
          }
        },
      ),
    );
  }

  void onEmotionSelected(String emotion) {
    setState(() {
      selectedEmotion = emotion;
    });
    // Handle emotion selection logic here
  }
}

class EmotionSelector extends StatelessWidget {
  final String selectedEmotion;
  final Function(String) onEmotionSelected;

  const EmotionSelector({
    Key? key,
    required this.selectedEmotion,
    required this.onEmotionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 50.0),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(88, 81, 81, 1),
        borderRadius: BorderRadius.circular(40.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () => onEmotionSelected('Message'),
            color: selectedEmotion == 'Message' ? Colors.blue : Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.sentiment_very_satisfied),
            onPressed: () => onEmotionSelected('Very Satisfied'),
            color:
                selectedEmotion == 'Very Satisfied' ? Colors.blue : Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied),
            onPressed: () => onEmotionSelected('Satisfied'),
            color: selectedEmotion == 'Satisfied' ? Colors.blue : Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.sentiment_neutral),
            onPressed: () => onEmotionSelected('Neutral'),
            color: selectedEmotion == 'Neutral' ? Colors.blue : Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.sentiment_very_dissatisfied),
            onPressed: () => onEmotionSelected('Very Dissatisfied'),
            color: selectedEmotion == 'Very Dissatisfied'
                ? Colors.blue
                : Colors.grey,
          ),
        ],
      ),
    );
  }
}
