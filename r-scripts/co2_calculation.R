# Load necessary library
library(dplyr)
library(DiagrammeR)

# Calculation of the CO2 emissions according to: https://sci-guide.greensoftware.foundation/

# Define the power usage in watts (inputs for laptop and Raspberry Pi)
laptop_watts_idle <- 6.3 # Average power usage of the Lenovo - ThinkPad T14s Gen 2 in watts (https://static.lenovo.com/ww/docs/regulatory/eco-declaration/eco-thinkpad-t14s-gen-2-amd.pdf)
raspberry_pi_watts_idle <- 1.9 # Average power usage of the Raspberry Pi 3 B+ in watts (https://www.pidramble.com/wiki/benchmarks/power-consumption)
emission_factor <- 268.48 # The average CO2 emissions in g for a kWh in the Netherlands for 2023 (https://www.statista.com/statistics/1290441/carbon-intensity-power-sector-netherlands/)

# Load the CSV file
run_table <- read.csv("/Users/joeldettinger/Downloads/run_table.csv")

# Filter runs where PACKAGE_ENERGY > 0
filtered_runs <- run_table %>%
  filter(PACKAGE_ENERGY > 0)

# Calculate total energy consumption in kWh (1 Joule = 2.77778e-7 kWh)
total_energy_kwh <- sum(filtered_runs$PACKAGE_ENERGY) * 2.77778e-7

# Calculate total time in hours (1 millisecond = 2.77778e-7 hours)
total_time_hours <- sum(filtered_runs$Time) * 2.77778e-7

# Calculate embodied emissions for laptop and Raspberry Pi
laptop_embodied_kwh <- laptop_watts_idle * total_time_hours / 1000 # Convert watts to kWh
raspberry_pi_embodied_kwh <- raspberry_pi_watts_idle * total_time_hours / 1000 # Convert watts to kWh
embodied_consumption <- laptop_embodied_kwh + raspberry_pi_embodied_kwh

# Add the embodied emissions to the total energy consumption
total_energy_with_embodied_kwh <- total_energy_kwh + embodied_consumption

# Calculate the carbon intensity using the formula SCI = (E * I) 
carbon_intensity <- (total_energy_with_embodied_kwh * emission_factor)

# Display results
cat("Total Energy Consumption:", round(total_energy_with_embodied_kwh, 3)," kWh \n")
cat("Experiment Consumption:", round(total_energy_kwh, 3)," kWh \n")
cat("Embodied Consumption:", round(embodied_consumption, 3)," kWh \n")
cat("Software Carbon Intensity (SCI):", round(carbon_intensity, 2)," g CO2e \n")
