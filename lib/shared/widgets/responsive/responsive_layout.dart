import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

/// A responsive layout widget that centers content and applies max width constraints
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centerContent;
  final Color? backgroundColor;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? context.contentMaxWidth;
    final effectivePadding = padding ?? context.responsivePadding;

    Widget content = Padding(
      padding: effectivePadding,
      child: child,
    );

    if (effectiveMaxWidth != double.infinity && centerContent) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: content,
        ),
      );
    }

    if (backgroundColor != null) {
      content = Container(
        color: backgroundColor,
        child: content,
      );
    }

    return content;
  }
}

/// A responsive scrollable layout
class ResponsiveScrollableLayout extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centerContent;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;

  const ResponsiveScrollableLayout({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
    this.scrollController,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: physics,
      child: ResponsiveLayout(
        maxWidth: maxWidth,
        padding: padding,
        centerContent: centerContent,
        child: child,
      ),
    );
  }
}

/// A responsive form layout with optimized max width for forms
class ResponsiveFormLayout extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const ResponsiveFormLayout({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? context.formMaxWidth;
    final effectivePadding = padding ?? context.responsivePadding;

    Widget content = Padding(
      padding: effectivePadding,
      child: child,
    );

    content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: content,
      ),
    );

    if (scrollable) {
      return SingleChildScrollView(child: content);
    }

    return content;
  }
}

/// A responsive grid layout
class ResponsiveGridLayout extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveGridLayout({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.childAspectRatio = 1.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return GridView.builder(
      padding: padding ?? context.responsivePadding,
      physics: physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// A responsive sliver grid
class ResponsiveSliverGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  const ResponsiveSliverGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
    );
  }
}

/// A two-pane layout for master-detail views
class ResponsiveTwoPaneLayout extends StatelessWidget {
  final Widget masterPane;
  final Widget? detailPane;
  final double masterPaneWidth;
  final bool showDetailOnMobile;

  const ResponsiveTwoPaneLayout({
    super.key,
    required this.masterPane,
    this.detailPane,
    this.masterPaneWidth = 350,
    this.showDetailOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return showDetailOnMobile && detailPane != null ? detailPane! : masterPane;
    }

    return Row(
      children: [
        SizedBox(
          width: masterPaneWidth,
          child: masterPane,
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: detailPane ??
              Center(
                child: Text(
                  'Select an item',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
        ),
      ],
    );
  }
}

/// A responsive row that wraps on mobile
class ResponsiveRowWrap extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final double runSpacing;
  final WrapAlignment wrapAlignment;

  const ResponsiveRowWrap({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16,
    this.runSpacing = 16,
    this.wrapAlignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Wrap(
        alignment: wrapAlignment,
        spacing: spacing,
        runSpacing: runSpacing,
        children: children,
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children
          .map((child) => Padding(
                padding: EdgeInsets.only(right: spacing),
                child: child,
              ))
          .toList(),
    );
  }
}

/// Adaptive container that changes between Card and plain container based on screen size
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool useCardOnMobile;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.useCardOnMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(16);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    if (context.isMobile && !useCardOnMobile) {
      return Container(
        margin: margin,
        padding: effectivePadding,
        child: child,
      );
    }

    return Card(
      margin: margin ?? EdgeInsets.zero,
      color: color,
      elevation: elevation ?? (context.isMobile ? 1 : 2),
      shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );
  }
}
