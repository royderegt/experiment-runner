# # Load required libraries
# library(effsize)  # For Cliff's delta
# library(xtable)   # For LaTeX tables
# library(dplyr)    # For data manipulation
# library(stats)    # For statistical tests
# 
# analyze_energy <- function(file_path) {
#   # Read data
#   data <- read.csv(file_path)
#   
#   # Initialize results dataframe
#   results <- data.frame(
#     Problem = character(),
#     P_Value = numeric(),
#     Cliffs_Delta = numeric(),
#     Effect_Size_Interpretation = character(),
#     stringsAsFactors = FALSE
#   )
#   
#   # Get unique problems
#   problems <- unique(data$problem)
#   
#   # Analyze each problem
#   for (prob in problems) {
#     # Subset data for current problem
#     prob_data <- subset(data, problem == prob)
#     
#     # Get energy values for human and basic solutions
#     human_energy <- prob_data$PACKAGE_ENERGY[prob_data$solution == "human"]
#     basic_energy <- prob_data$PACKAGE_ENERGY[prob_data$solution == "basic"]
#     
#     # Skip if either group has less than 2 observations
#     if (length(human_energy) < 2 || length(basic_energy) < 2) {
#       next
#     }
#     
#     # Perform Wilcoxon rank sum test (Mann-Whitney U test)
#     test_result <- wilcox.test(human_energy, basic_energy)
#     
#     # Calculate Cliff's delta
#     cliff_delta <- cliff.delta(human_energy, basic_energy)
#     
#     # Interpret effect size
#     effect_size <- case_when(
#       abs(cliff_delta$estimate) < 0.147 ~ "Negligible",
#       abs(cliff_delta$estimate) < 0.33 ~ "Small",
#       abs(cliff_delta$estimate) < 0.474 ~ "Medium",
#       TRUE ~ "Large"
#     )
#     
#     # Add results to dataframe
#     results <- rbind(results, data.frame(
#       Problem = prob,
#       P_Value = test_result$p.value,
#       Cliffs_Delta = cliff_delta$estimate,
#       Effect_Size_Interpretation = effect_size
#     ))
#   }
#   
#   # Calculate overall statistics
#   all_human_energy <- data$PACKAGE_ENERGY[data$solution == "human"]
#   all_basic_energy <- data$PACKAGE_ENERGY[data$solution == "basic"]
#   
#   # Overall Wilcoxon test
#   overall_test <- wilcox.test(all_human_energy, all_basic_energy)
#   
#   # Overall Cliff's delta
#   overall_cliff <- cliff.delta(all_human_energy, all_basic_energy)
#   
#   # Interpret overall effect size
#   overall_effect <- case_when(
#     abs(overall_cliff$estimate) < 0.147 ~ "Negligible",
#     abs(overall_cliff$estimate) < 0.33 ~ "Small",
#     abs(overall_cliff$estimate) < 0.474 ~ "Medium",
#     TRUE ~ "Large"
#   )
#   
#   # Add overall results as the last row
#   results <- rbind(results, data.frame(
#     Problem = "Overall",
#     P_Value = overall_test$p.value,
#     Cliffs_Delta = overall_cliff$estimate,
#     Effect_Size_Interpretation = overall_effect
#   ))
#   
#   # Format p-values and Cliff's delta for display
#   results$P_Value <- format.pval(results$P_Value, digits = 3)
#   results$Cliffs_Delta <- round(results$Cliffs_Delta, 3)
#   
#   # Generate LaTeX table
#   latex_table <- xtable(results,
#                         caption = "Statistical Comparison of Human vs Basic Solutions",
#                         label = "tab:energy_comparison",
#                         align = c("l", "l", "r", "r", "l"))
#   
#   # Print results
#   print("Results of Analysis:")
#   print(results)
#   
#   # Print LaTeX table
#   print("LaTeX Table:")
#   print(latex_table, include.rownames = FALSE)
#   
#   return(results)
# }
# 
# # Example usage:
# results <- analyze_energy("/home/roy/Downloads/drive-download-20241023T190837Z-001/run_table.csv")