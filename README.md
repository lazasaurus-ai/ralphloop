# ralphloop 
<img src="img/ralph-wiggum.png"
     alt="Ralph loop illustration"
     align="right"
     width="180"/>
`ralphloop` provides a persistent, truth-based iterative loop for LLM-driven
development workflows using the `ellmer` R package.

Inspired by the Ralph loop pattern from Anthropic’s Claude Code.


## Example

```r
library(ellmer)
library(ralphloop)

chat_client <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)

init_ralphloop(
  prompt = "Refactor the ETL pipeline and add tests",
  max_iterations = 10,
  completion_promise = "DONE"
)

ralph_loop(chat_client)

```

The loop continues until the completion promise is truthfully satisfied.

### Example with Status

````
  > ralphloop_status()
  
  🔍 ralphloop status
  ────────────────────────────────────────
  Active:              TRUE
  Iteration:           1
  Max iterations:      3
  Completion promise:  DONE
  Started at (UTC):    2026-01-15T02:23:56Z
  Output base dir:     /home/lazasaurus-ai/R/ralphloop
  Work directory:      /home/lazasaurus-ai/R/ralphloop/work
  ────────────────────────────────────────
  
  📌 Task prompt
  ────────────────────────────────────────
  Write a simple R function and add unit tests 
  ────────────────────────────────────────
  
  > ralph_loop(chat_client)
  🔄 Iteration 1
  Here's a simple R function with added unit tests:
  
  ```R
  # Function to calculate the area of a rectangle
  calculate_rectangle_area <- function(length, width) {
    if (!is.numeric(length) || !is.numeric(width)) {
      stop("Both length and width must be numeric values")
    }
    if (length <= 0 || width <= 0) {
      stop("Both length and width must be positive values")
    }
    return(length * width)
  }
  
  # Unit tests
  library(testthat)
  
  test_that("calculate_rectangle_area works correctly", {
    expect_equal(calculate_rectangle_area(5, 3), 15)
    expect_equal(calculate_rectangle_area(2.5, 4), 10)
    expect_equal(calculate_rectangle_area(10, 10), 100)
    
    expect_error(calculate_rectangle_area("5", 3), "Both length and width must be numeric values")
    expect_error(calculate_rectangle_area(5, "3"), "Both length and width must be numeric values")
    expect_error(calculate_rectangle_area(-5, 3), "Both length and width must be positive values")
    expect_error(calculate_rectangle_area(5, 0), "Both length and width must be positive values")
  })
  ```
  
  This code defines a function `calculate_rectangle_area` that calculates the area of a rectangle given its 
  length and width. It includes input validation to ensure that both inputs are numeric and positive.
  
  The unit tests use the `testthat` package to verify that the function works correctly for various inputs and
  throws appropriate errors for invalid inputs.
  
  To further improve this code, we could:
  
  1. Add more edge cases to the unit tests.
  2. Implement error handling for very large numbers to prevent overflow.
  3. Create a more comprehensive suite of geometric functions (e.g., area of circle, triangle, etc.).
  4. Add documentation using roxygen2 style comments for better code readability and potential package 
  development.
  
  Here's an example of how we might start to implement these improvements:
  
  ```R
  #' Calculate the area of a rectangle
  #'
  #' This function calculates the area of a rectangle given its length and width.
  #'
  #' @param length A positive numeric value representing the length of the rectangle.
  #' @param width A positive numeric value representing the width of the rectangle.
  #'
  #' @return The area of the rectangle as a numeric value.
  #'
  #' @examples
  #' calculate_rectangle_area(5, 3)
  #' calculate_rectangle_area(2.5, 4)
  #'
  #' @export
  calculate_rectangle_area <- function(length, width) {
    if (!is.numeric(length) || !is.numeric(width)) {
      stop("Both length and width must be numeric values")
    }
    if (length <= 0 || width <= 0) {
      stop("Both length and width must be positive values")
    }
    if (length > .Machine$double.xmax || width > .Machine$double.xmax) {
      stop("Input values are too large to calculate area")
    }
    return(length * width)
  }
  
  # Unit tests
  library(testthat)
  
  test_that("calculate_rectangle_area works correctly", {
    expect_equal(calculate_rectangle_area(5, 3), 15)
    expect_equal(calculate_rectangle_area(2.5, 4), 10)
    expect_equal(calculate_rectangle_area(10, 10), 100)
    expect_equal(calculate_rectangle_area(0.1, 0.1), 0.01)
    
    expect_error(calculate_rectangle_area("5", 3), "Both length and width must be numeric values")
    expect_error(calculate_rectangle_area(5, "3"), "Both length and width must be numeric values")
    expect_error(calculate_rectangle_area(-5, 3), "Both length and width must be positive values")
    expect_error(calculate_rectangle_area(5, 0), "Both length and width must be positive values")
    expect_error(calculate_rectangle_area(.Machine$double.xmax, 2), "Input values are too large to calculate 
  area")
  })
  ```
  
  This improved version includes roxygen2 documentation, handles very large input values, and adds more test 
  cases.
  🔄 Iteration 2
  Building on the previous improvements, let's expand our geometric functions library and enhance our testing 
  suite:
  
  ```R
  #' Geometric Shape Area Calculator
  #'
  #' A collection of functions to calculate areas of various geometric shapes.
  
  #' Calculate the area of a rectangle
  #'
  #' @param length A positive numeric value representing the length of the rectangle.
  #' @param width A positive numeric value representing the width of the rectangle.
  #' @return The area of the rectangle as a numeric value.
  #' @export
  calculate_rectangle_area <- function(length, width) {
    validate_positive_numeric(length, "length")
    validate_positive_numeric(width, "width")
    check_overflow(length * width)
    return(length * width)
  }
  
  #' Calculate the area of a circle
  #'
  #' @param radius A positive numeric value representing the radius of the circle.
  #' @return The area of the circle as a numeric value.
  #' @export
  calculate_circle_area <- function(radius) {
    validate_positive_numeric(radius, "radius")
    area <- pi * radius^2
    check_overflow(area)
    return(area)
  }
  
  #' Calculate the area of a triangle
  #'
  #' @param base A positive numeric value representing the base of the triangle.
  #' @param height A positive numeric value representing the height of the triangle.
  #' @return The area of the triangle as a numeric value.
  #' @export
  calculate_triangle_area <- function(base, height) {
    validate_positive_numeric(base, "base")
    validate_positive_numeric(height, "height")
    area <- 0.5 * base * height
    check_overflow(area)
    return(area)
  }
  
  # Helper functions
  
  validate_positive_numeric <- function(value, name) {
    if (!is.numeric(value) || value <= 0) {
      stop(paste(name, "must be a positive numeric value"))
    }
  }
  
  check_overflow <- function(value) {
    if (value > .Machine$double.xmax) {
      stop("Calculation result is too large")
    }
  }
  
  # Unit tests
  library(testthat)
  
  test_that("calculate_rectangle_area works correctly", {
    expect_equal(calculate_rectangle_area(5, 3), 15)
    expect_equal(calculate_rectangle_area(2.5, 4), 10)
    expect_equal(calculate_rectangle_area(10, 10), 100)
    expect_equal(calculate_rectangle_area(0.1, 0.1), 0.01)
    
    expect_error(calculate_rectangle_area("5", 3), "length must be a positive numeric value")
    expect_error(calculate_rectangle_area(5, "3"), "width must be a positive numeric value")
    expect_error(calculate_rectangle_area(-5, 3), "length must be a positive numeric value")
    expect_error(calculate_rectangle_area(5, 0), "width must be a positive numeric value")
    expect_error(calculate_rectangle_area(.Machine$double.xmax, 2), "Calculation result is too large")
  })
  
  test_that("calculate_circle_area works correctly", {
    expect_equal(calculate_circle_area(1), pi)
    expect_equal(calculate_circle_area(2), 4 * pi)
    expect_equal(round(calculate_circle_area(3), 6), 28.274334)
    
    expect_error(calculate_circle_area(-1), "radius must be a positive numeric value")
    expect_error(calculate_circle_area("2"), "radius must be a positive numeric value")
    expect_error(calculate_circle_area(0), "radius must be a positive numeric value")
  })
  
  test_that("calculate_triangle_area works correctly", {
    expect_equal(calculate_triangle_area(4, 3), 6)
    expect_equal(calculate_triangle_area(5, 2), 5)
    expect_equal(calculate_triangle_area(10, 10), 50)
    
    expect_error(calculate_triangle_area(-4, 3), "base must be a positive numeric value")
    expect_error(calculate_triangle_area(4, -3), "height must be a positive numeric value")
    expect_error(calculate_triangle_area("4", 3), "base must be a positive numeric value")
  })
  
  test_that("helper functions work correctly", {
    expect_silent(validate_positive_numeric(5, "test"))
    expect_error(validate_positive_numeric(-5, "test"), "test must be a positive numeric value")
    expect_error(validate_positive_numeric(0, "test"), "test must be a positive numeric value")
    expect_error(validate_positive_numeric("5", "test"), "test must be a positive numeric value")
    
    expect_silent(check_overflow(100))
    expect_error(check_overflow(.Machine$double.xmax * 2), "Calculation result is too large")
  })
  ```
  
  This improved version includes:
  
  1. Additional geometric functions for calculating areas of circles and triangles.
  2. Helper functions for input validation and overflow checking, reducing code duplication.
  3. More comprehensive unit tests for all functions, including edge cases.
  4. Consistent error messages and input validation across all functions.
  5. Roxygen2 documentation for all exported functions.
  
  To further enhance this code, we could:
  
  1. Add more geometric shapes (e.g., trapezoid, ellipse).
  2. Implement volume calculations for 3D shapes.
  3. Create a custom S3 class for shapes to allow for more complex operations.
  4. Add plotting capabilities to visualize the shapes.
  5. Optimize performance for large-scale calculations.
  🔄 Iteration 3
  Building on our geometric functions library, let's implement some of the suggested improvements:
  
  ```R
  #' Geometric Shape Calculator
  #'
  #' A collection of functions to calculate properties of various geometric shapes.
  
  library(ggplot2)
  
  #' Shape class
  #'
  #' @slot type Character string specifying the shape type.
  #' @slot dimensions List of numeric values representing the shape's dimensions.
  #' @export
  setClass("Shape", 
           slots = list(
             type = "character",
             dimensions = "list"
           ),
           validity = function(object) {
             if (!all(sapply(object@dimensions, is.numeric))) {
               return("All dimensions must be numeric")
             }
             if (!all(sapply(object@dimensions, function(x) x > 0))) {
               return("All dimensions must be positive")
             }
             return(TRUE)
           }
  )
  
  #' Calculate area of a shape
  #'
  #' @param shape A Shape object
  #' @return The area of the shape as a numeric value
  #' @export
  setGeneric("calculate_area", function(shape) standardGeneric("calculate_area"))
  
  #' @export
  setMethod("calculate_area", "Shape", function(shape) {
    switch(shape@type,
           "rectangle" = shape@dimensions$length * shape@dimensions$width,
           "circle" = pi * shape@dimensions$radius^2,
           "triangle" = 0.5 * shape@dimensions$base * shape@dimensions$height,
           "trapezoid" = 0.5 * (shape@dimensions$base1 + shape@dimensions$base2) * shape@dimensions$height,
           stop("Unsupported shape type")
    )
  })
  
  #' Calculate volume of a 3D shape
  #'
  #' @param shape A Shape object
  #' @return The volume of the shape as a numeric value
  #' @export
  setGeneric("calculate_volume", function(shape) standardGeneric("calculate_volume"))
  
  #' @export
  setMethod("calculate_volume", "Shape", function(shape) {
    switch(shape@type,
           "cube" = shape@dimensions$side^3,
           "sphere" = (4/3) * pi * shape@dimensions$radius^3,
           "cylinder" = pi * shape@dimensions$radius^2 * shape@dimensions$height,
           stop("Unsupported shape type or not a 3D shape")
    )
  })
  
  #' Plot a 2D shape
  #'
  #' @param shape A Shape object
  #' @return A ggplot object representing the shape
  #' @export
  plot_shape <- function(shape) {
    switch(shape@type,
           "rectangle" = {
             ggplot() + 
               geom_rect(aes(xmin = 0, xmax = shape@dimensions$length, 
                             ymin = 0, ymax = shape@dimensions$width),
                         fill = "blue", alpha = 0.5) +
               coord_fixed() +
               labs(title = "Rectangle")
           },
           "circle" = {
             ggplot() + 
               geom_circle(aes(x0 = 0, y0 = 0, r = shape@dimensions$radius),
                           fill = "red", alpha = 0.5) +
               coord_fixed() +
               labs(title = "Circle")
           },
           "triangle" = {
             ggplot() + 
               geom_polygon(aes(x = c(0, shape@dimensions$base, shape@dimensions$base/2),
                                y = c(0, 0, shape@dimensions$height)),
                            fill = "green", alpha = 0.5) +
               coord_fixed() +
               labs(title = "Triangle")
           },
           stop("Unsupported shape type or not a 2D shape")
    )
  }
  
  # Unit tests
  library(testthat)
  
  test_that("Shape class works correctly", {
    expect_s4_class(new("Shape", type = "rectangle", dimensions = list(length = 5, width = 3)), "Shape")
    expect_error(new("Shape", type = "rectangle", dimensions = list(length = -5, width = 3)), "All dimensions 
  must be positive")
    expect_error(new("Shape", type = "rectangle", dimensions = list(length = "5", width = 3)), "All dimensions
  must be numeric")
  })
  
  test_that("calculate_area works correctly", {
    rect <- new("Shape", type = "rectangle", dimensions = list(length = 5, width = 3))
    circ <- new("Shape", type = "circle", dimensions = list(radius = 2))
    tri <- new("Shape", type = "triangle", dimensions = list(base = 4, height = 3))
    
    expect_equal(calculate_area(rect), 15)
    expect_equal(calculate_area(circ), 4 * pi)
    expect_equal(calculate_area(tri), 6)
    
    expect_error(calculate_area(new("Shape", type = "hexagon", dimensions = list(side = 5))), "Unsupported 
  shape type")
  })
  
  test_that("calculate_volume works correctly", {
    cube <- new("Shape", type = "cube", dimensions = list(side = 3))
    sphere <- new("Shape", type = "sphere", dimensions = list(radius = 2))
    cylinder <- new("Shape", type = "cylinder", dimensions = list(radius = 2, height = 5))
    
    expect_equal(calculate_volume(cube), 27)
    expect_equal(calculate_volume(sphere), (4/3) * pi * 8)
    expect_equal(calculate_volume(cylinder), 20 * pi)
    
    expect_error(calculate_volume(new("Shape", type = "rectangle", dimensions = list(length = 5, width = 3))),
  "Unsupported shape type or not a 3D shape")
  })
  
  test_that("plot_shape works correctly", {
    rect <- new("Shape", type = "rectangle", dimensions = list(length = 5, width = 3))
    circ <- new("Shape", type = "circle", dimensions = list(radius = 2))
    tri <- new("Shape", type = "triangle", dimensions = list(base = 4, height = 3))
    
    expect_s3_class(plot_shape(rect), "ggplot")
    expect_s3_class(plot_shape(circ), "ggplot")
    expect_s3_class(plot_shape(tri), "ggplot")
    
    expect_error(plot_shape(new("Shape", type = "cube", dimensions = list(side = 3))), "Unsupported shape type
  or not a 2D shape")
  })
  ```
  
  This improved version includes:
  
  1. A custom S3 class `Shape` to represent different geometric shapes.
  2. Generic methods `calculate_area` and `calculate_volume` for calculating properties of shapes.
  3. A `plot_shape` function to visualize 2D shapes using ggplot2.
  4. Support for additional shapes (trapezoid, cube, sphere, cylinder).
  5. More comprehensive unit tests for all new functionality.
  
  To further enhance this code, we could:
  
  1. Implement more complex geometric operations (e.g., intersections, transformations).
  2. Add support for custom color schemes in the plotting function.
  3. Implement 3D visualization for 3D shapes using a package like `rgl`.
  4. Add more sophisticated error handling and input validation.
  5. Create a vignette demonstrating the usage of the package.
  🛑 Max iterations reached

  > system("ls work")
  iteration-1.md
  iteration-2.md
  iteration-3.md
````



