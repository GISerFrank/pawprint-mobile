import 'package:flutter/material.dart';

/// 自定义输入框组件
/// 封装常用配置，默认 textInputAction 为 done
class AppTextField extends StatelessWidget {
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final String? suffixText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.suffixText,
    this.suffixIcon,
    this.prefixIcon,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validator,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.style,
    this.decoration,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    // 单行输入框默认使用 done，多行默认使用 newline
    final effectiveTextInputAction = textInputAction ??
        (maxLines == 1 ? TextInputAction.done : TextInputAction.newline);

    return TextFormField(
      initialValue: controller == null ? initialValue : null,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: effectiveTextInputAction,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      style: style,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      decoration: decoration ??
          InputDecoration(
            hintText: hintText,
            labelText: labelText,
            suffixText: suffixText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
    );
  }
}
