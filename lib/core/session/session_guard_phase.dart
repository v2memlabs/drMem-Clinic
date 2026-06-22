/// Route guard için oturum fazı (mock: yalnızca unauthenticated / authenticated).
enum SessionGuardPhase {
  unauthenticated,
  initializing,
  authenticated,
  accountBlocked,
}
