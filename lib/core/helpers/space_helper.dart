import 'package:flutter/material.dart';

SizedBox verticalSpace(num height) => SizedBox(height: height.toDouble());

SizedBox horizontalSpace(num width) => SizedBox(width: width.toDouble());

SliverToBoxAdapter sliverVerticalSpace(num height) => SliverToBoxAdapter(
      child: SizedBox(height: height.toDouble()),
    );

SliverToBoxAdapter sliverHorizontalSpace(num width) => SliverToBoxAdapter(
      child: SizedBox(width: width.toDouble()),
    );

// Alias
SliverToBoxAdapter sliverHorzintoalSpace(num width) => sliverHorizontalSpace(width);
