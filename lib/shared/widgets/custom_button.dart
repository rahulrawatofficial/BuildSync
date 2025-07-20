import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        // icon:
        //     isLoading
        //         ? const SizedBox(
        //           width: 16,
        //           height: 16,
        //           child: CircularProgressIndicator(
        //             strokeWidth: 2,
        //             color: Colors.white,
        //           ),
        //         )
        //         : Icon(icon ?? Icons.check, size: 20, color: Colors.white),
        label: Text(
          isLoading ? 'Updating...' : text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          // backgroundColor: const Color(0xFF2BB56D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          elevation: 4,
        ),
      ),
    );
  }
}
