#' View \code{"surf"} object(s)
#' 
#' Visualize one or two \code{"surf"} objects(s), or the \code{"surf"} 
#'  component(s) in a \code{"xifti"} using an interactive Open GL window
#'  made with \code{rgl}. The \code{rgl} package is required.
#' 
#' This function works as a wrapper to \code{\link{view_xifti_surface}}, but 
#'  some arguments are not applicable (e.g. color scheme and legend). Also, 
#'  instead of using the \code{hemisphere} argument, name the surface arguments
#'  \code{surfL} or \code{surfR} (see description for parameter \code{...}).
#'  Finally, the default value for \code{param} is \code{"surf"}, not 
#'  \code{"xifti"}.
#' 
#' @inheritSection rgl_interactive_plots_Description Navigating and Embedding the Interactive Plots
#' @inheritSection rgl_static_plots_Description Embedding the Static Plots
#' 
#' @param ... One of: A \code{"surf"} object; two \code{"surf"} objects;
#'  or, a \code{"xifti"} object. If a \code{"surf"} object has an empty
#'  \code{"hemisphere"} metadata entry, it will be set to the opposite side 
#'  of the other's if known; otherwise, it will be set to the left side. If both
#'  are unknown, the first will be taken as the left and the second as the
#'  right. 
#' @inheritParams surface_plot_Params
#' 
#' @family surfing
#' @export
#' 
view_surf <- function(
  ..., view=c("both", "lateral", "medial"), widget=NULL, title=NULL,
  fname=FALSE, cex.title=NULL, text_color="black", bg=NULL,
  alpha=1.0, edge_color=NULL, vertex_color=NULL, vertex_size=0, material=NULL,
  width=NULL, height=NULL, zoom=NULL){
  
  surf <- list(...)

  # Convert any file names or giftis to surfaces.
  for (ii in seq_len(length(surf))) {
    if (!is.xifti(surf[[ii]], messages=FALSE)) {
      surf[[ii]] <- try(make_surf(surf[[ii]]))
      if (inherits(surf[[ii]], "try-error")) { 
        stop("A surface argument was neither a \"surface\" nor a \"xifti\" object.") 
      }
    }
  }

  # If surface arguments are named, use the names to get the hemisphere.
  if (any(names(surf) == "surfL")) {
    this_hemi <- is.null(surf[names(surf) == "surfL"]$hemisphere)
    if (is.null(this_hemi)) {
      surf[names(surf) == "surfL"]$hemisphere <- "left"
    } else {
      stop("surfL argument represents the right hemisphere.")
    }
  }
  if (any(names(surf) == "surfR")) {
    this_hemi <- is.null(surf[names(surf) == "surfR"]$hemisphere)
    if (is.null(this_hemi)) {
      surf[names(surf) == "surfR"]$hemisphere <- "right"
    } else {
      stop("surfR argument represents the left hemisphere.")
    }
  }

  # Handle the different surface arguments.
  if (length(surf) == 1) {
    surf <- surf[[1]]
    if (inherits(surf, "surf")) { 
      if (is.null(surf$hemisphere)) { surf$hemisphere <- "left" } 
      surfL <- switch(surf$hemisphere, left=surf, right=NULL)
      surfR <- switch(surf$hemisphere, left=NULL, right=surf)
    } else if (inherits(surf, "xifti")) {
      surfL <- surf$surf$cortex_left; surfR <- surf$surf$cortex_right
    } else {
      stop("The surface arguments must be \"surf\" or \"xifti\" objects.")
    }
  } else if (length(surf) == 2) {
    if (!inherits(surf[[1]], "surf") || !inherits(surf[[2]], "surf")) {
      stop(paste(
        "If arguments specifying the surfaces are provided, both must be",
        "\"surf\" objects."
      ))
    }
    if (is.null(surf[[1]]$hemisphere)) {
      if (is.null(surf[[2]]$hemisphere)) {
        surf[[1]]$hemisphere <- "left"; surf[[2]]$hemisphere <- "right"
        surfL <- surf[[1]]; surfR <- surf[[2]]
      } else {
        surf[[1]]$hemisphere <- switch(
          surf[[2]]$hemisphere, 
          left="right", right="left"
        )
      }
    } else {
      if (is.null(surf[[2]]$hemisphere)) {
        surf[[2]]$hemisphere <- switch(
          surf[[1]]$hemisphere, 
          left="right", right="left"
        )
      } else {
        if (surf[[1]]$hemisphere == surf[[2]]$hemisphere) {
          stop("The surfaces provided represent the same hemisphere.")
        }
      }
    }
    surfL <- switch(surf[[1]]$hemisphere, left=surf[[1]], right=surf[[2]]) 
    surfR <- switch(surf[[1]]$hemisphere, left=surf[[2]], right=surf[[1]])
  }

  hemisphere <- c("left", "right", "both")[1*(!is.null(surfL)) + 2*(!is.null(surfR))]

  # Plot
  view_xifti_surface(
    xifti=make_xifti(surfL=surfL, surfR=surfR),
    hemisphere=hemisphere, view=view, widget=widget, title=title, 
    fname=fname, cex.title=cex.title, text_color=text_color, bg=bg,
    alpha=alpha, edge_color=edge_color, 
    vertex_color=vertex_color, vertex_size=vertex_size,
    width=width, height=height, zoom=zoom
  )
}

#' S3 method: plot surface
#'
#' Visualize a single surface
#' 
#' @param x A \code{"surf"} object
#' @param ... Additional arguments to \code{\link{view_xifti_surface}}. But, the
#'  \code{hemisphere} argument behaves differently: it can be either
#'  \code{left} or \code{right} to indicate which hemisphere \code{x} 
#'  represents. It is only used if the \code{"hemisphere"} metadata entry in 
#'  \code{x} is \code{NULL}. If both the argument and the metadata entry are
#'  \code{NULL}, the surface will be treated as the left hemisphere.
#'
#' @method plot surf
#' 
#' @export
plot.surf <- function(x, ...){
  stopifnot(is.surf(x))

  if (is.null(x$hemisphere)) {
    if ("hemisphere" %in% names(list(...))) {
      hemisphere <- list(...)$hemisphere
      stopifnot(hemisphere %in% c("left", "right"))
      x$hemisphere <- hemisphere
    }
  }

  view_surf(x, ...)
}