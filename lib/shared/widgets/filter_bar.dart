import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../layout/app_breakpoints.dart';
import 'premium_surface.dart';

/// Arama, filtre toggle, primary CTA ve isteğe bağlı collapsible filtre paneli.
class FilterBar extends StatefulWidget {
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget> filters;
  final Widget? trailing;

  /// Varsayılan false — mevcut ekranlar filtreleri her zaman gösterir.
  final bool collapsible;

  /// [collapsible] true iken ilk açılış durumu.
  final bool filtersInitiallyExpanded;

  /// Aktif filtre sayısı — toggle etiketi için.
  final int activeFilterCount;

  /// Varsa gösterilir (aktif filtre varken).
  final VoidCallback? onClearFilters;

  /// Kartsız workbench — dış panel/çerçeve yok, alt divider ile liste ayrılır.
  final bool flat;

  /// Kart alt iç boşluğu kaldırılır; dış margin liste aralığıyla (12px) kalır.
  final bool tightListSpacing;

  const FilterBar({
    super.key,
    this.searchHint = 'Ara',
    this.onSearchChanged,
    this.filters = const [],
    this.trailing,
    this.collapsible = false,
    this.filtersInitiallyExpanded = false,
    this.activeFilterCount = 0,
    this.onClearFilters,
    this.flat = false,
    this.tightListSpacing = false,
  });

  /// Arama, buton ve filtre alanları için ortak yükseklik.
  static const double controlHeight = 40;

  static const BorderRadius _controlRadius = BorderRadius.all(Radius.circular(8));

  static String filtersToggleLabel(int activeFilterCount) {
    if (activeFilterCount > 0) {
      return 'Filtreler · $activeFilterCount aktif';
    }
    return 'Filtreler';
  }

  static BoxDecoration controlShellDecoration(
    BuildContext context, {
    Color? fillColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: fillColor ?? AppColors.surfaceCard,
      border: Border.all(color: borderColor ?? AppColors.borderSoft),
      borderRadius: _controlRadius,
    );
  }

  static Widget controlShell({
    required BuildContext context,
    required Widget child,
    Color? fillColor,
    Color? borderColor,
    double? width,
    Key? key,
  }) {
    return SizedBox(
      key: key,
      width: width,
      height: controlHeight,
      child: DecoratedBox(
        decoration: controlShellDecoration(
          context,
          fillColor: fillColor,
          borderColor: borderColor,
        ),
        child: child,
      ),
    );
  }

  static ButtonStyle toolbarButtonStyle({
    required Color foregroundColor,
    Color backgroundColor = AppColors.surfaceCard,
    OutlinedBorder? shape,
    BorderSide? side,
  }) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(0, controlHeight),
      ),
      maximumSize: const WidgetStatePropertyAll(
        Size(double.infinity, controlHeight),
      ),
      fixedSize: const WidgetStatePropertyAll(
        Size.fromHeight(controlHeight),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 14, height: 1.0, color: foregroundColor),
      ),
      foregroundColor: WidgetStatePropertyAll(foregroundColor),
      iconColor: WidgetStatePropertyAll(foregroundColor),
      backgroundColor: WidgetStatePropertyAll(backgroundColor),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: shape != null
          ? WidgetStatePropertyAll(shape)
          : const WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: _controlRadius),
            ),
      side: side != null ? WidgetStatePropertyAll(side) : null,
    );
  }

  static ButtonStyle filledToolbarStyle() {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, controlHeight),
      maximumSize: const Size(double.infinity, controlHeight),
      fixedSize: const Size.fromHeight(controlHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: AppColors.primaryDeepTeal,
      foregroundColor: Colors.white,
      iconColor: Colors.white,
      textStyle: const TextStyle(
        fontSize: 14,
        height: 1.0,
        color: Colors.white,
      ),
      shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
    );
  }

  /// Toolbar sağındaki birincil CTA — tema padding'ini ezer, 40px yükseklik.
  static Widget primaryTrailing({
    required VoidCallback? onPressed,
    required String label,
    IconData icon = Icons.add_rounded,
  }) {
    return FilledButton.icon(
      style: filledToolbarStyle(),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  static Widget compactDropdown<T>({
    required BuildContext context,
    required double width,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return controlShell(
      context: context,
      width: width,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 14,
              height: 1.0,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          style: const TextStyle(
            fontSize: 14,
            height: 1.0,
            color: AppColors.textPrimary,
          ),
          iconEnabledColor: AppColors.textSecondary,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  late bool _filtersExpanded;

  static const double _stackTrailingBreakpoint =
      AppBreakpoints.filterStackTrailing;

  static const double _sideTrailingBreakpoint =
      AppBreakpoints.filterSideTrailing;

  static const double _searchMinWidth = 200;
  static const double _estimatedTrailingWidth = 280;

  @override
  void initState() {
    super.initState();
    _filtersExpanded = widget.collapsible
        ? widget.filtersInitiallyExpanded
        : true;
  }

  @override
  void didUpdateWidget(FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.collapsible && oldWidget.collapsible) {
      _filtersExpanded = true;
    }
  }

  bool get _hasFilters => widget.filters.isNotEmpty;

  bool get _showFilterPanel =>
      _hasFilters && (!widget.collapsible || _filtersExpanded);

  Widget _normalizeTrailing(Widget trailing) {
    return Theme(
      data: Theme.of(context).copyWith(
        visualDensity: VisualDensity.compact,
        filledButtonTheme: FilledButtonThemeData(
          style: FilterBar.filledToolbarStyle().merge(
            Theme.of(context).filledButtonTheme.style,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: FilterBar.toolbarButtonStyle(
            foregroundColor: AppColors.primaryDeepTeal,
            side: const BorderSide(color: AppColors.borderSoft),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: FilterBar.toolbarButtonStyle(
            foregroundColor: AppColors.textSecondary,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      child: trailing,
    );
  }

  Widget? _toolbarTrailing(double width) {
    final parts = <Widget>[];

    if (widget.collapsible && _hasFilters) {
      parts.add(
        OutlinedButton.icon(
          style: FilterBar.toolbarButtonStyle(
            foregroundColor: AppColors.primaryDeepTeal,
            side: const BorderSide(color: AppColors.borderSoft),
          ),
          onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
          icon: Icon(
            _filtersExpanded ? Icons.expand_less : Icons.filter_list_outlined,
            size: 18,
          ),
          label: Text(FilterBar.filtersToggleLabel(widget.activeFilterCount)),
        ),
      );
      if (widget.onClearFilters != null && widget.activeFilterCount > 0) {
        parts.add(
          TextButton(
            style: FilterBar.toolbarButtonStyle(
              foregroundColor: AppColors.textSecondary,
            ),
            onPressed: widget.onClearFilters,
            child: const Text('Filtreleri temizle'),
          ),
        );
      }
    }

    if (widget.trailing != null) {
      parts.add(_normalizeTrailing(widget.trailing!));
    }

    if (parts.isEmpty) return null;

    if (parts.length == 1) return parts.first;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: width < _stackTrailingBreakpoint
          ? WrapAlignment.end
          : WrapAlignment.start,
      children: parts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final toolbar = _toolbarTrailing(width);
        final sideTrailing =
            toolbar != null && width >= _sideTrailingBreakpoint;

        if (sideTrailing) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _searchField(context)),
                  const SizedBox(width: AppSpacing.sm),
                  toolbar,
                ],
              ),
              if (_showFilterPanel) ...[
                const SizedBox(height: AppSpacing.sm),
                _filterWrap(),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _searchAndTrailingRow(width, toolbar),
            if (_showFilterPanel) ...[
              const SizedBox(height: AppSpacing.sm),
              _filterWrap(),
            ],
          ],
        );
      },
    );

    if (widget.flat) {
      final footerGap =
          widget.tightListSpacing ? AppSpacing.xs : AppSpacing.sm;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          SizedBox(height: footerGap),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
        ],
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: widget.tightListSpacing
          ? const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              0,
            )
          : const EdgeInsets.all(AppSpacing.sm),
      decoration: PremiumSurface.filterPanel(),
      child: body,
    );
  }

  Widget _searchField(BuildContext context) {
    return FilterBar.controlShell(
      key: const Key('filter_bar_search_shell'),
      context: context,
      fillColor: AppColors.surfaceCard,
      child: SizedBox.expand(
        child: TextField(
          maxLines: 1,
          onChanged: widget.onSearchChanged,
          style: const TextStyle(
            fontSize: 14,
            height: 1.0,
            color: AppColors.textPrimary,
          ),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: widget.searchHint,
            hintStyle: TextStyle(
              fontSize: 14,
              height: 1.0,
              color: AppColors.textSecondary.withValues(alpha: 0.85),
            ),
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.only(right: 12),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: AppColors.textSecondary,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: FilterBar.controlHeight,
              maxHeight: FilterBar.controlHeight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchAndTrailingRow(double width, Widget? toolbar) {
    if (toolbar == null) {
      return _searchField(context);
    }

    if (width < _stackTrailingBreakpoint) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _searchField(context),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: toolbar,
          ),
        ],
      );
    }

    final searchMaxWidth = (width - _estimatedTrailingWidth - AppSpacing.sm)
        .clamp(_searchMinWidth, width);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: _searchMinWidth.clamp(0, width),
            maxWidth: searchMaxWidth,
          ),
          child: _searchField(context),
        ),
        toolbar,
      ],
    );
  }

  Widget _filterWrap() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: widget.filters,
    );
  }
}
