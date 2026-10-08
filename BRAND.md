# Bujit brand colors

The pink palette comes from the logo (`site-assets/bujit-logo.svg`; source:
`bujit_logo.pdf`). Use these hex codes anywhere Bujit appears: the website, store
graphics, Google Forms, social posts.

## Logo colors

| Color | Hex | Where it's used |
|---|---|---|
| Logo pink | `#F495B7` | The logo's background; the app icon and launch screen background; the website header (light mode); browser theme color |
| Snout pink | `#E682A9` | The snout itself |
| Nostril pink | `#DA7BA1` | The nostrils |
| Hot pink | `#DB1867` | The snout's rim. **The main accent:** website buttons, active tabs; good for Google Forms' theme color |
| Swoosh pink | `#D0386E` | The swoosh under "BUJIT"; secondary accent |
| White | `#FFFFFF` | The "BUJIT" lettering; text on hot pink |

White text on hot pink (`#DB1867`) passes accessibility contrast (4.8:1). White on
logo pink (`#F495B7`) does **not** (2.1:1): use dark plum text there instead.

## Website, light mode

| Role | Hex |
|---|---|
| Page background | `#FFF7FA` |
| Cards | `#FFFFFF` |
| Card hover / soft fill | `#FDEEF4` |
| Borders | `#F3D3E0` |
| Links | `#C2185B` |
| Soft accent background (notes, icons) | `#FCE4EE` |
| Main text | `#24121B` |
| Secondary text | `#6B4A58` |
| Header text (dark plum, on logo pink) | `#4A0B26` |

## Website, dark mode

| Role | Hex |
|---|---|
| Page background | `#1A1015` |
| Header | `#3A1426` |
| Cards | `#24161D` |
| Card hover | `#2E1C25` |
| Borders | `#3F2833` |
| Links | `#F495B7` (logo pink) |
| Soft accent background | `#3A1C29` |
| Main text | `#F6E9EF` |
| Secondary text | `#C4A6B3` |

## Store graphics

- Play feature graphic: [play/listing/feature-graphic.png](play/listing/feature-graphic.png)
  (1024×500): logo pink background, heading in `#4A0B26`, tagline in `#6E1A3F`,
  swoosh in `#D0386E`.
- App icon for store listings: [site-assets/bujit-logo-512.png](site-assets/bujit-logo-512.png).

## The app

The app's own color theme is separate: its default accent is **blue**, and users
can pick another in Settings → Appearance. Only the icon and launch screen use the
logo pink. The website's values live in [site.css](site.css) (the `:root` block).
