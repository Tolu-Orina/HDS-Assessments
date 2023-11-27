# ------------------------------------------------------------------------------
# PART 1: ANSWERING SPECIFIC QUESTIONS/TASKS
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
library(dunn.test) # For Carrying out Post-hoc statistical test
library(FSA) # Statistical Analysis
library(broom) # To Allow for tidying the statistical test results


# Connect to the PostgreSQL Database
drv <- dbDriver('PostgreSQL')
con <- dbConnect(drv, dbname='gp_practice_data', host='localhost',
                 port=5432, user='postgres',
                 password=.rs.askForPassword(prompt = "Please enter your password: "))
tables <- dbListTables(con)
print(tables)


# TASK 1: TABLE OF HEALTH BOARD COMPARISON WITHIN WALES, INCLUDING:
#  - Health board name
#  - Number of GP practices in the HB
#  - Total num. of registered patients across all practices in the HB
#  - The Average num. of qof indicators for the practices in the HB
#  - Average spend per practice, per month on medications in the HB
# ------------------------------------------------------------------------------
# Firstly, we need to get the Health board names

# Query to get the health board name and corresponding health practice id
# from the address table
hb_name_query <- "
              -- Practice and Healthboard name
              select practiceid, locality 
              from address 
              where locality is not NULL and locality like '%HB'
              "
# Health board names table
hb_name_df <- dbGetQuery(con, hb_name_query)
# View(hb_name_df)

# If we run a `print(hb_name_df$practiceid)`,
print(hb_name_df$practiceid)
# we would notice that the practiceid column contains trailing whitespaces
# We would clean it up using dplyr's `trimws()` function
hb_name_df <- hb_name_df %>%
                mutate(practiceid = trimws(practiceid))
print(hb_name_df$practiceid) # Running it again shows that the whitespaces are gone

# Next, we'll first get total number of registered for each GP practice 
# and the total number of qof indicators reported for each GP practice
# from the QoF indicators and QoF achievement tables.

# qof indicator query
qof_ind_query <- "
              -- look at qof indicator
              select * 
              from qof_indicator 
              "
# Qof Indicator table
qof_df <- dbGetQuery(con, qof_ind_query)

# Filter out procedures and public health matters which are not necessarily disease conditions
not_diseases <- c("blood pressure", "child health surveillance", "quality and productivity",
                  "sexual health", "cervical screening", "primary prevention of cardiovacular disease",
                  "education and training", "patient communication", "practice management",
                  "maternity services", "medicines management", "palliative care", "patient experience",
                  "quality and safety", "records", "smoking in chronic disease")

qof_df_cleaned <- qof_df  %>%
  select(indicator, area) %>%
  mutate(area = tolower(trimws(area))) %>%
  filter(!(area %in% not_diseases)) %>%
  mutate(area = replace(area, area == "pad", "peripheral arterial disease"),
         area = str_to_title(area)) 
# View(qof_df_cleaned)

# Qof achievement query
qof_ach_query <- "
              -- look at qof achievement
              select * 
              from qof_achievement 
              "
# Qof achievement table
qof_ach_df <- dbGetQuery(con, qof_ach_query)
# View(qof_ach_df)

qof_ach_df_01 <- qof_ach_df %>%
                  filter(grepl('001', indicator))

# Total num. of patients in each GP. practice
total_patients_in_each_practice <- qof_ach_df_01 %>%
                                    select(orgcode, indicator, field4) %>%
                                    inner_join(qof_df_cleaned) %>%
                                    select(orgcode, field4) %>%
                                    distinct() %>%
                                    filter(!(orgcode == 'WAL')) %>%
                                    arrange(orgcode)
                                  
# Total num qof indicator reported in each GP. practice
total_num_qof <- qof_ach_df  %>%
                  group_by(orgcode) %>%
                  summarise(
                    num_qof_indicator = n_distinct(indicator)) %>%
                  ungroup() %>%
                  filter(!(orgcode == 'WAL')) %>%
                  distinct() %>%
                  arrange(orgcode)

# View(total_patients_in_each_practice)
# View(total_num_qof)

# The GP practice `W00141` is missing from the total_patients table,
# lets investigate this
qof_ach_df  %>%
  filter(orgcode == 'W00141' & grepl('001', indicator))

# It seems its patients count is under the 'BP001W' indicator
w00141_patients <- qof_ach_df  %>%
  filter(orgcode == 'W00141' & grepl('001', indicator) & indicator == 'BP001W') %>%
  select(orgcode, field4)

# Concatenate it to the total_patients_table
total_patients_in_each_practice <- total_patients_in_each_practice %>%
                                    bind_rows(w00141_patients)
# View(total_patients_in_each_practice)

total_patients_and_num_qof <- total_patients_in_each_practice %>%
                                inner_join(total_num_qof)
# View(total_patients_and_num_qof)

print(sum(total_patients_and_num_qof$field4))

# Next, we'll get the required columns to answer this question from the 
# gp_data_up_to_2015 table and also for GP Practice prescriptions
# data that are from 2015 only, since the QoF table which contains the number of registered
# patients is given for 2015

# SELECT THE NECESSARY COLUMNS FROM THE GP_DATA_UP_TO_2015 TABLE
hb_practice_query <- "
              -- SELECT THE NECESSARY COLUMNS FROM THE GP_DATA_UP_TO_2015 TABLE
              	select hb, practiceid, actcost, items, period
              	from gp_data_up_to_2015
              	where period between 201501 and 201512;
                "

# Health board name table
hb_practice_gp_data <- dbGetQuery(con, hb_practice_query)

# View(hb_practice_gp_data)

# Next, we need to combine the total patients in each GP practice table with
# the GP practice table in order to 
# calculate the total num. of patients in each health board
total_patients_all_hbs_and_avg_num_qof <-hb_practice_gp_data %>%
                                    select(hb, practiceid) %>%
                                    inner_join(total_patients_and_num_qof,
                                               by = c("practiceid" = "orgcode")) %>%
                                    distinct() %>% # In order to eliminate duplicate columns
                                    group_by(hb) %>%
                                    mutate(total_patients = sum(field4),
                                           avg_num_qof = mean(num_qof_indicator)) %>%
                                    select(hb, total_patients, avg_num_qof) %>%
                                    distinct()

View(total_patients_all_hbs_and_avg_num_qof)

# And then, assuming that the actcost is the cost of a prescription,
# we calculate the total cost of that prescription for the respective month
# By multiplying `actcost` and `items` from the gp_data
# After which we get calculate the average spend for each practice per month
avg_spend_per_practice_per_month <- hb_practice_gp_data %>%
                                      mutate(
                                        total_cost = round((actcost * items), 2)
                                        ) %>%
                                      select(hb, practiceid, period, total_cost) %>%
                                      group_by(practiceid, period) %>%
                                      summarise(avg_spend = round(mean(total_cost))) %>%
                                      ungroup()

View(avg_spend_per_practice_per_month)

# Next, we combine the tables for the health board name,
# the total number of patients and total num. of Qof reported in each GP practice table,
# the Average Spend per practice per month table 
# with the GP practice data using appropriate join keys
# This join takes approximately 4 minutes to run
hb_practice_name_data <- hb_practice_gp_data %>% 
                          inner_join(hb_name_df,
                                     by = c("hb" = "practiceid")) %>%
                          inner_join(total_patients_all_hbs_and_avg_num_qof,
                                     by = "hb") %>%
                          inner_join(avg_spend_per_practice_per_month, 
                                     by = c("practiceid", "period"))

View(hb_practice_name_data)

# Finally we get the required results for our table
# by first grouping by the health board to calculate the
# the number of distinct GP practices within the health board,
# un-group to retrieve the other columns, and then select the necessary columns
healthboard_comparison_table <- hb_practice_name_data %>%
                                  group_by(locality) %>%
                                  mutate(
                                    num_gp_practice=n_distinct(practiceid)
                                  ) %>%
                                  ungroup() %>%
                                  select(locality, num_gp_practice,
                                         total_patients,
                                         avg_num_qof, practiceid, period, avg_spend) %>%
                                  distinct()

View(healthboard_comparison_table)
# ------------------------------------------------------------------------------

# TASK 2: USER PROMPTS for Health Board name.
# OUTPUTS: 
#   1. A list of the GP Practices in that Health Board
#   2. The Three (3) Most prevalent conditions in the Health Board 
#          with their prevalence counts.
#   3. Prevalence from 2. above in each GP practice
#   2. and 3. are both tabular and graphical
#   ** Prevalence in this context refers to the number of patients having
#   a condition and are registered with the GP practice 
# ------------------------------------------------------------------------------

# HELPER FUNCTION TO CHECK FOR CORRECTNESS OF INPUT ENTERED BY USER
# USEFUL FOR BOTH TASK TWO AND THREE
check_if_in_vec <- function(vec, desired_value = "Practice") {
  "
  Checks if the practice entered is correct and return the value
  
  vec <- The vector to check
  desired_value <- either 'Practice' or 'Health board name' 
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

options(scipen = 999) # Prevent scientific notation

  "
  Aims to list the practices in a given health board e.g 'Cwn Taf HB'
  then, display a tabular and graphical results for the 
  three most prevalent conditions in the given health board.
  This is achieved by receiving input from the user as the program runs to give the
  desired results.
    "
  
hb_names <- hb_name_df$locality
          
# Print the Health Board names to console
cat(hb_names, sep="\n")
healthboard <- check_if_in_vec(hb_names, desired_value="Health board name")

if (is.character(healthboard)) {
  print(paste0(healthboard, " selected!"))
  
  # Firstly, we need to get the Health board names table
  # We already have it from the last task i.e `hb_name_df`,
  # join it to the GP practice prescribing data,
  # filter for the selected health board 
  # and display the distinct GP practices therein
  
  # GP practice in your selected Health board
  gp_practices_in_hb <- hb_practice_gp_data %>% 
    select(hb, practiceid) %>%
    inner_join(hb_name_df,
               by = c("hb" = "practiceid")) %>%
    filter(locality == healthboard) %>%
    distinct(practiceid)
  
  View(gp_practices_in_hb)

  # Most prevalent 3 conditions in the health board
  most_prevalent_3_in_hb_df <- qof_ach_df %>%
    select(orgcode, indicator, field4) %>%
    inner_join(qof_df_cleaned, by="indicator") %>%
    filter(orgcode %in% pull(gp_practices_in_hb)) %>%
    group_by(area) %>%
    summarize(prevalence = sum(field4)) %>%
    arrange(desc(prevalence)) %>%
    head(3)
  
  View(most_prevalent_3_in_hb_df)
  
  # PLOT OF THE THREE MOST PREVALENT CONDITIONS IN THE HEALTHBOARD
  plot_1 <- ggplot(most_prevalent_3_in_hb_df, aes(area, prevalence)) +
              geom_col(fill = "lightblue") + 
              labs(
                title = "Three (3) Most Prevalent Disease Conditions within selected HB",
                x = "Disease Condition",
                y = "Prevalence count") +
              theme(axis.text.x = element_text(angle = 30,
                                     hjust=0.8))
  
  print(plot_1)
  
  most_prevalent_3_in_hb <- pull(most_prevalent_3_in_hb_df, area)
  most_prevalent_3_in_hb
  
  # Most prevalent 3 conditions in each GP practice the health board
  most_prevalent_3_in_hb_in_gp_df <-qof_ach_df %>%
                                      select(orgcode, indicator, field4) %>%
                                      inner_join(qof_df_cleaned, by="indicator") %>%
                                      filter(orgcode %in% pull(gp_practices_in_hb)) %>%
                                      filter(area %in% most_prevalent_3_in_hb) %>%
                                      group_by(orgcode, area) %>%
                                      mutate(prevalence = sum(field4)) %>%
                                      select(orgcode, area, prevalence) %>%
                                      distinct() %>%
                                      arrange(orgcode) %>%
                                      ungroup()
  
  View(most_prevalent_3_in_hb_in_gp_df)

  # PLOTS OF THE THREE MOST PREVALENT CONDITIONS IN EACH GP PRACTICE IN THE HEALTHBOARD 
  gp_practices_in_hb_vec <- pull(gp_practices_in_hb, "practiceid")
  gp_practices_in_hb_vec
  
  for(current_practice in gp_practices_in_hb_vec) {
    
    if(current_practice %in% most_prevalent_3_in_hb_in_gp_df$orgcode) {
      practice_prevalence_df <- most_prevalent_3_in_hb_in_gp_df %>%
        filter(orgcode == current_practice)
      
      practice_plot <- ggplot(practice_prevalence_df, aes(area, prevalence)) +
        geom_col(fill = "lightblue") + 
        labs(
          title = qq("Three (3) Most Prevalent Disease Conditions within '@{current_practice}' GP Practice"),
          x = "Disease Condition",
          y = "Prevalence count") +
        theme(axis.text.x = element_text(angle = 30,
                                         hjust=0.8))
      print(practice_plot)
    }
  }
} else {
  print("Program exitted!!!")
}
# ------------------------------------------------------------------------------


# TASK 3: EXPLORATION OF THE MOST PRESCRIBED DRUGS IN A GP PRACTICE
# WITHIN AN HEALTH BOARD
# ENABLES THE USER TO SELECT AN HEALTHBOARD AND THEN A GP PRACTICE
# DISPLAYS THE FIVE (5) MOST PRESCRIBED TYPES OF DRUG IN THE GP PRACTICE
# ------------------------------------------------------------------------------

# Write a query to get the bnf data
bnf_query =  "
              -- load in the bnf table for the question
              select bnfchemical, subsectiondesc
              from bnf 
              "
# BNF TABLE contains the bnf subsectiondesc which describes 
# the generalized class of drug it belongs to
bnf_df <- dbGetQuery(con, bnf_query)
View(bnf_df)

hb_names <- hb_name_df$locality
print("THIS IS THE PROMPT FOR TASK 3, NOT A REPEAT 🤗")
# Print the Health Board names to console
cat(hb_names, sep="\n")
healthboard <- check_if_in_vec(hb_names, desired_value="Health board name")

if (is.character(healthboard)) {
  print(paste0(healthboard, " selected!"))
  
  # Firstly, we need to get the Health board names table
  # We already have it from the last task i.e `hb_name_df`,
  # join it to the GP practice prescribing data,
  # filter for the selected health board 
  # and display the distinct GP practices therein
  
  # GP practice in your selected Health board
  gp_practices_in_hb <- hb_practice_gp_data %>% 
    select(hb, practiceid) %>%
    inner_join(hb_name_df,
               by = c("hb" = "practiceid")) %>%
    filter(locality == healthboard) %>%
    distinct(practiceid)
  
  View(gp_practices_in_hb)
  
  # Get the practices in the healthboard
  gp_practices_in_hb_vec <- gp_practices_in_hb %>%
                              mutate(practiceid = trimws(practiceid)) %>%
                              pull(practiceid)
  
  cat(gp_practices_in_hb_vec, sep="\n")
  gp_practice <- check_if_in_vec(gp_practices_in_hb_vec, desired_value="GP Practice")
  if (is.character(gp_practice)) {
    print(paste0("Practice chosen is ", gp_practice))
    
    # SELECT THE NECESSARY COLUMNS FROM THE GP_DATA_UP_TO_2015 TABLE
    print("THIS QUERY CAN TAKE UP TO 4 MINUTES OR LESS!!!")
    hb_bnf_query <- qq("
              -- SELECT THE NECESSARY COLUMNS FROM THE GP_DATA_UP_TO_2015 TABLE
              	select practiceid, bnfcode, bnfname
              	from gp_data_up_to_2015
              	where practiceid = '@{gp_practice}'
                ")
    
    # Health board name table for the specific practice
    hb_bnf_data <- dbGetQuery(con, hb_bnf_query)
    
    View(hb_bnf_data)
    
    # Mutate the Bnf code column to get the first 9 characters
    # In order to match its value in the `bnf_df` table
    drug_class_data <- hb_bnf_data %>%
                        mutate(bnfcode = substr(bnfcode, 1,9)) %>%
                        left_join(bnf_df,
                                  by = c("bnfcode" = "bnfchemical"))
    View(drug_class_data)
    
    # Get the five most prescribed drugs for the selected gp practice
    top_5_prescriptions <- drug_class_data %>%
                            group_by(subsectiondesc) %>%
                            summarise(num_prescriptions = n()) %>%
                            arrange(desc(num_prescriptions))%>%
                            head(5) %>%
                            mutate(subsectiondesc = trimws(subsectiondesc))
    
    View(top_5_prescriptions)
    
    # Plot results of the five(5) most prescribed types of drugs
    top_5_presc_plot <- ggplot(top_5_prescriptions,
                         aes(x=subsectiondesc,y=num_prescriptions)) +
                          geom_col(color='black',fill='cyan3')+
                          labs(x='Type of Drug', y="Number of prescriptions",
                               title= qq(
                        "Five(5) Most Prescribed types of drugs in '@{gp_practice}' GP Practice")) +
                          theme(axis.text.x = element_text(angle = 30,
                                                  hjust=0.8))
    print(top_5_presc_plot)
  } else {
    print("Program exitted!!!")
  }
  } else {
  print("Program exitted!!!")
  }

# ------------------------------------------------------------------------------


# TASK 4: HYPOTHESIS TEST TO ANSWER THE QUESTION:
# IS THERE A, STATISTICALLY SIGNIFICANT, DIFFERENCE BETWEEN THE AVG. GP PRACTICE
# SPEND PER MONTH BETWEEN HEALTH BOARDS
# NULL HYPOTHESIS, H0: THERE IS NO DIFFERENCE BETWEEN THE AVG GP PRACTICE SPEND
#  PER MONTH BETWEEN HEALTH BOARDS I.E MEAN_SPEND OF HB A - MEAN_SPEND OF HB B = 0,
                                      # MEAN_SPEND OF HB B - MEAN_SPEND OF HB C = 0, .....
# ALTERNATIVE HYPOTHESIS, H1: THERE IS A DIFFERENCE BETWEEN THE AVG GP PRACTICE SPEND
#  PER MONTH BETWEEN HEALTH BOARDS I.E MEAN_SPEND OF HB A - MEAN_SPEND OF HB B ≠ 0,
#                                     MEAN_SPEND OF HB B - MEAN_SPEND OF HB C ≠ 0, .....
# ------------------------------------------------------------------------------

# SELECT THE NECESSARY COLUMNS FROM THE GP_DATA_UP_TO_2015 TABLE
hb_test_query <- "
              -- SELECT THE NECESSARY COLUMNS FROM THE GP_DATA_UP_TO_2015 TABLE
              	select hb, actcost, items, period
              	from gp_data_up_to_2015
                "

# short Health board name table for test purposes
hb_test_data <- dbGetQuery(con, hb_test_query)
# View(head(hb_test_data))


# Group by Health board and period (month)
# Seeing we are looking for the average gp practice spend in each health board
# Thus the health board serves as the reference point
avg_gp_spend_per_month_df <- hb_test_data %>%
                              inner_join(hb_name_df,
                                         by = c("hb" = "practiceid")) %>%
                              rename(healthboard_name = locality) %>%
                              select(-hb) %>%
                              mutate(total_cost = round((actcost * items), 2)) %>%
                              select(healthboard_name, period, total_cost) %>%
                              group_by(healthboard_name, period) %>%
                              summarize(avg_gp_spend_per_month = mean(total_cost)) %>%
                              ungroup()

View(avg_gp_spend_per_month_df)

# Does the health board explain the avg_gp_spend_per_month: 
labels = hb_names
# First: Visualize the avg_spend distribution of each health board on a boxplot
plot_avg_spend_hbs <- ggplot(avg_gp_spend_per_month_df,
                             aes(x=healthboard_name, y=avg_gp_spend_per_month)) + 
                        geom_boxplot(fill = 'darkgoldenrod1') +
                        labs(
                          title = "Average GP Practice Spend Per month for each health board",
                          x = "Health Board",
                          y = "Average GP Practice Spend") +
                        theme(axis.text.x = element_text(angle = 90,
                                                         vjust= 0.8,
                                                         hjust=0.8, size=7))
print(plot_avg_spend_hbs)
# From the plot, there seems to be a difference between the monthly spend
# in the distributions amongst a few of the healthboards  



# Secondly: To Carry out an ANOVA test
# First confirm the 4 assumptions
# 1. Observations in each health board is independent
# 2. Observations are approximately distributed between groups (i.e health boards)
# 3. Variances approximately equal within each of the groups
# 4. Normally distributed mean values for the dependent variable across the groups

# Numerical comparison of the variance within each health board
num_var_btw_hb <- avg_gp_spend_per_month_df %>%
  group_by(healthboard_name) %>%
  summarise(var(avg_gp_spend_per_month, na.rm = TRUE))

View(num_var_btw_hb)
# Most of the variances are equal

# One more visualization to help view the distributions: Histogram
dist_plot <- ggplot(avg_gp_spend_per_month_df, aes(x=avg_gp_spend_per_month)) + 
              geom_histogram(fill = 'lightblue') +
              facet_wrap(~ healthboard_name, ncol=2) + 
              labs(
                title = "Distribution of Average GP spend between Health Boards",
                )

print(dist_plot)

# From the Avg. Spend Distribution Plots appears non-normal, we would go on to perfom 
# A NON-PARAMETRIC TEST equivalent to ANOVA, i.e the Kruskal-Wallis test,
# The Kruskal-Wallis test is a Rank-based method that orders grouped continuous data 
# from smallest to largest and assigns a rank

options(scipen = 999) # Prevent scientific notation

kruskal_result <- avg_gp_spend_per_month_df %>%
                    kruskal.test(avg_gp_spend_per_month ~ healthboard_name, data= .) %>%
                    tidy()

print("DISPLAYING KRUSKAL WALLIS RESULTS ........")
cat("\n")
View(kruskal_result)

# With a sigificance level of .05, we can say that 
# there is a statistical significance btw the avg practice spend per month
# btw the various healthboards seeing our p-value is less than
# the chosen significance level of .05. Thus we reject the null hypothesis
# that there is no difference between avg practice spend per month
# btw the various healthboards
 
# Carry out a Dunn's Post-hoc Test to see where differences lie
dunn_test <- dunnTest(avg_gp_spend_per_month_df$avg_gp_spend_per_month,
               avg_gp_spend_per_month_df$healthboard_name,
               method = "bonferroni")

dunn_result <- dunn_test$res %>%
                  arrange(P.adj)
print("Ignore the error from above, it arranges it")

# View the Results from the Dunn Post-hoc Test
View(dunn_result)

# From the Dunn's test, some difference in average GP practice spend between
# various hbs are statistically significant,
# however the differences between some health boards doesn't seem to be significant
# Just as observed in the boxplots, a few of the signifcant ones are;
# Cardiff & Vale University HB - Powys Teaching HB
# Betsi Cadwaladr University HB - Powys Teaching HB 
# Hywel Dda HB - Powys Teaching HB 
# Cardiff & Vale University HB - Cwm Taf HB
# and more .....