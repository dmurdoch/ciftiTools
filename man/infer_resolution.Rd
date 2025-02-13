% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_xifti.R
\name{infer_resolution}
\alias{infer_resolution}
\title{Infer resolution from \code{"xifti"} and surfaces}
\usage{
infer_resolution(xifti, surfL = NULL, surfR = NULL)
}
\arguments{
\item{xifti}{A \code{"xifti"} object.}

\item{surfL}{Left surface}

\item{surfR}{Right surface}
}
\value{
The inferred resolution
}
\description{
Infer the numbers of vertices on each cortex of a \code{"xifti"} object.
Also supports the result of \code{\link{info_cifti}}.
}
