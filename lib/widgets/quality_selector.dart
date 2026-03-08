import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

class QualitySelector extends StatelessWidget {
  final int selectedBitrate;
  final ValueChanged<int> onChanged;

  const QualitySelector({
    super.key,
    required this.selectedBitrate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audio Quality',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: AppConstants.supportedBitrates.map((bitrate) {
            final isSelected = bitrate == selectedBitrate;
            return ChoiceChip(
              label: Text('${bitrate}kbps'),
              selected: isSelected,
              onSelected: (_) => onChanged(bitrate),
              backgroundColor: AppColors.surfaceVariant,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
      ],
    );
  }
}
