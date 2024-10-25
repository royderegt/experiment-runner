# Load necessary libraries
library(dplyr)
library(ggplot2)
library(reshape2)
library(gridExtra)

# Load the dataset
data <- read.csv("/Users/joeldettinger/Downloads/run_table.csv")

# Step 1: Filter out rows where energy consumption is < 0
filtered_data <- data %>%
  filter(PACKAGE_ENERGY >= 0)

# Step 2: Calculate the highest median among the 8 CPU cores for each row
cpu_medians <- filtered_data %>%
  select(starts_with("CPU_USAGE_")) %>%
  select(contains("MEDIAN"))
filtered_data$HIGHEST_CPU_MEDIAN <- apply(cpu_medians, 1, max, na.rm = TRUE)

# Step 3: Use the median of memory usage for each row
filtered_data$MEMORY_MEDIAN <- filtered_data$USED_MEMORY_MEDIAN / (1024 * 1024)  # Convert to KB
filtered_data$Time <- filtered_data$Time / 1000  # Convert to seconds

# Step 4: Filter outliers using the IQR method for energy, CPU, and memory usage
filter_outliers <- function(x) {
  Q1 <- quantile(x, 0.25, na.rm = TRUE)
  Q3 <- quantile(x, 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  x[x >= (Q1 - 1.5 * IQR) & x <= (Q3 + 1.5 * IQR)]
}

 # filtered_data <- filtered_data %>%
 #   filter(PACKAGE_ENERGY %in% filter_outliers(PACKAGE_ENERGY),
 #          HIGHEST_CPU_MEDIAN %in% filter_outliers(HIGHEST_CPU_MEDIAN),
 #          MEMORY_MEDIAN %in% filter_outliers(MEMORY_MEDIAN))

# Set the order of the solutions
filtered_data$solution <- factor(filtered_data$solution, levels = c("human", "basic", "efficient"))

# Define a consistent color scheme
color_scheme <- c("human" = "#1f77b4", "basic" = "#ff7f0e", "efficient" = "#2ca02c")

# Step 5: Create the plots

# Violin plot for Total Energy Consumption across Human, Basic, and Efficient solutions
ggplot(filtered_data, aes(x = solution, y = PACKAGE_ENERGY, fill = solution)) +
  geom_violin(trim = FALSE, alpha = 0.6) +
  geom_boxplot(width = 0.1, position = position_dodge(width = 0.75), color = "black") +
  scale_fill_manual(values = color_scheme) +
  labs(title = "Total Energy Consumption for Human, Basic, and Efficient Solutions",
       x = "Solution Type",
       y = "Total Energy Consumption (Joules)") +
  theme_minimal()

# Violin plot for energy consumption by solution type for each coding problem
ggplot(filtered_data, aes(x = solution, y = PACKAGE_ENERGY, fill = solution)) +
  geom_violin(trim = TRUE, alpha = 0.6) +
  geom_boxplot(width = 0.1, position = position_dodge(width = 0.75), color = "black") +
  scale_fill_manual(values = color_scheme) +
  labs(title = "Energy Consumption for Each Problem Type",
       x = "Solution Type",
       y = "Energy Consumption (Joules)") +
  facet_wrap(~ problem, scales = "free") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Scatterplots for each category 
# CPU-heavy coding problems
cpu_heavy_problems <- c("fibonacci_modified", "closest_numbers", "largest_rectangle")
cpu_plot <- ggplot(filtered_data %>% filter(problem %in% cpu_heavy_problems), 
                   aes(x = HIGHEST_CPU_MEDIAN, y = PACKAGE_ENERGY, color = solution)) +
  geom_point() +
  scale_color_manual(values = color_scheme) +
  labs(title = "CPU bound Problems",
       x = "Highest CPU Usage Median (%)",
       y = "") +
  theme_minimal() +
  theme(legend.position = "none")  # Remove legend from this plot

# Memory-heavy coding problems
memory_heavy_problems <- c("array_manipulation", "hourglass_sum", "median_array")
memory_plot <- ggplot(filtered_data %>% filter(problem %in% memory_heavy_problems), 
                      aes(x = MEMORY_MEDIAN, y = PACKAGE_ENERGY, color = solution)) +
  geom_point() +
  scale_color_manual(values = color_scheme) +
  labs(title = "Memory bound Problems",
       x = "Memory Median (MB)",
       y = "") +
  ylim(0, 15000) +
  theme_minimal() +
  theme(legend.position = "none")  # Remove legend from this plot

# Correlation of energy consumption and execution time for all problems
time_plot <- ggplot(filtered_data, 
                    aes(x = Time, y = PACKAGE_ENERGY, color = solution)) +
  geom_point() +
  scale_color_manual(values = color_scheme) +
  labs(title = "All Problems",
       x = "Execution Time (s)",
       y = "") +  
  ylim(0, 15000) +
  theme_minimal() +
  theme(legend.position = "right")  # Keep legend for this plot

# Combine the scatter plots in one row
grid.arrange(cpu_plot,
             memory_plot,
             time_plot,
             ncol = 3, 
             left = "Energy Consumption (Joules)",
             heights = unit(4, "in"))