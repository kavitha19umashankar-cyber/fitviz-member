import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRIVACY POLICY',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 16),
              const _Paragraph(
                'K2 Fitness Studio ("we", "us", "our") is committed to protecting '
                'your privacy. This policy explains how we collect and use your '
                'personal information.',
              ),
              const _Section(
                title: '1. Information We Collect',
                body:
                    'We collect your name, phone number, and email address when '
                    'you fill out our contact form or message us on WhatsApp.',
              ),
              const _Section(
                title: '2. How We Use Your Information',
                body:
                    'Your information is used to respond to enquiries, provide '
                    'membership information, and send updates about our services '
                    'via WhatsApp or SMS.',
              ),
              const _Section(
                title: '3. WhatsApp Communications',
                body:
                    'By contacting us on WhatsApp or submitting your number via '
                    'our form (with consent checked), you agree to receive '
                    'messages from K2 Fitness Studio. You may opt out at any time '
                    'by replying STOP.',
              ),
              const _Section(
                title: '4. Data Sharing',
                body:
                    'We do not sell, rent, or share your personal information '
                    'with third parties.',
              ),
              const _Section(
                title: '5. Data Retention',
                body:
                    'We retain your data only as long as necessary to provide '
                    'our services.',
              ),
              const _Section(
                title: '6. Contact Us',
                body:
                    'For privacy-related concerns, email us at: info@kkfitness.in',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(color: AppColors.divider),
              ),
              Text(
                'DATA DELETION POLICY',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 16),
              const _Paragraph(
                'K2 Fitness Studio is committed to protecting your personal data '
                'and respecting your right to erasure in accordance with '
                'applicable data protection laws.',
              ),
              const _Section(
                title: 'What Data We Store',
                body:
                    'When you contact us via our enquiry form or WhatsApp, we may '
                    'store your name, phone number, preferred location, and any '
                    'message content you provide. This data is used solely to '
                    'respond to your enquiry and communicate with you about our '
                    'fitness services.',
              ),
              const _Section(
                title: 'How to Request Data Deletion',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Paragraph(
                        'You may request the deletion of your personal data at '
                        'any time by contacting us via any of the following '
                        'methods:'),
                    SizedBox(height: 10),
                    _BulletItem('Email: info@kkfitness.in'),
                    _BulletItem('WhatsApp: +91 81221 26376'),
                  ],
                ),
              ),
              const _Section(
                title: 'What Happens After a Request',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Paragraph(
                        'Once we receive a verified data deletion request, we will:'),
                    SizedBox(height: 10),
                    _BulletItem(
                        'Confirm receipt of your request within 48 hours.'),
                    _BulletItem(
                        'Permanently delete your personal data from our records within 30 days.'),
                    _BulletItem(
                        'Send you a confirmation once deletion is complete.'),
                  ],
                ),
              ),
              const _Section(
                title: 'WhatsApp Data',
                body:
                    'If you have contacted us via WhatsApp, your conversation '
                    'data is stored on Meta\'s servers and governed by '
                    'WhatsApp\'s Privacy Policy. To delete WhatsApp message '
                    'history, please use the WhatsApp app\'s built-in delete '
                    'feature or contact Meta directly.',
              ),
              const _Section(
                title: 'Retention Exceptions',
                body: 'We may retain certain data where required by law (e.g., '
                    'financial or tax records). In such cases, we will inform you '
                    'of what data must be retained and for how long.',
              ),
              const _Section(
                title: 'Contact for Data Requests',
                body:
                    'For all data deletion requests or privacy concerns, please '
                    'contact us at: info@kkfitness.in',
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  final Widget? child;

  const _Section({required this.title, this.body, this.child})
      : assert(body != null || child != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 10),
          child ?? _Paragraph(body!),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;

  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: AppColors.textSecondary,
          ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;

  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 10),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
