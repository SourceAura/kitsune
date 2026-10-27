# The scene library

The scene that stands behind the Kitsune lock face: Ase, a
seven-tailed fox rendered as an SDF shader, and the seven
tarot cards of the mantra gate.

In this package the scene runs entirely inside the lock
theme. There is no backend, no network, and no stored
credential here: the lock face (content/Main.qml) deals the
cards, reads the taps, and speaks to SDDM. PAM checks the
password, as always.

## The seven folds

| Fold id    | Label       | Principle  | Colour    |
|:-----------|:------------|:-----------|:----------|
| truth      | THE EYE     | TRUTH      | `#4ade80` |
| power      | THE PHANTOM | POWER      | `#f43f5e` |
| wisdom     | THE BLADE   | WISDOM     | `#00B4D8` |
| judgment   | THE SAGE    | JUDGMENT   | `#9B1FA0` |
| life       | THE SHROUD  | LIFE       | `#818cf8` |
| love       | THE FORGE   | LOVE       | `#f59e0b` |
| discipline | THE MIRROR  | DISCIPLINE | `#6366f1` |

Each showing deals the cards shuffled. A card's back carries
its position number (1 to 7, left to right) and its fold
sigil; the front carries the label and the principle. You
answer by position, tapping the cards or typing the digits,
in your own order of the folds. The sequence is remembered
by principle, not by position: the cards move, the order
stays.

## Components

    InseiScene.qml      the composition: cards, Ase, whisper, HUD
    InseiGotchi.qml     the gate sequence state and card logic
    InseiCompanion.qml  Ase herself: SDF shader, mood, animation
    InseiTarot.qml      one card: 3D flip, hover lift, sigil and label
    InseiHud.qml        fold dots, entropy bar, live hash strip
    InseiLiveHash.qml   the 32-character stream under the scene
    InseiHub.qml        Ase ringed by her orbital sigils (not raised at the door)
    qmldir              module declarations

Shaders (../shaders):

    InseiKitsune.frag   the fox: seven tails, per-tail fold colours
    InseiSoul.frag      the core and swarm behind her
    crystallize.frag    the cards' crystallize and shatter
    pulse.frag          the energy field over the ground

InseiHub and InseiLiveHash ship as part of the scene library.
The lock face does not raise them; they are kept with the
scene they belong to.
