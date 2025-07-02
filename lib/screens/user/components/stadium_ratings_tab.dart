import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StadiumRatingsTab extends StatelessWidget {
  final List ratings;
  final bool isLoading;

  const StadiumRatingsTab({
    super.key,
    required this.ratings,
    required this.isLoading,
  });

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMMM y').format(date); // ✅ بدون تحديد لغة
    } catch (_) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ratings.isEmpty) {
      return const Center(child: Text('No ratings yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ratings.length,
      itemBuilder: (context, index) {
        final rating = ratings[index];
        final user = rating['user'];

        final ratingValue = rating['rating'] is int
            ? rating['rating']
            : int.tryParse(rating['rating'].toString()) ?? 0;

        final profileImage = user?['profile_image'];
        final imageUrl = (profileImage != null && profileImage != '')
            ? 'https://darajaty.net/images/profile_images/$profileImage'
            : 'https://via.placeholder.com/150';

        final createdAt = rating['created_at'] ?? '';

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            user?['name'] ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            formatDate(createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < ratingValue ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rating['comment'] ?? 'No comment.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
