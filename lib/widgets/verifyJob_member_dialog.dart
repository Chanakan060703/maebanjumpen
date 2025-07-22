// lib/widgets/verifyJob_member_dialog.dart
import 'package:flutter/material.dart';
import 'package:maebanjumpen/styles/finishJobStyles.dart'; // <<< สำคัญมาก: ต้อง Import ไฟล์ Styles/Localizations

class ConfirmFinishJobAlert extends StatefulWidget {
  final ValueChanged<BuildContext> onConfirm;
  final AppLocalizations localizations; // ต้องมี AppLocalizations เพื่อการแปลภาษา

  const ConfirmFinishJobAlert({
    super.key,
    required this.onConfirm,
    required this.localizations,
  });

  @override
  _ConfirmFinishJobAlertState createState() => _ConfirmFinishJobAlertState();
}

class _ConfirmFinishJobAlertState extends State<ConfirmFinishJobAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        backgroundColor: AppColors.white, // ใช้ AppColors.white
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacings.dialogBorderRadius),
        ),
        contentPadding: const EdgeInsets.all(AppSpacings.large),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: AppSpacings.avatarRadius,
              backgroundColor: AppColors.lightRedBackground,
              child: const Icon(Icons.check, color: AppColors.primaryRed, size: 40.0),
            ),
            const SizedBox(height: AppSpacings.medium),
            Text(
              widget.localizations.getConfirmFinishJobDialogTitle(),
              textAlign: TextAlign.center,
              style: AppTextStyles.dialogTitle,
            ),
            const SizedBox(height: AppSpacings.small),
            Text(
              widget.localizations.getConfirmFinishJobDialogMessage(),
              textAlign: TextAlign.center,
              style: AppTextStyles.dialogMessage,
            ),
            const SizedBox(height: AppSpacings.large),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacings.buttonBorderRadius),
                      ),
                      side: const BorderSide(color: AppColors.lightGreyBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        widget.localizations.getCancelButton(),
                        style: AppTextStyles.dialogButtonTextBlack,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacings.medium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onConfirm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacings.buttonBorderRadius),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        widget.localizations.getConfirmButton(),
                        style: AppTextStyles.buttonTextWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}