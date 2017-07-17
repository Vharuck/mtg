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
    function(y) lapply(y, class_fun)
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
  cards, type,          character, TRUE
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
  '
)

create_card_table <- function(all_sets_, column_defs_) {
  set_cards <- lapply(
    all_sets_,
    function(set_data) munge_json_list(set_data[['cards']], column_defs_)
  )
  rbindlist(set_cards, idcol = 'setCode')
}


create_all_tables <- function(all_sets_json) {
  all_sets <- fromJSON(all_sets_json, simplifyVector = FALSE)
  cards <- create_card_table(all_sets)
}