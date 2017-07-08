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


# Process JSON data according to specified type --------------------------------
class_processors <- list(
  integer   = as.integer,
  character = as.character,
  logical   = function(z) as.logical(toupper(z)),
  Date      = as.Date
)


process_field <- function(x, class_, is_vector) {
  if (is.null(x)) {
    x <- NA
  }
  class_fun <- class_processors[[class_]]
  processor_fun <- if (is_vector == 'TRUE') {
    function(y) list(lapply(y, class_fun))
  } else {
    class_fun
  }
  processor_fun(x)
}


#' Converts a basic list returned by fromJSON to have all required fields, each
#' of the correct class
munge_json_list <- function(json_list, column_defs_) {
  mapply(
    process_field,
    x         = json_list[column_defs_[, 'field']],
    class_    = column_defs_[, 'class'],
    is_vector = column_defs_[, 'is_vector'],
    SIMPLIFY  = FALSE
  )
}


# Create the tables ------------------------------------------------------------
card_list_to_table <- function(card_list, column_defs_) {
 filled_list <- lapply(card_list, munge_json_list, column_defs_ = column_defs_)
 rbindlist(filled_list)
}


create_card_table <- function(all_sets_) {
  column_defs <- matrix(
    ncol = 3L,
    dimnames = list(NULL, c('field', 'class', 'is_vector')),
    byrow = TRUE,
    c(
      'id',            'character', 'FALSE',
      'layout',        'character', 'FALSE',
      'name',          'character', 'FALSE',
      'names',         'character', 'TRUE',
      'manaCost',      'character', 'FALSE',
      'cmc',           'integer',   'FALSE',
      'colors',        'character', 'TRUE',
      'colorIdentity', 'character', 'TRUE',
      'type',          'character', 'TRUE',
      'supertypes',    'character', 'TRUE',
      'types',         'character', 'TRUE',
      'subtypes',      'character', 'TRUE',
      'rarity',        'character', 'FALSE',
      'text',          'character', 'FALSE',
      'flavor',        'character', 'FALSE',
      'artist',        'character', 'FALSE',
      'number',        'character', 'FALSE',
      'power',         'character', 'FALSE',
      'toughness',     'character', 'FALSE',
      'loyalty',       'integer',   'FALSE',
      'multiverseid',  'integer',   'FALSE',
      'variations',    'integer',   'TRUE',
      'imageName',     'character', 'FALSE',
      'watermark',     'character', 'FALSE',
      'border',        'character', 'FALSE',
      'timeshifted',   'logical',   'FALSE',
      'hand',          'integer',   'FALSE',
      'life',          'integer',   'FALSE',
      'reserved',      'logical',   'FALSE',
      'releaseDate',   'Date',      'FALSE',
      'starter',       'logical',   'FALSE',
      'mciNumber',     'integer',   'FALSE'
    )
  )
  set_cards <- lapply(
    all_sets_,
    function(set_data) card_list_to_table(set_data[['cards']], column_defs)
  )
  card_table <- rbindlist(set_cards, idcol = 'setCode')
  setnames(card_table, c('setCode', column_defs[, 'field']))
}


create_all_tables <- function(all_sets_json) {
  all_sets <- fromJSON(all_sets_json, simplifyVector = FALSE)
  cards <- create_card_table(all_sets)
}