import 'package:flutter/material.dart';
import 'package:fr3divi/core/theme/app_colors.dart';
import 'package:fr3divi/core/theme/app_text_styles.dart';
import 'package:fr3divi/core/theme/custom_input_decoration.dart';

/// Custom TextFormField with modern styling
class ModernTextFormField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;

  const ModernTextFormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
  });

  @override
  State<ModernTextFormField> createState() => _ModernTextFormFieldState();
}

class _ModernTextFormFieldState extends State<ModernTextFormField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      obscureText: _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      textInputAction: widget.textInputAction,
      style: AppTextStyles.bodyMedium,
      decoration: AppInputDecoration.defaultTextFieldDecoration(
        label: widget.label,
        hint: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppColors.primaryPurple)
            : null,
        suffixIcon: widget.obscureText
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textSecondary,
                ),
              )
            : (widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixTap,
                      child: widget.suffixIcon,
                    )
                  : null),
      ),
    );
  }
}

/// PIN input field - for admin authentication
class PinInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final VoidCallback? onComplete;

  const PinInputField({
    super.key,
    this.controller,
    this.validator,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 6,
      validator: validator,
      onChanged: (value) {
        if (value.length == 6) {
          onComplete?.call();
        }
      },
      style: AppTextStyles.headlineLarge.copyWith(
        letterSpacing: 12,
        color: AppColors.primaryPurple,
      ),
      textAlign: TextAlign.center,
      decoration: AppInputDecoration.pinFieldDecoration(label: 'Enter PIN'),
    );
  }
}
