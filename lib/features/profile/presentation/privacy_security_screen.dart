import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/sub_header.dart';

/// Privacy & Security screen. Displays readable Terms of Service and
/// Privacy Policy text within expandable cards.
class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(title: 'Privacy & Security', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                children: const [
                  _LegalSection(
                    icon:  Icons.description_outlined,
                    title: 'Terms of Service',
                    body:  _termsOfServiceText,
                  ),
                  SizedBox(height: 12),
                  _LegalSection(
                    icon:  Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    body:  _privacyPolicyText,
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

class _LegalSection extends StatefulWidget {
  final IconData icon;
  final String   title;
  final String   body;

  const _LegalSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  State<_LegalSection> createState() => _LegalSectionState();
}

class _LegalSectionState extends State<_LegalSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppTokens.bgCard,
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        border:       Border.all(color: AppTokens.border),
      ),
      child: Column(
        children: [
          // Header — always visible, tappable to expand/collapse
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTokens.rLg),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color:        AppTokens.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: AppTokens.blue, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                          style: const TextStyle(
                            color: AppTokens.tp, fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 1),
                        Text(
                          _expanded ? 'Tap to collapse' : 'Tap to read',
                          style: const TextStyle(color: AppTokens.ts, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns:    _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded, color: AppTokens.ts, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // Body — expandable text
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        AppTokens.bgEl.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTokens.rMd),
                  border:       Border.all(color: AppTokens.border),
                ),
                child: Text(
                  widget.body,
                  style: const TextStyle(
                    color:  AppTokens.ts,
                    fontSize: 12.5,
                    height:   1.55,
                  ),
                ),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legal text constants
// ---------------------------------------------------------------------------

const String _termsOfServiceText = '''
Last updated: May 2026

1. Acceptance of Terms
By accessing or using the Laventra mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.

2. Description of Service
Laventra provides a car wash monitoring and management platform that uses AI-powered detection to track vehicle washing events, device status, and operational analytics. The service is provided "as is" and may be updated or modified at any time.

3. User Accounts
You are responsible for maintaining the confidentiality of your account credentials. You agree to notify Laventra immediately of any unauthorized use of your account. You must provide accurate and complete information when creating your account.

4. Acceptable Use
You agree not to:
- Use the App for any unlawful purpose
- Attempt to gain unauthorized access to any systems or networks
- Interfere with or disrupt the integrity or performance of the App
- Reverse engineer, decompile, or disassemble any part of the App
- Share your account credentials with unauthorized persons

5. Data and Content
All data collected through the App, including device telemetry, event logs, and detection results, is owned by the account holder's organization. Laventra processes this data solely to provide and improve the service.

6. Intellectual Property
The App and its original content, features, and functionality are owned by Laventra and are protected by international copyright, trademark, and other intellectual property laws.

7. Limitation of Liability
Laventra shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the App. In no event shall Laventra's total liability exceed the amount paid by you for the service in the preceding 12 months.

8. Termination
Laventra reserves the right to terminate or suspend your account at any time, with or without cause, with or without notice.

9. Changes to Terms
Laventra reserves the right to modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the modified Terms.

10. Contact
For questions about these Terms, contact support@laventra.io.''';

const String _privacyPolicyText = '''
Last updated: May 2026

1. Information We Collect
Laventra collects the following types of information:
- Account information: name, email, phone number, and role
- Device data: camera status, connectivity logs, and telemetry
- Usage data: app interactions, feature usage, and session duration
- Detection data: AI-processed event results and confidence scores
- Biometric preferences: whether Face ID or Fingerprint is enabled (biometric data itself is never stored on our servers)

2. How We Use Your Information
We use collected information to:
- Provide and maintain the Laventra service
- Monitor car wash operations and generate reports
- Send notifications about device status and events
- Improve our AI detection models and App performance
- Communicate service updates and security alerts

3. Data Storage and Security
Your data is stored on secure servers with encryption at rest and in transit. Authentication tokens are stored in your device's secure keychain. We implement industry-standard security measures to protect your information.

4. Data Sharing
We do not sell your personal information. We may share data with:
- Your organization's administrators (within the same account)
- Service providers who assist in operating the App (under strict confidentiality)
- Law enforcement when required by law

5. Data Retention
We retain your data for as long as your account is active or as needed to provide services. You may request deletion of your data by contacting support.

6. Your Rights
You have the right to:
- Access the personal information we hold about you
- Request correction of inaccurate data
- Request deletion of your account and associated data
- Opt out of non-essential communications

7. Biometric Data
Laventra uses on-device biometric authentication (Face ID / Fingerprint) for convenience. Biometric data is processed entirely on your device and is never transmitted to or stored on Laventra servers.

8. Push Notifications
With your permission, we send push notifications for device alerts, event detections, and system updates. You can manage notification preferences within the App.

9. Children's Privacy
Laventra is not intended for use by individuals under 16 years of age. We do not knowingly collect personal information from children.

10. Changes to This Policy
We may update this Privacy Policy from time to time. We will notify you of any material changes through the App or via email.

11. Contact
For privacy-related questions or requests, contact privacy@laventra.io.''';
