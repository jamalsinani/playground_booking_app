import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../widgets/user_base_screen.dart';

class StadiumRatingScreen extends StatefulWidget {
  final int userId;
  final int stadiumId;
  final int bookingId;

  const StadiumRatingScreen({
    super.key,
    required this.userId,
    required this.stadiumId,
    required this.bookingId,
  });

  @override
  State<StadiumRatingScreen> createState() => _StadiumRatingScreenState();
}

class _StadiumRatingScreenState extends State<StadiumRatingScreen> {
  int rating = 0;
  final TextEditingController commentController = TextEditingController();
  bool isSubmitting = false;

  Future<void> submitRating() async {
    if (rating == 0 || commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تقييم وكتابة تعليق')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await UserService.submitRating(
        userId: widget.userId,
        stadiumId: widget.stadiumId,
        bookingId: widget.bookingId,
        rating: rating,
        comment: commentController.text.trim(),
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم إرسال التقييم بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل إرسال التقييم: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Widget buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 32,
      ),
      onPressed: () {
        setState(() {
          rating = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return UserBaseScreen(
      title: 'تقييم الملعب',
      userId: widget.userId,
      currentIndex: 2,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('كم تقييمك لهذا الملعب؟', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => buildStar(index + 1)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'اكتب تعليقك هنا',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSubmitting ? null : submitRating,
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('إرسال التقييم'),
            ),
          ],
        ),
      ),
    );
  }
}
