import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';

/// Shown when Apple (or social) login returns a user without email; saves via profile API.
class AddAppleEmailView extends StatefulWidget {
  const AddAppleEmailView({super.key});

  @override
  State<AddAppleEmailView> createState() => _AddAppleEmailViewState();
}

class _AddAppleEmailViewState extends State<AddAppleEmailView> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppPopUp.showToast(message: 'Please enter your email');
      return;
    }
    if (!isValidEmail(email)) {
      AppPopUp.showToast(message: 'Please enter a valid email');
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = Repository();
      final response = await repo.updateUserProfile({'email': email});
      if (!mounted) return;
      if (response.success == true) {
        AppPopUp.showToast(message: response.message ?? 'Email saved');
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.stagesView,
          (route) => false,
          arguments: {'fromLoginScreen': true},
        );
      } else {
        AppPopUp.showToast(
          message: response.message ?? 'Could not save email',
        );
      }
    } catch (e) {
      if (mounted) {
        AppPopUp.showToast(message: 'Something went wrong. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backGroundColor),
        child: Column(
          children: [
            CustomAppBar(
              centerTitle: true,
              title: const Text(
                'Add your email',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              backgroundClr: AppColors.transparent,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apple did not share an email. Enter the email you want on your account.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  textFieldTitle(title: 'Email'),
                  const SizedBox(height: 6),
                  CustomTextFormField(
                    controller: _emailController,
                    hintText: 'you@example.com',
                    textInputType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 30),
                  Button(
                    onTap: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save and continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
