import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final IconData? icon;
  final List<String> items;
  final String? value;
  final void Function(String?) onChanged;
  final ThemeData theme;
  final String? Function(String?)? validator;

  const CustomDropdown({
    super.key,
    required this.label,
    this.icon,
    required this.items,
    this.value,
    required this.onChanged,
    required this.theme,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: theme.colorScheme.primary) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      style: TextStyle(
        fontSize: 16,
        color: theme.colorScheme.onSurface,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
    );
  }
}
