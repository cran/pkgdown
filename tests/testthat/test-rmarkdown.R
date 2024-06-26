test_that("render_rmarkdown copies image files in subdirectories", {
  local_edition(3)
  skip_if_no_pandoc()
  tmp <- dir_create(file_temp())
  pkg <- list(src_path = test_path("."), dst_path = tmp, bs_version = 3)

  expect_snapshot(
    render_rmarkdown(pkg, "assets/vignette-with-img.Rmd", "test.html")
  )
  expect_equal(
    as.character(path_rel(dir_ls(tmp, type = "file", recurse = TRUE), tmp)),
    c("open-graph/logo.png", "test.html")
  )
})

test_that("render_rmarkdown yields useful error if pandoc fails", {
  local_edition(3)
  skip_on_cran() # fragile due to pandoc dependency
  skip_if_no_pandoc("2.18")

  tmp <- dir_create(file_temp())
  pkg <- list(src_path = test_path("."), dst_path = tmp, bs_version = 3)

  format <- rmarkdown::html_document(pandoc_args = "--fail-if-warnings")
  expect_snapshot(
    render_rmarkdown(pkg, "assets/pandoc-fail.Rmd", "test.html", output_format = format),
    error = TRUE
  )
})

test_that("render_rmarkdown yields useful error if R fails", {
  local_edition(3)
  skip_if_no_pandoc()

  tmp <- dir_create(file_temp())
  pkg <- list(src_path = test_path("."), dst_path = tmp, bs_version = 3)

  expect_snapshot(
    {
      "Test traceback"
      summary(expect_error(render_rmarkdown(pkg, "assets/r-fail.Rmd", "test.html")))

      "Just test that it works; needed for browser() etc"
      expect_error(render_rmarkdown(pkg, "assets/r-fail.Rmd", "test.html", new_process = FALSE))
    },
    # work around xfun bug
    transform = function(x) gsub("lines  ?at lines", "lines", x)
  )
})

test_that("render_rmarkdown styles ANSI escapes", {
  skip_if_no_pandoc()
  local_edition(3)
  tmp <- dir_create(file_temp())
  pkg <- list(src_path = test_path("."), dst_path = tmp, bs_version = 5)

  expect_snapshot({
    path <- render_rmarkdown(pkg,
      input = "assets/vignette-with-crayon.Rmd",
      output = "test.html"
    )
  })
  html <- xml2::read_html(path)
  expect_snapshot_output(xpath_xml(html, ".//code//span[@class='co']"))
})
