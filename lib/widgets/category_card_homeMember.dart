import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String rating; // เปลี่ยนเป็น String เพื่อรองรับ "Loading..."

  const CategoryCard({
    required this.icon,
    required this.label,
    required this.rating,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.red),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(rating, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ],
      ),
    );
  }
}