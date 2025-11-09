import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hotspot_hosts/screens/onboarding_screen.dart';
import 'package:hotspot_hosts/services/api_service.dart';
import 'package:hotspot_hosts/widget/background.dart';
import 'package:hotspot_hosts/models/experience_model.dart';
import 'package:hotspot_hosts/widget/app_bar.dart';
import 'dart:math';
import 'package:flutter/services.dart';
//fetching data from api
final experiencesProvider = FutureProvider<List<Experiences>>((ref) async {
  final api = ApiService();
  final result = await api.fetchExperiences(); 
  return result.data?.experiences ?? [];
});

final selectedExperiencesProvider = StateProvider<List<int>>((ref) => []);
final descriptionProvider = StateProvider<String>((ref) => '');
final animatedExperiencesProvider =
    StateProvider<List<Experiences>>((ref) => []);

class ExperienceSelectionScreen extends ConsumerStatefulWidget {
  const ExperienceSelectionScreen({super.key});

  @override
  ConsumerState<ExperienceSelectionScreen> createState() =>
      _ExperienceSelectionScreenState();
}

class _ExperienceSelectionScreenState
    extends ConsumerState<ExperienceSelectionScreen> {
  bool showGradient = false;
  bool isHovering = false;

  List<Experiences> reorderedExperiences(
      List<Experiences> experiences, List<int> selectedIds) {
    if (selectedIds.isEmpty) return experiences;
    final selectedId = selectedIds.first;
    final selected = experiences.firstWhere(
      (e) => e.id == selectedId,
      orElse: () => experiences.first,
    );
    final others = experiences.where((e) => e.id != selectedId).toList();
    return [selected, ...others];
  }

  @override
  Widget build(BuildContext context) {
    final experiencesAsync = ref.watch(experiencesProvider);
    final selectedIds = ref.watch(selectedExperiencesProvider);
    final description = ref.watch(descriptionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: DiagonalWavyBackground(
        child: experiencesAsync.when(
          data: (experiences) {

            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

            return LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomAppBar(
                      progressPercent: 0.3,
                      useGradient: showGradient,
                    ),
                    Expanded(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        padding:
                            EdgeInsets.only(bottom: max(0, keyboardHeight + 10)),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: availableHeight - 95, 
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 220),
                                  const Text(
                                    "01",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    "What kind of experiences do you want to host?",
                                    style: TextStyle(
                                      fontFamily: 'Space Grotesk',
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      height: 32 / 24,
                                      letterSpacing: -0.02,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 100,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 400),
                                      child: Consumer(
                                        builder: (context, ref, _) {
                                          final selectedIds =
                                              ref.watch(selectedExperiencesProvider);

                                          final reorderedExperiences = [
                                            ...experiences.where((e) =>
                                                selectedIds.contains(e.id)),
                                            ...experiences.where((e) =>
                                                !selectedIds.contains(e.id)),
                                          ];

                                          return ListView.separated(
                                            key: ValueKey(selectedIds.join(',')),
                                            scrollDirection: Axis.horizontal,
                                            itemCount: reorderedExperiences.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 12),
                                            itemBuilder: (context, idx) {
                                              final exp =
                                                  reorderedExperiences[idx];
                                              final isSelected =
                                                  selectedIds.contains(exp.id);

                                              return GestureDetector(
                                                onTap: () {
                                                  final ids =
                                                      List<int>.from(selectedIds);
                                                  if (isSelected) {
                                                    ids.remove(exp.id);
                                                  } else {
                                                    ids.insert(0, exp.id);
                                                  }
                                                  ref
                                                      .read(selectedExperiencesProvider
                                                          .notifier)
                                                      .state = ids;
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 350),
                                                  curve: Curves.easeInOut,
                                                  width: 96,
                                                  height: 96,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? Colors.blueAccent
                                                          : Colors.transparent,
                                                      width: 2,
                                                    ),
                                                    image: DecorationImage(
                                                      image: exp.imageUrl.isNotEmpty
                                                          ? NetworkImage(exp.imageUrl)
                                                          : const AssetImage(
                                                                  'assets/placeholder.png')
                                                              as ImageProvider,
                                                      fit: BoxFit.contain,
                                                      colorFilter: isSelected
                                                          ? null
                                                          : const ColorFilter.mode(
                                                              Colors.grey,
                                                              BlendMode.saturation,
                                                            ),
                                                    ),
                                                    boxShadow: [
                                                      if (isSelected)
                                                        BoxShadow(
                                                          color: Colors.blueAccent
                                                              .withOpacity(0.4),
                                                          blurRadius: 10,
                                                          offset: const Offset(0, 4),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 390,
                                      maxHeight: 159,
                                    ),
                                    child: TextField(
                                      maxLines: null,
                                      textAlignVertical: TextAlignVertical.top,
                                      expands: true,
                                      maxLength: 600,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(600),
                                      ],
                                      buildCounter: (
                                        BuildContext context, {
                                        required int currentLength,
                                        required bool isFocused,
                                        required int? maxLength,
                                      }) {
                                        return null; 
                                      },
                                      decoration: InputDecoration(
                                        hintText:
                                            "/ Describe your perfect hotspot",
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0.3,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[850],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color.fromRGBO(145, 150, 255, 1),
                                            width: 1.2,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 16),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      onChanged: (value) => ref
                                          .read(descriptionProvider.notifier)
                                          .state = value,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => isHovering = true),
                                    onExit: (_) =>
                                        setState(() => isHovering = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 390,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isHovering
                                              ? [
                                                  Colors.black.withOpacity(0.8),
                                                  Colors.white.withOpacity(0.9),
                                                  Colors.black.withOpacity(0.8),
                                                ]
                                              : [
                                                  Colors.black.withOpacity(0.6),
                                                  Colors.white.withOpacity(0.4),
                                                  Colors.black.withOpacity(0.6),
                                                ],
                                          stops: const [0.0, 0.3, 1.0],
                                        ),
                                        boxShadow: isHovering
                                            ? [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  blurRadius: 14,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 2),
                                                )
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                )
                                              ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const OnboardingSelectionScreen(),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: const BorderSide(
                                              color: Colors.white,
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Next",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward,
                                                color: Colors.white),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          error: (err, _) => Center(
            child: Text(
              'Error loading experiences: $err',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
