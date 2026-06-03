import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CounterWidget extends StatelessWidget {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final IconData? icon;

  const CounterWidget({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 999999,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildStepperButton(
                icon: Icons.remove,
                onPressed: value <= minValue ? null : () => onChanged(value - 1),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _buildStepperButton(
                icon: Icons.add,
                onPressed: value >= maxValue ? null : () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final bool disabled = onPressed == null;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: disabled ? Colors.grey[100] : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        color: disabled ? Colors.grey[400] : AppColors.primaryDark,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
