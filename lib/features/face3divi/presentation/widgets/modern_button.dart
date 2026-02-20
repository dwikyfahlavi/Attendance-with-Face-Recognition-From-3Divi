import 'package:flutter/material.dart';
import 'package:fr3divi/core/theme/app_colors.dart';
import 'package:fr3divi/core/theme/app_text_styles.dart';

/// Modern styled button with gradient background
class ModernButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final bool isPrimary;
  final IconData? icon;
  final MainAxisAlignment? mainAxisAlignment;
  final EdgeInsets? padding;

  const ModernButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = 52,
    this.isPrimary = true,
    this.icon,
    this.mainAxisAlignment,
    this.padding,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPressed() {
    if (!widget.isEnabled || widget.isLoading) return;
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: widget.isPrimary
              ? AppColors.primaryGradient
              : (!widget.isEnabled
                    ? const LinearGradient(
                        colors: [AppColors.disabled, AppColors.disabled],
                      )
                    : const LinearGradient(
                        colors: [
                          AppColors.secondaryCyan,
                          AppColors.secondaryCyanDark,
                        ],
                      )),
          borderRadius: BorderRadius.circular(16),
          boxShadow: !widget.isEnabled
              ? []
              : [
                  BoxShadow(
                    color: widget.isPrimary
                        ? AppColors.primaryPurple.withOpacity(0.22)
                        : AppColors.secondaryCyan.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isEnabled && !widget.isLoading ? _onPressed : null,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withOpacity(0.2),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment:
                          widget.mainAxisAlignment ?? MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: AppColors.textLight,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: AppTextStyles.buttonText.copyWith(
                            color: widget.isEnabled
                                ? AppColors.textLight
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary button style
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ModernButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isPrimary: false,
      icon: icon,
      width: width,
    );
  }
}
