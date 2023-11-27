## PMIM102-SUBMISSION

### SETUP

- Open R Studio, Click on File and click New Project.
- In the dialog that opens, choose Version Control, select Git, and enter https://github.com/Tolu-Orina/HDS-Assessments.git for the Repository URL. Enter a directory name and choose a sub-directory of your choice.
- Click Create Project, and a new session of the R-studio will be opened with the directory name entered.
- Navigate into the PMIM102-submission folder in the right portion of the r-studio under files. Click on part1.R and part2.R to open them.
- Click File on the toolbar, then click New File, and select R script. Use ctrl + S or Cmd + S to save and rename the newly created script.

***Before moving on, install the following packages using install.packages("package-name");***
- RPostgreSQL
- GetoptLong
- Tidyverse
- ggplot2
- dunn.test
- FSA
- broom
- stringr
- lubridate
- tools

**You are setup to start the Data Analysis of the GP Data!!!, move on to part 1 implementation steps.**

### PART 1 IMPLEMENTATION STEPS
In this section of the analysis, we look to answer specific questions related to the GP Prescribing Data for Wales and the QOF Results (2015) for Wales Data.

We will use the model shown in the diagram above whilst answering these specific questions:

**QUESTION 1**: How many GP practices are in each of the health boards represented in the GP Data for Wales? How many registered patients exist in all the practices in each health board? What is the average spend per GP practice per month on medications in the Health Board?

**To answer this question, we are going to display a table that contains the aforementioned results, thus comparing the health boards in Wales.**

**N.B**:- The number of registered patients can be found in the QOF achievement table, which is limited to 2015 QOF results; thus, we would subset the GP prescribing data to return values for only 2015.

- **STEP 1**: Copy lines 7 to line 30 from part1.R into your .R file during the setup from above, click on the Source button, enter the password for your postgresql database and click enter. This establishes a connection with the database that contains the GP data.
- **STEP 2**: Copy lines 31 to 51 from part1.R and paste beneath the code in your .R file, Click the Source button, and enter the password (we will repeat this each time you click source, so from here on I won't remind you to enter your password; you'll do this yourself). Lines 31 to 51 run a query against the addres table to get the practiceid (which matches the hb column in the GP data table as shown in the ERD image above) and the health board names (from the locality column where the locality is not NA and the locality has HB at the end). It also does some cleaing of the practiceid column by removing trailing whitespaces, giving us a table containing the health board id and health board names in Wales.
- **STEP 3**: Copy lines 52 to 135 from part1.R and paste beneath the code in your .R file, Click the Source button. These lines of code retrieve the total number of registered patients for each GP practice and the total number of QOF indicators reported for each GP practice from the QOF indicators and QOF achievement tables.
- **STEP 4**: Copy lines 138 to 185 from part1.R and paste beneath the code in your .R file, Click the Source button. These lines of code combine the total number of patients and the qof total table with the GP practice prescription data for 2015 to calculate the overall total number of patients in each healthboard and the average number of QOF in each healthboard. They go on in lines 172 to 185 to calculate the average spend for each GP practice per month.
- **STEP 5**: Copy lines 187 to 217 from part1.R and paste beneath the code in your .R file, Click the Source button. These lines of code combine the table for healthboard name from STEP 2 with the total number of patients and total numebr of qof reported for eacch practice, the average spend per GP practice per month table and the gp practice data for 2015. Finally, we calculate the number of distinct GP practices within the health board and get the resulting table that answers question 1

**QUESTION 2**: This task receives input (in the form of a Healthboard name) from the user. It answers the question that, for a given health board, what are the GP practices within that board? What are the three most prevalent disease conditions in the health board? displays the prevalence for these conditions in the Health Board and the prevalence of these conditions in each GP practices in that health board

- **STEP 1**: Copy Lines 220 to 256 from part1.R and paste beneath the code in your .R file, Click the Source button. These lines of code effectively implements a function to check the correctness of the user input and prevent scientific notations.
- **STEP 2**: Copy Lines 258 to 358 from part1.R and paste beneath the code in your .R file, Click the Source button. These lines of code get the GP practices from the selected healthboard, check for the most prevalent conditions in the healthboard and in each GP practice, and then generate a plot for them.


**QUESTION 3**: This task receives input (in the form of a healthboard name and then a GP practice within that healthboard) from the user. It then answers the question, what are the five (5) most prescribed types of drugs in that practice?

- **STEP 1**: Copy lines 362 to 377 from part1.R and paste them beneath the code in your .R file, click the source button, These lines of code get the bnf subsectiondesc, which describes the generalized class of drug a particular medication prescription belongs to.

- **STEP 2**: Copy lines 362 to 461 from part1.R and paste beneath the code in your .R file, Click the Source button. These lines of code are used to filter for the data containing the selected GP practice prescriptions in the GP prescriptions data and then join it to the subsectiondesc column gotten from the BNF table in Step 1 above. It goes on to display the tabular and graphical results.

***N.B.: Some GP practices have only one or a few prescriptions recorded in the dataset.***

**QUESTION 4**: HYPOTHESIS TEST TO ANSWER THE QUESTION: IS THERE A, STATISTICALLY SIGNIFICANT, DIFFERENCE BETWEEN THE AVGERAGE GP PRACTICE
SPEND PER MONTH BETWEEN HEALTH BOARDS?

1. NULL HYPOTHESIS, H0: THERE IS NO DIFFERENCE BETWEEN THE AVG GP PRACTICE SPEND PER MONTH BETWEEN HEALTH BOARDS, i.e., MEAN_SPEND OF HB A - MEAN_SPEND OF HB B = 0, MEAN_SPEND OF HB B - MEAN_SPEND OF HB C = 0,...
2. ALTERNATIVE HYPOTHESIS, H1: THERE IS A DIFFERENCE BETWEEN THE AVG GP PRACTICE SPEND PER MONTH BETWEEN HEALTH BOARDS, I.E MEAN_SPEND OF HB A - MEAN_SPEND OF HB B ≠ 0, MEAN_SPEND OF HB B - MEAN_SPEND OF HB C ≠ 0, .....

- **STEP 1**: Copy lines 465 to 502 from part1.R and paste beneath the code in your .R file, click the source button. These lines of code
extracts the data needed to conduct the hypothesis test in order to answer the research question. Seeing we are looking for the average gp practice spend per month in each health board, the health board serves as the reference point, that is a group by Health board and then by month to get the resulting average spend

- **STEP 2**: Copy Lines 503 to 551 from part1.R and paste beneath the code in your .R file, click the source button, These lines of code
generates plot to see if the dependent variable follows the assumptions that satisfy using the anova parametric test. The Plots do not lend confidence to satisfy the assumptions, especially the normality of the distribution; thus, we would conduct a non-parametric Kruskal-Wallis test to test for the significance of a continuous variable between more than two groups (health boards in this case)

- **STEP 3**: Copy Lines 503 to 551 from part1.R and paste beneath the code in your .R file, click the source button, These lines of code
carries out the Kruskal-Wallis test and a significant difference is established with details by performing a Post-hoc Dunn's test to see where the statistical difference lies

### PART 2 IMPLEMENTATION STEPS
In this section, we will look at a CASE STUDY OF HEALTHCARE USAGE WITHIN SWANSEA LOCAL COUNCIL.

The Local Council of Swansea is seeking to understand the health behaviours and conditions of the people living in its local authority. They would love to understand how people seek care, including access to care and utilization patterns.

In order to generate a report on health care access and utilization for the local council of Swansea and its populace, some questions would be answered through this analysis. They include:

**QUESTION 1**: How many GP practices are within the council of Swansea? What health boards and localities do they belong to? How many GP practices exist in a health board and in each locality within the health board?

- **STEP 1**: Copy lines 9 to 27 from part2.R and paste beneath the code in your .R file, click the source button. Enter the password for your Postgresql database and click enter. This establishes a connection with the database that contains the GP data.

- **STEP 2**: Copy lines 29 to 141 from part2.R and paste beneath the code in your .R file, click the source button. These lines of code gets a subset of the gp practices where their postcode starts with “SA” from the Address table, displays the number of GP practices in Swansea local council, gets how many gp practices are in each healthboards and their constituent localities and displays the finding on a clustered bar chart.

**QUESTION 2**: What is the health care usage pattern of patients, in the form of the number of GP practice prescriptions issued each month within Swansea?

- **STEP 1**: Copy lines 143 to 151 from part2.R and paste beneath the code in your .R file, click the source button. These lines of code retrieve the top 5 drugs prescribed in Swansea each month.

**QUESTION 3**: What drugs are most commonly prescribed each month? in order to understand seasonal drugs and plan for financial allocations for these drugs.

- **STEP 1**: Copy lines 155 to 226 from part2.R and paste them beneath the code in your .R file, click the source button. These lines of code retrieve the number of prescription issued in Swansea within each month.

**QUESTION 4**: The local council officer (hypothetical user) can select a public health QOF indicator, e.g Cervical Screening, and understand how many patients within Swansea are ascribed to that QOF indicator and what GP practices carried out the exercise for that QOF indicator.

- **STEP 1**: Copy lines 230 to 347 from part2.R and paste beneath the code in your .R file, click the source button. These lines of code
models a user prompt that allows the local council officer enter in a public health-related QOF indicator from the list displayed and then
displays the number of patients in the Swansea Health Boards ascribed to that indicator. 

**QUESTION 5**: What is the healthcare expenditure on drugs in Swansea for 2015 and across each month in 2015, and in each locality?

- **STEP 1**: Copy lines 349 to 393 from part2.R and paste beneath the code in your .R file, click the source button. These lines of code display the total cost of drugs prescribed each month in 2015.
-  **STEP 2**: Copy lines 395 to 405 from part2.R and paste beneath the code in your .R file, Click the source button. These lines of code displays the top 5 most expensive drugs in swansea for the year 2015


