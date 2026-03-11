import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../models/question_model.dart';
import '../../providers/question_provider.dart';

class StudyModeSelector extends ConsumerStatefulWidget {
  const StudyModeSelector({super.key});

  @override
  ConsumerState<StudyModeSelector> createState() => _StudyModeSelectorState();
}

class _StudyModeSelectorState extends ConsumerState<StudyModeSelector> {
  TestType? _selectedTestType;
  Section? _selectedSection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose Your Test',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Test type selection
            Row(
              children: [
                Expanded(
                  child: _TestTypeCard(
                    type: TestType.sat,
                    isSelected: _selectedTestType == TestType.sat,
                    onTap: () => setState(() {
                      _selectedTestType = TestType.sat;
                      _selectedSection = null;
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TestTypeCard(
                    type: TestType.act,
                    isSelected: _selectedTestType == TestType.act,
                    onTap: () => setState(() {
                      _selectedTestType = TestType.act;
                      _selectedSection = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Section selection
            if (_selectedTestType != null) ...[
              Text(
                'Choose a Section',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ..._getSectionsForTest(_selectedTestType!).map((section) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SectionCard(
                    section: section,
                    testType: _selectedTestType!,
                    isSelected: _selectedSection == section,
                    onTap: () => setState(() => _selectedSection = section),
                  ),
                );
              }),
            ],

            const SizedBox(height: 32),

            // Start button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedTestType != null && _selectedSection != null
                    ? _startStudying
                    : null,
                child: const Text('Start Studying'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Section> _getSectionsForTest(TestType testType) {
    if (testType == TestType.sat) {
      return [Section.Math, Section.Reading, Section.Writing];
    } else {
      return [Section.Math, Section.Reading, Section.English, Section.Science];
    }
  }

  Future<void> _startStudying() async {
    if (_selectedTestType == null || _selectedSection == null) return;

    // Convert legacy TestType to ExamType for the provider
    final examType =
        _selectedTestType == TestType.sat ? ExamType.SAT : ExamType.ACT;
    final sectionName = _selectedSection!.displayName;

    // Start the session
    await ref.read(studySessionProvider.notifier).startSession(
          examType,
          sectionName,
        );

    if (!mounted) return;
    context.push(Routes.question);
  }
}

class _TestTypeCard extends StatelessWidget {
  final TestType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TestTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        type == TestType.sat ? AppTheme.primaryColor : AppTheme.secondaryColor;
    final label = type == TestType.sat ? 'SAT' : 'ACT';
    final description = type == TestType.sat
        ? 'Reading, Writing & Math'
        : 'English, Math, Reading & Science';

    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppTheme.textPrimary,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Section section;
  final TestType testType;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectionCard({
    required this.section,
    required this.testType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = _getSectionInfo(section);

    return Material(
      color: isSelected
          ? AppTheme.primaryColor.withValues(alpha: 0.1)
          : AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(info.icon, color: info.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      info.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  _SectionInfo _getSectionInfo(Section section) {
    switch (section) {
      case Section.Math:
        return _SectionInfo(
          name: 'Math',
          description: 'Algebra, geometry, and data analysis',
          icon: Icons.calculate,
          color: Colors.blue,
        );
      case Section.Reading:
        return _SectionInfo(
          name: 'Reading',
          description: 'Comprehension and analysis',
          icon: Icons.menu_book,
          color: Colors.green,
        );
      case Section.Writing:
        return _SectionInfo(
          name: 'Writing',
          description: 'Grammar and expression',
          icon: Icons.edit,
          color: Colors.orange,
        );
      case Section.Science:
        return _SectionInfo(
          name: 'Science',
          description: 'Scientific reasoning (ACT only)',
          icon: Icons.science,
          color: Colors.purple,
        );
      case Section.English:
        return _SectionInfo(
          name: 'English',
          description: 'Grammar and rhetoric (ACT only)',
          icon: Icons.spellcheck,
          color: Colors.teal,
        );
    }
  }
}

class _SectionInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  _SectionInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}
