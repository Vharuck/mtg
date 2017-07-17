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
     column_defs_[, 'field'],
     column_defs_[, 'is_vector'],
     FUN = function(field, is_vector) {
       values <- lapply(json_list, get_with_default, name = field)
       if (is_vector == 'TRUE') {
         values
       } else {
         unlist(values)
       }
     },
     SIMPLIFY = FALSE
   )
   setDT(columns)
   setnames(columns, column_defs_[, 'field'])
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
  Date      = as.Date
)


process_field <- function(x, class_, is_vector) {
  class_fun <- class_processors[[class_]]
  processor_fun <- if (is_vector == 'TRUE') {
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
    class_    = column_defs_[, 'class'],
    is_vector = column_defs_[, 'is_vector'],
    SIMPLIFY  = FALSE
  )
}


# Create the tables ------------------------------------------------------------
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
    function(set_data) munge_json_list(set_data[['cards']], column_defs)
  )
  card_table <- rbindlist(set_cards, idcol = 'setCode')
  setnames(card_table, c('setCode', column_defs[, 'field']))
}


create_all_tables <- function(all_sets_json) {
  all_sets <- fromJSON(all_sets_json, simplifyVector = FALSE)
  cards <- create_card_table(all_sets)
}