import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF12372A);
  static const Color secondary = Color(0xFF436850);
  static const Color accent = Color(0xFFADBC9F);
  static const Color background = Color(0xFFF8F7F2);
  static const Color textDark = Color(0xFF1F2933);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color success = Color(0xFF1B8A5A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFE11D48);
  static const Color info = Color(0xFF2563EB);
}

InputDecoration inputDecoration(String label, IconData icon, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
  );
}

class AppNav {
  static void _go(BuildContext context, String ruta) {
    final actual = ModalRoute.of(context)?.settings.name;
    if (actual == ruta) return;
    Navigator.pushNamed(context, ruta);
  }

  static BottomNavigationBar bottomMenu(int currentIndex, BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) _go(context, '/');
        if (index == 1) _go(context, '/clientes');
        if (index == 2) _go(context, '/clientes/form');
        if (index == 3) _go(context, '/mapa');
      },
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey.shade600,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Clientes'),
        BottomNavigationBarItem(icon: Icon(Icons.add_location_alt_rounded), label: 'Nuevo'),
        BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Ruta'),
      ],
    );
  }
}

Widget emptyState({required IconData icon, required String title, required String subtitle}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(70),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 44),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, height: 1.35),
          ),
        ],
      ),
    ),
  );
}
