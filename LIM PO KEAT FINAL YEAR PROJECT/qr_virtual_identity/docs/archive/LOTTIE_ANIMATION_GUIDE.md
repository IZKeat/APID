# Ticket Verification System - Lottie Animation Usage

## 📁 Animation Assets

To enhance the visual feedback of the ticket verification dialogs, you can add Lottie animations:

### Recommended Animations:

1. **Success Animation** (`assets/animations/success.json`)

   - Green checkmark animation
   - Bouncy/elastic effect
   - Duration: ~1.5 seconds

2. **Error Animation** (`assets/animations/error.json`)
   - Red X or exclamation mark
   - Shake/wiggle effect
   - Duration: ~1.5 seconds

### Implementation:

Replace the current `_AnimatedCheck` and `_AnimatedError` widgets in `ticket_verification_dialog.dart` with:

```dart
// Success animation
Lottie.asset(
  'assets/animations/success.json',
  width: 80,
  height: 80,
  repeat: false,
)

// Error animation
Lottie.asset(
  'assets/animations/error.json',
  width: 80,
  height: 80,
  repeat: false,
)
```

### Animation Sources:

- LottieFiles.com (Free): https://lottiefiles.com/featured
- Search for: "success checkmark", "error cross", "verification"
- Download as JSON format
- Place in `assets/animations/` folder

### Alternative:

The current implementation uses custom animated widgets with Material icons, which provides consistent Material Design 3 styling without external dependencies.
