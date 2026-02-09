import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_note/kumi_chat/view/theme/kumi_theme.dart';

/// Widget displaying a source note reference as a clickable chip.
///
/// Shows a compact preview of the source note that was used to generate
/// a response, allowing users to see the context used by Kumi.
class SourceChip extends StatefulWidget {
  const SourceChip({
    required this.note,
    super.key,
  });

  /// The note model to display as a source reference
  final NoteModel note;

  @override
  State<SourceChip> createState() => _SourceChipState();
}

class _SourceChipState extends State<SourceChip> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: _isExpanded
          ? _buildExpandedView(context)
          : _buildCompactView(context),
    );
  }

  /// Builds the compact chip view
  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KumiTheme.spacingS,
        vertical: KumiTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: KumiTheme.orange.withValues(alpha: 0.15),
        border: Border.all(
          color: KumiTheme.orange,
          width: 1,
        ),
        borderRadius: KumiTheme.fullRadius,
        boxShadow: [KumiTheme.subtleShadow],
      ),
      child: Text(
        '📝 Source',
        style: KumiTheme.smallStyle.copyWith(
          color: KumiTheme.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Builds the expanded modal view
  Widget _buildExpandedView(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.all(KumiTheme.spacingM),
      decoration: BoxDecoration(
        color: KumiTheme.cream,
        border: Border.all(
          color: KumiTheme.orange,
          width: 2,
        ),
        borderRadius: KumiTheme.mediumRadius,
        boxShadow: [KumiTheme.mediumShadow],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Source Detail',
                  style: KumiTheme.subtitleStyle,
                ),
                GestureDetector(
                  onTap: _toggleExpanded,
                  child: Icon(
                    Icons.close,
                    color: KumiTheme.anthraciteGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KumiTheme.spacingM),

            // Content
            Text(
              widget.note.content,
              style: KumiTheme.bodyStyle,
            ),
            const SizedBox(height: KumiTheme.spacingM),

            // Metadata
            Container(
              padding: const EdgeInsets.all(KumiTheme.spacingS),
              decoration: BoxDecoration(
                color: KumiTheme.lightGray,
                borderRadius: KumiTheme.smallRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Created: ${_formatDate(widget.note.createdAt)}',
                    style: KumiTheme.smallStyle.copyWith(
                      color: KumiTheme.disabledGray,
                    ),
                  ),
                  const SizedBox(height: KumiTheme.spacingXS),
                  Text(
                    'ID: ${widget.note.id.substring(0, 8)}...',
                    style: KumiTheme.smallStyle.copyWith(
                      color: KumiTheme.disabledGray,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggles the expanded state
  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() => _isExpanded = !_isExpanded);
  }

  /// Formats a date into a readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
