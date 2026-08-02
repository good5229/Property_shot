bool bonusGoalReached({
  required int levelIndex,
  required int shotCount,
  required bool bumperHit,
  required bool switchPressed,
}) {
  if (shotCount <= 0) {
    return false;
  }
  return switch (levelIndex) {
    0 => shotCount <= 3,
    1 => bumperHit,
    _ => switchPressed,
  };
}
