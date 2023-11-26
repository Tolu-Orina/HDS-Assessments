# ------------------------------------------------------------------------------
# PART 2: CASE STUDY OF HEALTHCARE ACCESS WITHIN SWANSEA LOCAL COUNCIL 
# Tolulope Orina (Health Data Science Msc Student)
# 26.11.2023
# ------------------------------------------------------------------------------

# 1. General Importing of the necessary libraries.
# ------------------------------------------------------------------------------
library(RPostgreSQL)    # To access the database.
library(GetoptLong)     # To substitute variables into strings.
library(tidyverse)  # To make use of the many functions available in the tidyverse
library(ggplot2) # Import ggplot2 for better visualizations
library(stringr)
library(lubridate)
library(tools)


# Connect to the PostgreSQL Database
drv <- dbDriver('PostgreSQL')
con <- dbConnect(drv, dbname='gp_practice_data', host='localhost',
                 port=5432, user='postgres',
                 password=.rs.askForPassword(prompt = "Please enter your password: "))
tables <- dbListTables(con)
print(tables)

####### FINDING 1: 
# - NUMBER OF GP PRACTICES IN SWANSEA
# - THE HEALTH BOARD AND LOCALITY THEY BELONG TO
# - NUMBER OF GP PRACICES IN EACH HEALTH BOARD AND EACH LOCALITY
# ------------------------------------------------------------------------------
query_1 <- "
            -- GP practices within the Swansea council
          	SELECT *
          	from address
          	WHERE postcode like 'SA%' and practiceid like 'W%';
            "
swansea_gp_practices <- dbGetQuery(con, query_1)

# Remove the locality column as it contains NAs for the GP practices
swansea_gp_practices <- swansea_gp_practices %>%
                          select(-locality)
View(swansea_gp_practices)

# The number of GP practices within the Swansea council
num_gp_practices_swansea <- swansea_gp_practices %>%
                              summarize(num_gp_practices = n())
View(num_gp_practices_swansea)

# Health boards in Swansea
query_2 <- "
            -- Health boards in Swansea
          	SELECT *
          	from address
          	WHERE locality like '%HB' and postcode like 'SA%';
            "
swansea_hbs <- dbGetQuery(con, query_2)

# Rename Locality to Healthboard name and practiceid to hb
# and remove trailng whitespaces from hb column
swansea_hbs <- swansea_hbs %>%
                rename(healthboard_name = locality,
                       hb = practiceid) %>%
                mutate(hb = trimws(hb))
# View(swansea_hbs)

query_3 <- "
            -- Localities within Swansea
          	SELECT *
          	from address
          	WHERE practiceid like '6%' and postcode like 'SA%';
            "
swansea_locals <- dbGetQuery(con, query_3)

# Rename locality to locality_name and practiceid to locality
# and remove trailng whitespaces from locality column
swansea_locals <- swansea_locals %>%
                    rename(locality_name = locality,
                           locality = practiceid) %>%
                    mutate(locality = trimws(locality))
# View(swansea_locals)

query_4 <- "
        -- GP practice prescribing data for Swansea
        SELECT *
        FROM gp_data_up_to_2015
        WHERE practiceid IN 
                  (
                  -- GP practices in Swansea 
                  SELECT practiceid
                  FROM address
                	WHERE postcode like 'SA%' and practiceid like 'W%'
                  );
        "
swansea_gp_data <- dbGetQuery(con, query_4)

View(swansea_gp_data)

# Pick only the Health board and its name
swansea_hbs_name <- swansea_hbs %>%
  select(hb, healthboard_name)

# Pick only the locality and its name
swansea_locals_name <- swansea_locals %>%
  select(locality, locality_name)

# Select only the unique hb, locality and gp practice from the swansea gp data
swansea_gp_hb_locality <- swansea_gp_data %>%
                            select(hb, locality, practiceid) %>%
                              distinct()

# Swansea GP practices with hb and locality names
swansea_gp_with_hb_and_locality_names <-  swansea_gp_practices %>%
                                            left_join(swansea_gp_hb_locality) %>%
                                            left_join(swansea_hbs_name) %>% 
                                            left_join(swansea_locals_name)

View(swansea_gp_with_hb_and_locality_names)

# How many GP practices exist in an health board
# and in each locality within the health board
num_gp_practice_in_hb_locality <- swansea_gp_with_hb_and_locality_names %>%
  group_by(healthboard_name, locality_name) %>%
  summarize(num_gp_practices = n()) %>%
  filter(!is.na(healthboard_name) & !is.na(locality_name)) # filter out the NAs

View(num_gp_practice_in_hb_locality)

# PLOT OF THE GP practices counts in Swansea Health boards
num_gp_practice_plot <- num_gp_practice_in_hb_locality %>%
                          ggplot(aes(healthboard_name, num_gp_practices,
                                     fill = locality_name)) + 
                            geom_bar(stat = "identity", position = "dodge") + 
                            labs(
                              title = "Number of GP practices in Swansea Health Boards and their constituent localities",
                              x = "Health boards",
                              y = "Number of GP practices")
print(num_gp_practice_plot)
# ------------------------------------------------------------------------------

####### FINDING 2: 
# - NUMBER OF PRESCRIPTIONS EACH MONTH IN THE HEALTHBOARD
# - 
# ------------------------------------------------------------------------------
num_presc_hb_each_month <- swansea_gp_data %>%
                            group_by(hb, period) %>%
                            summarize(num_presc = n())
  
View(num_presc_hb_each_month)

# ------------------------------------------------------------------------------

####### FINDING 3: 
# - DRUGS MOST COMMONLY PRESCRIBED EACH MONTH 
#   in order to understand seasonal drugs and plan for financial allocations 
#    for these drugs
# ------------------------------------------------------------------------------
query_5 <- "
              -- 
              	select *
              	from bnf;
                "
bnf_data <- dbGetQuery(con, query_5)

# View(bnf_data)

# Select the bnfchemical and chemicaldesc columns
bnf_data_sub <- bnf_data %>%
                  select(bnfchemical, chemicaldesc)

# View(bnf_data_sub)

swansea_gp_data_with_drug_generic_name <- swansea_gp_data %>%
                                      select(bnfcode, bnfname, period) %>%
                                      mutate(
                                        month = period - (period %/% 100) * 100,
                                        
                                        bnfcode = substr(bnfcode, 1,9)) %>%
                                      left_join(bnf_data_sub,
                                                by = c("bnfcode" = "bnfchemical"))
# View(swansea_gp_data_with_drug_generic_name)

not_wanted <- c("Other Preparations", "Wound Management & other Dressings", 
                "Other Appliances","Glucose Blood Testing Reagents")

top_5_drugs_prescribed_each_month <- swansea_gp_data_with_drug_generic_name %>%
                                mutate(chemicaldesc = trimws(chemicaldesc)) %>% # Trim whitespaces
                                filter(!(chemicaldesc %in% not_wanted)) %>% # Filter out the unwanted chemicals
                                group_by(month) %>%
                                count(chemicaldesc, sort = TRUE) %>%
                                slice_max(order_by = n,n=5)
View(top_5_drugs_prescribed_each_month)

fill_colors <-  c(
  "chartreuse1", "blue", "darkviolet", "yellow",
  "orange", "aquamarine"
)
month_labels <-  c(
  `1` = "January", `2` = "February",
  `3` = "March", `4` = "April",
  `5` = "May", `6` = "June",
  `7` = "July", `8` = "August",
  `9` = "September", `10` = "October",
  `11` = "November", `12` = "December"
)

# PLOT OF TOP FIVE (5) DRUGS PRESCRIBED EACH MONTH
plot_of_top_5_pres_drugs_each_month <- ggplot(top_5_drugs_prescribed_each_month,
                                          aes(chemicaldesc, n, fill = chemicaldesc)) +
                                        geom_bar(stat="identity") + 
                                        coord_flip() +
                                        facet_wrap(~ month,
                                              labeller = labeller(month = month_labels)) +
                                        theme(axis.text.x = element_text(angle = 90,
                                                    vjust = 0.5, hjust=1)) + 
                                        labs(
                                          title = "Top Five (5) Drugs prescribed in each month",
                                          x = "Drug Names",
                                          y = "Number of times prescribed") +
                                        scale_fill_manual(values = fill_colors) +
                                        theme(legend.position = "none")
                                              

print(plot_of_top_5_pres_drugs_each_month)

# ------------------------------------------------------------------------------

####### FINDING 4: 
# - LOCAL COUNCIL OFFICER CHOOSES A PUBLIC HEALTH QOF INDICATOR FROM THE LIST BELOW
# Quality And Productivity
# Cervical Screening
# Primary Prevention Of Cardiovacular Disease
# Palliative Care
# - How many patients in the Swansea Health boards are ascribed to that indicator
# - What GP practices participated for the selected QOF indicator
# ------------------------------------------------------------------------------

# HELPER FUNCTION TO CHECK USER INPUT
check_if_in_vec <- function(vec, desired_value = "Practice") {
  "
  Checks if the practice entered is correct and return the value
  
  vec <- The vector to check
  desired_value <- string to print to console e.g Practice, Healthboard, QOF, etc 
  "
  truthy = FALSE
  while (!truthy) {
    prac <- readline(qq("Enter a/an '@{desired_value}' from the list above, or enter q to quit: "))
    if (prac %in% vec) {
      truthy = TRUE
    } else if (prac == "q"){
      print("Exiting")
      truthy = TRUE
      prac = FALSE
    }    else {
      print("Not a valid entry....")
    }
  }
  return(prac)
}


public_health_qofs <- c("Quality And Productivity", "Cervical Screening",
                        "Primary Prevention Of Cardiovacular Disease",
                        "Palliative Care")

# Print the Public Health QOF indicators to console
cat(public_health_qofs, sep = '\n')
selected_qof_area <- check_if_in_vec(public_health_qofs,
                                     desired_value = "Public Health QOF indicator")

if (is.character(selected_qof_area)) {
  print(paste0(selected_qof_area, " selected!"))
  
  public_health_qofs <- tolower(public_health_qofs)
  
  # qof indicator query
  qof_ind_query <- "
                -- look at qof indicator
                select * 
                from qof_indicator 
                "
  # Qof Indicator table
  qof_df <- dbGetQuery(con, qof_ind_query)
  
  # Public Health QOF table
  qof_df_public <-  qof_df  %>%
                      select(indicator, area) %>%
                      mutate(area = tolower(trimws(area))) %>%
                      filter(area %in% public_health_qofs) %>%
                      mutate(area = str_to_title(area))
  
  # View(qof_df_public)
  
  # Qof achievement query
  qof_ach_query <- "
                -- look at qof achievement
                SELECT * 
                FROM qof_achievement 
                "
  # Qof achievement table
  qof_ach_df <- dbGetQuery(con, qof_ach_query)
  # View(qof_ach_df)
  
  qof_ach_df_01 <- qof_ach_df %>%
        filter(grepl('001', indicator))
  
  # Patients that participated in the selected QOF
  selected_qof_patients <- qof_ach_df_01 %>%
                            select(orgcode, indicator, field4) %>%
                            inner_join(qof_df_public) %>%
                            filter(!(orgcode == 'WAL')) %>%
                            filter(area == selected_qof_area) %>%
                            select(orgcode, field4)
  
  # GP practices that participated for the QOF
  # and the number of patients therein `field4`
  View(selected_qof_patients)
  
  # Number of patients for the chosen indicator in each of the Swansea Health boards
  num_patients_ph_swansea_hbs <- swansea_gp_with_hb_and_locality_names %>%
                                  select(practiceid, hb, locality,
                                         healthboard_name, locality_name) %>%
                                  inner_join(selected_qof_patients,
                                             by = c("practiceid" = "orgcode")) %>%
                                  group_by(healthboard_name) %>%
                                  summarize(num_patients = sum(field4)) %>%
                                  ungroup() %>%
                                  filter(!is.na(healthboard_name)) # Filter out NAs
  View(num_patients_ph_swansea_hbs)
  
  # PLOT OF THE NUMBER OF PATIENTS FOR THE SELECTED QOF IN SWANSEA HEALTH BOARDS
  selected_qof_plot <- num_patients_ph_swansea_hbs %>%
                        ggplot(aes(healthboard_name, num_patients)) +
                        geom_col(fill = "deepskyblue4") + 
                        theme_classic() + theme(line = element_blank()) +
                        labs(
                          title = qq("Number of patients for @{selected_qof_area} in the Swansea Health Boards"),
                          x = "Health Board Names",
                          y = "Number of patients")
  
  print(selected_qof_plot)
} else {
  print("Program exitted!!!")
}
# ------------------------------------------------------------------------------

####### FINDING 5: 
# - HEALTHCARE EXPENDITURE ON DRUGS IN SWANSEA DURING 2015 
# -  in each month in 2015
# - and in each locality
# ------------------------------------------------------------------------------
prescriptions_2015 <- swansea_gp_data %>%
                            filter(grepl('2015', period)) %>% # Filter for 2015
                            mutate(
                              total_cost = round(actcost * quantity, 2)
                                   ) # total cost for each prescription
                            
total_cost_2015 <- prescriptions_2015 %>%
                    summarize(total_cost = sum(total_cost))

total_cost_2015_per_month <- prescriptions_2015 %>%
                              group_by(period) %>%
                              summarize(total_2015 = sum(total_cost)) 


View(prescriptions_2015)

# The expenditure on drugs within each locality in each month in 2015
total_cost_2015_per_month_per_locality <- prescriptions_2015 %>%
                                            inner_join(swansea_locals_name) %>%
                                            group_by(locality_name, period) %>%
                                            summarize(
                                              total_cost = sum(total_cost)) %>%
                                            ungroup()

View(total_cost_2015_per_month_per_locality)

options(scipen = 999)
# PLOT OF THE TOTAL COST OF DRUGS IN EACH MONTH IN 2015
plot_cost_each_locality <- total_cost_2015_per_month_per_locality %>%
                            ggplot(aes(locality_name, total_cost, 
                                       fill = locality_name)) +
                            geom_col() +
                            facet_wrap(~ period) +
                            theme(axis.text.x = element_text(angle = 90,
                                                           vjust = 0.5, hjust=1)) + 
                            labs(
                              title = "Total Cost of Drugs prescribed in each month within each locality",
                              x = "Locality Names",
                              y = "Cost accrued (£)") +
                            theme(legend.position = "none")

print(plot_cost_each_locality)

# ------------------------------------------------------------------------------

