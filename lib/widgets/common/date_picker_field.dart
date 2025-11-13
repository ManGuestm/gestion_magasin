import 'package:flutter/material.dart';
import '../../utils/date_utils.dart' as app_date;

class DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final double? width;
  final double height;
  final bool readOnly;

  const DatePickerField({
    super.key,
    required this.controller,
    this.label,
    this.width,
    this.height = 25,
    this.readOnly = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        readOnly: readOnly,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          suffixIcon: Icon(Icons.calendar_today, size: 16),
        ),
        onTap: readOnly ? () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            controller.text = app_date.AppDateUtils.formatDate(date);
          }
        } : null,
      ),
    );
  }
}