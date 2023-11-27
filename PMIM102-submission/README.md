## PMIM102-SUBMISSION

### SETUP

- Open R Studio, Click on File and click New Project.
- In the dialog that opens, choose Version Control, select Git, and enter https://github.com/Tolu-Orina/HDS-Assessments.git for the Repository URL. Enter a directory name and choose a sub-directory of your choice.
- Click Create Project, and a new session of the R-studio will be opened with the directory name entered.
- Navigate into the PMIM102-submission folder in the right portion of the r-studio under files, Click on part1.R and part2.R to open them.
- Click File on the toolbar, then click New File, and select R script, Use ctrl + S or Cmd + S to save and rename the newly created script.

***Before moving on, install the following packages using install.packages("package-name");***
- RPostgreSQL
- GetoptLong
- Tidyverse
- ggplot2
- dunn.test
- FSA
- broom

**You are setup to start the Data Analysis of the GP Data!!!, move on to part 1 implementation steps.**

### PART 1 IMPLEMENTATION STEPS
In this section of the Analysis, we look to answer specific question related to the GP Prescribing Data for Wales and the QOF Results (2015) for Wales Data.

We will take the model shown in the diagram above whilst answering these specific questions;

**QUESTION 1**. How many GP Practices are in each of the Health Boards represented in the GP Data for Wales, how many registered patients exist in all the practices in each Health board? What is the average spend for each GP practice, per month on medications in the Health Board?

**To answer this question, we are going to display a table that contains the aforementioned results thus comparing the health boards in Wales.**

**N.B**:- The number of registered patients can be found in the QOF achievement table which is limited to 2015 QOF Results thus we would subset the GP Prescribing Data to return values for only 2015.

- **STEP 1**: Copy lines 7 to line 30 from part1.R into your .R file during the SETUP from above and click on the Source button, enter the password for your postgresql database and click enter. This establishes a connection with the database that contains the GP data.
- **STEP 2**: Copy Lines 31 to line 51 from part1.R and paste beneath the code in your .R file, click the source button, enter the password (we would repeat this each time you click source, so from here on I wont remind you to enter your password, you'll do this yourself). Lines 31 to 51 runs a query against the addres table to get the practiceid (which matches the hb column in the gp data table as shown in the ERD image above) and the health boards names (from the locality column where the locality is not NA and locality has HB at the end), it also does some cleaing of the practiceid column by removing trailing whitespaces giving us a table containing the health board id and health board names in Wales.
- **STEP 3**: Copy Lines 52 to line 135 from part1.R and paste beneath the code in your .R file, click the source button, These lines of code retrieves the total number of registered patients for each GP practice and the total number of QOF indicators reported for each GP practice from the QOF indicators and QOF achievement tables.
- **STEP 4**: Copy Lines 138 to 185 from part1.R and paste beneath the code in your .R file, click the source button, These lines of code combines the total number of patients and qof total table to the gp practice prescription data for 2015 and calculates the overall total patients in each healthboard and the average numbber of QOF in each healthboard and goes on in lines 172 to 185 to calculate the average spend for each GP practice per month.
- **STEP 5**: Copy Lines 187 to 217 from part1.R and paste beneath the code in your .R file, click the source button, These lines of code combines the table for healthboard name from STEP 2 with the total number of patients and total numebr of qof reported for eacch practice, the average spend per GP practice per month table and the gp practice data for 2015, finally we calculate the number of distinct GP practices within the health board and get the resulting table that answers question 1

**QUESTION 2**: This task receives an input (in the form of an Healthboard name) from the user. It answers the question that, for a given health board, what are the GP practices within that Healthboard? What is the most prevalent three conditions in the Health Board? displays the prevalence for these conditions in the Health Board and the prevalence of these conditions in each GP practices in that Health board

- **STEP 1**: Copy Lines 220 to 256 from part1.R and paste beneath the code in your .R file, click the source button, These lines of code effectively implements a function to check the correctness of the user input and prevent scientific notations.
- **STEP 2**: Copy Lines 258 to 358 from part1.R and paste beneath the code in your .R file, click the source button, These lines of code get the GP practices from the selected healthboard, checks for the most prevalent conditions in the healthboard and in each gp practice and then generates plot for them.


**QUESTION 3**: This task receives an input (in the form of an Healthboard name and then a GP practice within that healthboard) from the user. It then answers the question, what are the five (5) most prescribed types of drugs in that practice?

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


