# Download card data and make data.tables --------------------------------------
# All data is taken from mtgjson.com
library(data.table)
library(jsonlite)


download_mtg_data <- function(save_dir) {
    mtgjson_url    <- 'https://mtgjson.com'
    sets_json_url  <- file.path(mtgjson_url, 'json/AllSets-x.json.zip')
    sets_zip       <- file.path(save_dir, basename(sets_json_url))
    download.file(sets_json_url, sets_zip, cacheOK = FALSE)
    unzip(sets_zip, exdir = save_dir)
}


get_with_default <- function(object, name) {
  if (name %in% names(object)) {
    object[[name]]
  } else {
    NA
  }
}


columnize_json <- function(json_list, column_defs_) {
   columns <- mapply(
     column_defs_[['field']],
     column_defs_[['is_vector']],
     FUN = function(field, is_vector) {
       values <- lapply(json_list, get_with_default, name = field)
       if (is_vector) {
         values
       } else {
         is_null_value <- vapply(values, is.null, logical(1L))
         values[is_null_value] <- NA
         unlist(values)
       }
     },
     SIMPLIFY = FALSE
   )
   setDT(columns)
   setnames(columns, column_defs_[['field']])
   columns
}


# Process JSON data according to specified type --------------------------------
class_processors <- list(
  integer   = function(z) {
    z <- trimws(z)
    z[grep('^X+$', z)] <- '0'
    as.integer(z)
  },
  character = as.character,
  logical   = function(z) as.logical(toupper(z)),
  Date      = function(z) {
    z <- trimws(z)
    only_to_year  <- which(nchar(z) == 4L)
    z[only_to_year]  <- paste0(z[only_to_year],  '-01-01')
    only_to_month <- which(nchar(z) == 7L)
    z[only_to_month] <- paste0(z[only_to_month], '-01')
    as.Date(z)
  }
)


process_field <- function(x, class_, is_vector) {
  class_fun <- class_processors[[class_]]
  processor_fun <- if (is_vector) {
    function(y) {
      is_sublist <- lapply(y, function(z) lengths(z) > 1L)
      is_nested <- any(unlist(is_sublist))
      if (is_nested) {
        rapply(y, class_fun, how = 'replace')
      } else {
        lapply(y, class_fun)
      }
    }
  } else {
    class_fun
  }
  processor_fun(x)
}


#' Converts a basic list returned by fromJSON to have all required fields, each
#' of the correct class
munge_json_list <- function(json_list, column_defs_) {
  columns <- columnize_json(json_list, column_defs_)
  mapply(
    process_field,
    x         = columns,
    class_    = column_defs_[['class_']],
    is_vector = column_defs_[['is_vector']],
    SIMPLIFY  = FALSE
  )
}


# Create the tables ------------------------------------------------------------
column_defs <- fread(
  '
  table, field,        class_,    is_vector
  cards, id,            character, FALSE
  cards, layout,        character, FALSE
  cards, name,          character, FALSE
  cards, names,         character, TRUE
  cards, manaCost,      character, FALSE
  cards, cmc,           integer,   FALSE
  cards, colors,        character, TRUE
  cards, colorIdentity, character, TRUE
  cards, type,          character, FALSE
  cards, supertypes,    character, TRUE
  cards, types,         character, TRUE
  cards, subtypes,      character, TRUE
  cards, rarity,        character, FALSE
  cards, text,          character, FALSE
  cards, flavor,        character, FALSE
  cards, artist,        character, FALSE
  cards, number,        character, FALSE
  cards, power,         character, FALSE
  cards, toughness,     character, FALSE
  cards, loyalty,       integer,   FALSE
  cards, multiverseid,  integer,   FALSE
  cards, variations,    integer,   TRUE
  cards, imageName,     character, FALSE
  cards, watermark,     character, FALSE
  cards, border,        character, FALSE
  cards, timeshifted,   logical,   FALSE
  cards, hand,          integer,   FALSE
  cards, life,          integer,   FALSE
  cards, reserved,      logical,   FALSE
  cards, releaseDate,   Date,      FALSE
  cards, starter,       logical,   FALSE
  cards, mciNumber,     character, FALSE
  sets,  name,          character, FALSE
  sets,  code,          character, FALSE
  sets,  releaseDate,   Date,      FALSE
  sets,  border,        character, FALSE
  sets,  type,          character, FALSE
  sets,  block,         character, FALSE
  sets,  onlineOnly,    logical,   FALSE
  sets,  booster,       character, TRUE
  '
)

# Cards table ------------------------------------------------------------------


expand_to_dummies <- function(x, prefix = NULL) {
  all_levels <- unique(unlist(x))
  all_levels <- all_levels[!is.na(all_levels)]
  is_element_vectorized <- Vectorize(is.element, 'set')
  dummies <- lapply(all_levels, function(level) is_element_vectorized(level, x))
  setDT(dummies)
  column_names <- gsub('[^[:alpha:]]+', '_', tolower(all_levels))
  prefix <- if (is.null(prefix)) {
    ''
  } else {
    paste0(prefix, '_')
  }
  column_names <- paste0('is_', prefix, column_names)
  setnames(dummies, column_names)
  dummies
}


create_cards_table <- function(all_sets_, cards_column_defs_) {
  set_cards <- lapply(
    all_sets_,
    function(set_data) munge_json_list(set_data[['cards']], cards_column_defs_)
  )
  cards_table <- rbindlist(set_cards, idcol = 'setCode')
  type_dummies      <- expand_to_dummies(cards_table$types,         'type')
  supertype_dummies <- expand_to_dummies(cards_table$supertypes,    'supertype')
  subtype_dummies   <- expand_to_dummies(cards_table$subtypes,      'subtype')
  color_dummies     <- expand_to_dummies(cards_table$colors,        'color')
  identity_dummies  <- expand_to_dummies(cards_table$colorIdentity, 'identity')
  set(cards_table, j = names(type_dummies),      value = type_dummies)
  set(cards_table, j = names(supertype_dummies), value = supertype_dummies)
  set(cards_table, j = names(subtype_dummies),   value = subtype_dummies)
  set(cards_table, j = names(color_dummies),     value = color_dummies)
  set(cards_table, j = names(identity_dummies),  value = identity_dummies)
  cards_table[, ':='(
    rarity = factor(
      tolower(rarity),
      c('basic land', 'common', 'uncommon', 'rare', 'mythic rare', 'special'),
      ordered = TRUE
    ),
    layout = factor(
      layout,
      c("normal", "split", "token", "flip", "double-faced", "leveler",
        "phenomenon", "plane", "scheme", "vanguard", "aftermath")
    )
  )]
  cards_table
}


# Sets table ------------------------------------------------------------------


count_booster_cards <- function(booster_, rarity) {
  # 1 for every "guarantee", fraction for a choice. Might want to adjust to
  # reflect actual probability, e.g. for mythic rare vs rare
  match_amount <- vapply(
    booster_,
    function(x) {
      matches <- grep(paste0('\\b', rarity, '\\b'), x, ignore.case = TRUE)
      length(matches) / length(x)
    },
    numeric(1L)
  )
  sum(match_amount)
}


count_booster_cards <- Vectorize(count_booster_cards, 'booster_')


create_sets_table <- function(all_sets_, sets_column_defs_) {
  sets_table <- munge_json_list(all_sets_, sets_column_defs_)
  setDT(sets_table)
  setnames(
    sets_table,
    c('code',    'name',    'type'),
    c('setCode', 'setName', 'setType')
  )
  sets_table[is.na(onlineOnly), onlineOnly := FALSE]
  sets_table[, ':='(
    border            = factor(border, c('black', 'white', 'silver')),
    setType           = factor(setType, c(
      'core', 'expansion', 'reprint', 'box', 'un', 'from the vault',
      'premium deck', 'duel deck', 'starter', 'commander', 'planechase',
      'archenemy', 'promo', 'vanguard', 'masters', 'conspiracy', 'masterpiece'
    )),
    booster_commons   = count_booster_cards(booster, 'common'),
    booster_uncommons = count_booster_cards(booster, 'uncommon'),
    booster_rares     = count_booster_cards(booster, 'rare'),
    booster_lands     = count_booster_cards(booster, 'land')
  )]
  sets_table[, booster_size := ifelse(
    vapply(booster, identical, logical(1L), NA_character_), 0L, lengths(booster)
  )]
  sets_table
}


all_sets_json <- download_mtg_data('data/download')
all_sets      <- fromJSON(all_sets_json, simplifyVector = FALSE)
cards         <- create_cards_table(all_sets, column_defs[table == 'cards'])
sets          <- create_sets_table(all_sets,  column_defs[table == 'sets'])

# A card's release date is only given when it's different from the set's
cards[
  sets[, list(setCode, setRelease = releaseDate)],
  releaseDate := ifelse(
    is.na(releaseDate),
    setRelease,
    releaseDate
  ),
  on = 'setCode'
]

save(cards, file = 'data/cards.RData')
save(sets,  file = 'data/sets.RData')
