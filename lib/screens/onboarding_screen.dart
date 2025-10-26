import 'package:flutter/material.dart';
// provider and auth_provider imports removed - not used in this screen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _OnboardPage(title: 'Welcome', body: 'Manage your contacts and never forget birthdays.'),
                  _OnboardPage(title: 'Reminders', body: 'Get reminders 3 times a day for upcoming birthdays.'),
                  _OnboardPage(title: 'Messages', body: 'Generate personalized messages for each relation.'),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.all(4.0),
                child: CircleAvatar(radius: 6, backgroundColor: _page==i? Theme.of(context).colorScheme.primary: Colors.grey[300]),
              )),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // mark onboarding done by navigating to auth
                  Navigator.of(context).pushReplacementNamed('/auth');
                },
                child: const Text('Get started'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String title;
  final String body;
  const _OnboardPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cake, size: 120, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
