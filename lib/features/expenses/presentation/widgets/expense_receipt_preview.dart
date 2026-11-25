import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qa3ty_app/core/networking/api_constants.dart';

class ExpenseReceiptPreview extends StatelessWidget {
  final String path;

  const ExpenseReceiptPreview({
    super.key,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'معاينة الإيصال',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPreview(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: _image(fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _image({
    required BoxFit fit,
    double? height,
  }) {
    final image = Uri.tryParse(path);
    final isNetworkImage =
        image != null && (image.scheme == 'http' || image.scheme == 'https');

    if (isNetworkImage || !File(path).existsSync()) {
      final resolvedPath = isNetworkImage
          ? path
          : Uri.parse(ApiConstants.apiBaseUrl).resolve(path).toString();
      return Image.network(
        resolvedPath,
        fit: fit,
        height: height,
        errorBuilder: _imageError,
      );
    }

    return Image.file(
      File(path),
      fit: fit,
      height: height,
      errorBuilder: _imageError,
    );
  }

  Widget _imageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const Center(child: Icon(Icons.broken_image_outlined));
  }

  void _showPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('معاينة الإيصال')),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  child: _image(
                    fit: BoxFit.contain,
                    height: MediaQuery.sizeOf(context).height * 0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
