# Design QA — Training Home Effects Prototype

- Source visual truth: `C:\Users\Administrator\.codex\generated_images\01a038c7-e0db-7580-addf-eb488795bc37\exec-8e0b9c1f-332e-4267-a1b7-2fd5255634ec.png`
- Implementation screenshot: `D:\projects\stopwatch\design-prototypes\training-home-effects\implementation-mobile-screen-fixed.png`
- Combined comparison: `D:\projects\stopwatch\design-prototypes\training-home-effects\design-qa-comparison.png`
- Browser URL: `http://localhost:4173/`
- State: iPhone preview, training tab selected, default FX intensity 86%, speed 55%, motion enabled
- CSS viewport: app screen `393 x 852`, device scale factor 1
- Source pixels: `853 x 1844`, normalized to `393 x 852` for comparison
- Implementation pixels: `393 x 852`

## Full-view comparison evidence

The implementation preserves the selected concept's hierarchy: date and workout heading, translucent training portal, lime progress/action, plan link, circular voice core, meal shortcut, and five-item floating dock. The mobile template's iPhone frame and live status chrome are intentionally present and are not app-content drift.

The animated background matches the approved direction through layered cyan/warm mist, sparse drifting particles, curved flow lines, portal breathing energy, and voice-state ripples. The web prototype adds an approval-only FX panel without changing the production-app specification.

## Focused-region comparison evidence

- Background: source has stronger static streaks and particle highlights; implementation uses lower-density moving particles and mist so the effect can be evaluated in motion.
- Training portal: composition, progress arc, hierarchy and CTA match; the source raster has finer glow detail than the code-native responsive portal.
- Bottom dock: order, floating translucent container and selected training capsule match. Runtime safe-area placement remains above the iOS home indicator.
- Voice core: circular form and subtitle match; clicking it changes the subtitle and activates expanding ripple states.

## Comparison history

### Iteration 1

- [P1] Floating navigation appeared at the top because the app shell did not inherit the template's `--mobile-safe-area-height` variable.
  - Fix: anchor it with the runtime-owned `--device-safe-area-bottom` token and add matching scroll content padding.
  - Post-fix evidence: the dock is fixed 44px above the screen bottom and remains above iOS chrome.
- [P1] Ambient effects were hidden behind the template's default white `.app-screen` surface.
  - Fix: make the app scroll surface transparent and place ambient layers below content but above the root background.
  - Post-fix evidence: cyan/warm mist and animated depth now remain visible across the screen.
- [P2] Initial particles and flow paths were too faint compared with the selected concept.
  - Fix: increase particle peak opacity, glow radius and flow-line contrast while keeping text regions clean.

### Final pass

- [P1] User review found the voice assistant and meal action below the visible first screen and partially obstructed by the dock.
  - Fix: compress the header, portal, CTA and assistant spacing; resize the voice and meal circles; reserve dock-safe bottom space.
  - Post-fix evidence: assistant bottom `398.1px`, meal bottom `444.3px`, dock top `478.9px`; both actions are fully above the dock.
- [P2] User review found the ambient motion too subtle to perceive at the default setting.
  - Fix: raise default intensity to 86%, add two animated light ribbons, increase mist opacity, and enlarge/brighten the moving particles.
  - Post-fix evidence: computed mist and particle transforms changed across a 900ms sample, and the default screenshot shows the cyan/warm flow bands without opening settings.

No actionable P0, P1 or P2 issues remain for the scoped approval prototype after the correction pass.

## Required fidelity surfaces

- Fonts and typography: hierarchy, weight and wrapping are consistent; browser uses the available mobile/system Chinese fallback rather than raster-source antialiasing.
- Spacing and layout rhythm: main regions, CTA, voice core and fixed dock follow the source proportions; mobile runtime chrome explains the visible top/bottom inset difference.
- Colors and visual tokens: pale cyan/warm ivory atmosphere, black text and `#BAFF00` primary accent are preserved.
- Image quality and asset fidelity: no source imagery was replaced with a placeholder. The selected visual contains no photographic assets; UI icons use the installed Radix icon set.
- Copy and content: all app-specific Chinese labels and navigation order match the selected concept.

## Primary interactions tested

- Open/close FX controls.
- Toggle reduced-motion mode.
- Activate/deactivate voice listening ripple.
- Start-training temporary feedback.
- Switch the selected bottom navigation item.
- Browser console checked: no warnings or errors.

## Follow-up polish

- [P3] Final Flutter implementation can tune blur and particle density against real GPU performance.
- [P3] Production icons should use the final Stopwatch icon set rather than prototype-library approximations.

final result: passed
