import 'package:flutter/material.dart';
import 'package:booking_demo/services/favorite_service.dart';
import 'package:booking_demo/widgets/user_base_screen.dart';
import 'stadium_booking_screen.dart';

class FavoriteStadiumsScreen extends StatefulWidget {
  final int userId;
  const FavoriteStadiumsScreen({super.key, required this.userId});

  @override
  State<FavoriteStadiumsScreen> createState() => _FavoriteStadiumsScreenState();
}

class _FavoriteStadiumsScreenState extends State<FavoriteStadiumsScreen> {
  List<dynamic> favoriteStadiums = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final favs = await FavoriteService.fetchFavorites(widget.userId);
      setState(() {
        favoriteStadiums = favs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل في تحميل الملاعب المفضلة")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserBaseScreen(
      title: "الملاعب المفضلة",
      userId: widget.userId,
      currentIndex: 0,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteStadiums.isEmpty
              ? const Center(child: Text("لا توجد ملاعب مفضلة بعد."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteStadiums.length,
                  itemBuilder: (context, index) {
                    final stadium = favoriteStadiums[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.stadium, color: Colors.green),
                        title: Text(stadium['name'] ?? ''),
                        subtitle: Text('📍 ${stadium['location'] ?? ''}'),
                        trailing: Text('${stadium['price_per_hour']} ر.ع'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StadiumBookingScreen(
                                stadiumName: stadium['name'] ?? '',
                                imageUrl: '', // عدل لاحقًا لعرض صور إن وُجدت
                                price: stadium['price_per_hour'].toString(),
                                stadiumId: stadium['id'],
                                location: stadium['location'] ?? '',
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
