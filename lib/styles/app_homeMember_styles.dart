import 'package:flutter/material.dart';

// Text Styles
const TextStyle kTitleTextStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
);

const TextStyle kRedBoldTextStyle = TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.red,
);

const TextStyle kSmallRedTextStyle = TextStyle(
  fontSize: 12,
  color: Colors.red,
);

// Box Decorations
final kCategoryCardDecoration = BoxDecoration(
  color: Colors.blue.shade50,
  borderRadius: BorderRadius.circular(12),
);

// Spacing
const SizedBox kSmallVerticalSpace = SizedBox(height: 8);
const SizedBox kMediumVerticalSpace = SizedBox(height: 16);
const SizedBox kLargeVerticalSpace = SizedBox(height: 20);