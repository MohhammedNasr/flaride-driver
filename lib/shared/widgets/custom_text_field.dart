import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? leadingIcon;
  final bool isPassword;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.leadingIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword ? _obscured : false,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.leadingIcon != null ? Icon(widget.leadingIcon, color: AppColors.midGray) : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(_obscured ? CupertinoIcons.eye_slash : CupertinoIcons.eye, color: AppColors.midGray),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}


