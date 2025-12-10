import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: December 10, 2025',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Introduction',
              'Flutter Tasker Pro ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
            ),
            
            _buildSection(
              context,
              'Information We Collect',
              'We collect the following types of information:\n\n'
              '• Account Information: Email address, name, and profile picture (optional)\n'
              '• Task Data: Tasks, subtasks, categories, and related information you create\n'
              '• Usage Data: App preferences, settings, and usage patterns\n'
              '• Device Information: Device type, operating system, and app version\n'
              '• Biometric Data: Fingerprint/face data (stored locally on your device only for authentication)',
            ),
            
            _buildSection(
              context,
              'How We Use Your Information',
              'We use your information to:\n\n'
              '• Provide and maintain our service\n'
              '• Authenticate your account using Firebase Authentication\n'
              '• Sync your tasks across devices\n'
              '• Send task reminders and notifications\n'
              '• Improve app functionality and user experience\n'
              '• Display personalized advertisements (with internet connection)',
            ),
            
            _buildSection(
              context,
              'Data Storage and Security',
              '• Local Storage: All task data is stored locally on your device using SQLite database\n'
              '• Firebase: Account credentials are securely stored using Firebase Authentication\n'
              '• Biometric Data: Never leaves your device and is managed by your device\'s secure enclave\n'
              '• Encryption: All data transmissions are encrypted using industry-standard protocols',
            ),
            
            _buildSection(
              context,
              'Third-Party Services',
              'We use the following third-party services:\n\n'
              '• Firebase Authentication: For secure user authentication\n'
              '• Google AdMob: For displaying advertisements (only when internet is available)\n'
              '• Firebase Services: For app analytics and crash reporting\n\n'
              'These services have their own privacy policies and we encourage you to review them.',
            ),
            
            _buildSection(
              context,
              'Advertising',
              'We use Google AdMob to display advertisements in our app. AdMob may collect and use certain data for ad personalization. Ads are only displayed when you have an active internet connection. You can learn more about Google\'s privacy practices at https://policies.google.com/privacy',
            ),
            
            _buildSection(
              context,
              'Your Rights',
              'You have the right to:\n\n'
              '• Access your personal data\n'
              '• Delete your account and all associated data\n'
              '• Export your tasks to CSV or PDF format\n'
              '• Opt-out of personalized advertisements\n'
              '• Request data corrections',
            ),
            
            _buildSection(
              context,
              'Data Retention',
              'We retain your data as long as your account is active. When you delete your account, all associated data is permanently removed from our servers and your device.',
            ),
            
            _buildSection(
              context,
              'Children\'s Privacy',
              'Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
            ),
            
            _buildSection(
              context,
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last updated" date. Continued use of the app constitutes acceptance of the updated policy.',
            ),
            
            _buildSection(
              context,
              'Contact Us',
              'If you have questions about this Privacy Policy, please contact us:\n\n'
              'WhatsApp: +92 327 0728950\n'
              'Developer: Atif Choudhary\n'
              'App: Flutter Tasker Pro',
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
