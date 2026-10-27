# Kitsune

> **Part of [Jurai](https://github.com/SourceAura/jurai-suite)** — a living desktop ecosystem by 0xSrcAura. This piece is one of its public doors.

Ase, the seven-tailed kitsune, and her seven tarot folds — a lockscreen
and greeter theme for SDDM (and for Ryoku's session lock, which speaks
the same idiom).

## The mantra gate

Kitsune can stand a sequence gate in front of the password field. It
ships **off**. Turn it on in `theme.conf`:

    MantraGate=true
    MantraOrder=truth,power,wisdom,judgment,life,love,discipline

With the gate on, the seven folds are dealt **shuffled at every
showing** — every lock, every login screen, and again after every
wrong answer. You answer with the slot numbers (the small numeral on
each card, 1–7 left to right) in *your* order of the folds: type the
digits, or tap the cards. The folds are named truth, power, wisdom,
judgment, life, love, discipline — `MantraOrder` is where you put
them in the order that means something to you. A wrong sequence
redeals. Three wrong sequences (MantraAttempts) stand the gate down to the password field for the rest of the showing; only the manual switch stands it again — nothing re-arms it on its own. A hint at the bottom left of the face opens a panel with the switch, the attempt limit for the showing, whether a key is set, and this same account of the gate in plain words. The corner words — hint, mantra, reboot, power off — bloom on hover. The switch at the bottom right of the face lifts the gate
for that showing only; `theme.conf` is the standing setting.

A right sequence opens the password field. If you also set

    MantraPass=<your password>

a right sequence skips the field and logs in directly. Read that
again before you set it: **MantraPass is your password, in plain
text, in a config file.** Anyone who can read the file has the
password. It exists for a seat whose `theme.conf` nobody else can
read (chmod 600, your own machine) — and it is empty in the shipped
theme, on purpose.

Straight talk about what the gate is: a personal sequence in front
of your password, not a replacement for it. PAM still checks the
credential, exactly as before. Anyone watching one full unlock can
see the order you answered in, just like watching a password typed.
The gate's value is that it is yours — a ritual, and friction for
casual hands. It claims nothing more.

## Setting your mantra

You do not need to edit theme.conf by hand. The package ships a
companion, **kitsune-mantra**, which runs in your session:

    qs -p ~/.local/share/qylock/themes/kitsune/companion

It deals the same fan. Speak your order by tapping the cards or
typing their numbers — the cards are numbered because both ways
are first-class: tapping is not an option for everyone, and some
people simply never want to leave the keyboard. The window
prints its own keyboard map. **Try your mantra** deals a
practice fan, shuffled like the door's, and tells you whether
she would open.

Sealing writes theme.conf through a small writer. Your password
crosses to it on standard input only — never an argument, never
shown back — and the file lands at mode 600. The stored-key
warning applies exactly: it is your password in plain text, in
a file only you can read. Leave it out and a right sequence
simply opens the password field. No setup is ever required to
log in.

## The ground

Behind her is your own desktop, photographed at the moment of
locking and blurred past reading — shapes and light, nothing
legible. The screenshot is taken locally by the `tools/fuin-lock`
wrapper, kept in the runtime tmpfs (`/run/user/<uid>/fuin-desktop.png`),
never sent anywhere, overwritten at every lock, gone at logout.
Locks that have no fresh capture — the greeter, an idle lock — fall
back to the wallpaper under the same blur and dimming.

Faint energy moves in that ground: filaments at rest, a slow surge
of light now and then, a rare brighter crackle. Decoration, nothing
more — a shader over the blur, driven by a sporadic timer.

## The password ceremony

With the gate off — or once it opens — the face works as she always
has: type your password and the folds bind one by one, each
whispered as it lands. At seven the Cast rises: INVOKE THE SEAL. A
wrong password hurts her and scatters the cards; the right one
transforms her, and the seal opens.

Built by 0xSrcAura in 2026 for Jurai shell, carried to RyoStore
whole. See PROVENANCE.txt for what the port touched and what it did
not.

Install (RyoStore): the `kitsune` lockscreen. On Ryoku she seats
herself for both the session lock and — once SDDM's Current names
her — the login door. For the desktop capture at the session lock,
bind your lock key to `tools/fuin-lock` (on Ryoku it screenshots,
then calls `ryoku-shell lock`; elsewhere, any screenshot tool plus
your own lock command in the same two lines).

## Her sister door

Kitsune is one of a pair. Her sister is [Fūin](https://github.com/SourceAura/fuin)
— Jurai's Threshold: the wallpaper blurred behind a drawn veil, a
password field breathing prism light. Two wards of the same house,
speaking the same gate idiom: the face never learns who checks the
password.
