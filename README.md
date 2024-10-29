# Medieval Market
A MineColonies style pack

# Usage

## Prerequisites

This is a style pack for [MineColonies](https://minecolonies.com/), so it needs that (and its dependencies) installed.

Apart from that you need the following mods:

- [Macaw's Lights and Lamps](https://www.curseforge.com/minecraft/mc-mods/macaws-lights-and-lamps) \
  For the colorful lanterns

## Installation

- Create a new subfolder in `blueprints` of your Minecraft installation
- Either download a release and unpack it into that folder.\
  The `pack.json` should end up in your created subfolder.
- Or build the pack yourself (see below) and use the created ZIP-Archive

## Building buildings

- Select the style pack `Market` with your build-tool
- For each market-stall you want to build, you will be asked for a material and a color. \
  This determines the look of your market stall and let's you customize the market regarding the wood and dye types you need to supply.

# Build

## Prerequisites

You will need a Linux installation with the following tools installed
- ruby-sdk + bundler for running rake to build
- The zip binary for creating the archive

## Preparing

- Run `bundle install` to install the required Gems

## Importing huts to the correct folders

- Create a folder called `import`
- Put your blueprints there
- Run `rake import` \
  **NOTE:** If you want to overwrite existing huts you need to run `rake import FORCE=1`

## Sanity-Testing your schematics

- Run `rake test` to run some sanity checks against your schematics.

The following things will be checked:
- The filename of the schematic must end with a number
- Only the numbers 1-5 are allowed
- The numbers must be consecutive starting with 1 \
  But the highest number may be any in between 1 and 5 inclusive
- The same hut may only appear once in the `src` folder structure
- The dimensions of all 5 scans must be the same

## Building

- Run `rake all` to build all variants of the stalls and create the ZIP-Archive.
  If creation of the ZIP-Archive fails, you will still find the files in `out/pack` and can copy or zip them yourself.
