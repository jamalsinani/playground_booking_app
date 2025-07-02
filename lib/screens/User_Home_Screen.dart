import 'package:flutter/material.dart';

class UserHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // الشريط العلوي
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Color(0xFF22235D),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo.png', // ضع شعارك هنا
                      height: 30,
                    ),
                    Icon(Icons.notifications_none, color: Colors.white),
                  ],
                ),
              ),

              // شريط البحث
              Container(
                color: Color(0xFF22235D),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث عن ملعبك',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),

              // الخريطة (Placeholder)
              Container(
                height: 250,
                margin: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(child: Text("خريطة Placeholder")),
                    Positioned(
                      top: 30,
                      right: 30,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Text("ملعب البلدي\nعلى بعد 4 كم", textAlign: TextAlign.center),
                          ),
                          Icon(Icons.location_pin, color: Colors.red, size: 40),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // بطاقات الملاعب
              Container(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  children: [
                    buildStadiumCard('assets/images/stadium1.png', 'ملعب البلدي', 'على بعد 4 كم'),
                    SizedBox(width: 10),
                    buildStadiumCard('assets/images/stadium2.png', 'ملعب النجوم', 'على بعد 6 كم'),
                  ],
                ),
              ),

              // أزرار التنقل السفلي
              Spacer(),
              BottomNavigationBar(
                currentIndex: 0,
                selectedItemColor: Color(0xFF22235D),
                unselectedItemColor: Colors.grey,
                items: [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
                  BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: ''),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStadiumCard(String imagePath, String title, String distance) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(imagePath, height: 80, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(distance, style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
