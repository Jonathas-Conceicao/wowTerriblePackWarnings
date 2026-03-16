# TerriblePackWarnings

A WoW Midnight addon that shows timed ability warnings when you pull
dungeon trash packs in Mythic+ -- so you know what's coming before it
kills you.

TerriblePackWarnings uses imported MDT routes to know which mobs are in
each pack and what dangerous abilities they have. When you pull a
tracked pack, spell icons with countdown timers appear on screen to warn
you about incoming abilities. It's part of the "Terrible" addon family,
where we build bad solutions to problems Blizzard won't solve for us.

**This addon is a work-in-progress and has not been published yet.**
It is in early development -- expect rough edges, missing features, and
things that don't work quite right.

## AI Usage

This addon was built with the help of [Claude AI](https://claude.ai/).
I'm an experienced Software Developer but very new to Blizzard's API
and game addon/modding development. Claude assisted with learning the
WoW addon API and writing the implementation. The addon is maintained by
me to the best of my abilities.

## Showcase

![Pack warnings in action](ws_fst_pack.png)

## Features

- Import MDT routes via paste (no slash command -- WoW chat buffer too small)
- Per-pack ability warnings with spell icons and countdown timers
- Automatic mob detection via nameplate scanning
- Combat-aware: warnings activate when you pull tracked packs
- Supports custom dungeon data packs

## Usage

- `/tpw` -- Open the pack management frame
- Import a route: copy an MDT export string, open TPW, click Import, paste
- Warnings appear automatically when pulling packs with tracked abilities

## Known Issues and Limitations

- Nameplate scanning requires nameplates to be visible (enemy nameplates
  must be enabled)
- Only supports dungeons with data packs (currently Windrunner's Spire)
- 0.25s nameplate scan interval may miss very brief nameplate appearances
- WIP: many features still in development

## License

[WTFPL](LICENSE)
