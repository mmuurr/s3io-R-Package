#' @title Write a file to AWS S3
#' @param obj The object to write.
#' @param bucket [string] AWS S3 bucket name.
#' @param key [string] AWS S3 object key.
#' @param writefun [function] A write function where the first argument is the object to write and the second argument is a filepath.
#'        The function's signature should look like \code{writefun(obj, file, ...)}.
#' @param ... Additional arguments passed on to \code{writefun}.
#' @param .localfile [string] The local filepath for the initial write-to-disk.
#' @param .rm_localfile [boolean] Remove \code{localfile} once the copy-to-S3 is complete?
#' @param .put_object_args [list] Additional optional args passed on to \code{awscli::s3api_put_object}.
#'        A common option you may want to specify, e.g., is content-type: \code{.put_object_args = list("content-type" = "application/json")}.
#' @return The returned value from \code{writefun}.
#' @examples
#' \dontrun{
#'   s3io_write(iris, "mybucket", "my/object/key.csv", readr::write_csv, col_names = TRUE)
#' }
s3io_write <- function(obj, bucket, key,
                       writefun, ...,
                       .localfile = tempfile(),
                       .rm_localfile = TRUE,
                       .put_object_args = list()) {
    if(.rm_localfile) on.exit(try_file_remove(.localfile), add = TRUE)

    flog.debug("writing to %s", .localfile)
    retval <- withVisible(writefun(obj, .localfile, ...))
    flog.debug("%s --> s3://%s/%s", .localfile, bucket, key)
    do.call(awscli::s3api_put_object, c(list(.localfile, bucket, key), .put_object_args))

    if(retval$visible) {
        return(retval$value)
    } else {
        return(invisible(retval$value))
    }
}
