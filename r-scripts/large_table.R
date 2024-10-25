# Load required libraries
library(dplyr)
library(xtable)
library(tidyr)

generate_summary_table <- function(file_path) {
  # Read data and filter out negative values
  data <- read.csv(file_path) %>%
    filter(PACKAGE_ENERGY > 0)  # Filter out negative values
  
  # Function to calculate coefficient of variation
  cv <- function(x) (sd(x) / mean(x)) * 100
  
  # Calculate statistics for each problem and solution combination
  stats <- data %>%
    group_by(problem, solution) %>%
    summarise(
      Mean = mean(PACKAGE_ENERGY),
      SD = sd(PACKAGE_ENERGY),
      Min = min(PACKAGE_ENERGY),
      Median = median(PACKAGE_ENERGY),
      Max = max(PACKAGE_ENERGY),
      CV = cv(PACKAGE_ENERGY),
      n = n(),  # Count number of measurements
      .groups = 'drop'
    )
  
  # Function to reorder solutions for each problem
  reorder_solutions <- function(problem_data) {
    # Reorder the rows to match desired presentation order
    human_row <- problem_data[problem_data$solution == "human", ]
    basic_row <- problem_data[problem_data$solution == "basic", ]
    efficient_row <- problem_data[problem_data$solution == "efficient", ]
    
    bind_rows(human_row, basic_row, efficient_row)
  }
  
  # Apply reordering to each problem's data
  stats <- stats %>%
    group_by(problem) %>%
    group_modify(~reorder_solutions(.x)) %>%
    ungroup()
  
  # Get unique problems
  problems <- unique(stats$problem)
  n_problems <- length(problems)
  first_half <- problems[1:floor(n_problems/2)]
  second_half <- problems[(floor(n_problems/2) + 1):n_problems]
  
  # Print summary of filtered data
  cat("Number of measurements per problem and solution after filtering:\n")
  print(stats %>% select(problem, solution, n))
  
  # Function to format numbers
  format_number <- function(x) {
    if(is.na(x)) return("NA")
    
    # Special handling for CV which is already a percentage
    if(x < 100 && x > -100) {
      return(sprintf("%.2f", x))
    }
    
    # For regular energy values (expected to be in thousands)
    return(sprintf("%.0f", x))
  }
  
  # Create LaTeX table header
  latex_header <- "\\begin{table*}[t]
\\centering
\\small
\\begin{tabular}{l"
  
  # Add column specifications for first half
  for(p in first_half) {
    latex_header <- paste0(latex_header, "rrr")
  }
  latex_header <- paste0(latex_header, "}")
  
  # Create column headers
  header_row <- "\\toprule\n& "
  for(p in first_half) {
    header_row <- paste0(header_row, 
                         "\\multicolumn{3}{c}{", p, "} & ")
  }
  header_row <- substr(header_row, 1, nchar(header_row)-2)
  header_row <- paste0(header_row, "\\\\\n")
  
  # Create solution headers
  solution_row <- "Metric & "
  for(p in first_half) {
    solution_row <- paste0(solution_row, 
                           "Human & Basic & Efficient & ")
  }
  solution_row <- substr(solution_row, 1, nchar(solution_row)-2)
  solution_row <- paste0(solution_row, "\\\\\n\\midrule\n")
  
  # Create rows for each metric
  metrics <- c("Mean", "SD", "Min", "Median", "Max", "CV")
  rows <- ""
  
  for(metric in metrics) {
    row <- paste0(metric, " & ")
    for(p in first_half) {
      problem_data <- stats %>% 
        filter(problem == p)
      values <- problem_data[[metric]]
      
      # Format values
      formatted_values <- sapply(values, format_number)
      row <- paste0(row, 
                    paste(formatted_values, collapse = " & "),
                    " & ")
    }
    row <- substr(row, 1, nchar(row)-2)
    rows <- paste0(rows, row, "\\\\\n")
  }
  
  # First half of table
  first_table <- paste0(latex_header, "\n",
                        header_row,
                        solution_row,
                        rows,
                        "\\bottomrule\n\\end{tabular}\n",
                        "\\caption{Summary Statistics for Package Energy (First Half). All energy values are in Joules. CV is presented as percentage. Negative values were filtered out.}\n",
                        "\\label{tab:summary_stats1}\n",
                        "\\end{table*}\n\n")
  
  # Second half - similar process
  latex_header2 <- "\\begin{table*}[t]
\\centering
\\small
\\begin{tabular}{l"
  
  for(p in second_half) {
    latex_header2 <- paste0(latex_header2, "rrr")
  }
  latex_header2 <- paste0(latex_header2, "}")
  
  header_row2 <- "\\toprule\n& "
  for(p in second_half) {
    header_row2 <- paste0(header_row2, 
                          "\\multicolumn{3}{c}{", p, "} & ")
  }
  header_row2 <- substr(header_row2, 1, nchar(header_row2)-2)
  header_row2 <- paste0(header_row2, "\\\\\n")
  
  solution_row2 <- "Metric & "
  for(p in second_half) {
    solution_row2 <- paste0(solution_row2, 
                            "Human & Basic & Efficient & ")
  }
  solution_row2 <- substr(solution_row2, 1, nchar(solution_row2)-2)
  solution_row2 <- paste0(solution_row2, "\\\\\n\\midrule\n")
  
  rows2 <- ""
  for(metric in metrics) {
    row <- paste0(metric, " & ")
    for(p in second_half) {
      problem_data <- stats %>% 
        filter(problem == p)
      values <- problem_data[[metric]]
      
      # Format values
      formatted_values <- sapply(values, format_number)
      row <- paste0(row, 
                    paste(formatted_values, collapse = " & "),
                    " & ")
    }
    row <- substr(row, 1, nchar(row)-2)
    rows2 <- paste0(rows2, row, "\\\\\n")
  }
  
  # Second half of table
  second_table <- paste0(latex_header2, "\n",
                         header_row2,
                         solution_row2,
                         rows2,
                         "\\bottomrule\n\\end{tabular}\n",
                         "\\caption{Summary Statistics for Package Energy (Second Half). All energy values are in Joules. CV is presented as percentage. Negative values were filtered out.}\n",
                         "\\label{tab:summary_stats2}\n",
                         "\\end{table*}")
  
  # Write tables to file
  writeLines(c(first_table, second_table), "summary_tables.tex")
  
  cat("\nTables have been written to 'summary_tables.tex'\n")
}

generate_summary_table("/home/roy/Downloads/drive-download-20241023T190837Z-001/run_table.csv")