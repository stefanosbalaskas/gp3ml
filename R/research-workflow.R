
#' Simulate realistic cross-package Gazepoint research handoffs
#'
#' Generates deterministic, shareable, synthetic prepared outputs representing
#' handoffs from `gp3tools`, `gpbiometrics`, and `gp3sequences`. The outcome is
#' an experimentally assigned condition. Biometrics variables are signal-quality
#' summaries only; no health, emotion, stress, cognition, or other mental-state
#' outcome is generated or inferred.
#'
#' @param n_participants Number of participants.
#' @param n_stimuli Number of stimuli.
#' @param trials_per_stimulus Trials per participant-stimulus cell.
#' @param seed Deterministic seed.
#'
#' @return A `gp3ml_research_bundle`.
#' @export
simulate_gazepoint_research_handoffs <- function(
  n_participants = 24L,
  n_stimuli = 6L,
  trials_per_stimulus = 1L,
  seed = 3001L
) {
  n_participants <- as.integer(n_participants)
  n_stimuli <- as.integer(n_stimuli)
  trials_per_stimulus <- as.integer(trials_per_stimulus)

  if (n_participants < 6L || n_stimuli < 2L || trials_per_stimulus < 1L) {
    .gp3ml_stop(
      "Use at least 6 participants, 2 stimuli, and 1 trial per stimulus."
    )
  }

  restore <- .gp3ml_set_seed(seed)
  on.exit(restore(), add = TRUE)

  participants <- sprintf("P%03d", seq_len(n_participants))
  stimuli <- sprintf("S%02d", seq_len(n_stimuli))

  design <- expand.grid(
    participant_id = participants,
    stimulus_id = stimuli,
    replicate = seq_len(trials_per_stimulus),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  design$trial_id <- sprintf("T%05d", seq_len(nrow(design)))

  participant_condition <- rep(c("A", "B"), length.out = n_participants)
  names(participant_condition) <- participants
  design$assigned_condition <- participant_condition[design$participant_id]

  condition_b <- as.integer(design$assigned_condition == "B")
  n <- nrow(design)

  gaze <- data.frame(
    participant_id = design$participant_id,
    trial_id = design$trial_id,
    stimulus_id = design$stimulus_id,
    assigned_condition = design$assigned_condition,
    valid_gaze_prop = pmin(
      0.999,
      pmax(0.70, stats::rnorm(n, 0.92 + 0.015 * condition_b, 0.035))
    ),
    fixation_count = stats::rpois(n, lambda = 8 + 1.1 * condition_b),
    mean_fixation_ms = pmax(
      80,
      stats::rnorm(n, 225 + 14 * condition_b, 26)
    ),
    gaze_dispersion = pmax(
      0.02,
      stats::rnorm(n, 0.31 - 0.025 * condition_b, 0.055)
    ),
    stringsAsFactors = FALSE
  )

  biometrics <- data.frame(
    participant_id = design$participant_id,
    trial_id = design$trial_id,
    stimulus_id = design$stimulus_id,
    eda_valid_prop = pmin(
      1,
      pmax(0.65, stats::rnorm(n, 0.94, 0.035))
    ),
    hr_valid_prop = pmin(
      1,
      pmax(0.65, stats::rnorm(n, 0.96, 0.025))
    ),
    ibi_valid_prop = pmin(
      1,
      pmax(0.60, stats::rnorm(n, 0.90, 0.050))
    ),
    stringsAsFactors = FALSE
  )

  sequences <- data.frame(
    participant_id = design$participant_id,
    trial_id = design$trial_id,
    stimulus_id = design$stimulus_id,
    sequence_length = pmax(
      2L,
      stats::rpois(n, lambda = 9 + 0.8 * condition_b)
    ),
    unique_state_count = pmax(
      1L,
      pmin(6L, stats::rpois(n, lambda = 3.2))
    ),
    transition_rate = pmin(
      1,
      pmax(0, stats::rnorm(n, 0.58 + 0.03 * condition_b, 0.08))
    ),
    stringsAsFactors = FALSE
  )

  keys <- c("participant_id", "trial_id", "stimulus_id")

  handoffs <- list(
    gp3tools = create_gazepoint_handoff(
      gaze,
      source_package = "gp3tools",
      producer = "synthetic prepared gaze/fixation summaries",
      keys = keys,
      outcome = "assigned_condition",
      predictors = c(
        "valid_gaze_prop",
        "fixation_count",
        "mean_fixation_ms",
        "gaze_dispersion"
      )
    ),
    gpbiometrics = create_gazepoint_handoff(
      biometrics,
      source_package = "gpbiometrics",
      producer = "synthetic signal-quality summaries",
      keys = keys,
      predictors = c(
        "eda_valid_prop",
        "hr_valid_prop",
        "ibi_valid_prop"
      )
    ),
    gp3sequences = create_gazepoint_handoff(
      sequences,
      source_package = "gp3sequences",
      producer = "synthetic sequence summaries",
      keys = keys,
      predictors = c(
        "sequence_length",
        "unique_state_count",
        "transition_rate"
      )
    )
  )

  structure(
    list(
      handoffs = handoffs,
      keys = keys,
      outcome = "assigned_condition",
      generalization_target = "new_participants",
      seed = seed,
      governance_note = paste(
        "Synthetic workflow for an experimentally assigned condition.",
        "No medical, diagnostic, identity, protected-attribute, emotion,",
        "stress, cognition, comprehension, intent, personality, deception,",
        "or mental-state inference is represented."
      )
    ),
    class = "gp3ml_research_bundle"
  )
}

#' Validate a synthetic cross-package research bundle
#'
#' @param x A `gp3ml_research_bundle`.
#'
#' @return A `gp3ml_research_bundle_validation`.
#' @export
validate_gazepoint_research_bundle <- function(x) {
  if (!inherits(x, "gp3ml_research_bundle")) {
    .gp3ml_stop("`x` must be created by simulate_gazepoint_research_handoffs().")
  }

  required_sources <- c("gp3tools", "gpbiometrics", "gp3sequences")
  sources_present <- all(required_sources %in% names(x$handoffs))

  validations <- lapply(x$handoffs, validate_gazepoint_handoff)
  handoffs_pass <- all(vapply(
    validations,
    function(y) identical(y$status, "pass"),
    logical(1)
  ))

  combined <- if (handoffs_pass) {
    combine_gazepoint_handoffs(x$handoffs, keys = x$keys, collision = "error")
  } else {
    NULL
  }

  data <- if (is.null(combined)) data.frame() else combined$data
  outcome_present <- nrow(data) > 0L && x$outcome %in% names(data)

  prohibited_pattern <- paste(
    c(
      "emotion", "stress", "deception", "personality",
      "diagnos", "disease", "health_status", "protected",
      "identity", "intent", "cognition", "comprehension"
    ),
    collapse = "|"
  )
  prohibited_columns <- if (ncol(data)) {
    grep(
      prohibited_pattern,
      names(data),
      ignore.case = TRUE,
      value = TRUE
    )
  } else {
    character()
  }

  checks <- data.frame(
    check = c(
      "required_sources_present",
      "all_handoffs_pass",
      "combined_rows_present",
      "assigned_outcome_present",
      "no_prohibited_inference_columns",
      "participant_generalization_declared"
    ),
    status = c(
      if (sources_present) "pass" else "fail",
      if (handoffs_pass) "pass" else "fail",
      if (nrow(data) > 0L) "pass" else "fail",
      if (outcome_present) "pass" else "fail",
      if (!length(prohibited_columns)) "pass" else "fail",
      if (identical(x$generalization_target, "new_participants")) "pass" else "fail"
    ),
    detail = c(
      paste(names(x$handoffs), collapse = ", "),
      sprintf(
        "%d/%d handoffs passed.",
        sum(vapply(validations, function(y) y$status == "pass", logical(1))),
        length(validations)
      ),
      sprintf("%d combined rows.", nrow(data)),
      x$outcome,
      if (!length(prohibited_columns)) "None detected." else
        paste(prohibited_columns, collapse = ", "),
      x$generalization_target
    ),
    stringsAsFactors = FALSE
  )

  status <- if (any(checks$status == "fail")) "fail" else "pass"

  structure(
    list(
      status = status,
      checks = checks,
      handoff_validations = validations,
      bundle = combined,
      governance_note = x$governance_note
    ),
    class = "gp3ml_research_bundle_validation"
  )
}

#' @method print gp3ml_research_bundle
#' @export
print.gp3ml_research_bundle <- function(x, ...) {
  cat(
    " gp3ml research bundle: ",
    length(x$handoffs),
    " sources; outcome=",
    x$outcome,
    "; target=",
    x$generalization_target,
    "\n",
    sep = ""
  )
  invisible(x)
}

#' @method print gp3ml_research_bundle_validation
#' @export
print.gp3ml_research_bundle_validation <- function(x, ...) {
  cat(" gp3ml research bundle validation: ", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}

#' Plot research-bundle validation
#'
#' @param x A `gp3ml_research_bundle_validation`.
#' @param ... Additional graphical parameters.
#'
#' @method plot gp3ml_research_bundle_validation
#' @export
plot.gp3ml_research_bundle_validation <- function(x, ...) {
  if (!inherits(x, "gp3ml_research_bundle_validation")) {
    .gp3ml_stop("`x` must be a gp3ml research-bundle validation.")
  }
  values <- table(factor(x$checks$status, levels = c("pass", "review", "fail")))
  graphics::barplot(
    values,
    ylab = "Checks",
    main = paste("Integrated research workflow:", x$status),
    ...
  )
  invisible(x)
}
