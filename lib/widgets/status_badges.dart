import 'package:flutter/material.dart';
import '../models/product_model.dart';

class StockStatusBadge extends StatelessWidget {
  final StockStatus status;
  const StockStatusBadge({super.key, required this.status});

  ({Color color, String label}) get _config {
    switch (status) {
      case StockStatus.healthy:
        return (color: const Color(0xFF2E9E5B), label: 'Healthy');
      case StockStatus.low:
        return (color: const Color(0xFFE08A2E), label: 'Low Stock');
      case StockStatus.critical:
        return (color: const Color(0xFFE0483E), label: 'Critical');
      case StockStatus.outOfStock:
        return (color: const Color(0xFF9C948C), label: 'Out of Stock');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(c.label,
              style: TextStyle(
                  color: c.color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class ExpirationStatusBadge extends StatelessWidget {
  final ExpirationStatus status;
  final int? daysRemaining;
  const ExpirationStatusBadge({super.key, required this.status, this.daysRemaining});

  ({Color color, String label}) get _config {
    switch (status) {
      case ExpirationStatus.good:
        return (color: const Color(0xFF2E9E5B), label: '${daysRemaining ?? ''}d left');
      case ExpirationStatus.warning:
        return (color: const Color(0xFFE08A2E), label: '${daysRemaining ?? ''}d left');
      case ExpirationStatus.critical:
        return (color: const Color(0xFFE0483E), label: '${daysRemaining ?? ''}d left');
      case ExpirationStatus.expired:
        return (color: const Color(0xFF9C948C), label: 'Expired');
      case ExpirationStatus.none:
        return (color: Colors.transparent, label: '');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == ExpirationStatus.none) return const SizedBox.shrink();
    final c = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(c.label,
          style: TextStyle(color: c.color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}