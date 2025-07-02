import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/favorite_service.dart';

class FavoriteShareButtons extends StatefulWidget {
  final int userId;
  final int stadiumId;
  final String shareText;
  final VoidCallback? onFavoriteToggle;

  const FavoriteShareButtons({
    super.key,
    required this.userId,
    required this.stadiumId,
    required this.shareText,
    this.onFavoriteToggle,
  });

  @override
  State<FavoriteShareButtons> createState() => _FavoriteShareButtonsState();
}

class _FavoriteShareButtonsState extends State<FavoriteShareButtons> {
  bool isFav = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadFavoriteStatus();
  }

  Future<void> loadFavoriteStatus() async {
    try {
      final result = await FavoriteService.isFavorite(widget.userId, widget.stadiumId);
      if (mounted) {
        setState(() {
          isFav = result;
        });
      }
    } catch (e) {
      // تجاهل الخطأ أو سجل
    }
  }

  Future<void> toggleFavorite() async {
    setState(() => isLoading = true);
    try {
      final result = await FavoriteService.toggleFavorite(widget.userId, widget.stadiumId);
      if (mounted) {
        setState(() {
          isFav = result;
        });

        final message = result
            ? '✅ تمت إضافة الملعب إلى المفضلة'
            : '❌ تمت إزالة الملعب من المفضلة';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.onFavoriteToggle != null) {
          widget.onFavoriteToggle!();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء حفظ التفضيل')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: Colors.redAccent,
                ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share, size: 16, color: Colors.blueAccent),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            final playStoreUrl = 'https://play.google.com/store/apps/details?id=com.example.booking_demo';
            final fullText = '${widget.shareText}\n\n📲 حمل التطبيق من هنا:\n$playStoreUrl';

            Share.share(fullText, subject: 'احجز ملعبك عبر تطبيق ملعبنا');
          },
        ),
      ],
    );
  }
}
