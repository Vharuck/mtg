# Project data

These datasets are those which can be relied on by any script/report/whatever in
this project:

-   `sets.RData`
-   `cards.RData`

All of these "blessed" data files are located in this directory (`data`). Raw or
intermediate data is saved in subdirectories (e.g., `data/download` for files
from the web).

## `sets.RData`

Data on set releases.

For most columns, descriptions of the content can be found at http://mtgjson.com/documentation.html. Those have been copied below.

|Column              |Class       |Summary                                       |
|:-------------------|:-----------|:---------------------------------------------|
|`name`              |`character` | Name of the set
|`setCode`           |`character` | Abbreviated code (key for matching with `cards`)
|`releaseDate`       |`Date`      | Release date
|`border`            |`factor`    | Card border color: `"white"`, `"black"`, or `"silver"`
|`type`              |`factor`    | Type of the set
|`block`             |`character` | Name of the set block
|`onlineOnly`        |`logical`   | Was set only released online?
|`booster`           |`list`      | List of `character` vectors with card rarities in each booster pack
|`booster_commons`   |`numeric`   | Number of common cards in a booster pack
|`booster_uncommons` |`numeric`   | Number of uncommon cards in a booster pack
|`booster_rares`     |`numeric`   | Number of rare cards in a booster pack
|`booster_lands`     |`numeric`   | Number of land cards in a booster pack
|`booster_size`      |`integer`   | Total number of cards in booster pack (not just sum of the above)

## `cards.RData`

Every card has its own record. If more than one "card" share a physical card
(e.g., split, transforming, etc.), each one has its own record.

If a value contains mana symbols (for example, `manaCost` or an ability cost in
`text`), the symbols will be denoted as:

-   `{B}`: black mana
-   `{G}`: green mana
-   `{R}`: red mana
-   `{U}`: blue mana
-   `{W}`: white mana
-   `{C}`: colorless mana (must be colorless, like with some Eldrazi cards)
-   `{N}`: *N* mana of any color (can also be `X`, which is a variable amount)

|Column          |Class       |Summary |
|:---------------|:-----------|:-------|
|`setCode`       |`character` | See descripion for `sets.RData`
|`id`            |`character` | Unique hash ID for card
|`layout`        |`character` | Layout of the card (important for split cards and such); see below
|`name`          |`character` | Name
|`names`         |`list`      | Names of all cards on the physical card
|`manaCost`      |`character` | Casting cost. Of the form `"{N}{R}{G}{G}"`, where `N` is the colorless cost, and `X` and `Y` are mana symbols
|`cmc`           |`integer`   | Converted mana cost value
|`colors`        |`list`      | Character vectors of card colors
|`colorIdentity` |`list`      | Character vectors of symbols (without braces) for associated colors
|`type`          |`character` | Full text of card type
|`supertypes`    |`list`      | Character vector of supertypes (e.g., `"Legendary"`)
|`types`         |`list`      | Character vector of types (e.g., `"Enchantment"`)
|`subtypes`      |`list`      | Character vector of subtypes (e.g., `"Goblin"`)
|`rarity`        |`factor`    | Card rarity
|`text`          |`character` | Text of the mechanics
|`flavor`        |`character` | Flavor text
|`artist`        |`character` | Artist name
|`number`        |`character` | Number printed at bottom of card
|`power`         |`character` | Creature's power
|`toughness`     |`character` | Creature's toughness
|`loyalty`       |`integer`   | Planeswalker loyalty (`X` is replaced with `NA`)
|`multiverseid`  |`integer`   | ID for Wizard's Gatherer website
|`variations`    |`list`      | Multiverse IDs for alternate art
|`imageName`     |`character` | Filename of card image from a deprecated website
|`watermark`     |`character` | Name of the watermark over the text box
|`border`        |`character` | Color of the border (if same as set, `NA`)
|`timeshifted`   |`logical`   | Is this a timeshifted card in the set?
|`hand`          |`integer`   | Max hand size modifier (only for Vanguard)
|`life`          |`integer`   | Starting life modifier (only for Vanguard)
|`reserved`      |`logical`   | Is the card reserved from reprinting?
|`releaseDate`   |`Date`      | When the card was released, may be imputed
|`starter`       |`logical`   | Is the card only available in a core box set?
|`mciNumber`     |`character` | ID used by [MagicCards.info](MagicCards.info)
|`is_...`        |`logical`   | Flag of the form `is_X_Y`, where `Y` is a category of `X`
