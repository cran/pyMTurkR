#' ToDataFrameHITs
#'
#' Convert a list of HITs to a data frame
#'
#' @param hits hits
#' @return A data frame of information on HITs, one per row.
#' @export
ToDataFrameHITs <- function(hits) {

  HITs <- emptydf(length(hits), 19, c("HITId", "HITTypeId", "HITGroupId",
                                      "CreationTime", "Title", "Description", "Keywords", "HITStatus",
                                      "MaxAssignments", "Amount", "AutoApprovalDelayInSeconds",
                                      "Expiration", "AssignmentDurationInSeconds",
                                      "HITReviewStatus", "RequesterAnnotation", "NumberOfAssignmentsPending",
                                      "NumberOfAssignmentsAvailable", "NumberOfAssignmentsCompleted",
                                      "Question"))
  for (i in 1:length(hits)) {

    hit <- hits[[i]]
    HITs[i, 1] <- hit$HITId
    HITs[i, 2] <- hit$HITTypeId
    HITs[i, 3] <- hit$HITGroupId
    HITs[i, 4] <- reticulate::py_to_r(hit$CreationTime)
    HITs[i, 5] <- hit$Title
    HITs[i, 6] <- hit$Description
    if (!is.null(hit$Keywords)) {
      HITs[i, 7] <- hit$Keywords
    }
    HITs[i, 8] <- hit$HITStatus
    HITs[i, 9] <- hit$MaxAssignments
    if (!is.null(hit$Reward)) {
      HITs[i, 10] <- hit$Reward
    }
    HITs[i, 11] <- hit$AutoApprovalDelayInSeconds
    HITs[i, 12] <- reticulate::py_to_r(hit$Expiration)
    HITs[i, 13] <- hit$AssignmentDurationInSeconds
    HITs[i, 14] <- hit$HITReviewStatus
    if (!is.null(hit$RequesterAnnotation)) {
      HITs[i, 15] <- hit$RequesterAnnotation
    }
    HITs[i, 16] <- hit$NumberOfAssignmentsPending
    HITs[i, 17] <- hit$NumberOfAssignmentsAvailable
    HITs[i, 18] <- hit$NumberOfAssignmentsCompleted
    HITs[i, 19] <- hit$Question
  }

  invisible(return(HITs))
}


#' ToDataFrameReviewableHITs
#' @param hits hits
#' @return A Data frame of reviewable HIT information 
#' @export
ToDataFrameReviewableHITs <- function(hits) {

  HITs <- emptydf(length(hits), 2, c("HITId", "RequesterAnnotation"))
  for (i in 1:length(hits)) {

    hit <- hits[[i]]
    HITs[i, 1] <- hit$HITId
    if (!is.null(hit$RequesterAnnotation)) {
      HITs[i, 2] <- hit$RequesterAnnotation
    }
  }

  invisible(return(HITs))
}



# QUALIFICATION STRUCTURES

#' ToDataFrameQualificationRequirements
#' @param hits hits
#' @return A Data frame of Qualification Requirements for the given HITs
#' @export
ToDataFrameQualificationRequirements <- function(hits) {

  return.quals <- emptydf(nrow = 0, ncol = 6, c('HITId', 'QualificationTypeId',  'Comparator',
                                                'Value', 'RequiredToPreview', 'ActionsGuarded'))

  for (i in 1:length(hits)) {

    hit <- hits[[i]]
    hitid <- hit$HITId
    quals <- hit$QualificationRequirements

    Quals <- emptydf(length(quals), 6, c('HITId', 'QualificationTypeId',  'Comparator',
                                         'Value', 'RequiredToPreview', 'ActionsGuarded'))

    if(length(quals) > 0) {

      for (k in 1:length(quals)) {

        qual <- quals[[k]]

        Quals[k, 1] <- hitid
        Quals[k, 2] <- qual$QualificationTypeId
        Quals[k, 3] <- qual$Comparator

        # This may need more testing and more conditions
        if (!is.null(qual$IntegerValues)) {
          Quals[k, 4] <- qual$IntegerValues
        } else if (!is.null(qual$LocaleValues)) { # Country quals
          Quals[k, 4] <- qual$LocaleValues[[1]]$Country
          if(length(qual$LocaleValues) > 1) {
            for (j in 2:length(qual$LocaleValues)) {
              Quals[k, 4] <- paste(Quals[k, 4], ", ", qual$LocaleValues[[j]]$Country)
            }
          }
        }

        Quals[k, 5] <- qual$RequiredToPreview
        Quals[k, 6] <- qual$ActionsGuarded

      }
    } else {
      Quals[1, 1] <- hitid
    }
    return.quals <- rbind(Quals, return.quals)

  }

  return(return.quals)

}





# ASSIGNMENTS

#' ToDataFrameAssignment
#'
#' Get a list of assignment and answer information for an assignment
#' 
#' @param assignment assignment
#' @return A list of Data frames, for assignment information and answers
#' @export
ToDataFrameAssignment <- function(assignment) {

  Assignment <- emptydf(nrow = 1, ncol = 11, c('AssignmentId', 'WorkerId', 'HITId',
                                               'AssignmentStatus', 'AutoApprovalTime',
                                               'AcceptTime', 'SubmitTime', 'ApprovalTime',
                                               'RejectionTime', 'RequesterFeedback',
                                               'Answer'))

  return.answers <- list()

  Assignment[1] <- assignment$AssignmentId
  Assignment[2] <- assignment$WorkerId
  Assignment[3] <- assignment$HITId
  Assignment[4] <- assignment$AssignmentStatus
  Assignment[5] <- reticulate::py_to_r(assignment$AutoApprovalTime)

  if (!is.null(assignment$AcceptTime)) {
    Assignment[6] <- reticulate::py_to_r(assignment$AcceptTime)
  } else {
    Assignment[6] <- as.POSIXct(NA, origin = '1970-01-01')
  }

  Assignment[7] <- reticulate::py_to_r(assignment$SubmitTime)

  if (!is.null(assignment$ApprovalTime)) {
    Assignment[8] <- reticulate::py_to_r(assignment$ApprovalTime)
  } else {
    Assignment[8] <- as.POSIXct(NA, origin = '1970-01-01')
  }

  if (!is.null(assignment$RejectionTime)) {
    Assignment[9] <- reticulate::py_to_r(assignment$RejectionTime)
  } else {
    Assignment[9] <- as.POSIXct(NA, origin = '1970-01-01')
  }

  if (!is.null(assignment$RequesterFeedback)) {
    Assignment[10] <- assignment$RequesterFeedback
  }

  if (!is.null(assignment$Answer)) {
    answers <- ToDataFrameQuestionFormAnswers(Assignment, assignment$Answer)
    return.answers <- rbind(return.answers, answers)
  } else {
    return.answers = NULL
  }


  return(list(assignments = Assignment, answers = return.answers))
}






# QUESTION FORM ANSWERS

#' ToDataFrameQuestionFormAnswers
#' @param assignment assignment
#' @param answers answers
#' @return A Data frame of Answer information for the assignment 
#' @export
ToDataFrameQuestionFormAnswers <- function(assignment, answers) {

  # Parse XML
  nsDefs <- XML::xmlNamespaceDefinitions(XML::xmlParse(answers))
  ns <- structure(sapply(nsDefs, function(x) x$uri), names = names(nsDefs))
  names(ns)[1] <- "x"
  xmlAnswers <- XML::xpathSApply(XML::xmlParse(answers), "//x:Answer", namespaces=ns)

  questions <- length(XML::xmlChildren(xmlAnswers[[1]][["QuestionIdentifier"]]))
  return.answers <- emptydf(nrow = 0, 9, c("AssignmentId", "WorkerId", "HITId", "QuestionIdentifier",
                                           "FreeText", "SelectionIdentifier", "OtherSelectionField",
                                           "UploadedFileKey", "UploadedFileSizeInBytes"))

  for (i in 1:length(xmlAnswers)) {

    Answer <- emptydf(1, 9, c("AssignmentId", "WorkerId", "HITId", "QuestionIdentifier",
                              "FreeText", "SelectionIdentifier", "OtherSelectionField",
                              "UploadedFileKey", "UploadedFileSizeInBytes"))

    question <- xmlAnswers[[i]]

    Answer[1] <- assignment$AssignmentId
    Answer[2] <- assignment$WorkerId
    Answer[3] <- assignment$HITId
    Answer[4] <- XML::xmlValue(question[["QuestionIdentifier"]][[1]])
    if (!is.null(question[["FreeText"]]))
      Answer[5] <- XML::xmlValue(question[["FreeText"]][[1]])
    if (!is.null(question[["SelectionIdentifier"]]))
      Answer[6] <- XML::xmlValue(question[["SelectionIdentifier"]][[1]])
    if (!is.null(question[["OtherSelectionField"]]))
      Answer[7] <- XML::xmlValue(question[["OtherSelectionField"]][[1]])
    if (!is.null(question[["UploadedFileKey"]]))
      Answer[8] <- XML::xmlValue(question[["UploadedFileKey"]][[1]])
    if (!is.null(question[["UploadedFileSizeInBytes"]]))
      Answer[9] <- XML::xmlValue(question[["UploadedFileSizeInBytes"]][[1]])

    return.answers <- rbind(Answer, return.answers)

  }

  return(return.answers)

}



# BLOCKED WORKERS

#' ToDataFrameWorkerBlock
#' @param workers workers
#' @return A Data frame of blocked workers
#' @export
ToDataFrameWorkerBlock <- function(workers) {

  return.workers <- emptydf(0, 2, c("WorkerId", "Reason"))

  for (i in 1:length(workers)) {
    worker <- workers[[i]]
    this.worker <- emptydf(1, 2, c("WorkerId", "Reason"))
    this.worker[1] <- worker$WorkerId
    this.worker[2] <- worker$Reason
    return.workers <- rbind(return.workers, this.worker)
  }

  return.workers
}



# BONUS PAYMENTS

#' ToDataFrameBonusPayments
#'
#' @param bonuses bonuses
#' @return A Data frame of Bonus payment information
#' @export
ToDataFrameBonusPayments <- function(bonuses){


  return.bonuses <- emptydf(0, 5, c("AssignmentId", "WorkerId",
                                    "BonusAmount", "Reason",
                                    "GrantTime"))

  for (i in 1:length(bonuses)) {
    bonus <- bonuses[[i]]
    this.bonus <- emptydf(1, 5, c("AssignmentId", "WorkerId",
                                  "BonusAmount", "Reason",
                                  "GrantTime"))
    this.bonus[1] <- bonus$AssignmentId
    this.bonus[2] <- bonus$WorkerId
    this.bonus[3] <- bonus$BonusAmount
    this.bonus[4] <- bonus$Reason
    this.bonus[5] <- reticulate::py_to_r(bonus$GrantTime)
    return.bonuses <- rbind(return.bonuses, this.bonus)
  }

  return.bonuses
}



# QUALIFICATIONS

#' ToDataFrameQualificationRequests
#' @aliases ToDataFrameQualificationRequests
#' @param requests requests
#' @return A Data frame of Qualification Request information
#' @export
ToDataFrameQualificationRequests <- function(requests){

  return.requests <- emptydf(0, 6, c("QualificationRequestId",
                                     "QualificationTypeId", "WorkerId",
                                     "Test", "Answer",
                                     "SubmitTime"))

  if(length(requests) == 0){
    return(return.requests)
  } else {
    for (i in 1:length(requests)) {
      request <- requests[[i]]
      this.request <- emptydf(1, 6, c("QualificationRequestId",
                                      "QualificationTypeId", "WorkerId",
                                      "Test", "Answer",
                                      "SubmitTime"))

      this.request[1] <- request$QualificationRequestId
      this.request[2] <- request$QualificationTypeId
      this.request[3] <- request$WorkerId
      if(!is.null(request$Test)){
        this.request[4] <- request$Test
      }
      if(!is.null(request$Answer)){
        this.request[5] <- request$Answer
      }
      this.request[6] <- reticulate::py_to_r(request$SubmitTime)
      return.requests <- rbind(return.requests, this.request)
    }

    return.requests
  }
}


#' ToDataFrameQualifications
#' @param quals qualifications
#' @return A Data frame of qualification information 
#' @export
ToDataFrameQualifications <- function(quals){

  return.quals <- emptydf(0, 5, c("QualificationTypeId",
                                  "WorkerId", "GrantTime",
                                  "Value", "Status"))

  if(length(quals) == 0){
    return(return.quals)
  } else if(length(names(quals)) > 0) { # Test if list is not nested (1 qual)
    qual <- quals
    this.qual <- emptydf(1, 5, c("QualificationTypeId",
                                 "WorkerId", "GrantTime",
                                 "Value", "Status"))

    this.qual[1] <- qual$QualificationTypeId
    this.qual[2] <- qual$WorkerId
    this.qual[3] <- reticulate::py_to_r(qual$GrantTime)
    if(!is.null(qual$IntegerValue)){
      this.qual[4] <- qual$IntegerValue
    }
    this.qual[5] <- qual$Status
    this.qual

  } else { # Else more than 1 qual
    for (i in 1:length(quals)) {
      qual <- quals[[i]]
      this.qual <- emptydf(1, 5, c("QualificationTypeId",
                                   "WorkerId", "GrantTime",
                                   "Value", "Status"))

      this.qual[1] <- qual$QualificationTypeId
      this.qual[2] <- qual$WorkerId
      this.qual[3] <- reticulate::py_to_r(qual$GrantTime)
      if(!is.null(qual$IntegerValue)){
        this.qual[4] <- qual$IntegerValue
      }
      this.qual[5] <- qual$Status

      return.quals <- rbind(return.quals, this.qual)
    }

    return.quals
  }
}


#' ToDataFrameQualificationTypes
#' @param quals qualifications
#' @return A Data frame of Qualification Types
#' @export
ToDataFrameQualificationTypes <- function(quals) {

  return.quals <- emptydf(nrow = 0, ncol = 9, c('QualificationTypeId', 'CreationTime', 'Name',
                                                'Description', 'Keywords', 'QualificationTypeStatus',
                                                'RetryDelayInSeconds', 'IsRequestable', 'AutoGranted'))

  for (i in 1:length(quals)) {

    Quals <- emptydf(1, 9, c('QualificationTypeId', 'CreationTime', 'Name',
                             'Description', 'Keywords', 'QualificationTypeStatus',
                             'RetryDelayInSeconds', 'IsRequestable', 'AutoGranted'))

    qual <- quals[[i]]

    Quals[1] <- qual$QualificationTypeId
    if(!is.null(qual$CreationTime)){
      Quals[2] <- reticulate::py_to_r(qual$CreationTime)
    }
    Quals[3] <- qual$Name
    Quals[4] <- qual$Description
    if(!is.null(qual$Keywords)){
      Quals[5] <- qual$Keywords
    }
    Quals[6] <- qual$QualificationTypeStatus
    if(!is.null(qual$RetryDelayInSeconds)){
      Quals[7] <- qual$RetryDelayInSeconds
    }
    Quals[8] <- qual$IsRequestable
    Quals[9] <- qual$AutoGranted

    return.quals <- rbind(Quals, return.quals)

  }

  return(return.quals)

}






# REVIEW RESULTS

#' ToDataFrameReviewResults
#' @param results results
#' @return A list of Data frames of Assignment Reviews/Actions and HIT Reviews/Actions.
#' @export
ToDataFrameReviewResults <- function(results) {

  out <- list(AssignmentReviewResult = NULL,
              AssignmentReviewAction = NULL,
              HITReviewResult = NULL,
              HITReviewAction = NULL)

  if (length(results$AssignmentReviewReport) > 0) {

    out$AssignmentReviewResult <- emptydf(0, 8, c("HITId", "AssignmentReviewPolicy",
                                                  "ActionId", "SubjectId",
                                                  "SubjectType", "QuestionId",
                                                  "Key", "Value"))


    out$AssignmentReviewAction <- emptydf(0, 8, c("HITId", "AssignmentReviewPolicy",
                                                  "ActionId", "SubjectId",
                                                  "SubjectType", "QuestionId",
                                                  "Key", "Value"))

    review.results <- results$AssignmentReviewReport$ReviewResults
    review.actions <- results$AssignmentReviewReport$ReviewActions
    review.policy <- results$AssignmentReviewPolicy$PolicyName
    hit <- results$HITId

    for(i in 1:length(review.results)){
      result <- emptydf(1, 8, c("HITId", "AssignmentReviewPolicy", "ActionId", "SubjectId",
                                "SubjectType", "QuestionId", "Key", "Value"))
      result$HITId <- hit
      result$AssignmentReviewPolicy <- review.policy
      result$ActionId <- review.results[[i]]$ActionId
      result$SubjectId <- review.results[[i]]$SubjectId
      result$SubjectType <- review.results[[i]]$SubjectType
      result$QuestionId <- review.results[[i]]$QuestionId
      result$Key <- review.results[[i]]$Key
      result$Value <- review.results[[i]]$Value
      out$AssignmentReviewResult <- rbind(out$AssignmentReviewResult, result)
    }

    for(i in 1:length(review.actions)){
      action <- emptydf(1, 8, c("HITId", "AssignmentReviewPolicy", "ActionId", "ActionName",
                                "TargetId", "TargetType", "Status", "Result"))
      action$HITId <- hit
      action$AssignmentReviewPolicy <- review.policy
      action$ActionId <- review.actions[[i]]$ActionId
      action$ActionName <- review.actions[[i]]$ActionName
      action$TargetId <- review.actions[[i]]$TargetId
      action$TargetType <- review.actions[[i]]$TargetType
      action$Status <- review.actions[[i]]$Status
      if(!is.null(review.actions[[i]]$Result)){
        action$Result <- review.actions[[i]]$Result
      }
      out$AssignmentReviewAction <- rbind(out$AssignmentReviewAction, action)
    }

  }


  if (length(results$HITReviewReport) > 0) {

    out$HITReviewResult <- emptydf(0, 8, c("HITId", "HITReviewPolicy",
                                           "ActionId", "SubjectId",
                                           "SubjectType", "QuestionId",
                                           "Key", "Value"))


    out$HITReviewAction <- emptydf(0, 8, c("HITId", "HITReviewPolicy",
                                           "ActionId", "SubjectId",
                                           "SubjectType", "QuestionId",
                                           "Key", "Value"))

    review.results <- results$HITReviewReport$ReviewResults
    review.actions <- results$HITReviewReport$ReviewActions
    review.policy <- results$HITReviewPolicy$PolicyName
    hit <- results$HITId

    for(i in 1:length(review.results)){
      result <- emptydf(1, 8, c("HITId", "HITReviewPolicy", "ActionId", "SubjectId",
                                "SubjectType", "QuestionId", "Key", "Value"))
      result$HITId <- hit
      result$HITReviewPolicy <- review.policy
      result$ActionId <- review.results[[i]]$ActionId
      result$SubjectId <- review.results[[i]]$SubjectId
      result$SubjectType <- review.results[[i]]$SubjectType
      result$QuestionId <- review.results[[i]]$QuestionId
      result$Key <- review.results[[i]]$Key
      result$Value <- review.results[[i]]$Value
      out$HITReviewResult <- rbind(out$HITReviewResult, result)
    }

    for(i in 1:length(review.actions)){
      action <- emptydf(1, 8, c("HITId", "HITReviewPolicy", "ActionId", "ActionName",
                                "TargetId", "TargetType", "Status", "Result"))
      action$HITId <- hit
      action$HITReviewPolicy <- review.policy
      action$ActionId <- review.actions[[i]]$ActionId
      action$ActionName <- review.actions[[i]]$ActionName
      action$TargetId <- review.actions[[i]]$TargetId
      action$TargetType <- review.actions[[i]]$TargetType
      action$Status <- review.actions[[i]]$Status
      if(!is.null(review.actions[[i]]$Result)){
        action$Result <- review.actions[[i]]$Result
      }
      out$HITReviewAction <- rbind(out$HITReviewAction, action)
    }

  }

  return(out)
}

