# Welcome animation assets

Drop the MiniMax (Hailuo) generated clips here, named to match
`WelcomeAnimationScreen._assetForGoal` in
`lib/screens/welcome_animation_screen.dart`:

- `goal_weight_loss.mp4` — 减脂
- `goal_muscle_gain.mp4` — 增肌
- `goal_toning.mp4` — 塑形
- `goal_endurance.mp4` — 体能
- `goal_recovery.mp4` — 恢复

No code changes needed — the screen loads whichever file is present and
falls back to a simple in-app animation if the file is missing.
