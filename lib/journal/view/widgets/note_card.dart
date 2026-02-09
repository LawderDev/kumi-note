import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kumi_app/core/theme/kumi_colors.dart';
import 'package:kumi_app/core/theme/kumi_text_styles.dart';
import 'package:kumi_app/core/widgets/kumi_card.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Card displaying a single note with Kumi styling
class NoteCard extends StatelessWidget {
  const NoteCard({required this.note, super.key});

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    return KumiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.content,
            style: KumiTextStyles.bodyL,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.clock,
                size: 14,
                color: KumiColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(note.createdAt),
                style: KumiTextStyles.caption.copyWith(
                  color: KumiColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KumiColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.checkCircle2,
                      size: 12,
                      color: KumiColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Indexé (${note.embedding.length}d)',
                      style: KumiTextStyles.caption.copyWith(
                        color: KumiColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inHours < 1) return 'Il y a ${difference.inMinutes}min';
    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${DateFormat.Hm().format(date)}';
    }
    if (difference.inDays == 1) return 'Hier';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} jours';

    return DateFormat.yMd().format(date);
  }
}
