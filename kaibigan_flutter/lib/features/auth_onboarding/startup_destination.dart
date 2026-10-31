enum StartupDestination { loading, recovery, demo, authentication, setup, home }

abstract final class StartupDestinationPolicy {
  static StartupDestination choose({
    required bool loaded,
    required bool recovery,
    required bool canUseApp,
    required bool setupComplete,
    required bool demoSeen,
    bool reopenDemo = false,
  }) {
    if (!loaded) return StartupDestination.loading;
    if (recovery) return StartupDestination.recovery;
    if (canUseApp) {
      return setupComplete ? StartupDestination.home : StartupDestination.setup;
    }
    if (reopenDemo || !demoSeen) return StartupDestination.demo;
    return StartupDestination.authentication;
  }
}
