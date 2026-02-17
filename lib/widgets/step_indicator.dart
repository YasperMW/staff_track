import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final ThemeData theme;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Step numbers
        Row(
          children: List.generate(
            totalSteps,
            (index) => Expanded(
              child: Row(
                children: [
                  // Step circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= currentStep
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      border: Border.all(
                        color: index <= currentStep
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: index <= currentStep
                          ? index < currentStep
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                    ),
                  ),
                  // Connector line
                  if (index < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: index < currentStep
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Step labels
        Row(
          children: [
            Expanded(
              child: Text(
                'Personal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: currentStep >= 0 ? FontWeight.w600 : FontWeight.w400,
                  color: currentStep >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Contact',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: currentStep >= 1 ? FontWeight.w600 : FontWeight.w400,
                  color: currentStep >= 1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: currentStep >= 2 ? FontWeight.w600 : FontWeight.w400,
                  color: currentStep >= 2
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Employment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: currentStep >= 3 ? FontWeight.w600 : FontWeight.w400,
                  color: currentStep >= 3
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: currentStep >= 4 ? FontWeight.w600 : FontWeight.w400,
                  color: currentStep >= 4
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Security',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: currentStep >= 5 ? FontWeight.w600 : FontWeight.w400,
                  color: currentStep >= 5
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
