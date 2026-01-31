---
inclusion: always
---

# Babyland Flutter Design System Rules

This document defines the design system structure and integration guidelines for the Babyland Flutter application when working with Figma designs.

## Design System Structure

### 1. Token Definitions

**Color Tokens** - Located in `lib/app/theme/app_colors.dart`
```dart
// Primary brand colors
static const Color primary = Color(0xFFFAC8F1);
static const Color backgroundClr1 = Color(0xFFFAC8F1);
static const Color backgroundClr2 = Color(0xFFFFDCCE);
static const Color buttonClr1 = Color(0xFFF8926C);
static const Color buttonClr2 = Color(0xFFFF48DD);

// Text colors
static const Color textClr = Color(0xFF1E293B);
static const Color textLightClr = Color(0xFF5B6679);

// Gradients
static LinearGradient buttonClr = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    AppColors.buttonClr1.withValues(alpha: 0.9),
    AppColors.buttonClr2.withValues(alpha: 0.6),
  ],
);
```

**Typography Tokens** - Located in `lib/app/theme/font_style.dart`
- Uses Gilroy font family with 10 weight variants (UltraLight to Black)
- Systematic naming: `text_{size}_{weight}` (e.g., `text_16_400`, `text_24_600`)
- Default line height: 1.4
- Font families defined in `lib/app/theme/font_family.dart`

**Spacing & Layout**
- Uses Flutter's standard EdgeInsets and padding system
- Common patterns: `EdgeInsets.symmetric(vertical: 14, horizontal: 24)`
- Border radius: Default 8px for inputs, 100px for buttons

### 2. Component Library

**Location**: `lib/app/widgets/`

**Core Components**:
- `Button` - Customizable button with gradient support
- `CustomTextFormField` - Form input with validation
- `GradientText` - Text with gradient effects
- `CustomAppBar` - Application header component

**Component Architecture**:
```dart
// Example Button component structure
class Button extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Gradient? gradient;
  final void Function()? onTap;
  // ... other properties
}
```

### 3. Framework & Libraries

**Primary Framework**: Flutter 3.9.2+
**Key Dependencies**:
- `flutter_svg: ^2.2.1` - SVG asset handling
- `cached_network_image: ^3.4.1` - Image optimization
- `provider: ^6.1.5+1` - State management
- `firebase_core: ^4.2.0` - Backend integration

### 4. Asset Management

**Images**: `assets/images/` directory
- SVG icons and illustrations
- PNG images for complex graphics
- Naming convention: descriptive names (e.g., `baby_growth.svg`, `calendar.svg`)

**Fonts**: `assets/fonts/` directory
- Complete Gilroy font family (10 weights)
- Registered in `pubspec.yaml` with family names

### 5. Icon System

**Storage**: `assets/images/` (mixed with other assets)
**Format**: Primarily SVG for scalability
**Usage**: Via `flutter_svg` package
**Naming**: Descriptive names (e.g., `heart.svg`, `notification.png`)

### 6. Styling Approach

**Method**: Custom theme classes with static methods
**Global Styles**: Centralized in theme directory
**Responsive Design**: Flutter's built-in responsive widgets
**Color System**: Static color constants with gradient support

### 7. Project Structure

```
lib/
├── app/
│   ├── theme/           # Design tokens
│   │   ├── app_colors.dart
│   │   ├── font_family.dart
│   │   └── font_style.dart
│   ├── widgets/         # Reusable components
│   ├── view/           # Screen components
│   ├── controller/     # Business logic
│   └── data/          # Data layer
└── main.dart
```

## Figma Integration Guidelines

### When Converting Figma Designs to Flutter:

1. **Color Mapping**:
   - Map Figma colors to `AppColors` constants
   - Use existing gradients from `AppColors.buttonClr`, `AppColors.pinkPurple`
   - Prefer design system colors over hardcoded values

2. **Typography Conversion**:
   - Convert Figma text styles to `AppFontStyle` methods
   - Match font weights: 300→w300, 400→w400, 500→w500, 600→w600, 800→w800
   - Use appropriate Gilroy font family variants

3. **Component Reuse**:
   - Use existing `Button` component instead of creating new buttons
   - Leverage `CustomTextFormField` for all input fields
   - Apply `GradientText` for branded text elements

4. **Spacing & Layout**:
   - Use Flutter's `EdgeInsets` for padding/margins
   - Apply consistent border radius (8px inputs, 100px buttons)
   - Maintain design system spacing patterns

5. **Asset Integration**:
   - Place new assets in appropriate `assets/` subdirectories
   - Use SVG format for icons when possible
   - Follow existing naming conventions

### Code Generation Rules:

- **Replace** hardcoded colors with `AppColors` constants
- **Replace** inline text styles with `AppFontStyle` methods
- **Reuse** existing widget components where applicable
- **Maintain** 1:1 visual parity with Figma designs
- **Validate** final implementation against Figma screenshots

### State Management:
- Use `Provider` pattern for state management
- Follow existing controller structure in `lib/app/controller/`
- Maintain separation between UI and business logic