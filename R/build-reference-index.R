data_reference_index <- function(pkg = ".") {
  pkg <- as_pkgdown(pkg)

  meta <- pkg$meta[["reference"]] %||% default_reference_index(pkg)
  if (length(meta) == 0) {
    return(list())
  }

  rows <- meta %>%
    purrr::imap(data_reference_index_rows, pkg = pkg) %>%
    purrr::compact() %>%
    unlist(recursive = FALSE)

  has_icons <- purrr::some(rows, ~ .x$row_has_icons %||% FALSE)

  check_missing_topics(rows, pkg)
  rows <- Filter(function(x) !x$is_internal, rows)

  print_yaml(list(
    pagetitle = tr_("Function reference"),
    rows = rows,
    has_icons = has_icons
  ))
}

data_reference_index_rows <- function(section, index, pkg) {
  is_internal <- identical(section$title, "internal")

  rows <- list()
  if (has_name(section, "title")) {
    rows[[1]] <- list(
      title = markdown_text_inline(section$title),
      slug = make_slug(section$title),
      desc = markdown_text_block(section$desc),
      is_internal = is_internal
    )
  }

  if (has_name(section, "subtitle")) {
    rows[[2]] <- list(
      subtitle = markdown_text_inline(section$subtitle),
      slug = make_slug(section$subtitle),
      desc = markdown_text_block(section$desc),
      is_internal = is_internal
    )
  }


  if (has_name(section, "contents")) {
    check_all_characters(section$contents, index, pkg)
    topics <- section_topics(section$contents, pkg$topics, pkg$src_path)

    names <- topics$name
    topics$name <- NULL

    rows[[3]] <- list(
      topics = purrr::transpose(topics),
      names = names,
      row_has_icons = !purrr::every(topics$icon, is.null),
      is_internal = is_internal
    )
  }

  purrr::compact(rows)
}

check_all_characters <- function(contents, index, pkg) {
  null <- purrr::map_lgl(contents, is.null)
  any_null <- any(null)

  if (any_null) {
    abort(
      c(
        sprintf(
          "Item %s in section %s in %s is empty.",
          toString(which(null)),
          index,
          pkgdown_field(pkg, "reference")
        ),
        i = "Either delete the empty line or add a function name."
      )
    )
  }

  not_char <- !purrr::map_lgl(contents, is.character)
  any_not_char <- any(not_char)

  if (!any_not_char) {
    return(invisible())
  }

  abort(
    c(
      sprintf(
        "Item %s in section %s in %s must be a character.",
        toString(which(not_char)),
        index,
        pkgdown_field(pkg, "reference")
      ),
      i = "You might need to add '' around e.g. - 'N' or - 'off'."
    )
  )

}

find_icons <- function(x, path) {
  purrr::map(x, find_icon, path = path)
}
find_icon <- function(aliases, path) {
  names <- paste0(aliases, ".png")
  exists <- file_exists(path(path, names))

  if (!any(exists)) {
    NULL
  } else {
    names[which(exists)[1]]
  }
}

default_reference_index <- function(pkg = ".") {
  pkg <- as_pkgdown(pkg)

  exported <- pkg$topics[!pkg$topics$internal, , drop = FALSE]
  if (nrow(exported) == 0) {
    return(list())
  }

  print_yaml(list(
    list(
      title = tr_("All functions"),
      contents = paste0('`', exported$name, '`')
    )
  ))
}

check_missing_topics <- function(rows, pkg) {
  # Cross-reference complete list of topics vs. topics found in index page
  all_topics <- rows %>% purrr::map("names") %>% unlist(use.names = FALSE)
  in_index <- pkg$topics$name %in% all_topics

  missing <- !in_index & !pkg$topics$internal

  if (any(missing)) {
    topics <- paste0(pkg$topics$name[missing], collapse = ", ")
    abort(c(
      "All topics must be included in reference index",
      `x` = paste0("Missing topics: ", topics),
      i = "Either add to _pkgdown.yml or use @keywords internal"
    ))
  }
}
