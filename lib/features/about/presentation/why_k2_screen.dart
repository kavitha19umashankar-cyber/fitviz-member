import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class WhyK2Screen extends StatelessWidget {
  const WhyK2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Why K2 Fitness Studio'),
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
                'WHY K2 FITNESS STUDIO?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Empowering people through fitness.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              const _Paragraph(
                'K2 Fitness Studio was built with one purpose—to empower '
                'individuals to become stronger, healthier, more confident, '
                'and more disciplined through fitness.',
              ),
              const SizedBox(height: 12),
              const _Paragraph(
                'We don’t just build physiques.\n'
                'We build lifestyles, confidence, discipline, and a stronger community.',
                emphasis: true,
              ),
              const _Section(
                title: 'OUR VISION',
                body:
                    'To become the most respected and successful fitness brand by '
                    'maintaining the highest standards of discipline, professionalism, '
                    'and service excellence.',
              ),
              const _Section(
                title: 'OUR MISSION',
                body:
                    'To transform lives, serve millions, and bring happiness through '
                    'fitness by helping every individual achieve a healthier, stronger, '
                    'and more confident life.',
              ),
              _Section(
                title: 'OUR VALUES',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _BulletItem(
                        'Conduct our business with fairness, integrity, and transparency.'),
                    _BulletItem(
                        'Maintain the highest standards of professionalism and excellence.'),
                    _BulletItem(
                        'Take responsibility for the well-being of our clients and employees.'),
                    _BulletItem(
                        'Foster a culture of respect, discipline, and continuous improvement.'),
                  ],
                ),
              ),
              const _Section(
                title: 'OUR BRAND PROMISE',
                body:
                    'Every member at K2 Fitness Studio will be treated equally—with '
                    'no favoritism or partiality.\n\n'
                    'We promise a welcoming environment where everyone feels '
                    'comfortable, respected, and confident to approach our trainers '
                    'for guidance and support.\n\n'
                    'Your success is our priority.',
              ),
              const _Section(
                title: 'OUR PURPOSE',
                body:
                    'To be the most respected fitness brand by upholding exceptional '
                    'standards, uncompromising quality, and strong work ethics.\n\n'
                    'We are committed to creating an environment where discipline, '
                    'professionalism, and genuine care help every member achieve '
                    'lasting transformation.',
              ),
              _Section(
                title: 'OUR PHILOSOPHY',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Paragraph(
                        'If you say we’re strict, we say it’s our standard.'),
                    const SizedBox(height: 12),
                    Text(
                      'Because standards create discipline.\n'
                      'Discipline creates consistency.\n'
                      'Consistency creates transformation.\n'
                      'And transformation changes lives.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 12),
          child ?? _Paragraph(body!),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  final bool emphasis;

  const _Paragraph(this.text, {this.emphasis = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.6,
            fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
            color: emphasis ? AppColors.textPrimary : AppColors.textSecondary,
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
