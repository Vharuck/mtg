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

|Column            |Class       |Summary                                       |
|:-----------------|:-----------|:---------------------------------------------|
|name              |`character` | Name of the set
|setCode           |`character` | Abbreviated code (key for matching with `cards`)
|releaseDate       |`Date`      | Release date
|border            |`factor`    | Card border color: `"white"`, `"black"`, or `"silver"`
|type              |`factor`    | Type of the set; see below
|block             |`character` | Name of the set block
|onlineOnly        |`logical`   | Was set only released online?
|booster           |`list`      | List of `character` vectors with card rarities in each booster pack
|booster_commons   |`numeric`   | Number of common cards in a booster pack
|booster_uncommons |`numeric`   | Number of uncommon cards in a booster pack
|booster_rares     |`numeric`   | Number of rare cards in a booster pack
|booster_lands     |`numeric`   | Number of land cards in a booster pack
|booster_size      |`integer`   | Total number of cards in booster pack (not just sum of the above)
