#' @title Intensify of SMAC model
#'
#' @description Checking if current candidate parameter configuration is better than the current best parameter configuration chosen till now or not.
#'
#' @param R Dataframe of tried out candidate parameter configurations.
#' @param bestParams String of best parameter configuration found till now.
#' @param bestPerf Vector of performance of classifier on all folds of dataset.
#' @param candidateConfs Vector of strings of candidate parameter configurations.
#' @param trainingSet Dataframe of the training set.
#' @param validationSet Dataframe of the validation Set.
#' @param foldedSet List of the folds of the dataset in each tree of the SMAC forest.
#' @param classifierAlgorithm  String value of the classifier Name.
#' @param maxTime Float of maximum time budget allowed.
#' @param timeTillNow Float of the time spent till now.
#' @param B number of trees in the forest of trees of SMAC optimization algorithm (default = 10).
#' @param metric Metric to be used in evaluation:
#' \itemize{
#' \item "acc" - Accuracy,
#' \item "avg-fscore" - Average of F-Score of each label,
#' \item "avg-recall" - Average of Recall of each label,
#' \item "avg-precision" - Average of Precision of each label,
#' \item "fscore" - Micro-Average of F-Score of each label,
#' \item "recall" - Micro-Average of Recall of each label,
#' \item "precision" - Micro-Average of Precision of each label.
#' }
#'
#' @return List of current best parameter configuration, its performance, dataframe of tried out candidate parameter configurations, and time till now.
#'
#' @examples intensify(c('1'), '1', c(0.89, 0.91), list(c(1,2,4), c(3,5)), data.frame(salary = c(623, 515, 611, 729, 843), class = c (0, 0, 0, 1, 1)), data.frame(salary = c(400, 800), class = c (0, 1)), 'knn', 100, 5, 2)
#'
#' @noRd
#'
#' @keywords internal

intensify <- function(R, bestParams, bestPerf, candidateConfs, foldedSet, trainingSet, validationSet, classifierAlgorithm, maxTime, timeTillNow , B = 10, metric = metric) {
  for(j in 1:nrow(candidateConfs)){
    cntParams <- candidateConfs[j,]
    cntPerf <- c()
    folds <- sample(1:B)
    pointer <- 1
    timeFlag <- FALSE
    N <- 1
    #number of folds with higher performance for candidate configuration
    forMe <- 0
    #number of folds with lower performance for candidate configuration
    againstMe <- 0
    fails <- 0
    while(pointer < B){
      for(i in pointer:min(pointer+N-1, B)){
        tmpPerf <- runClassifier(trainingSet[foldedSet[[i]], ], validationSet, cntParams, classifierAlgorithm, metric = metric)
        if(tmpPerf$perf == 0){
          fails <- fails + 1
        }
        cntPerf <- c(cntPerf, tmpPerf$perf)
        if(i > length(bestPerf))
          tmpPerf <- runClassifier(trainingSet[foldedSet[[i]], ], validationSet, bestParams, classifierAlgorithm, metric = metric)
          bestPerf <- c(bestPerf, tmpPerf$perf)
        if(cntPerf[i] >= bestPerf[i])forMe <- forMe + 1
        else againstMe <- againstMe + 1

        #Check time consumed till now
        t <- toc(quiet = TRUE)
        timeTillNow <- timeTillNow + t$toc - t$tic
        tic(quiet = TRUE)
        if(timeTillNow > maxTime || fails > 2){
          timeFlag <- TRUE
          break
        }
      }
      if(forMe < againstMe || timeFlag == TRUE) break
      pointer <- pointer + N
      N <- N * 2
    }
    #make the current candidate as the best candidate
    if(timeFlag == FALSE && forMe > againstMe){
      bestParams <- cntParams
      bestPerf <- cntPerf
    }
    cntParams$performance <- mean(cntPerf)
    bestParams$performance <- mean(bestPerf)
    R <- rbind(R, cntParams)
  }
  return(list(params = bestParams, perf = bestPerf, r = R, timeTillNow = timeTillNow, fails = fails))
}
