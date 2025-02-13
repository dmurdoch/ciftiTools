#' \code{resample_cifti} wrapper
#'
#' Calls \code{resample_cifti} using the original file names
#'  listed in the \code{original_fnames} argument and the target file names
#'  listed in the \code{resamp_fnames} argument.
#'
#' Currently used by read_cifti and resample_cifti.
#'
#' @inheritParams original_fnames_Param_resampled
#' @param resamp_fnames Where to write the resampled files. This is a named list
#'  where each entry's name is a file type label, and each entry's value
#'  is a file name indicating where to write the corresponding resampled file.
#'  The recognized file type labels are: "cortexL", "cortexR",
#'  "ROIcortexL", "ROIcortexR", "validROIcortexL", and "validROIcortexR".
#'
#'  Entry values can be \code{NULL}, in which case a default file name will be
#'  used: see \code{\link{resample_cifti_default_fname}}. Default file names
#'  will also be used for files that need to be resampled/written but without a
#'  corresponding entry in \code{resamp_fnames}.
#'
#'  Entries in \code{resamp_fnames} will be ignored if they are not needed
#'  based on \code{[ROI_]brainstructures}. For example, if
#'  \code{brainstructures="left"}, then \code{resamp_fnames$cortexR} will be
#'  ignored if specified.
#'
#'  The \code{write_dir} argument can be used to place each resampled file in
#'  the same directory.
#' @param original_res The original resolution(s) of the CIFTI cortical surface(s).
#' @inheritParams resamp_res_Param_required
#' @inheritParams surfL_fname_Param
#' @inheritParams surfR_fname_Param
#' @param surfL_target_fname,surfR_target_fname (Optional) File path for
#'  the resampled GIFTI surface geometry file representing the left/right
#'  cortex. If NULL (default),
#' @inheritParams read_dir_Param_separated
#' @inheritParams write_dir_Param_generic
#'
#' @return The return value of the \code{resample_cifti} call
#'
#' @keywords internal
#'
resample_cifti_wrapper <- function(
  original_fnames, resamp_fnames=NULL,
  original_res, resamp_res,
  surfL_original_fname=NULL, surfR_original_fname=NULL,
  surfL_target_fname=NULL, surfR_target_fname=NULL,
  read_dir=NULL, write_dir=NULL) {

  # Get kwargs.
  resamp_kwargs <- list(
    original_res=original_res, resamp_res=resamp_res,
    surfL_original_fname=surfL_original_fname, 
    surfR_original_fname=surfR_original_fname,
    surfL_target_fname=surfL_target_fname,
    surfR_target_fname=surfR_target_fname,
    read_dir=read_dir, write_dir=write_dir
  )

  # Get expected file names.
  expected_labs <- get_kwargs(resample_cifti_components)
  expected_labs <- expected_labs[grepl("fname", expected_labs, fixed=TRUE)]
  expected_labs <- unique(gsub("_.*", "", expected_labs))

  # Check and add original file names to the kwargs.
  if (!is.null(original_fnames)) {
    match_input(names(original_fnames), expected_labs,
      user_value_label="original_fnames")
    resamp_kwargs[paste0(names(original_fnames), "_original_fname")] <- original_fnames
  }
  # Check and add resampled/target file names to the kwargs.
  if (!is.null(resamp_fnames)) {
    match_input(names(resamp_fnames), expected_labs,
      user_value_label="resamp_fnames")
    resamp_kwargs[paste0(names(resamp_fnames), "_target_fname")] <- resamp_fnames
  }

  # Do resample_cifti_components.
  resamp_kwargs[vapply(resamp_kwargs, is.null, FALSE)] <- NULL
  do.call(resample_cifti_components, resamp_kwargs)
}

#' Resample CIFTI data
#'
#' Performs spatial resampling of CIFTI data on the cortical surface
#'  by separating it into GIFTI and NIFTI files, resampling the GIFTIs, and then
#'  putting them together. (The subcortex is not resampled.)
#'
#'  Can accept a \code{"xifti"} object as well as a path to a CIFTI-file.
#'
#' @param x The CIFTI file name or \code{"xifti"} object to resample. If
#'  \code{NULL}, the result will be a \code{"xifti"} with resampled surfaces
#'  given by \code{surfL_original_fname} and \code{surfR_original_fname}.
#' @param cifti_target_fname File name for the resampled CIFTI. Will be placed
#'  in \code{write_dir}. If \code{NULL}, will be written to "resampled.d*.nii".
#'  \code{write_dir} will be appended to the beginning of the path.
#' @param surfL_original_fname,surfR_original_fname (Optional) Path to a GIFTI
#'  surface geometry file representing the left/right cortex. One or both can be
#'  provided. These will be resampled too, and are convenient for visualizing
#'  the resampled data.
#'
#'  If \code{x} is a \code{"xifti"} object with surfaces, these arguments
#'  will override the surfaces in the \code{"xifti"}.
#' @param surfL_target_fname,surfR_target_fname (Optional) File names for the
#'  resampled GIFTI surface geometry files. Will be placed in \code{write_dir}.
#'  If \code{NULL} (default), will use default names created by
#'  \code{\link{resample_cifti_default_fname}}.
#' @inheritParams resamp_res_Param_required
#' @param write_dir Where to write the resampled CIFTI (and surfaces if present.)
#'  If \code{NULL} (default), will use the current working directory if \code{x}
#'  was a CIFTI file, and a temporary directory if \code{x} was a \code{"xifti"}
#'  object.
#' @param mwall_values If the medial wall locations are not indicated in the
#'  CIFTI, use these values to infer the medial wall mask. Default:
#'  \code{c(NA, NaN)}. If \code{NULL}, do not attempt to infer the medial wall.
#'
#'  Correctly indicating the medial wall locations is important for resampling,
#'  because the medial wall mask is taken into account during resampling
#'  calculations.
#' @inheritParams verbose_Param_TRUE
#'
#' @return A named character vector of written files: \code{"cifti"} and
#'  potentially \code{"surfL"} (if \code{surfL_original_fname} was provided)
#'  and/or \code{"surfR"} (if \code{surfR_original_fname} was provided).
#'
#' @family common
#' @export
#'
#' @section Connectome Workbench:
#' This function interfaces with the \code{"-metric-resample"}, \code{"-label-resample"},
#'  and/or \code{"-surface-resample"} Workbench commands, depending on the input.
#'
resample_cifti <- function(
  x=NULL, cifti_target_fname=NULL,
  surfL_original_fname=NULL, surfR_original_fname=NULL,
  surfL_target_fname=NULL, surfR_target_fname=NULL,
  resamp_res, write_dir=NULL, mwall_values=c(NA, NaN), verbose=TRUE) {

  # Handle if no data ----------------------------------------------------------
  if (is.null(x)) {
    if (is.null(surfL_original_fname) && is.null(surfR_original_fname)) {
      warning("`x`, `surfL_original_fname` and `surfR_original_fname` were all NULL: Nothing to resample!\n")
      return(NULL)
    }
    return(read_cifti(
      surfL_fname=surfL_original_fname,
      surfR_fname=surfR_original_fname,
      resamp_res=resamp_res
    ))
  }

  input_is_xifti <- is.xifti(x, messages=FALSE)
  if (input_is_xifti && all(vapply(x$data, is.null, FALSE))) {
    x <- add_surf(x, surfL=surfL_original_fname, surfR=surfR_original_fname)
    if (!is.null(x$surf$cortex_left)) {
      x$surf$cortex_left <- resample_surf(x$surf$cortex_left, resamp_res, "left")
    }
    if (!is.null(x$surf$cortex_right)) {
      x$surf$cortex_right <- resample_surf(x$surf$cortex_right, resamp_res, "right")
    }
    return(x)
  }

  # Args check -----------------------------------------------------------------
  if (is.null(write_dir) & input_is_xifti) { write_dir <- tempdir() }
  stopifnot(resamp_res > 0)
  surfL_return <- surfR_return <- FALSE

  if (verbose) { exec_time <- Sys.time() }

  # Setup ----------------------------------------------------------------------
  if (input_is_xifti) {
    # Check intent. Treat unknown itents as dscalar.
    x_intent <- x$meta$cifti$intent
    if (!is.null(x_intent) && (x_intent %in% supported_intents()$value)) {
      x_extn <- supported_intents()$extension[supported_intents()$value == x_intent]
    } else {
      warning("The CIFTI intent was unknown, so resampling as a dscalar.")
      x_extn <- "dscalar.nii"
    }

    # Write out the CIFTI.
    cifti_original_fname <- file.path(tempdir(), paste0("to_resample.", x_extn))
    write_cifti(x, cifti_original_fname, verbose=FALSE)

    # Set the target CIFTI file name.
    if (is.null(cifti_target_fname)) {
      cifti_target_fname <- basename(gsub(
        "to_resample.", "resampled.", cifti_original_fname, fixed=TRUE
      ))
    }

    # Get the surfaces present.
    if (is.null(surfL_original_fname) && !is.null(x$surf$cortex_left)) {
      surfL_return <- TRUE
      surfL_original_fname <- file.path(tempdir(), "left.surf.gii")
      write_surf_gifti(x$surf$cortex_left, surfL_original_fname, hemisphere="left")
    }
    if (is.null(surfR_original_fname) && !is.null(x$surf$cortex_right)) {
      surfR_return <- TRUE
      surfR_original_fname <- file.path(tempdir(), "right.surf.gii")
      write_surf_gifti(x$surf$cortex_right, surfR_original_fname, hemisphere="right")
    }

    cifti_info <- x$meta
    brainstructures <- vector("character")
    if (!is.null(x$data$cortex_left)) { brainstructures <- c(brainstructures, "left") }
    if (!is.null(x$data$cortex_right)) { brainstructures <- c(brainstructures, "right") }
    if (!is.null(x$data$subcort)) { brainstructures <- c(brainstructures, "subcortical") }
    ROI_brainstructures <- brainstructures

    original_res <- infer_resolution(x)
    if (!is.null(original_res) && any(original_res < 2 & original_res > 0)) {
      warning("The CIFTI resolution is already too low (< 2 vertices). Skipping resampling.")
      return(x)
    }

  } else {
    # Check that the original file is valid.
    cifti_original_fname <- x
    stopifnot(file.exists(cifti_original_fname))
    cifti_info <- info_cifti(cifti_original_fname)
    brainstructures <- ROI_brainstructures <- cifti_info$cifti$brainstructures
    # Check that the resolutions match
    # Set the target CIFTI file name.
    if (is.null(cifti_target_fname)) {
      cifti_target_fname <- paste0("resampled.", get_cifti_extn(cifti_original_fname))
    }

    original_res <- infer_resolution(cifti_info)
    if (!is.null(original_res) && any(original_res < 2 & original_res > 0)) {
      warning("The CIFTI resolution is already too low (< 2 vertices). Skipping resampling.")
      return(NULL)
    }
  }
  cifti_target_fname <- format_path(cifti_target_fname, write_dir, mode=2)

  # Check that at least one surface is present.
  if (!("left" %in% brainstructures || "right" %in% brainstructures)) {
    warning("The CIFTI does not have cortical data, so there's nothing to resample.")
    if (input_is_xifti) { return(x) } else { return(NULL) }
  }

  # Separate the CIFTI ---------------------------------------------------------

  if (verbose) { cat("Separating CIFTI file.\n") }

  to_cif <- separate_cifti_wrapper(
    cifti_fname=cifti_original_fname,
    brainstructures=brainstructures, ROI_brainstructures=ROI_brainstructures,
    sep_fnames=NULL, write_dir=tempdir()
  )

  if (verbose) {
    print(Sys.time() - exec_time)
    exec_time <- Sys.time()
  }

  # Handle medial wall values --------------------------------------------------

  if (!is.null(mwall_values)) {
    if ("left" %in% brainstructures) {
      fix_gifti_mwall(
        to_cif["cortexL"], to_cif["cortexL"],
        to_cif["ROIcortexL"], to_cif["ROIcortexL"],
        mwall_values
      )
    }
    if ("right" %in% brainstructures) {
      fix_gifti_mwall(
        to_cif["cortexR"], to_cif["cortexR"],
        to_cif["ROIcortexR"], to_cif["ROIcortexR"],
        mwall_values
      )
    }
  }

  # resample_cifti_components() ------------------------------------------------

  # Do not resample the subcortical data.
  to_resample <- to_cif[!grepl("subcort", names(to_cif))]
  if (verbose) { cat("Resampling CIFTI file.\n") }

  # Do resample_cifti_components.
  resamp_result <- resample_cifti_wrapper(
    original_res=original_res, resamp_res=resamp_res,
    original_fnames=to_resample, resamp_fnames=NULL,
    surfL_original_fname=surfL_original_fname, 
    surfR_original_fname=surfR_original_fname,
    surfL_target_fname=surfL_target_fname,
    surfR_target_fname=surfR_target_fname,
    read_dir=NULL, write_dir=tempdir()
  )

  # Replace resampled files.
  to_cif[names(to_cif) %in% names(resamp_result)] <- resamp_result[names(to_cif)[names(to_cif) %in% names(resamp_result)]]

  # Copy resampled surface files to desired file paths.
  if (!is.null(surfL_original_fname)) {
    surfL_target_fname_old <- resamp_result["surfL"]
    surfL_target_fname <- format_path(basename(surfL_target_fname_old), write_dir, mode=2)
    file.copy(surfL_target_fname_old, surfL_target_fname)
  }
  if (!is.null(surfR_original_fname)) {
    surfR_target_fname_old <- resamp_result["surfR"]
    surfR_target_fname <- format_path(basename(surfR_target_fname_old), write_dir, mode=2)
    file.copy(surfR_target_fname_old, surfR_target_fname)
  }

  if (verbose) {
    print(Sys.time() - exec_time)
    exec_time <- Sys.time()
  }

  # Put together ---------------------------------------------------------------

  # Create target CIFTI dense timeseries.
  if (verbose) cat("Merging components into a CIFTI file... \n")
  to_cif <- to_cif[names(to_cif) != "ROIsubcortVol"]
  wcfs_kwargs <- c(list(cifti_fname=cifti_target_fname), as.list(to_cif))
  do.call(write_cifti_from_separate, wcfs_kwargs)

  if (verbose) {
    print(Sys.time() - exec_time)
    exec_time <- Sys.time()
  }

  # Return results -------------------------------------------------------------
  if (input_is_xifti) {
    read_xifti_args <- list(
      cifti_fname = cifti_target_fname,
      brainstructures = brainstructures
    )
    if (surfL_return) { read_xifti_args$surfL_fname <- surfL_target_fname }
    if (surfR_return) { read_xifti_args$surfR_fname <- surfR_target_fname }
    return(do.call(read_xifti, read_xifti_args))
  } else {
    return(unlist(list(
      cifti=cifti_target_fname,
      surfL=surfL_target_fname, surfR=surfR_target_fname
    )))
  }
}

#' @rdname resample_cifti
#' @export
resampleCIfTI <- function(
  x=NULL, cifti_target_fname=NULL,
  surfL_original_fname=NULL, surfR_original_fname=NULL,
  surfL_target_fname=NULL, surfR_target_fname=NULL,
  resamp_res, write_dir=NULL, mwall_values=c(NA, NaN), verbose=TRUE) {

  resample_cifti(
    x=x, cifti_target_fname=cifti_target_fname,
    surfL_original_fname=surfL_original_fname, surfR_original_fname=surfR_original_fname,
    surfL_target_fname=surfL_target_fname, surfR_target_fname=surfR_target_fname,
    resamp_res=resamp_res, write_dir=write_dir, mwall_values=mwall_values, verbose=verbose
  )
}

#' @rdname resample_cifti
#' @export
resamplecii <- function(
  x=NULL, cifti_target_fname=NULL,
  surfL_original_fname=NULL, surfR_original_fname=NULL,
  surfL_target_fname=NULL, surfR_target_fname=NULL,
  resamp_res, write_dir=NULL, mwall_values=c(NA, NaN), verbose=TRUE) {

  resample_cifti(
    x=x, cifti_target_fname=cifti_target_fname,
    surfL_original_fname=surfL_original_fname, surfR_original_fname=surfR_original_fname,
    surfL_target_fname=surfL_target_fname, surfR_target_fname=surfR_target_fname,
    resamp_res=resamp_res, write_dir=write_dir, mwall_values=mwall_values, verbose=verbose
  )
}

#' @rdname resample_cifti
#' @export
resample_xifti <- function(
  x=NULL, cifti_target_fname=NULL,
  surfL_original_fname=NULL, surfR_original_fname=NULL,
  surfL_target_fname=NULL, surfR_target_fname=NULL,
  resamp_res, write_dir=NULL, mwall_values=c(NA, NaN), verbose=TRUE) {

  resample_cifti(
    x=x, cifti_target_fname=cifti_target_fname,
    surfL_original_fname=surfL_original_fname, surfR_original_fname=surfR_original_fname,
    surfL_target_fname=surfL_target_fname, surfR_target_fname=surfR_target_fname,
    resamp_res=resamp_res, write_dir=write_dir, mwall_values=mwall_values, verbose=verbose
  )
}
