# Synthetic research demonstration; not part of the exported gp3ml API.
# Each participant has a repeated feature fingerprint and a randomly assigned
# participant label. The label contains no transportable population signal.
# Split conclusions apply only to this deliberately stylized source.
gp3ml_october_leakage_data <- function(seed = 20261022L,
                                      participants = 48L, trials = 6L) {
  stopifnot(length(seed) == 1L, participants >= 8L, trials >= 3L)
  set.seed(seed)
  id <- rep(seq_len(participants), each = trials)
  prototypes <- matrix(stats::rnorm(participants * 6L), ncol = 6L)
  features <- prototypes[id, , drop = FALSE] +
    matrix(stats::rnorm(length(id) * 6L, sd = 0.008), ncol = 6L)
  participant_y <- sample(rep(0:1, length.out = participants))
  list(id = id, y = participant_y[id], x = features)
}

gp3ml_october_leakage_accuracy <- function(dat, train, test) {
  stopifnot(length(train) > 0L, length(test) > 0L,
            length(intersect(train, test)) == 0L)
  pred <- vapply(test, function(k) {
    differences <- sweep(dat$x[train, , drop = FALSE], 2L, dat$x[k, ], "-")
    dat$y[train[which.min(rowSums(differences^2))]]
  }, integer(1L))
  mean(pred == dat$y[test])
}

gp3ml_october_leakage_audit <- function(repeats = 24L,
                                        seed = 20261022L) {
  stopifnot(length(repeats) == 1L, repeats >= 2L)
  dat <- gp3ml_october_leakage_data(seed = seed)
  n <- length(dat$id)
  participants <- unique(dat$id)
  result <- vector("list", 2L * repeats)
  for (i in seq_len(repeats)) {
    set.seed(seed + i)
    row_train <- sort(sample.int(n, size = floor(0.7 * n)))
    row_test <- setdiff(seq_len(n), row_train)
    group_train <- sort(sample(participants, floor(0.7 * length(participants))))
    group_train_rows <- which(dat$id %in% group_train)
    group_test_rows <- which(!dat$id %in% group_train)
    result[[2L * i - 1L]] <- data.frame(
      split = "observation", repeat_id = i,
      heldout_accuracy = gp3ml_october_leakage_accuracy(dat, row_train, row_test),
      shared_participants = length(intersect(unique(dat$id[row_train]),
                                             unique(dat$id[row_test]))),
      train_rows = length(row_train), test_rows = length(row_test))
    result[[2L * i]] <- data.frame(
      split = "participant", repeat_id = i,
      heldout_accuracy = gp3ml_october_leakage_accuracy(
        dat, group_train_rows, group_test_rows),
      shared_participants = length(intersect(unique(dat$id[group_train_rows]),
                                             unique(dat$id[group_test_rows]))),
      train_rows = length(group_train_rows), test_rows = length(group_test_rows))
  }
  do.call(rbind, result)
}

gp3ml_october_plot_leakage <- function(ledger) {
  required <- c("split", "heldout_accuracy", "shared_participants")
  stopifnot(is.data.frame(ledger), all(required %in% names(ledger)))
  oldpar <- graphics::par(mfrow = c(1L, 2L), mar = c(4, 4, 3, 1))
  on.exit(graphics::par(oldpar), add = TRUE)
  groups <- c("observation", "participant")
  for (j in seq_along(c("heldout_accuracy", "shared_participants"))) {
    key <- c("heldout_accuracy", "shared_participants")[j]
    values <- lapply(groups, function(s) ledger[[key]][ledger$split == s])
    graphics::boxplot(values, names = c("Row", "Participant"),
                      ylab = c("Held-out accuracy", "Shared participants")[j],
                      main = c("Synthetic 1-NN performance", "Train/test identity overlap")[j],
                      col = c("#D7E7F5", "#E8E8E8"), border = "#4E5967")
    graphics::stripchart(values, vertical = TRUE, add = TRUE,
                         method = "jitter", jitter = 0.08,
                         pch = 19, col = grDevices::adjustcolor("#254B6D", alpha.f = 0.45))
    if (j == 1L) graphics::abline(h = 0.5, lty = 3, col = "#777777")
  }
  invisible(ledger)
}
