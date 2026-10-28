# Trick or Treat

A Halloween game of nerve for the 48K ZX Spectrum, written in Sinclair BASIC.

![Trick or Treat](screenshot.png)

**[Play it in your browser](https://mindbox77.github.io/zx-spectrum-games/play.html?g=trick-or-treat)**

You are a kid with a bag, a street of eight front doors, and until midnight to fill it. Every door is a gamble. Most of them hand out sweets. Some have nobody in. A few have a dog. And one or two have a witch behind them who will take the lot and chase you home.

The sweets in your bag are not yours until you run home and tip them into the big bowl, and running home costs you half an hour you could have spent knocking. That is the whole game: how greedy do you get before you bank it?

## Playing it

Load the tape from [Releases](https://github.com/mindbox77/zx-spectrum-games/releases) in your emulator of choice, or on the real thing via a DivMMC or similar. It is plain BASIC so it will run on anything from a rubber key 48K upwards.

Keys:

| Key | What it does |
| --- | --- |
| 1 to 8 | Knock on that door |
| H | Run home and empty your bag into the bowl (30 minutes) |
| N | Give up on this street and try the next one (15 minutes) |

Each knock takes somewhere between 8 and 15 minutes. The night runs from 6pm to midnight.

## Reading the street

Nothing is certain, but the houses give you clues:

- Lit windows (yellow) usually mean someone is in. Dark windows (blue) usually mean nobody, or something worse.
- A pumpkin on the step is a good sign. People who carve pumpkins buy sweets.
- A kennel means there is probably a dog. Probably.

Every door you have knocked on gets marked so you know what you found there.

## What is behind the doors

- **Treats.** One to four sweets, occasionally a jackpot of full size bars.
- **Nobody.** A wasted knock.
- **The dog.** You drop up to three sweets running away and lose ten minutes.
- **The witch.** She takes your whole bag and chases you home. Twenty minutes gone and nothing to show for it.
- **Trick houses.** They want a magic word before they pay up. Type the three letters shown before the bar runs out and you get a big handful. Miss it and the door slams.

The later it gets, the meaner the street. Witches and dogs become more common as the night goes on, and the trick houses give you less time to type.

## Midnight

At midnight Mum is on the doorstep. Anything still in your bag gets halved for being late, so the last trip home is worth thinking about.

## Building from source

`TRICK.bas` is the plain text listing. `tools/build.sh` at the top of the repo builds it, or by hand:

```
zmakebas -a 10 -n TRICK -o TRICK.tap TRICK.bas
```

It also tokenises cleanly with bas2tap if you prefer its stricter syntax checking.

## Notes

The clock is driven by the game, not real time, so you can take as long as you like deciding. The one exception is the trick house, which uses the FRAMES system variable for its countdown, so that one really is against the clock.

UDGs cover the roofs, bricks, windows, doors, pumpkins, kennels and the icons for what you found. Everything else is standard character set with attributes doing the work.

Damian Cooper, 2026
