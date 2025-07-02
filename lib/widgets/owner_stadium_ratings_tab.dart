import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OwnerStadiumRatingsTab extends StatefulWidget {
  final int stadiumId;

  const OwnerStadiumRatingsTab({super.key, required this.stadiumId});

  @override
  State<OwnerStadiumRatingsTab> createState() => _OwnerStadiumRatingsTabState();
}

class _OwnerStadiumRatingsTabState extends State<OwnerStadiumRatingsTab> {
  List ratings = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchRatings();
  }

  Future<void> fetchRatings() async {
    try {
      final response = await http.get(
        Uri.parse('https://darajaty.net/api/ratings/stadium/${widget.stadiumId}'),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        setState(() {
          ratings = data;
          isLoading = false;
        });
      } else {
        throw Exception('فشل في جلب التقييمات');
      }
    } catch (e) {
      print('❌ Error fetching ratings: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return const Center(child: Text("حدث خطأ أثناء تحميل التقييمات"));
    }

    if (ratings.isEmpty) {
      return const Center(child: Text("لا توجد تقييمات حتى الآن"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ratings.length,
      itemBuilder: (context, index) {
        final rating = ratings[index];
        final user = rating['user'];
        final stars = int.tryParse(rating['rating'].toString()) ?? 0;
        final comment = rating['comment'] ?? '';
        final username = user?['name'] ?? 'مستخدم';
        final profileImage = user?['profile_image'];
        final imageUrl = profileImage != null
            ? 'https://darajaty.net/images/profile_images/$profileImage'
            : null;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : const AssetImage('assets/images/user.png') as ImageProvider,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < stars ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        comment,
                        style: const TextStyle(fontSize: 14, height: 1.4),
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
