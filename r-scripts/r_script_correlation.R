# Load necessary libraries
library(ggplot2)
library(dplyr)
library(xtable)

# Load the dataset
run_data <- read.csv("/home/roy/Downloads/drive-download-20241023T190837Z-001/run_table.csv")

# Filter the dataset to include only 'basic' and 'human' solutions
run_data <- run_data %>%
  filter(solution %in% c("basic", "human"))

# Ensure the 'solution' column is treated as a factor with exactly two levels
run_data$solution <- factor(run_data$solution, levels = c("basic", "human"))

# Add problem category
run_data <- run_data %>%
  mutate(problem_category = case_when(
    problem %in% c("fibonacci_modified", "closest_numbers", "largest_rectangle") ~ "CPU bound",
    TRUE ~ "Memory bound"
  ))

# Calculate the highest median CPU usage across all 8 CPU cores for each run
run_data <- run_data %>%
  rowwise() %>%
  mutate(highest_median_cpu = max(c(CPU_USAGE_0_MEDIAN, CPU_USAGE_1_MEDIAN, CPU_USAGE_2_MEDIAN, CPU_USAGE_3_MEDIAN, 
                                    CPU_USAGE_4_MEDIAN, CPU_USAGE_5_MEDIAN, CPU_USAGE_6_MEDIAN, 
                                    CPU_USAGE_7_MEDIAN), na.rm = TRUE))

# Memory Usage will use the USED_MEMORY_MEDIAN column directly
run_data$highest_memory_usage <- run_data$USED_MEMORY_MEDIAN

# Function to perform correlation test and return formatted results
perform_correlation_test <- function(var1, var2, var_name, solution_type, category) {
  # Handle cases where there might be insufficient data
  if (length(var1) < 3 || length(var2) < 3) {
    return(c(category, solution_type, var_name, "Insufficient data", "NA", "NA"))
  }
  
  # Perform Shapiro-Wilk test
  if (shapiro.test(var1)$p.value > 0.05 && shapiro.test(var2)$p.value > 0.05) {
    test_result <- cor.test(var1, var2, method = "pearson")
    method <- "Pearson"
  } else {
    test_result <- cor.test(var1, var2, method = "spearman")
    method <- "Spearman"
  }
  
  # Format p-value with scientific notation if very small
  p_value <- ifelse(test_result$p.value < 0.001,
                    sprintf("%.2e", test_result$p.value),
                    sprintf("%.3f", test_result$p.value))
  
  return(c(category, solution_type, var_name, method, 
           sprintf("%.3f", test_result$estimate),
           p_value))
}

# Function to analyze one combination of solution type and problem category
analyze_group <- function(data, solution_type, category) {
  filtered_data <- data %>%
    filter(solution == solution_type, problem_category == category)
  
  if (nrow(filtered_data) == 0) {
    return(NULL)
  }
  
  rbind(
    perform_correlation_test(filtered_data$PACKAGE_ENERGY, filtered_data$Time, 
                             "Execution Time", solution_type, category),
    perform_correlation_test(filtered_data$PACKAGE_ENERGY, filtered_data$highest_median_cpu, 
                             "CPU Usage", solution_type, category),
    perform_correlation_test(filtered_data$PACKAGE_ENERGY, filtered_data$highest_memory_usage, 
                             "Memory Usage", solution_type, category)
  )
}

# Perform all analyses
results_list <- list()
for (category in c("CPU bound", "Memory bound")) {
  for (sol_type in c("human", "basic")) {
    result <- analyze_group(run_data, sol_type, category)
    if (!is.null(result)) {
      results_list[[length(results_list) + 1]] <- result
    }
  }
}

# Combine all results
results <- do.call(rbind, results_list)

# Create results data frame
results_df <- as.data.frame(results)
colnames(results_df) <- c("Category", "Solution", "Metric", "Method", "Correlation", "p-value")

# Create xtable object
xtable_output <- xtable(results_df,
                        caption = "Correlation Analysis with Energy Consumption by Problem Category and Solution Type",
                        label = "tab:correlation",
                        align = c("l", "l", "l", "l", "l", "r", "r"))

# Calculate row positions for horizontal lines
cpu_bound_end <- sum(results_df$Category == "CPU bound")
memory_bound_start <- cpu_bound_end + 1

# Print the xtable with specific formatting
print(xtable_output,
      include.rownames = FALSE,
      floating = TRUE,
      hline.after = c(-1, 0, 
                      cpu_bound_end,  # Line after CPU bound section
                      nrow(results_df)),  # Line at the end
      booktabs = TRUE,
      caption.placement = "top",
      sanitize.text.function = function(x) x)