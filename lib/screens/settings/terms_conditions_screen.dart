import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
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
              'Acceptance of Terms',
              'By downloading, installing, or using Flutter Tasker Pro ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App.',
            ),
            
            _buildSection(
              context,
              'License to Use',
              'We grant you a limited, non-exclusive, non-transferable, revocable license to use the App for personal, non-commercial purposes. You may not:\n\n'
              '• Modify, reverse engineer, or decompile the App\n'
              '• Remove any copyright or proprietary notices\n'
              '• Use the App for any illegal or unauthorized purpose\n'
              '• Attempt to gain unauthorized access to any portion of the App',
            ),
            
            _buildSection(
              context,
              'User Account',
              'To use certain features of the App, you must create an account using Firebase Authentication. You are responsible for:\n\n'
              '• Maintaining the confidentiality of your account credentials\n'
              '• All activities that occur under your account\n'
              '• Notifying us immediately of any unauthorized use\n'
              '• Ensuring your account information is accurate and up-to-date',
            ),
            
            _buildSection(
              context,
              'User Content',
              'You retain ownership of all tasks, notes, and content you create in the App ("User Content"). By using the App, you grant us the right to:\n\n'
              '• Store your User Content locally on your device\n'
              '• Sync your User Content across your devices using Firebase\n'
              '• Process your User Content to provide app features (reminders, exports, etc.)\n\n'
              'You are solely responsible for your User Content and must ensure it does not violate any laws or third-party rights.',
            ),
            
            _buildSection(
              context,
              'Advertisements',
              'The App displays advertisements through Google AdMob. By using the App, you acknowledge and agree that:\n\n'
              '• Advertisements will be displayed when you have internet connectivity\n'
              '• We have no control over the content of advertisements\n'
              '• We are not responsible for any products or services advertised\n'
              '• Clicking on ads is at your own risk',
            ),
            
            _buildSection(
              context,
              'Premium Features',
              'Certain features may require in-app purchases or subscription. All purchases are:\n\n'
              '• Processed through Google Play Store\n'
              '• Subject to Google Play\'s terms and refund policies\n'
              '• Non-refundable except as required by law\n'
              '• Limited to your personal use only',
            ),
            
            _buildSection(
              context,
              'Data and Privacy',
              'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your information. By using the App, you consent to our data practices as described in the Privacy Policy.',
            ),
            
            _buildSection(
              context,
              'Biometric Authentication',
              'If you enable biometric authentication (fingerprint, face recognition):\n\n'
              '• Biometric data is stored securely on your device only\n'
              '• We never access or store your biometric data on our servers\n'
              '• You are responsible for securing your device\n'
              '• We are not liable for unauthorized access due to device security breaches',
            ),
            
            _buildSection(
              context,
              'Disclaimer of Warranties',
              'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:\n\n'
              '• Merchantability or fitness for a particular purpose\n'
              '• Uninterrupted or error-free operation\n'
              '• Accuracy or reliability of content\n'
              '• Security of data transmission\n\n'
              'We do not guarantee that the App will meet your requirements or that defects will be corrected.',
            ),
            
            _buildSection(
              context,
              'Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR:\n\n'
              '• Any indirect, incidental, or consequential damages\n'
              '• Loss of data, profits, or business opportunities\n'
              '• Damages resulting from third-party advertisements\n'
              '• Unauthorized access to your account or device\n'
              '• Any damages exceeding the amount you paid for the App (if applicable)',
            ),
            
            _buildSection(
              context,
              'Termination',
              'We reserve the right to terminate or suspend your access to the App at any time, without notice, for:\n\n'
              '• Violation of these Terms and Conditions\n'
              '• Fraudulent or illegal activity\n'
              '• Any reason at our sole discretion\n\n'
              'Upon termination, you must cease all use of the App and delete it from your devices.',
            ),
            
            _buildSection(
              context,
              'Updates and Modifications',
              'We may update the App from time to time to:\n\n'
              '• Add new features or improve existing ones\n'
              '• Fix bugs or security vulnerabilities\n'
              '• Comply with legal requirements\n\n'
              'Updates may be required to continue using the App. We may also modify these Terms and Conditions at any time.',
            ),
            
            _buildSection(
              context,
              'Third-Party Services',
              'The App integrates with third-party services including:\n\n'
              '• Firebase (Google LLC) - Authentication and backend services\n'
              '• Google AdMob - Advertisement platform\n'
              '• WhatsApp - Customer support communication\n\n'
              'Use of these services is subject to their respective terms and conditions.',
            ),
            
            _buildSection(
              context,
              'Intellectual Property',
              'All intellectual property rights in the App, including but not limited to:\n\n'
              '• App design, code, and functionality\n'
              '• Logos, trademarks, and brand elements\n'
              '• Documentation and user guides\n\n'
              'are owned by us or our licensors. You may not use, copy, or distribute any of these elements without permission.',
            ),
            
            _buildSection(
              context,
              'Governing Law',
              'These Terms and Conditions are governed by and construed in accordance with the laws of Pakistan. Any disputes arising from these terms shall be resolved in the courts of Pakistan.',
            ),
            
            _buildSection(
              context,
              'Contact Information',
              'If you have questions about these Terms and Conditions, please contact us:\n\n'
              'Developer: Atif Choudhary\n'
              'WhatsApp: +92 327 0728950\n'
              'App: Flutter Tasker Pro\n'
              'Version: 1.0.0',
            ),
            
            _buildSection(
              context,
              'Severability',
              'If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.',
            ),
            
            _buildSection(
              context,
              'Entire Agreement',
              'These Terms and Conditions, together with our Privacy Policy, constitute the entire agreement between you and us regarding the use of the App.',
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Important Notice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By continuing to use Flutter Tasker Pro, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions and our Privacy Policy.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
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
