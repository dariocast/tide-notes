# Tide Organic Visual Foundation Design

**Date:** 2026-07-22  
**Status:** Approved in design review  
**Scope:** Visual foundation, themes, typography, viewport depth, motion policy, component refinement, and test-suite simplification

## Intent

Evolve Tide from a technically clean but visually rigid baseline into a softer, calmer, more organic notes experience. Borrow the strongest interaction principles visible in the supplied Gravity screenshots—compact capture, flat stream, quiet metadata, progressive disclosure, inline editing, and theme choice—without copying Gravity's branding, exact palette, typography, assets, or mobile-only composition.

Tide must feel like its name: foam, mist, depth, changing water, and resurfacing. The result should remain restrained. No literal wave ornaments, nautical illustrations, decorative logos, glassmorphism, or novelty motion.

## Scope Boundaries

This design includes:

- a new Atlantic visual system;
- Quicksand and Nunito typography;
- light, dark, OLED, and system theme selection;
- viewport-relative sinking treatment;
- a corrected reduced-motion policy;
- softer header, composer, note-row, hover, focus, empty-state, and settings treatments;
- preservation of the mobile vertical and macOS split layouts;
- removal of redundant and implementation-fragile tests.

Search is intentionally excluded. It will receive a separate design and implementation cycle after this visual foundation is complete. Domain behavior, persistence schema, note ordering, append, edit, rescue, and undo semantics remain unchanged.

## Competitive Study

The supplied screenshots show four useful Gravity patterns:

- `home-overview.jpeg`: compact centered identity, count/date hierarchy, shallow composer, flat notes, quiet separators, prefix color, and dense metadata;
- `home+searchbar.jpeg`: search as a temporary stream mode with immediate results and inline term highlighting;
- `light-dark-oled-themes.jpeg`: theme choice expressed through the whole surface system rather than a color accent alone;
- `note-editing-creating-ui.jpeg`: capture and inline editing remain visually inside the stream rather than opening a separate editor screen.

Tide will adopt the underlying principles, not the exact arrangements. Its macOS split composition, ocean palette, viewport depth effect, type pairing, theme names, and rescue model provide independent product identity.

## Visual Direction

The chosen direction is **Tide-native restraint**. Organic character comes from typography, color relationships, spacing rhythm, continuous surfaces, and controlled depth—not from decorative symbols.

### Shape Language

- Composer: soft capsule-like surface with an 18–22 logical-pixel radius and a circular append action.
- Buttons and settings choices: pills or softly rounded rectangles; never sharp zero-radius boxes.
- Note stream: flat rows with no card shell, hard left rail, or drop shadow.
- Separators: low-contrast hairlines that may fade with viewport depth.
- Hover/focus: a soft blue-water wash plus a restrained focus outline; no rectangular glow.
- Empty state: short text-only guidance with generous breathing room.

The softer shape language applies consistently. Components should not mix square editorial framing with rounded aquatic controls.

## Responsive Composition

### Mobile and Narrow macOS

- Preserve the full-width vertical flow.
- App bar places settings on the left, `Tide` centered, and a balanced right slot reserved for the later search action.
- Count and localized date sit below the title as quiet secondary information.
- Composer remains directly above the stream.
- Notes stay edge-to-edge within compact horizontal padding.

The reserved search slot is a layout spacer in this phase, not an interactive placeholder.

### Wide macOS

- Preserve the split layout at 840 logical pixels and above.
- Left “shore” panel contains product identity, count/date, composer, settings, and undo.
- Right panel contains the note stream and future search mode.
- Desktop spacing is roomier than mobile while keeping readable note line length.
- Pointer hover, keyboard focus, Command+Enter, inline editing, and scroll position continue working across resize.

## Typography

Tide uses one branded pair on every platform:

- App name: Quicksand Regular, 24 logical pixels.
- Section and empty-state titles: Quicksand Medium.
- Note content: Nunito Regular, 17 logical pixels, approximately 1.45 line height.
- Prefixes: Nunito Bold.
- Metadata: Nunito Medium, 12 logical pixels.
- Controls and settings labels: Nunito SemiBold.

No third family is introduced. Platform fallbacks are declared for missing-glyph resilience. Font files must come from the official upstream distribution, be bundled deterministically, and include their license notice in the repository.

Large-text behavior must remain functional. Typography may wrap and grow; controls and note content must not clip at the currently supported accessibility scale.

## Atlantic Theme System

Semantic theme roles remain centralized under `lib/design`. Exact color values are selected as one coherent palette during implementation and are accepted only if automated contrast gates pass.

### Foam — Light

- Background: cool pearl and blue mist, not beige.
- Surfaces: foam white with subtle blue-green separation.
- Primary ink: deep blue-petrol.
- Primary accent: restrained petrol.
- Rescue accent: sea-glass green.
- Warm counterpoint: wet sand, used sparingly.
- Prefix accent set: petrol blue, sea-glass teal, muted coral.

### Deep Tide — Dark

- Background: layered midnight navy, not brown or absolute black.
- Surfaces: slightly lifted blue-black.
- Text: cool pearl.
- Accents: desaturated water tones that remain visible without glowing.

### Abyss — OLED

- Background: absolute black.
- Primary stream surface: absolute black.
- Elevated controls may use near-black blue only when separation is required.
- Text: cool pearl.
- Accents: low-saturation petrol and sea-glass colors tuned independently for black.

### Contrast Contract

- Note content and metadata remain at least 4.5:1 in resting, hovered, focused, and deepest-fade states.
- Controls and focus indicators remain distinguishable in all themes.
- Theme tokens are not accepted by visual judgment alone; tests calculate worst-case composited contrast.

## Viewport-Relative Sinking

Sinking belongs to screen position, not note age or list index.

- The top 65% of the note viewport renders at full presence.
- The bottom 35% applies a smooth, bottom-only alpha gradient.
- A note regains full presence automatically as scrolling moves it upward.
- Header, composer, sidebar, undo, and settings never receive the mask.
- Data, ordering, semantics, and hit targets remain unchanged.
- The fade minimum is theme-specific and derived from the contrast contract rather than chosen arbitrarily.
- Base content and metadata colors may be strengthened so the deepest visible fade still reaches 4.5:1.
- While inline editing is active, the stream fade is disabled so the editor and surrounding context remain stable.
- When high-contrast mode is active, the fade is disabled.

The implementation should use one viewport-level depth unit, not per-note scroll listeners. A gradient shader or equivalent compositing wrapper is preferred because it naturally follows scrolling and keeps list construction lazy.

## Motion Policy

The manual `Reduce motion` setting is removed. Its current 150 ms to 120 ms change is too small to communicate meaningful behavior and creates a preference with little user value.

Tide instead follows the operating-system accessibility preference automatically:

- Normal mode: short color/focus transitions and restrained append, rescue, and reorder motion.
- OS reduced motion: non-essential spatial and opacity animations use zero duration; state changes remain immediate and understandable.
- No perpetual floating, parallax, pulsing, or ambient wave motion.

The obsolete persisted manual motion preference may be ignored safely. No migration is needed because it does not affect note data.

## Component Design

### Header

- Mobile title is centered and set in Quicksand.
- Settings remains discoverable but visually quiet.
- Count/date uses Nunito and normal sentence casing.
- Desktop header aligns with the shore panel rather than forcing mobile centering.

### Composer

- Shallow rounded surface, calm border, no hard accent rail or heavy shadow.
- Input uses Nunito and supports existing multiline behavior.
- Append action is circular and meets the minimum touch target.
- Command+Enter remains available.

### Note Row

- Flat background at rest.
- Prefix carries semantic accent color; remaining content uses primary note ink.
- Metadata stays compact and secondary.
- Hover uses a soft water wash.
- Focus and editing restore full viewport presence.
- Rescue reveal uses sea-glass color and one clear upward/resurface cue.

### Settings

- Theme choices: System, Foam, Deep Tide, Abyss.
- Mobile presentation uses a compact modal sheet; macOS uses a popover appropriate to pointer interaction.
- Manual motion choice is absent.
- Selection state is explicit; labels do not expose implementation names such as `ThemeMode.dark`.

### Empty State

- Text only.
- One short Quicksand title and one Nunito guidance line.
- No logo, illustration, keyboard keycaps, or decorative water symbol.

## Architecture

Introduce three focused presentation/design units:

1. `TideThemeSelection`: represents System, Foam, Deep Tide, and Abyss and owns persisted selection mapping.
2. `TideDepthFade`: owns bottom-gradient composition and accessibility bypass rules; receives editing state without accessing BLoC or repository data.
3. `TideMotionPolicy`: maps OS accessibility state to normal or zero-duration transitions.

Existing widgets consume semantic tokens and shared policies. `TidePage` continues binding BLoC state to presentation. Domain, repository, database, and use-case layers remain untouched.

Theme selection may adapt Flutter's `ThemeMode` internally, but OLED remains an explicit Tide theme selection because `ThemeMode` has no OLED state.

## Test Strategy

Development speed improves by removing redundant implementation-detail coverage, not by removing risk coverage.

Retain:

- domain, repository, BLoC, append, edit, rescue, undo, persistence, lazy-list, and core semantics tests;
- pure contrast tests for resting, hover, and deepest viewport fade across Foam, Deep Tide, and Abyss;
- theme-selection persistence tests;
- one mobile and one macOS responsive flow;
- one OLED selection/rendering flow;
- one viewport-fade scroll test showing a note recover presence as it rises;
- one edit/high-contrast test showing the fade bypass;
- large-text and critical control-label coverage.

Remove or consolidate:

- duplicate geometry assertions already covered by responsive integration tests;
- tests coupled to private widget nesting, exact internal wrapper types, or decorative implementation details;
- repeated theme checks that can be expressed once as parameterized pure tests;
- redundant widget tests whose behavior is already proven end-to-end.

No full golden matrix is required in this phase. Manual visual acceptance uses four representative targets: compact iPhone light, compact Android dark, wide macOS Foam, and wide macOS Abyss.

## Error and State Behavior

- Theme persistence failure falls back to System without affecting notes.
- Missing font glyphs use declared platform fallbacks.
- Fade and animation policies are presentation-only and cannot block note interaction.
- Fatal repository retry, snackbars, undo state, focus, scroll, and inline-edit flushing remain unchanged.

## Acceptance Criteria

- Tide no longer looks beige, square, or editorially rigid.
- Quicksand and Nunito render consistently on mobile and macOS.
- System, Foam, Deep Tide, and Abyss themes are selectable and persist.
- OLED uses true black for the primary background and stream.
- Notes fade only in the bottom 35% of the viewport and recover as they move upward.
- Fade is disabled during editing and high-contrast mode.
- Manual reduced-motion setting is removed; OS reduced motion produces zero-duration non-essential transitions.
- Header, composer, note rows, settings, and empty state share one soft organic language.
- Mobile vertical and macOS split behavior remain intact.
- Existing note behavior and critical accessibility contracts remain green.
- Search is not included in this implementation.
