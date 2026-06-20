class LayoutService {
  int getGridColumns(int participantCount) {
    if (participantCount <= 1) return 1;
    if (participantCount <= 4) return 2;
    return 3;
  }

  double getThumbnailWidth(double screenWidth, int participantCount) {
    const maxWidth = 160.0;
    final available = screenWidth - (participantCount + 1) * 8;
    final perItem = available / participantCount;
    return perItem > maxWidth ? maxWidth : perItem;
  }
}
