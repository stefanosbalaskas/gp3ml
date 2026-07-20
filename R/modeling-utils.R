`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

.gp3ml_stop <- function(..., call. = FALSE) {
  stop(sprintf(...), call. = call.)
}

.gp3ml_assert_data <- function(data) {
  if (!is.data.frame(data)) {
    .gp3ml_stop("`data` must be a data frame.")
  }
  if (nrow(data) < 2L) {
    .gp3ml_stop("`data` must contain at least two rows.")
  }
  invisible(TRUE)
}

.gp3ml_assert_columns <- function(data, columns, argument = "columns") {
  columns <- unique(columns[!is.na(columns) & nzchar(columns)])
  missing <- setdiff(columns, names(data))
  if (length(missing)) {
    .gp3ml_stop(
      "Missing %s: %s.",
      argument,
      paste(missing, collapse = ", ")
    )
  }
  invisible(TRUE)
}

.gp3ml_clip_probability <- function(x, eps = 1e-15) {
  pmin(pmax(as.numeric(x), eps), 1 - eps)
}

.gp3ml_set_seed <- function(seed) {
  if (length(seed) != 1L || is.na(seed) || !is.numeric(seed)) {
    .gp3ml_stop("`seed` must be one finite number.")
  }
  old_exists <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (old_exists) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  set.seed(as.integer(seed))
  function() {
    if (old_exists) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
    invisible(NULL)
  }
}

.gp3ml_bind_rows <- function(x) {
  x <- Filter(Negate(is.null), x)
  if (!length(x)) return(data.frame())
  columns <- unique(unlist(lapply(x, names), use.names = FALSE))
  x <- lapply(x, function(item) {
    missing <- setdiff(columns, names(item))
    for (column in missing) item[[column]] <- NA
    item[columns]
  })
  out <- do.call(rbind, x)
  rownames(out) <- NULL
  out
}

.gp3ml_hash_object <- function(x) {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(x, path, version = 3)
  unname(tools::md5sum(path))
}

.gp3ml_write_tables <- function(tables, directory, prefix, overwrite = FALSE) {
  if (!dir.exists(directory)) dir.create(directory, recursive = TRUE)
  paths <- file.path(directory, paste0(prefix, "_", names(tables), ".csv"))
  existing <- paths[file.exists(paths)]
  if (length(existing) && !isTRUE(overwrite)) {
    .gp3ml_stop(
      "Refusing to overwrite existing files: %s.",
      paste(basename(existing), collapse = ", ")
    )
  }
  for (i in seq_along(tables)) {
    utils::write.csv(tables[[i]], paths[[i]], row.names = FALSE, na = "")
  }
  stats::setNames(paths, names(tables))
}

.gp3ml_metric_direction <- function(metric) {
  if (metric %in% c("rmse", "mae", "log_loss", "brier", "ece")) "minimize" else "maximize"
}

.gp3ml_mean_metric <- function(metrics, metric) {
  if (!metric %in% names(metrics)) return(NA_real_)
  value <- mean(metrics[[metric]], na.rm = TRUE)
  if (is.nan(value)) NA_real_ else value
}

.gp3ml_merge_lists <- function(x, y) {
  if (!length(y)) return(x)
  x[names(y)] <- y
  x
}

.gp3ml_redeclare_task <- function(data, task) {
  declare_gazepoint_task(
    data = data,
    outcome = task$outcome,
    purpose = task$purpose,
    task_type = task$task_type,
    unit_id = task$unit_id,
    participant_id = task$participant_id,
    stimulus_id = task$stimulus_id,
    generalization_target = task$generalization_target,
    positive = task$positive,
    observed_outcome = task$observed_outcome,
    sensitive_outcome = FALSE
  )
}
