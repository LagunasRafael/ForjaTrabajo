import 'package:flutter/material.dart';

class AddressSuggestionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final Function(Map<String, dynamic> suggestion) onSuggestionSelected;

  const AddressSuggestionsCard({
    super.key,
    required this.suggestions,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on_outlined, color: Color(0xFF4F46E5)),
            title: Text(
              item['display_name'] ?? '',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSuggestionSelected(item),
          );
        },
      ),
    );
  }
}
