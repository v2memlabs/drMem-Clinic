/// Timeline liste hata/boş durumu — kullanıcıya gösterilecek metinler.
class TimelineListFailurePresentation {
  final String title;
  final String description;
  final bool showRetry;

  const TimelineListFailurePresentation({
    required this.title,
    this.description = '',
    this.showRetry = true,
  });
}
