import 'legal_section.dart';

abstract final class LegalContent {
  static const policyVersion = '2026-06';
  static const appName = 'Daily Wages';
  static const developer = 'Syntech';
  static const supportEmail = 'support_home@payqure.com';

  static const privacyPolicy = <LegalSection>[
    LegalSection(
      id: 'last_updated',
      title: 'Last Updated',
      body: 'June 2026\nPolicy Version: 2026-06\nCompany/Developer: Syntech',
    ),
    LegalSection(
      id: 'information_collected',
      title: 'Information We Collect',
      body:
          'The app may collect information you provide, including your name, phone number, email address, profile photo, service provider details, attendance records, wage information, payment records, notes, and comments.',
    ),
    LegalSection(
      id: 'information_not_collected',
      title: 'Information We Do NOT Collect',
      body:
          'The app does not collect bank passwords, UPI PINs, credit card details, Aadhaar numbers, PAN numbers, precise location, or device contacts unless explicitly introduced and permitted in a future version.',
    ),
    LegalSection(
      id: 'information_use',
      title: 'How We Use Your Information',
      body:
          'We use your information to maintain attendance records, calculate wages, manage payment history, generate summaries, sync data across devices, and enable sharing with connected service providers when you choose to use sync features.',
    ),
    LegalSection(
      id: 'data_ownership',
      title: 'Data Ownership',
      body:
          'You remain the owner of the data you create. Service provider records, attendance records, and payment records belong to the user who created them. If you connect with another user, shared access is limited to records related to that relationship.',
    ),
    LegalSection(
      id: 'cloud_sync',
      title: 'Cloud Synchronization',
      body:
          'If cloud sync is enabled, your data may be securely stored on our servers to provide backup and synchronization. If sync is not enabled, your data may remain only on your device.',
    ),
    LegalSection(
      id: 'third_party',
      title: 'Third-Party Services',
      body:
          'The app may use trusted services such as Supabase, Apple Sign In, Google Sign In, Apple iCloud, or Firebase. These services have their own privacy policies.',
    ),
    LegalSection(
      id: 'security',
      title: 'Data Security',
      body:
          'We use reasonable security measures to protect your data. However, no system is completely secure.',
    ),
    LegalSection(
      id: 'children',
      title: 'Children’s Privacy',
      body:
          'The app is intended for adults and is not designed for children under 13 years of age.',
    ),
    LegalSection(
      id: 'retention',
      title: 'Data Retention',
      body:
          'Your data is retained while your account remains active. If you delete your account or request deletion, your personal data will be deleted within a reasonable period unless retention is required by law.',
    ),
    LegalSection(
      id: 'rights',
      title: 'Your Rights',
      body:
          'You may access, update, export, or request deletion of your data. You may also disconnect shared service provider relationships.',
    ),
    LegalSection(
      id: 'deletion',
      title: 'Data Deletion Requests',
      body:
          'You can request deletion from More > Legal > Delete My Data or by contacting support.',
    ),
    LegalSection(
      id: 'changes',
      title: 'Changes to This Policy',
      body:
          'We may update this Privacy Policy from time to time. Updated versions will be available inside the app.',
    ),
    LegalSection(
      id: 'contact',
      title: 'Contact Us',
      body: 'For questions, contact $supportEmail.',
    ),
  ];

  static const termsDisclaimer = <LegalSection>[
    LegalSection(
      id: 'record_keeping',
      title: 'Record Keeping',
      body: 'The app is provided for record keeping and convenience only.',
    ),
    LegalSection(
      id: 'user_responsibility',
      title: 'Your Responsibility',
      body:
          'Users are responsible for verifying attendance, wages, salary details, calculations, and payments before relying on them.',
    ),
    LegalSection(
      id: 'no_professional_role',
      title: 'No Professional Relationship',
      body:
          'The app does not act as an employer, payroll provider, bank, payment provider, or legal advisor.',
    ),
    LegalSection(
      id: 'calculation_estimates',
      title: 'Calculation Estimates',
      body:
          'Calculations and summaries are estimates and should be reviewed by the user.',
    ),
    LegalSection(
      id: 'disputes',
      title: 'Service Disputes',
      body:
          'The app is not responsible for disputes between a customer and a service provider.',
    ),
    LegalSection(
      id: 'terms_contact',
      title: 'Contact Us',
      body: 'For questions, contact $supportEmail.',
    ),
  ];
}
