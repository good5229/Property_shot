bool bonusGoalReached({
  required int levelIndex,
  required int shotCount,
  required bool bumperHit,
  required bool switchPressed,
  bool drainedSourceMoved = false,
}) {
  if (shotCount <= 0) {
    return false;
  }
  return switch (levelIndex) {
    0 => shotCount <= 3,
    1 => bumperHit,
    2 || 3 => switchPressed,
    4 => drainedSourceMoved,
    _ => false,
  };
}
