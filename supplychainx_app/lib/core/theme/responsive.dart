import 'package:flutter/material.dart';

/// Standard Responsive Breakpoints for SupplyChainX
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  static const double smallMobile = 380;
  static const double mobile = 640;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

/// Extension on BuildContext for quick, ergonomic responsive queries
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isSmallMobile => screenWidth < ResponsiveBreakpoints.smallMobile;
  bool get isMobile => screenWidth < ResponsiveBreakpoints.mobile;
  bool get isTablet =>
      screenWidth >= ResponsiveBreakpoints.mobile &&
      screenWidth < ResponsiveBreakpoints.tablet;
  bool get isDesktop => screenWidth >= ResponsiveBreakpoints.tablet;
  bool get isWideDesktop => screenWidth >= ResponsiveBreakpoints.desktop;

  /// Returns true when on desktop or tablet (landscape / wide viewports)
  bool get isMediumOrWider => screenWidth >= ResponsiveBreakpoints.mobile;

  /// Selects a value based on the active screen size tier
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? wide,
  }) {
    if (isWideDesktop && wide != null) return wide;
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

/// Adaptive page wrapper that constraints max width on wide displays (ultrawide/4K)
/// while providing ergonomic gutter padding across mobile and desktop.
class ResponsivePageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsivePageContainer({
    super.key,
    required this.child,
    this.maxWidth = 1320,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPad = context.responsiveValue<double>(
      mobile: 14,
      tablet: 20,
      desktop: 28,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 16),
          child: child,
        ),
      ),
    );
  }
}

/// An adaptive grid that computes columns and child aspect ratios dynamically
/// based on available width, preventing RenderFlex overflow on small devices.
class ResponsiveKpiGrid extends StatelessWidget {
  final List<Widget> children;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveKpiGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final int columns;
        final double aspectRatio;

        if (w < 340) {
          columns = 1;
          aspectRatio = 2.7;
        } else if (w < 680) {
          columns = 2;
          aspectRatio = 1.45;
        } else if (w < 1050) {
          columns = children.length <= 2 ? 2 : (w < 850 ? 2 : 3);
          aspectRatio = 1.85;
        } else {
          columns = children.length <= 3 ? children.length : 4;
          aspectRatio = 2.15;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: children,
        );
      },
    );
  }
}

/// Automatically renders children as a Row on wider screens and as a Column on mobile
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final CrossAxisAlignment rowCrossAxisAlignment;
  final MainAxisAlignment rowMainAxisAlignment;
  final CrossAxisAlignment columnCrossAxisAlignment;
  final double spacing;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.breakpoint = 580,
    this.rowCrossAxisAlignment = CrossAxisAlignment.start,
    this.rowMainAxisAlignment = MainAxisAlignment.start,
    this.columnCrossAxisAlignment = CrossAxisAlignment.stretch,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isRow = constraints.maxWidth >= breakpoint;
        if (isRow) {
          return Row(
            crossAxisAlignment: rowCrossAxisAlignment,
            mainAxisAlignment: rowMainAxisAlignment,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(child: children[i]),
              ],
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: columnCrossAxisAlignment,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
      },
    );
  }
}
