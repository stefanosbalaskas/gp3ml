
.gp3ml_split_targets <- function() {
  c(
    "new_trials_known_participants",
    "new_participants",
    "new_stimuli",
    "new_participants_and_new_stimuli"
  )
}


.gp3ml_split_scalar_column <- function(
    x,
    argument,
    allow_null = TRUE) {
  if (is.null(x) && allow_null) {
    return(NULL)
  }

  if (
    !is.character(x) ||
      length(x) != 1L ||
      is.na(x) ||
      !nzchar(trimws(x))
  ) {
    stop(
      sprintf(
        "`%s` must be a single non-empty column name.",
        argument
      ),
      call. = FALSE
    )
  }

  trimws(x)
}


.gp3ml_split_missing_identifier <- function(x) {
  is.na(x) | !nzchar(trimws(as.character(x)))
}


.gp3ml_split_require_columns <- function(
    data,
    columns,
    argument = "data") {
  columns <- unique(columns[!is.na(columns)])

  missing_columns <- setdiff(
    columns,
    names(data)
  )

  if (length(missing_columns) > 0L) {
    stop(
      sprintf(
        "`%s` is missing required columns: %s.",
        argument,
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  invisible(columns)
}


.gp3ml_split_group_values <- function(
    data,
    column,
    argument) {
  values <- as.character(data[[column]])

  if (any(.gp3ml_split_missing_identifier(values))) {
    stop(
      sprintf(
        "`%s` contains missing or empty grouping identifiers.",
        argument
      ),
      call. = FALSE
    )
  }

  trimws(values)
}


.gp3ml_split_trial_units <- function(
    participant,
    trial) {
  paste0(
    nchar(participant),
    ":",
    participant,
    "|",
    nchar(trial),
    ":",
    trial
  )
}


.gp3ml_split_holdout_count <- function(
    n_groups,
    proportion) {
  if (n_groups < 2L) {
    stop(
      "At least two distinct groups are required for splitting.",
      call. = FALSE
    )
  }

  count <- as.integer(round(n_groups * proportion))

  max(
    1L,
    min(n_groups - 1L, count)
  )
}


.gp3ml_split_restore_rng <- function(
    had_seed,
    previous_seed) {
  if (had_seed) {
    assign(
      ".Random.seed",
      previous_seed,
      envir = .GlobalEnv
    )
  } else if (
    exists(
      ".Random.seed",
      envir = .GlobalEnv,
      inherits = FALSE
    )
  ) {
    rm(
      ".Random.seed",
      envir = .GlobalEnv
    )
  }

  invisible(NULL)
}


.gp3ml_split_manifest <- function(
    feature_manifest,
    predictors) {
  if (missing(feature_manifest) || is.null(feature_manifest)) {
    stop(
      paste0(
        "`feature_manifest` is required. Create and validate it ",
        "before group-aware splitting."
      ),
      call. = FALSE
    )
  }

  if (
    !is.data.frame(feature_manifest) ||
      !"feature" %in% names(feature_manifest)
  ) {
    stop(
      "`feature_manifest` must be a compatible feature manifest.",
      call. = FALSE
    )
  }

  missing_features <- setdiff(
    predictors,
    feature_manifest$feature
  )

  if (length(missing_features) > 0L) {
    stop(
      sprintf(
        "Predictors missing from `feature_manifest`: %s.",
        paste(missing_features, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  positions <- match(
    predictors,
    feature_manifest$feature
  )

  manifest <- feature_manifest[
    positions,
    ,
    drop = FALSE
  ]

  class(manifest) <- class(feature_manifest)

  validation <- validate_gazepoint_feature_manifest(
    manifest
  )

  if (!identical(validation$status, "pass")) {
    stop(
      sprintf(
        paste0(
          "The predictor feature manifest must pass validation ",
          "before splitting; current status is `%s`."
        ),
        validation$status
      ),
      call. = FALSE
    )
  }

  list(
    manifest = manifest,
    validation = validation
  )
}


.gp3ml_split_two_way_assignment <- function(
    participant,
    stimulus,
    assessment_prop,
    max_attempts = 250L) {
  participants <- sort(unique(participant))
  stimuli <- sort(unique(stimulus))

  participant_count <- .gp3ml_split_holdout_count(
    length(participants),
    sqrt(assessment_prop)
  )

  stimulus_count <- .gp3ml_split_holdout_count(
    length(stimuli),
    sqrt(assessment_prop)
  )

  best <- NULL
  best_score <- Inf

  for (attempt in seq_len(max_attempts)) {
    held_participants <- sample(
      participants,
      size = participant_count,
      replace = FALSE
    )

    held_stimuli <- sample(
      stimuli,
      size = stimulus_count,
      replace = FALSE
    )

    participant_held <- participant %in%
      held_participants

    stimulus_held <- stimulus %in%
      held_stimuli

    partition <- ifelse(
      participant_held & stimulus_held,
      "assessment",
      ifelse(
        !participant_held & !stimulus_held,
        "analysis",
        "excluded"
      )
    )

    if (
      !any(partition == "analysis") ||
        !any(partition == "assessment")
    ) {
      next
    }

    achieved <- mean(partition == "assessment")
    excluded <- mean(partition == "excluded")

    score <- abs(
      achieved - assessment_prop
    ) + excluded

    if (score < best_score) {
      best_score <- score

      best <- list(
        partition = partition,
        participant_held = participant_held,
        stimulus_held = stimulus_held,
        held_participants = sort(
          held_participants
        ),
        held_stimuli = sort(
          held_stimuli
        )
      )
    }
  }

  if (is.null(best)) {
    stop(
      paste0(
        "Could not construct non-empty analysis and assessment ",
        "blocks for simultaneous participant and stimulus ",
        "generalization."
      ),
      call. = FALSE
    )
  }

  best
}


.gp3ml_split_group_counts <- function(
    data,
    partition,
    participant_id,
    trial_id,
    stimulus_id) {
  partitions <- c(
    "analysis",
    "assessment",
    "excluded"
  )

  rows <- list()

  add_counts <- function(unit, values) {
    for (partition_name in partitions) {
      selected <- partition == partition_name

      count <- if (any(selected)) {
        length(unique(values[selected]))
      } else {
        0L
      }

      rows[[length(rows) + 1L]] <<- data.frame(
        partition = partition_name,
        unit = unit,
        n_groups = as.integer(count),
        stringsAsFactors = FALSE
      )
    }
  }

  if (!is.null(participant_id)) {
    participant <- as.character(
      data[[participant_id]]
    )

    add_counts(
      "participant",
      participant
    )
  }

  if (!is.null(trial_id)) {
    trial <- as.character(
      data[[trial_id]]
    )

    if (!is.null(participant_id)) {
      participant <- as.character(
        data[[participant_id]]
      )

      trial <- .gp3ml_split_trial_units(
        participant,
        trial
      )

      add_counts(
        "participant_trial",
        trial
      )
    } else {
      add_counts(
        "trial",
        trial
      )
    }
  }

  if (!is.null(stimulus_id)) {
    stimulus <- as.character(
      data[[stimulus_id]]
    )

    add_counts(
      "stimulus",
      stimulus
    )
  }

  if (length(rows) == 0L) {
    return(
      data.frame(
        partition = character(),
        unit = character(),
        n_groups = integer(),
        stringsAsFactors = FALSE
      )
    )
  }

  result <- do.call(
    rbind,
    rows
  )

  row.names(result) <- NULL
  result
}


#' Create a deterministic group-aware Gazepoint holdout split
#'
#' Creates analysis and assessment partitions that preserve the
#' grouping unit implied by an explicit generalization target.
#'
#' @param data Data frame containing the outcome, predictors, and
#'   grouping identifiers.
#' @param outcome Name of the outcome column.
#' @param predictors Character vector of predictor-column names.
#' @param feature_manifest Feature manifest containing the predictors.
#' @param generalization_target Declared predictive-generalization
#'   target.
#' @param participant_id Optional participant-identifier column.
#' @param trial_id Optional trial-identifier column.
#' @param stimulus_id Optional stimulus-identifier column.
#' @param assessment_prop Requested assessment proportion.
#' @param seed Integer random seed.
#' @param source_row_id Name of the source-row identifier added to the
#'   returned partitions.
#'
#'
#' @examples
#' example_data <- expand.grid(
#'   participant_id = sprintf("P%02d", 1:6),
#'   stimulus_id = sprintf("S%02d", 1:4),
#'   repetition = 1:2,
#'   KEEP.OUT.ATTRS = FALSE,
#'   stringsAsFactors = FALSE
#' )
#' example_data$trial_id <- paste0(
#'   example_data$stimulus_id,
#'   "_T",
#'   example_data$repetition
#' )
#' participant_number <- as.integer(
#'   sub("P", "", example_data$participant_id)
#' )
#' stimulus_number <- as.integer(
#'   sub("S", "", example_data$stimulus_id)
#' )
#' example_data$outcome <- factor(
#'   ifelse(
#'     (participant_number + stimulus_number) %% 2L == 0L,
#'     "review",
#'     "pass"
#'   ),
#'   levels = c("pass", "review")
#' )
#' row_index <- seq_len(nrow(example_data))
#' example_data$fixation_duration <- 180 + row_index
#' example_data$pupil_change <- round(
#'   sin(row_index / 7),
#'   4
#' )
#' example_data$repetition <- NULL
#' manifest <- create_gazepoint_feature_manifest(
#'   features = c("fixation_duration", "pupil_change"),
#'   scientific_source = c(
#'     "Gazepoint fixation export",
#'     "Gazepoint pupil export"
#'   ),
#'   source_table = c("fixations", "pupil"),
#'   transformation = c(
#'     "Trial-level mean",
#'     "Trial-level change"
#'   ),
#'   availability_stage = "during_exposure",
#'   prediction_time_available = TRUE,
#'   preprocessing_scope = "none",
#'   fold_local_required = FALSE
#' )
#' split <- split_gazepoint_ml_data(
#'   data = example_data,
#'   outcome = "outcome",
#'   predictors = c("fixation_duration", "pupil_change"),
#'   feature_manifest = manifest,
#'   generalization_target = "new_participants",
#'   participant_id = "participant_id",
#'   trial_id = "trial_id",
#'   stimulus_id = "stimulus_id",
#'   assessment_prop = 1 / 3,
#'   seed = 101L
#' )
#' split
#' @return An object of class `gazepoint_ml_split`.
#'
#' @details
#' For simultaneous participant and stimulus generalization,
#' cross-block rows are placed in the excluded partition.
#'
#' This function does not perform preprocessing, feature selection,
#' resampling, or model fitting.
#'
#' @export
split_gazepoint_ml_data <- function(
    data,
    outcome,
    predictors,
    feature_manifest,
    generalization_target,
    participant_id = NULL,
    trial_id = NULL,
    stimulus_id = NULL,
    assessment_prop = 0.20,
    seed = 1L,
    source_row_id = ".gp3ml_source_row") {
  if (!is.data.frame(data)) {
    stop(
      "`data` must be a data frame.",
      call. = FALSE
    )
  }

  if (nrow(data) < 2L) {
    stop(
      "`data` must contain at least two rows.",
      call. = FALSE
    )
  }

  outcome <- .gp3ml_split_scalar_column(
    outcome,
    "outcome",
    allow_null = FALSE
  )

  source_row_id <- .gp3ml_split_scalar_column(
    source_row_id,
    "source_row_id",
    allow_null = FALSE
  )

  participant_id <- .gp3ml_split_scalar_column(
    participant_id,
    "participant_id"
  )

  trial_id <- .gp3ml_split_scalar_column(
    trial_id,
    "trial_id"
  )

  stimulus_id <- .gp3ml_split_scalar_column(
    stimulus_id,
    "stimulus_id"
  )

  if (
    !is.character(predictors) ||
      length(predictors) == 0L ||
      anyNA(predictors) ||
      any(!nzchar(trimws(predictors)))
  ) {
    stop(
      "`predictors` must contain non-empty column names.",
      call. = FALSE
    )
  }

  predictors <- trimws(predictors)

  if (anyDuplicated(predictors)) {
    stop(
      "`predictors` must contain unique column names.",
      call. = FALSE
    )
  }

  if (outcome %in% predictors) {
    stop(
      "`outcome` must not be included in `predictors`.",
      call. = FALSE
    )
  }

  identifier_columns <- c(
    participant_id,
    trial_id,
    stimulus_id,
    source_row_id
  )

  identifier_predictors <- intersect(
    predictors,
    identifier_columns
  )

  if (length(identifier_predictors) > 0L) {
    stop(
      sprintf(
        "Identifier columns must not be predictors: %s.",
        paste(identifier_predictors, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  targets <- .gp3ml_split_targets()

  if (
    !is.character(generalization_target) ||
      length(generalization_target) != 1L ||
      is.na(generalization_target) ||
      !(generalization_target %in% targets)
  ) {
    stop(
      sprintf(
        "`generalization_target` must be one of: %s.",
        paste(targets, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  if (
    !is.numeric(assessment_prop) ||
      length(assessment_prop) != 1L ||
      is.na(assessment_prop) ||
      !is.finite(assessment_prop) ||
      assessment_prop <= 0 ||
      assessment_prop >= 1
  ) {
    stop(
      "`assessment_prop` must be strictly between 0 and 1.",
      call. = FALSE
    )
  }

  if (
    !is.numeric(seed) ||
      length(seed) != 1L ||
      is.na(seed) ||
      !is.finite(seed) ||
      seed != as.integer(seed)
  ) {
    stop(
      "`seed` must be a single finite integer.",
      call. = FALSE
    )
  }

  seed <- as.integer(seed)

  identifiers_ok <- switch(
    generalization_target,
    new_trials_known_participants =
      !is.null(participant_id) &&
      !is.null(trial_id),
    new_participants =
      !is.null(participant_id),
    new_stimuli =
      !is.null(stimulus_id),
    new_participants_and_new_stimuli =
      !is.null(participant_id) &&
      !is.null(stimulus_id)
  )

  if (!identifiers_ok) {
    stop(
      sprintf(
        paste0(
          "Required grouping identifiers were not supplied for ",
          "`generalization_target = \"%s\"`."
        ),
        generalization_target
      ),
      call. = FALSE
    )
  }

  if (source_row_id %in% names(data)) {
    stop(
      sprintf(
        "`data` already contains the reserved source-row column `%s`.",
        source_row_id
      ),
      call. = FALSE
    )
  }

  required_columns <- c(
    outcome,
    predictors,
    participant_id,
    trial_id,
    stimulus_id
  )

  .gp3ml_split_require_columns(
    data,
    required_columns
  )

  manifest_result <- .gp3ml_split_manifest(
    feature_manifest,
    predictors
  )

  participant <- if (!is.null(participant_id)) {
    .gp3ml_split_group_values(
      data,
      participant_id,
      "participant_id"
    )
  } else {
    NULL
  }

  trial <- if (!is.null(trial_id)) {
    .gp3ml_split_group_values(
      data,
      trial_id,
      "trial_id"
    )
  } else {
    NULL
  }

  stimulus <- if (!is.null(stimulus_id)) {
    .gp3ml_split_group_values(
      data,
      stimulus_id,
      "stimulus_id"
    )
  } else {
    NULL
  }

  had_seed <- exists(
    ".Random.seed",
    envir = .GlobalEnv,
    inherits = FALSE
  )

  previous_seed <- if (had_seed) {
    get(
      ".Random.seed",
      envir = .GlobalEnv,
      inherits = FALSE
    )
  } else {
    NULL
  }

  on.exit(
    .gp3ml_split_restore_rng(
      had_seed,
      previous_seed
    ),
    add = TRUE
  )

  set.seed(seed)

  participant_held <- rep(
    FALSE,
    nrow(data)
  )

  stimulus_held <- rep(
    FALSE,
    nrow(data)
  )

  split_unit <- rep(
    NA_character_,
    nrow(data)
  )

  if (
    generalization_target ==
      "new_trials_known_participants"
  ) {
    trial_units <- .gp3ml_split_trial_units(
      participant,
      trial
    )

    split_unit <- trial_units
    assessment_units <- character()

    participants <- sort(unique(participant))

    for (participant_value in participants) {
      participant_rows <- participant ==
        participant_value

      units <- sort(unique(
        trial_units[participant_rows]
      ))

      if (length(units) < 2L) {
        stop(
          sprintf(
            paste0(
              "Participant `%s` has fewer than two distinct ",
              "participant-trial units."
            ),
            participant_value
          ),
          call. = FALSE
        )
      }

      assessment_count <- .gp3ml_split_holdout_count(
        length(units),
        assessment_prop
      )

      assessment_units <- c(
        assessment_units,
        sample(
          units,
          size = assessment_count,
          replace = FALSE
        )
      )
    }

    partition <- ifelse(
      trial_units %in% assessment_units,
      "assessment",
      "analysis"
    )
  } else if (
    generalization_target == "new_participants"
  ) {
    participants <- sort(unique(participant))

    assessment_count <- .gp3ml_split_holdout_count(
      length(participants),
      assessment_prop
    )

    held_participants <- sample(
      participants,
      size = assessment_count,
      replace = FALSE
    )

    participant_held <- participant %in%
      held_participants

    split_unit <- participant

    partition <- ifelse(
      participant_held,
      "assessment",
      "analysis"
    )
  } else if (
    generalization_target == "new_stimuli"
  ) {
    stimuli <- sort(unique(stimulus))

    assessment_count <- .gp3ml_split_holdout_count(
      length(stimuli),
      assessment_prop
    )

    held_stimuli <- sample(
      stimuli,
      size = assessment_count,
      replace = FALSE
    )

    stimulus_held <- stimulus %in%
      held_stimuli

    split_unit <- stimulus

    partition <- ifelse(
      stimulus_held,
      "assessment",
      "analysis"
    )
  } else {
    two_way <- .gp3ml_split_two_way_assignment(
      participant = participant,
      stimulus = stimulus,
      assessment_prop = assessment_prop
    )

    partition <- two_way$partition
    participant_held <- two_way$participant_held
    stimulus_held <- two_way$stimulus_held

    split_unit <- paste0(
      nchar(participant),
      ":",
      participant,
      "|",
      nchar(stimulus),
      ":",
      stimulus
    )
  }

  if (
    !any(partition == "analysis") ||
      !any(partition == "assessment")
  ) {
    stop(
      "The requested split produced an empty partition.",
      call. = FALSE
    )
  }

  source_rows <- seq_len(nrow(data))

  split_data <- data
  split_data[[source_row_id]] <- source_rows

  analysis_indices <- source_rows[
    partition == "analysis"
  ]

  assessment_indices <- source_rows[
    partition == "assessment"
  ]

  excluded_indices <- source_rows[
    partition == "excluded"
  ]

  analysis <- split_data[
    analysis_indices,
    ,
    drop = FALSE
  ]

  assessment <- split_data[
    assessment_indices,
    ,
    drop = FALSE
  ]

  excluded <- split_data[
    excluded_indices,
    ,
    drop = FALSE
  ]

  row.names(analysis) <- NULL
  row.names(assessment) <- NULL
  row.names(excluded) <- NULL

  assignment <- data.frame(
    source_row = source_rows,
    partition = partition,
    split_unit = split_unit,
    participant_held_out = participant_held,
    stimulus_held_out = stimulus_held,
    stringsAsFactors = FALSE
  )

  summary <- data.frame(
    generalization_target = generalization_target,
    seed = seed,
    assessment_prop_requested = assessment_prop,
    assessment_prop_achieved_all =
      length(assessment_indices) / nrow(data),
    assessment_prop_achieved_retained =
      length(assessment_indices) /
      (
        length(analysis_indices) +
          length(assessment_indices)
      ),
    n_total = nrow(data),
    n_analysis = length(analysis_indices),
    n_assessment = length(assessment_indices),
    n_excluded = length(excluded_indices),
    stringsAsFactors = FALSE
  )

  group_counts <- .gp3ml_split_group_counts(
    data = data,
    partition = partition,
    participant_id = participant_id,
    trial_id = trial_id,
    stimulus_id = stimulus_id
  )

  leakage_audit <- audit_gazepoint_ml_leakage(
    analysis = analysis,
    assessment = assessment,
    outcome = outcome,
    predictors = predictors,
    participant_id = participant_id,
    trial_id = trial_id,
    stimulus_id = stimulus_id,
    generalization_target = generalization_target
  )

  result <- structure(
    list(
      analysis = analysis,
      assessment = assessment,
      excluded = excluded,
      analysis_indices = analysis_indices,
      assessment_indices = assessment_indices,
      excluded_indices = excluded_indices,
      assignment = assignment,
      summary = summary,
      group_counts = group_counts,
      feature_manifest = manifest_result$manifest,
      feature_manifest_validation =
        manifest_result$validation,
      leakage_audit = leakage_audit,
      metadata = list(
        outcome = outcome,
        predictors = predictors,
        participant_id = participant_id,
        trial_id = trial_id,
        stimulus_id = stimulus_id,
        generalization_target =
          generalization_target,
        assessment_prop = assessment_prop,
        seed = seed,
        source_row_id = source_row_id,
        n_source_rows = nrow(data)
      ),
      call = match.call()
    ),
    class = "gazepoint_ml_split"
  )

  result$validation <- validate_gazepoint_ml_split(
    result
  )

  result
}


#' Validate a group-aware Gazepoint holdout split
#'
#' @param x An object returned by [split_gazepoint_ml_data()].
#'
#'
#' @examples
#' example_data <- expand.grid(
#'   participant_id = sprintf("P%02d", 1:6),
#'   stimulus_id = sprintf("S%02d", 1:4),
#'   repetition = 1:2,
#'   KEEP.OUT.ATTRS = FALSE,
#'   stringsAsFactors = FALSE
#' )
#' example_data$trial_id <- paste0(
#'   example_data$stimulus_id,
#'   "_T",
#'   example_data$repetition
#' )
#' participant_number <- as.integer(
#'   sub("P", "", example_data$participant_id)
#' )
#' stimulus_number <- as.integer(
#'   sub("S", "", example_data$stimulus_id)
#' )
#' example_data$outcome <- factor(
#'   ifelse(
#'     (participant_number + stimulus_number) %% 2L == 0L,
#'     "review",
#'     "pass"
#'   ),
#'   levels = c("pass", "review")
#' )
#' row_index <- seq_len(nrow(example_data))
#' example_data$fixation_duration <- 180 + row_index
#' example_data$pupil_change <- round(
#'   sin(row_index / 7),
#'   4
#' )
#' example_data$repetition <- NULL
#' manifest <- create_gazepoint_feature_manifest(
#'   features = c("fixation_duration", "pupil_change"),
#'   scientific_source = c(
#'     "Gazepoint fixation export",
#'     "Gazepoint pupil export"
#'   ),
#'   source_table = c("fixations", "pupil"),
#'   transformation = c(
#'     "Trial-level mean",
#'     "Trial-level change"
#'   ),
#'   availability_stage = "during_exposure",
#'   prediction_time_available = TRUE,
#'   preprocessing_scope = "none",
#'   fold_local_required = FALSE
#' )
#' split <- split_gazepoint_ml_data(
#'   data = example_data,
#'   outcome = "outcome",
#'   predictors = c("fixation_duration", "pupil_change"),
#'   feature_manifest = manifest,
#'   generalization_target = "new_participants",
#'   participant_id = "participant_id",
#'   trial_id = "trial_id",
#'   stimulus_id = "stimulus_id",
#'   assessment_prop = 1 / 3,
#'   seed = 101L
#' )
#' validation <- validate_gazepoint_ml_split(split)
#' validation
#' @return An object of class `gazepoint_ml_split_validation`.
#'
#' @export
validate_gazepoint_ml_split <- function(x) {
  if (!inherits(x, "gazepoint_ml_split")) {
    stop(
      "`x` must be a `gazepoint_ml_split` object.",
      call. = FALSE
    )
  }

  required_components <- c(
    "analysis",
    "assessment",
    "excluded",
    "assignment",
    "summary",
    "group_counts",
    "feature_manifest_validation",
    "leakage_audit",
    "metadata"
  )

  missing_components <- setdiff(
    required_components,
    names(x)
  )

  if (length(missing_components) > 0L) {
    stop(
      sprintf(
        "Split object is missing components: %s.",
        paste(missing_components, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  source_row_id <- x$metadata$source_row_id

  for (partition_name in c(
    "analysis",
    "assessment",
    "excluded"
  )) {
    partition_data <- x[[partition_name]]

    if (
      !is.data.frame(partition_data) ||
        !(source_row_id %in% names(partition_data))
    ) {
      stop(
        sprintf(
          "Partition `%s` is not structurally valid.",
          partition_name
        ),
        call. = FALSE
      )
    }
  }

  checks <- list()

  add_check <- function(
      check_id,
      status,
      message,
      remediation) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check_id = check_id,
      status = status,
      message = message,
      remediation = remediation,
      stringsAsFactors = FALSE
    )
  }

  analysis_rows <- x$analysis[[source_row_id]]
  assessment_rows <- x$assessment[[source_row_id]]
  excluded_rows <- x$excluded[[source_row_id]]

  add_check(
    check_id = "analysis_non_empty",
    status = if (nrow(x$analysis) > 0L) {
      "pass"
    } else {
      "fail"
    },
    message = if (nrow(x$analysis) > 0L) {
      "The analysis partition is non-empty."
    } else {
      "The analysis partition is empty."
    },
    remediation = if (nrow(x$analysis) > 0L) {
      "None."
    } else {
      "Revise the split request."
    }
  )

  add_check(
    check_id = "assessment_non_empty",
    status = if (nrow(x$assessment) > 0L) {
      "pass"
    } else {
      "fail"
    },
    message = if (nrow(x$assessment) > 0L) {
      "The assessment partition is non-empty."
    } else {
      "The assessment partition is empty."
    },
    remediation = if (nrow(x$assessment) > 0L) {
      "None."
    } else {
      "Revise the split request."
    }
  )

  duplicated_rows <-
    anyDuplicated(analysis_rows) > 0L ||
    anyDuplicated(assessment_rows) > 0L ||
    anyDuplicated(excluded_rows) > 0L

  add_check(
    check_id = "source_rows_unique_within_partitions",
    status = if (duplicated_rows) {
      "fail"
    } else {
      "pass"
    },
    message = if (duplicated_rows) {
      "Source rows are duplicated within a partition."
    } else {
      "Source rows are unique within each partition."
    },
    remediation = if (duplicated_rows) {
      "Restore one assignment per source row."
    } else {
      "None."
    }
  )

  overlap <- length(intersect(
    analysis_rows,
    assessment_rows
  )) +
    length(intersect(
      analysis_rows,
      excluded_rows
    )) +
    length(intersect(
      assessment_rows,
      excluded_rows
    ))

  add_check(
    check_id = "source_rows_disjoint",
    status = if (overlap > 0L) {
      "fail"
    } else {
      "pass"
    },
    message = if (overlap > 0L) {
      "Source rows overlap across returned partitions."
    } else {
      "Source rows are disjoint across returned partitions."
    },
    remediation = if (overlap > 0L) {
      "Assign each source row to only one partition."
    } else {
      "None."
    }
  )

  all_rows <- sort(c(
    analysis_rows,
    assessment_rows,
    excluded_rows
  ))

  expected_rows <- seq_len(
    x$metadata$n_source_rows
  )

  complete_accounting <- identical(
    all_rows,
    expected_rows
  )

  add_check(
    check_id = "source_rows_fully_accounted",
    status = if (complete_accounting) {
      "pass"
    } else {
      "fail"
    },
    message = if (complete_accounting) {
      "All source rows are accounted for exactly once."
    } else {
      "Source-row accounting is incomplete or invalid."
    },
    remediation = if (complete_accounting) {
      "None."
    } else {
      "Reconstruct the split from the original data."
    }
  )

  target <- x$metadata$generalization_target

  excluded_compatible <- nrow(x$excluded) == 0L ||
    identical(
      target,
      "new_participants_and_new_stimuli"
    )

  add_check(
    check_id = "excluded_rows_compatible",
    status = if (excluded_compatible) {
      "pass"
    } else {
      "fail"
    },
    message = if (nrow(x$excluded) == 0L) {
      "No rows were excluded."
    } else if (excluded_compatible) {
      paste0(
        "Cross-block rows were excluded to preserve simultaneous ",
        "participant and stimulus generalization."
      )
    } else {
      "Rows were unexpectedly excluded for this target."
    },
    remediation = if (excluded_compatible) {
      "None."
    } else {
      "Recreate the split using the declared grouping target."
    }
  )

  manifest_status <- x$feature_manifest_validation$status

  add_check(
    check_id = "feature_manifest_passed",
    status = manifest_status,
    message = sprintf(
      "Feature-manifest validation status is `%s`.",
      manifest_status
    ),
    remediation = if (identical(
      manifest_status,
      "pass"
    )) {
      "None."
    } else {
      "Resolve feature-provenance issues before evaluation."
    }
  )

  audit_status <- x$leakage_audit$status

  add_check(
    check_id = "leakage_audit_status",
    status = audit_status,
    message = sprintf(
      "Leakage-audit status is `%s`.",
      audit_status
    ),
    remediation = if (identical(
      audit_status,
      "pass"
    )) {
      "None."
    } else {
      "Review and resolve the embedded leakage-audit issues."
    }
  )

  checks <- do.call(
    rbind,
    checks
  )

  row.names(checks) <- NULL

  issues <- checks[
    checks$status != "pass",
    ,
    drop = FALSE
  ]

  row.names(issues) <- NULL

  overall_status <- if (any(
    checks$status == "fail"
  )) {
    "fail"
  } else if (any(
    checks$status == "review"
  )) {
    "review"
  } else {
    "pass"
  }

  status_levels <- c(
    "pass",
    "review",
    "fail"
  )

  summary <- data.frame(
    status = status_levels,
    n_checks = vapply(
      status_levels,
      function(status) {
        sum(checks$status == status)
      },
      integer(1)
    ),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      status = overall_status,
      summary = summary,
      checks = checks,
      issues = issues,
      leakage_audit = x$leakage_audit,
      feature_manifest_validation =
        x$feature_manifest_validation,
      call = match.call()
    ),
    class = "gazepoint_ml_split_validation"
  )
}


#' Print a group-aware Gazepoint split
#'
#' @param x A `gazepoint_ml_split` object.
#' @param ... Additional arguments, currently unused.
#'
#'
#' @examples
#' example_data <- expand.grid(
#'   participant_id = sprintf("P%02d", 1:6),
#'   stimulus_id = sprintf("S%02d", 1:4),
#'   repetition = 1:2,
#'   KEEP.OUT.ATTRS = FALSE,
#'   stringsAsFactors = FALSE
#' )
#' example_data$trial_id <- paste0(
#'   example_data$stimulus_id,
#'   "_T",
#'   example_data$repetition
#' )
#' participant_number <- as.integer(
#'   sub("P", "", example_data$participant_id)
#' )
#' stimulus_number <- as.integer(
#'   sub("S", "", example_data$stimulus_id)
#' )
#' example_data$outcome <- factor(
#'   ifelse(
#'     (participant_number + stimulus_number) %% 2L == 0L,
#'     "review",
#'     "pass"
#'   ),
#'   levels = c("pass", "review")
#' )
#' row_index <- seq_len(nrow(example_data))
#' example_data$fixation_duration <- 180 + row_index
#' example_data$pupil_change <- round(
#'   sin(row_index / 7),
#'   4
#' )
#' example_data$repetition <- NULL
#' manifest <- create_gazepoint_feature_manifest(
#'   features = c("fixation_duration", "pupil_change"),
#'   scientific_source = c(
#'     "Gazepoint fixation export",
#'     "Gazepoint pupil export"
#'   ),
#'   source_table = c("fixations", "pupil"),
#'   transformation = c(
#'     "Trial-level mean",
#'     "Trial-level change"
#'   ),
#'   availability_stage = "during_exposure",
#'   prediction_time_available = TRUE,
#'   preprocessing_scope = "none",
#'   fold_local_required = FALSE
#' )
#' split <- split_gazepoint_ml_data(
#'   data = example_data,
#'   outcome = "outcome",
#'   predictors = c("fixation_duration", "pupil_change"),
#'   feature_manifest = manifest,
#'   generalization_target = "new_participants",
#'   participant_id = "participant_id",
#'   trial_id = "trial_id",
#'   stimulus_id = "stimulus_id",
#'   assessment_prop = 1 / 3,
#'   seed = 101L
#' )
#' print(split)
#' @return `x`, invisibly.
#'
#' @export
print.gazepoint_ml_split <- function(x, ...) {
  cat("<gazepoint_ml_split>\n")
  cat(
    "Target: ",
    x$metadata$generalization_target,
    "\n",
    sep = ""
  )
  cat(
    "Status: ",
    toupper(x$validation$status),
    "\n",
    sep = ""
  )
  cat(
    "Rows: analysis=",
    nrow(x$analysis),
    ", assessment=",
    nrow(x$assessment),
    ", excluded=",
    nrow(x$excluded),
    "\n",
    sep = ""
  )
  cat(
    "Seed: ",
    x$metadata$seed,
    "\n",
    sep = ""
  )

  invisible(x)
}


#' Print group-aware split validation
#'
#' @param x An object returned by
#'   [validate_gazepoint_ml_split()].
#' @param ... Additional arguments, currently unused.
#'
#'
#' @examples
#' example_data <- expand.grid(
#'   participant_id = sprintf("P%02d", 1:6),
#'   stimulus_id = sprintf("S%02d", 1:4),
#'   repetition = 1:2,
#'   KEEP.OUT.ATTRS = FALSE,
#'   stringsAsFactors = FALSE
#' )
#' example_data$trial_id <- paste0(
#'   example_data$stimulus_id,
#'   "_T",
#'   example_data$repetition
#' )
#' participant_number <- as.integer(
#'   sub("P", "", example_data$participant_id)
#' )
#' stimulus_number <- as.integer(
#'   sub("S", "", example_data$stimulus_id)
#' )
#' example_data$outcome <- factor(
#'   ifelse(
#'     (participant_number + stimulus_number) %% 2L == 0L,
#'     "review",
#'     "pass"
#'   ),
#'   levels = c("pass", "review")
#' )
#' row_index <- seq_len(nrow(example_data))
#' example_data$fixation_duration <- 180 + row_index
#' example_data$pupil_change <- round(
#'   sin(row_index / 7),
#'   4
#' )
#' example_data$repetition <- NULL
#' manifest <- create_gazepoint_feature_manifest(
#'   features = c("fixation_duration", "pupil_change"),
#'   scientific_source = c(
#'     "Gazepoint fixation export",
#'     "Gazepoint pupil export"
#'   ),
#'   source_table = c("fixations", "pupil"),
#'   transformation = c(
#'     "Trial-level mean",
#'     "Trial-level change"
#'   ),
#'   availability_stage = "during_exposure",
#'   prediction_time_available = TRUE,
#'   preprocessing_scope = "none",
#'   fold_local_required = FALSE
#' )
#' split <- split_gazepoint_ml_data(
#'   data = example_data,
#'   outcome = "outcome",
#'   predictors = c("fixation_duration", "pupil_change"),
#'   feature_manifest = manifest,
#'   generalization_target = "new_participants",
#'   participant_id = "participant_id",
#'   trial_id = "trial_id",
#'   stimulus_id = "stimulus_id",
#'   assessment_prop = 1 / 3,
#'   seed = 101L
#' )
#' validation <- validate_gazepoint_ml_split(split)
#' print(validation)
#' @return `x`, invisibly.
#'
#' @export
print.gazepoint_ml_split_validation <- function(x, ...) {
  cat("<gazepoint_ml_split_validation>\n")
  cat(
    "Overall status: ",
    toupper(x$status),
    "\n",
    sep = ""
  )
  cat(
    "Non-passing checks: ",
    nrow(x$issues),
    "\n",
    sep = ""
  )

  print(
    x$summary,
    row.names = FALSE,
    right = FALSE
  )

  invisible(x)
}


#' Write group-aware split tables to CSV
#'
#' @param x A `gazepoint_ml_split` object.
#' @param directory Output directory.
#' @param prefix Filename prefix.
#' @param tables Tables to export.
#' @param overwrite Whether existing files may be replaced.
#' @param na Character representation of missing values.
#'
#'
#' @examples
#' example_data <- expand.grid(
#'   participant_id = sprintf("P%02d", 1:6),
#'   stimulus_id = sprintf("S%02d", 1:4),
#'   repetition = 1:2,
#'   KEEP.OUT.ATTRS = FALSE,
#'   stringsAsFactors = FALSE
#' )
#' example_data$trial_id <- paste0(
#'   example_data$stimulus_id,
#'   "_T",
#'   example_data$repetition
#' )
#' participant_number <- as.integer(
#'   sub("P", "", example_data$participant_id)
#' )
#' stimulus_number <- as.integer(
#'   sub("S", "", example_data$stimulus_id)
#' )
#' example_data$outcome <- factor(
#'   ifelse(
#'     (participant_number + stimulus_number) %% 2L == 0L,
#'     "review",
#'     "pass"
#'   ),
#'   levels = c("pass", "review")
#' )
#' row_index <- seq_len(nrow(example_data))
#' example_data$fixation_duration <- 180 + row_index
#' example_data$pupil_change <- round(
#'   sin(row_index / 7),
#'   4
#' )
#' example_data$repetition <- NULL
#' manifest <- create_gazepoint_feature_manifest(
#'   features = c("fixation_duration", "pupil_change"),
#'   scientific_source = c(
#'     "Gazepoint fixation export",
#'     "Gazepoint pupil export"
#'   ),
#'   source_table = c("fixations", "pupil"),
#'   transformation = c(
#'     "Trial-level mean",
#'     "Trial-level change"
#'   ),
#'   availability_stage = "during_exposure",
#'   prediction_time_available = TRUE,
#'   preprocessing_scope = "none",
#'   fold_local_required = FALSE
#' )
#' split <- split_gazepoint_ml_data(
#'   data = example_data,
#'   outcome = "outcome",
#'   predictors = c("fixation_duration", "pupil_change"),
#'   feature_manifest = manifest,
#'   generalization_target = "new_participants",
#'   participant_id = "participant_id",
#'   trial_id = "trial_id",
#'   stimulus_id = "stimulus_id",
#'   assessment_prop = 1 / 3,
#'   seed = 101L
#' )
#' output_directory <- tempfile()
#' paths <- write_gazepoint_ml_split_csv(
#'   x = split,
#'   directory = output_directory,
#'   tables = c("summary", "group_counts")
#' )
#' paths
#' unlink(output_directory, recursive = TRUE)
#' @return A named character vector of normalized file paths,
#'   invisibly.
#'
#' @export
write_gazepoint_ml_split_csv <- function(
    x,
    directory,
    prefix = "gazepoint_ml_split",
    tables = c(
      "analysis",
      "assessment",
      "excluded",
      "assignment",
      "summary",
      "group_counts",
      "checks",
      "issues"
    ),
    overwrite = FALSE,
    na = "") {
  if (!inherits(x, "gazepoint_ml_split")) {
    stop(
      "`x` must be a `gazepoint_ml_split` object.",
      call. = FALSE
    )
  }

  if (
    !is.character(directory) ||
      length(directory) != 1L ||
      is.na(directory) ||
      !nzchar(directory)
  ) {
    stop(
      "`directory` must be a single non-empty path.",
      call. = FALSE
    )
  }

  if (
    !is.character(prefix) ||
      length(prefix) != 1L ||
      is.na(prefix) ||
      !nzchar(trimws(prefix))
  ) {
    stop(
      "`prefix` must be a single non-empty string.",
      call. = FALSE
    )
  }

  if (grepl("[/\\\\]", prefix)) {
    stop(
      "`prefix` must not contain directory separators.",
      call. = FALSE
    )
  }

  valid_tables <- c(
    "analysis",
    "assessment",
    "excluded",
    "assignment",
    "summary",
    "group_counts",
    "checks",
    "issues"
  )

  if (
    !is.character(tables) ||
      length(tables) == 0L ||
      anyNA(tables) ||
      any(!(tables %in% valid_tables))
  ) {
    stop(
      sprintf(
        "`tables` must use values from: %s.",
        paste(valid_tables, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  tables <- unique(tables)

  if (
    !is.logical(overwrite) ||
      length(overwrite) != 1L ||
      is.na(overwrite)
  ) {
    stop(
      "`overwrite` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  if (
    !is.character(na) ||
      length(na) != 1L ||
      is.na(na)
  ) {
    stop(
      "`na` must be a single non-missing character value.",
      call. = FALSE
    )
  }

  directory <- path.expand(directory)

  if (!dir.exists(directory)) {
    created <- dir.create(
      directory,
      recursive = TRUE
    )

    if (!created && !dir.exists(directory)) {
      stop(
        sprintf(
          "Could not create output directory: %s.",
          directory
        ),
        call. = FALSE
      )
    }
  }

  table_data <- list(
    analysis = x$analysis,
    assessment = x$assessment,
    excluded = x$excluded,
    assignment = x$assignment,
    summary = x$summary,
    group_counts = x$group_counts,
    checks = x$validation$checks,
    issues = x$validation$issues
  )

  files <- file.path(
    directory,
    paste0(
      prefix,
      "_",
      tables,
      ".csv"
    )
  )

  names(files) <- tables

  existing <- files[file.exists(files)]

  if (length(existing) > 0L && !overwrite) {
    stop(
      sprintf(
        "Output files already exist: %s.",
        paste(existing, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  for (table_name in tables) {
    utils::write.csv(
      table_data[[table_name]],
      file = files[[table_name]],
      row.names = FALSE,
      na = na,
      fileEncoding = "UTF-8"
    )
  }

  normalized <- vapply(
    files,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )

  invisible(normalized)
}
