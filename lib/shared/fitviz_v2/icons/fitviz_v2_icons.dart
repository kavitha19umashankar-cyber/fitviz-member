/// FitViz v2 icon set — 22 single-stroke SVG icons extracted verbatim from
/// the redesign artifact's inline <symbol> defs, at
/// assets/fitviz/icons_v2/i-<name>.svg
enum FitVizV2Icon {
  home,
  dumbbell,
  grid,
  calendar,
  user,
  bell,
  flame,
  drop,
  smile,
  chart,
  doc,
  pin,
  phone,
  mail,
  briefcase,
  finger,
  lock,
  eye,
  chevron,
  play,
  check,
  stopwatch,
}

extension FitVizV2IconAsset on FitVizV2Icon {
  String get assetPath {
    switch (this) {
      case FitVizV2Icon.home:
        return 'assets/fitviz/icons_v2/i-home.svg';
      case FitVizV2Icon.dumbbell:
        return 'assets/fitviz/icons_v2/i-dumbbell.svg';
      case FitVizV2Icon.grid:
        return 'assets/fitviz/icons_v2/i-grid.svg';
      case FitVizV2Icon.calendar:
        return 'assets/fitviz/icons_v2/i-calendar.svg';
      case FitVizV2Icon.user:
        return 'assets/fitviz/icons_v2/i-user.svg';
      case FitVizV2Icon.bell:
        return 'assets/fitviz/icons_v2/i-bell.svg';
      case FitVizV2Icon.flame:
        return 'assets/fitviz/icons_v2/i-flame.svg';
      case FitVizV2Icon.drop:
        return 'assets/fitviz/icons_v2/i-drop.svg';
      case FitVizV2Icon.smile:
        return 'assets/fitviz/icons_v2/i-smile.svg';
      case FitVizV2Icon.chart:
        return 'assets/fitviz/icons_v2/i-chart.svg';
      case FitVizV2Icon.doc:
        return 'assets/fitviz/icons_v2/i-doc.svg';
      case FitVizV2Icon.pin:
        return 'assets/fitviz/icons_v2/i-pin.svg';
      case FitVizV2Icon.phone:
        return 'assets/fitviz/icons_v2/i-phone.svg';
      case FitVizV2Icon.mail:
        return 'assets/fitviz/icons_v2/i-mail.svg';
      case FitVizV2Icon.briefcase:
        return 'assets/fitviz/icons_v2/i-briefcase.svg';
      case FitVizV2Icon.finger:
        return 'assets/fitviz/icons_v2/i-finger.svg';
      case FitVizV2Icon.lock:
        return 'assets/fitviz/icons_v2/i-lock.svg';
      case FitVizV2Icon.eye:
        return 'assets/fitviz/icons_v2/i-eye.svg';
      case FitVizV2Icon.chevron:
        return 'assets/fitviz/icons_v2/i-chevron.svg';
      case FitVizV2Icon.play:
        return 'assets/fitviz/icons_v2/i-play.svg';
      case FitVizV2Icon.check:
        return 'assets/fitviz/icons_v2/i-check.svg';
      case FitVizV2Icon.stopwatch:
        return 'assets/fitviz/icons_v2/i-stopwatch.svg';
    }
  }
}
