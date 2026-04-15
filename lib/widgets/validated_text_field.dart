import 'package:flutter/material.dart';
import '../utils/validators.dart';
import '../../theme/app_theme.dart';

/// A text field widget with built-in validation and active visual feedback.
///
/// Features:
/// - Real-time validation as user types
/// - Visual indicators (checkmark for valid, error icon for invalid)
/// - Color-coded borders for valid/invalid states
/// - Error text displayed below the field
class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValidationType validationType;
  final bool isPassword;
  final bool readOnly;
  final bool isRequired;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final int maxLines;
  final String? hint;
  final TextEditingController? passwordController;
  final String? Function(String?)? customValidator;
  final String fieldName;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validationType = ValidationType.required,
    this.isPassword = false,
    this.readOnly = false,
    this.isRequired = true,
    this.keyboardType,
    this.onTap,
    this.maxLines = 1,
    this.hint,
    this.passwordController,
    this.customValidator,
    this.fieldName = '',
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  bool _obscureText = true;
  bool _hasBeenTouched = false;
  String? _errorText;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateOnChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateOnChanged);
    super.dispose();
  }

  void _validateOnChanged() {
    if (_hasBeenTouched) {
      _validate();
    }
  }

  void _validate() {
    final value = widget.controller.text;
    final validator = _getValidator();
    final error = validator(value);
    setState(() {
      _errorText = error;
      _isValid = error == null && value.isNotEmpty;
    });
  }

  FormFieldValidator<String> _getValidator() {
    if (widget.customValidator != null) {
      return widget.customValidator!;
    }

    switch (widget.validationType) {
      case ValidationType.email:
        return Validators.email(required: widget.isRequired);
      case ValidationType.phone:
        return Validators.phone(required: widget.isRequired);
      case ValidationType.password:
        return Validators.password();
      case ValidationType.confirmPassword:
        if (widget.passwordController == null) {
          return Validators.required('Password confirmation');
        }
        return Validators.confirmPassword(widget.passwordController!);
      case ValidationType.name:
        return Validators.name(
          widget.fieldName.isNotEmpty ? widget.fieldName : widget.label,
          required: widget.isRequired,
        );
      case ValidationType.employeeId:
        return Validators.employeeId(required: widget.isRequired);
      case ValidationType.nationalId:
        return Validators.nationalId(required: widget.isRequired);
      case ValidationType.required:
        return Validators.required(widget.label);
      case ValidationType.optional:
      case ValidationType.none:
        return Validators.optional();
    }
  }

  Color _getBorderColor(ThemeData theme) {
    if (!_hasBeenTouched || widget.controller.text.isEmpty) {
      return Colors.transparent;
    }
    if (_isValid) {
      return Colors.green;
    }
    return AppTheme.paleRed;
  }

  Color? _getFillColor(ThemeData theme) {
    if (widget.readOnly) {
      return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    }
    return theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.withValues(alpha: 0.05);
  }

  Widget? _getSuffixIcon() {
    if (!_hasBeenTouched || widget.controller.text.isEmpty) {
      return null;
    }
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.grey,
          size: 20,
        ),
        onPressed: () {
          setState(() => _obscureText = !_obscureText);
        },
      );
    }
    if (_isValid) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
    return Icon(Icons.error_outline, color: AppTheme.paleRed, size: 20);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = _getBorderColor(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          onChanged: (value) {
            if (!_hasBeenTouched) {
              setState(() => _hasBeenTouched = true);
            }
            _validate();
          },
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon, size: 20),
            suffixIcon: _getSuffixIcon(),
            filled: true,
            fillColor: _getFillColor(theme),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.skyBlue, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.paleRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.paleRed, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorText: null, // We handle error display ourselves
          ),
          validator: _getValidator(),
          autovalidateMode: _hasBeenTouched
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
        ),
        if (_hasBeenTouched && _errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              _errorText!,
              style: TextStyle(
                color: AppTheme.paleRed,
                fontSize: 12,
              ),
            ),
          ),
      ],
  );
  }
}

/// A dropdown field widget with built-in validation and visual feedback.
class ValidatedDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;
  final bool isRequired;

  const ValidatedDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = value != null && value!.isNotEmpty;

    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: items.contains(value) ? value : null,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isValid
            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
            : null,
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.skyBlue, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: isValid
              ? const BorderSide(color: Colors.green, width: 1.5)
              : BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: isRequired
          ? (val) => val == null || val.isEmpty ? 'Required' : null
          : null,
    );
  }
}