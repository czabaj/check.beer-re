# check-beer -- Specification

Status: draft, ready for implementation

## 1. Overview

The `check-beer` is a Progressive Web Application (PWA) for running a garage pub. It allows an easy way to track consumption per user and make a fair settlement of the expenses. An unique feature is that the price of the keg is distributed among users based on their individual consumption, therefore there is no profit for the pub owner and the cost is shared fairly among the patrons.

The application uses Firebase Firestore as a backend, so it features a real-time data synchronization and offline capabilities. Therefore the app is responsible for data consistency and Rescript lang is used to cover all edge cases.

## 2. Design principles: keep it simple

React is used as a framework but we prefer to use native browser APIs whenever possible. The dominant user-agent is a mobile device, either a smartphone or a tablet. Assume drunk users so the interface must be easy to understand, controls and text must be large and there should be enough spacing to prevent accidental taps.

## 3. User interface

The UI is in Czech. Labels below are quoted in Czech with an English gloss. Layout is a single narrow column (mobile first), every page starts with a header card: back button (`↩️ Zpět`) on the left, title + subtitle in the middle, page-level action buttons (emoji icon + small caption) on the right. Secondary flows open as modal `<dialog>`s; forms have `Uložit` (save) / `Zrušit` (cancel), detail dialogs have a `✖️` close button.

### 3.1 Routes

| Path | Page |
| --- | --- |
| `/` | Homepage – landing with title "Pivní zápisník" and `Otevřít` (open) button |
| `/misto` | My places (list of places of the signed-in user) |
| `/misto/:placeId` | Place – the tally sheet ("Lístek") |
| `/misto/:placeId/nastaveni` | Place settings – taps, kegs, accounting overview |
| `/misto/:placeId/nastaveni/osob` | Personal accounts – guests and their balances |
| `/s/:linkId` | Invitation link resolver |

All routes except `/` and `/s/:linkId` require sign-in; unauthenticated users get the sign-in screen, freshly registered users go through onboarding first.

### 3.2 Roles

Each account linked to a place has a role; permissions are cumulative (`role >= required`):

| Role | Czech | Can |
| --- | --- | --- |
| Viewer (10) | Pozorovatel | watch the tally sheet only |
| SelfService (20) | Kumpán | add consumptions for themselves |
| Staff (50) | Výčepní | add consumptions for anyone, add guests, stock and tap/untap kegs; no irreversible money operations |
| Admin (80) | Správce | everything except editing the owner's account |
| Owner (100) | Vlastník | everything, including transfer of ownership |

### 3.3 Sign-in and onboarding (unauthenticated)

- **Přihlášení (sign in)** – e-mail + password, passkey (`Přihlásit otiskem`), or Google. Links to registration and forgotten password.
- **Registrace (sign up)** – e-mail, password, password again.
- **Zapomenuté heslo (forgotten password)** – e-mail form, then confirmation that a reset link was sent.
- **Onboarding** after first sign-in, one step per screen:
  1. *Ukládání dat* – trust this device (enables offline persistence and passwordless login) or decline.
  2. *Přihlášení bez hesla* – optional passkey setup (`Nastavit` / `Přeskočit`), shown only when the device supports it.
  3. *Jak ti říkají?* – nickname, used as the default name in places the user creates.

### 3.4 My places (`/misto`)

- Header: user's nickname, "Již od <date>" (member since). Actions: `🚴‍♂️ Odhlásit` (sign out), `⚙️ Nastavení` (user settings).
- Section **Moje místa** – list of places (name + "Založeno: <date>"), each links to the place. Button `Nové místo` opens a dialog: place name, my nickname in that place.
- **Úprava uživatele** dialog: nickname, e-mail, `Změnit heslo` (current / new / repeat), toggle `Důvěřovat tomuto zařízení` (offline mode).
- App version shown in the footer.

### 3.5 Place – tally sheet (`/misto/:placeId`)

The main screen used at the bar.

- Header: place name, "Založeno <date>". Actions: `📢 Notifikace` (only if push is supported), `⚙️ Nastavení` (Staff+).
- Section **Lístek** – grid of guests, one row each: name and a string of consumption marks from the last 12 hours (sliding window, includes recently depleted kegs). Default marks: `I` = small beer (300 ml), `X` = large beer (500 ml); the place can override the symbols. The current user's row is marked `aria-current`. A row flashes when a new consumption arrives in real time.
- **👁️ toggle** (`Zobrazit všechny hosty`) – switches to "show all" mode: hidden guests appear too, and every row gets an eye switch to hide/show the guest on the sheet. With everyone hidden, the sheet shows a hint to use the eye.
- **Tap on a guest** (Staff+, or SelfService on their own row) opens the **drink dialog**:
  - guest name + `Zavřít`;
  - tap selector – radio list of taps with a tapped keg ("Pípa: Pilsner Urquell #001") and a keg level meter; preselected is the guest's preferred tap. No tapped keg → message "Naražte sudy!".
  - two large picture buttons `Malé` / `Velké` – a single tap records the consumption immediately and closes the dialog (no confirm step, optimised for speed);
  - collapsible `Nezaúčtovaná piva` (unbilled beers) – table of the guest's consumptions on not-yet-settled kegs (beer, time, mark) with `🗑️ Smáznout` to delete a mistaken entry.
- **Notifikace** dialog – per-user opt-in switches: `První pivo` (first beer of the session, i.e. "the pub is open") and `Čerstvý sud` (a fresh keg was tapped); explains that browser permission is required; `Send test notification`.

### 3.6 Place settings (`/misto/:placeId/nastaveni`)

- Header action `✏️ Změnit` – dialog *Základní údaje místa*: name, founding date, and `Smazat místo` (delete place; requires typing the place name, irreversible).
- **Účetnictví** (accounting) summary: number of guests, total value of kegs in stock. Button `Osobní účty` links to personal accounts.
- **Pípy** (taps) – `Přidat pípu` (tap label). Each tap card shows tap name, tapped keg (`#001 Pilsner Urquell`) and a level meter, plus:
  - `Odrazit` (untap) – immediate, no confirmation; keg returns to stock untapped;
  - `Narazit` (tap) on an empty tap – dialog choosing a keg from stock;
  - `⋯` menu: `Přejmenovat` (rename), `Smazat` (delete; disabled while a keg is tapped, confirmation dialog).
- **Sudy na skladě** (kegs in stock) – table: No., beer, stocked date, price, volume, remaining. `Přidat sud` dialog: beer name, keg volume (l), price (Kč), and who paid – "Vkládá vlastník místa" (owner) or, when unchecked, a list of donors (`Vkladatelé sudu`); the payment is credited to their accounts.
  - Row click → **keg detail** dialog (cycles with `⬅️ Předchozí` / `Následující ➡️`): volume, remaining, stocked date and price, price of a large beer, first draw; which tap it is on; list of drawn beers (`Vytočená piva`: name, time, mark, `🗑️ Smáznout`).
  - `Odepsat ze skladu a rozúčtovat` (write off and settle) – opens a confirmation summarising total drawn vs. keg volume, efficiency, and the resulting large-beer price (keg price / efficiency); warns that settlement is irreversible (red warning when efficiency < 70 %). Settling splits the keg price among consumers by volume and books it to their accounts.
  - A keg without consumptions and not tapped can be removed (`odebrat z aplikace`).
- **Dopité sudy** (depleted kegs) – paginated history (`Načíst další`): volume, drunk, losses, stocked/tapped/depleted dates, keg price, large-beer price, efficiency. Empty-state text when none.

### 3.7 Personal accounts (`/misto/:placeId/nastaveni/osob`)

- Table of guests: name, last activity (relative, "před 4 minutami"), role (only for linked accounts), balance (`Konto`). `Přidat hosta` dialog: name.
- Row click → **person detail** dialog (cycles between persons):
  - member since, last seen, balance;
  - account link: either "Má propojený účet a oprávnění jako <role>" with `Změnit roli`, or "Nemá propojený účet" with `Poslat pozvánku` (choose role → generates share link `/s/:linkId`, roles with descriptions listed);
  - person without consumptions and accounting records can be removed completely (`zcela odebrat z aplikace`);
  - **Účetní záznamy** (ledger): date, amount, note (e.g. "Nezaúčtované: vklad za sud #001" for a keg deposit). `Nová platba` – *Platba mezi účastníky*: money handed from this person to another (`Komu`, `Částka`, `Poznámka`).

### 3.8 Invitation (`/s/:linkId`)

"Pozvánka" page: invites the user to the place with the given role, button `Přijmout pozvání`. Invalid/used link shows an explanation and a link to `Můj seznam míst`.
