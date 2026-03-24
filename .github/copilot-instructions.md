# TÂM AN - Copilot Instructions

TÂM AN is a Flutter emotion-tracking app with Vietnamese localization (心安 = "peace of mind"). Focus on the Vietnamese UI text and emotion/wellness domain logic.

## Architecture Overview

**Multi-screen navigation**: Login → EmotionFlow (emotion check-in) → Dashboard/Home → detailed analytics screens. See [lib/main.dart](lib/main.dart) for entry point. Most screens use simple MaterialApp without state management (no Provider/BLoC) - add state conditionally only if required.

**Theme centralization**: All UI styling (colors, shapes, fonts) lives in [lib/theme/app_theme.dart](lib/theme/app_theme.dart). Use `Theme.of(context).primaryColor` (blue #4A90E2) and `BorderRadius.circular(16)` (cards) consistently. AppBar is transparent with centered title.

## Key Patterns & Conventions

### Screen Structure
- Screens inherit `StatelessWidget` by default; use `StatefulWidget` only for forms/selections requiring state
- Each screen has a Scaffold with optional AppBar; body uses Padding(16-24px) for consistent margins
- Private helper widgets (prefixed `_`) handle cards/lists/sections within the main screen (see [dashboard_screen.dart](screens/dashboard_screen.dart#L38))
- Navigation: Use `Navigator.push/pushReplacement` directly (no named routes yet)

### Widget Reusables
- [AuthTextField](widgets/auth_textfield.dart): Auth forms only; has password visibility toggle
- [PrimaryButton](widgets/primary_button.dart): Full-width buttons with loading state support
- [EmotionCard](widgets/emotion_card.dart): Emotion selection with visual feedback (selected = blue border)
- Custom inline cards for dashboard summaries (see `_EmotionBox` in [dashboard_screen.dart](screens/dashboard_screen.dart#L66))

### Data Flow Patterns
- No explicit models/DTOs yet; UI receives inline hardcoded data (e.g., "Vui", "Căng thẳng", percentages)
- Future: When adding APIs, create `models/` directory; maintain Vietnamese labels as constants
- Screen callbacks use `VoidCallback` for simple events; extend to `Function(T)` for data passing if needed

## Styling & Localization

- **Colors**: Primary blue #4A90E2, background #F5F7FA, use ColorScheme.fromSeed for consistency
- **Spacing**: 8px (SizedBox.height), 12px gaps, 16px padding, 24px screen margins, 28px titles
- **Typography**: Roboto font (default); bold 28px for titles, 20px for subtitles, 16px body
- **Language**: All user-facing text is Vietnamese (no i18n framework—hardcoded strings fine for MVP)

## Common Tasks

### Adding a new emotion tracking screen
1. Create file in [lib/screens/](lib/screens/) (e.g., `new_checkin_screen.dart`)
2. Extend `StatelessWidget`; use Scaffold + AppBar + Padding layout
3. Reuse [EmotionCard](widgets/emotion_card.dart) for emotion selection or [PrimaryButton](widgets/primary_button.dart) for CTAs
4. Add navigation from existing screen using `Navigator.push`

### Modifying theme/colors
Update [lib/theme/app_theme.dart](lib/theme/app_theme.dart) `lightTheme` (Material3 enabled). All screens auto-inherit via `ThemeData` in [main.dart](main.dart#L14).

### Adding form fields
Use [AuthTextField](widgets/auth_textfield.dart) for login/register; for new domains, create lightweight custom TextField wrapper if needed (avoid redundant wrapper widgets).

## Build & Deployment

- **Platforms**: Android, iOS, Web, Linux, Windows (full Flutter multi-platform support)
- **Commands**: `flutter pub get`, `flutter run`, `flutter build apk/ios/web`
- **No CI/CD yet**: Manual builds required; check [android/build.gradle.kts](../android/build.gradle.kts) and [ios/Runner.xcodeproj](../ios/Runner.xcodeproj) for signing configs

## Avoid Common Mistakes

- **Don't** hardcode screen padding—wrap in `Padding(EdgeInsets.all(16))` consistently
- **Don't** create new button/input variants—extend [PrimaryButton](widgets/primary_button.dart) / [AuthTextField](widgets/auth_textfield.dart) with parameters
- **Don't** use `Navigator.of(context).push()` indirectly; use `Navigator.push()` directly
- **Don't** add state management library without team consensus; keep StatelessWidget default
