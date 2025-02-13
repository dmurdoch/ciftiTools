% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/resample_cifti.R
\name{resample_cifti_wrapper}
\alias{resample_cifti_wrapper}
\title{\code{resample_cifti} wrapper}
\usage{
resample_cifti_wrapper(
  original_fnames,
  resamp_fnames = NULL,
  original_res,
  resamp_res,
  surfL_original_fname = NULL,
  surfR_original_fname = NULL,
  surfL_target_fname = NULL,
  surfR_target_fname = NULL,
  read_dir = NULL,
  write_dir = NULL
)
}
\arguments{
\item{original_fnames}{The files to resample. This is a named list
where each element's name is a file type label, and each element's value
is a file name. Labels must be one of the following: "cortexL", "cortexR",
"ROIcortexL", "ROIcortexR", "surfL", or "surfR". If
\code{read_dir} is not \code{NULL}, then all these file names should be
relative to \code{read_dir}.}

\item{resamp_fnames}{Where to write the resampled files. This is a named list
where each entry's name is a file type label, and each entry's value
is a file name indicating where to write the corresponding resampled file.
The recognized file type labels are: "cortexL", "cortexR",
"ROIcortexL", "ROIcortexR", "validROIcortexL", and "validROIcortexR".

Entry values can be \code{NULL}, in which case a default file name will be
used: see \code{\link{resample_cifti_default_fname}}. Default file names
will also be used for files that need to be resampled/written but without a
corresponding entry in \code{resamp_fnames}.

Entries in \code{resamp_fnames} will be ignored if they are not needed
based on \code{[ROI_]brainstructures}. For example, if
\code{brainstructures="left"}, then \code{resamp_fnames$cortexR} will be
ignored if specified.

The \code{write_dir} argument can be used to place each resampled file in
the same directory.}

\item{original_res}{The original resolution(s) of the CIFTI cortical surface(s).}

\item{resamp_res}{Target resolution for resampling (number of
cortical surface vertices per hemisphere).}

\item{surfL_target_fname, surfR_target_fname}{(Optional) File path for
the resampled GIFTI surface geometry file representing the left/right
cortex. If NULL (default),}

\item{read_dir}{Directory to append to the path of every file being read,
e.g. \code{cortexL_original_fname}. If \code{NULL} (default), do not append
any directory to the path.

\code{read_dir} must already exist, or an error will be raised.}

\item{write_dir}{Where should the separated files be placed? \code{NULL}
(default) will write them to the current working directory.

\code{write_dir} must already exist, or an error will occur.}
}
\value{
The return value of the \code{resample_cifti} call
}
\description{
Calls \code{resample_cifti} using the original file names
listed in the \code{original_fnames} argument and the target file names
listed in the \code{resamp_fnames} argument.
}
\details{
Currently used by read_cifti and resample_cifti.
}
\keyword{internal}
