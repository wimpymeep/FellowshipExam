
Author Cory Ross                                                                                             
Data 3/12/2022                                                                                               
Fellowship Exam.sas                                                                                          
																											   
Written on SAS 9.4                                                                                           
																											   
This code performs the tasks as detailed in the document provided on 2/12/2022 for the Stream 2:             
Data Engineering exam.                                                                                       
																											   
This code requires that you have downloaded the 9 months of data for the Labour Force Survey located here:   
https://www150.statcan.gc.ca/n1/en/catalogue/71M0001X/                                                       
																											   
These need to be extracted into one directory on your PC and the location defined in the macro variable      
StartLocation.                                                                                               
																											   
The program is outlined in 5 sections following the design of the exam document.                             


INPUT REQUIREMENTS:

%let StartLocation = C:\Users\roscory\Downloads\exam_data\;


Download JAN-SEPT data into the startlocation above from:
https://www150.statcan.gc.ca/n1/en/catalogue/71M0001X/ 

Once this has been completed, simply execute the program and validate the outputs listed below in the work directory.



For Examiners:

OUTPUTS:
TASK2:
work.naics_21
work.prov
work.educ
work.noc_40
work.age_12

TASK3:
work.Master_data_revised

TASK4:
work.part4_1_3 - Question 1
work.part4_2_3 - Question 2
work.part4_3_4 - Question 3

Task5:
work.part5_1_3



TASK2
Transform the provided concordance file within the zipped PUMF into something usable
Also who on labour is responsible for creating such a garbage layout?


Task 2 Step 1: Import the concord file                                                                             
infile: 				LFS_PUMF_EPA_FGMD_variables.csv                                                              
output directory: 	Work                                                                                         
filename:				dictionary                                                                                   
                                                                                                                   
The provided headers were not usable or readable by SAS, somehow separated by carriage returns                     
over the first 11 rows. Data started on the 12th so that's where the import will begin extracting information.     
Task 2 Step 2: Fix the layout of the provided Concord                                                              
Data step                                                                                                          
infile:		work.Dictionary                                                                                 	 
outfile:		work.Dictionary1                                                                                     
                                                                                                                   
Variable spacing on the provided concordance was horrific, merging to the file was impossible in the               
original layout. There were null values in the rows supposed to be detailing the variable names                    
associated with the codes and descriptions.                                                                        
This step creates a new variable VARNAME based off of the column describing the variable names on the              
data file(s). It retains its value over the blank fields creating the appropriate specified design.                


Task 2 Step 3: Rename and reorient the requested mapping (concordance) tables                                      
Macro function                                                                                                     
Macro Name:		map_xfrm                                                                                         
Arguments:		column - name of the variable to make the concordance table and name of outgoing table           
Inputs:			work.dictionary1                                                                                 
Outputs:		work.<column> as defined in the arguement of the function                                            
                                                                                                                   
Datasets in the work directory named: naics_21, prov, educ, noc_40, and age_12 correspond to the specifications    
provided in the exam document.                                                                                     
                                                                                                                   
This function takes the corrected dictionary above and produces a concordance table for the specified              
variable defined by the criteria listed below.                                                                     
                                                                                                                   
Col Name 	Data Type 		Notes                                                                                    
code 		Int 			Code value                                                                               
en_label 	String 			English labels pertaining to the code value                                              
fr_label 	String 			French labels pertaining to the code value                                               

TASK 3
Append the 9 month's worth of data and create a single table according to the specifications provided


TASK3 Step1: collecting the 9 months of data together                                                             
REQUIREMENT - the files must be downloaded and placed in the directory as specified in the above variable         
startlocation. Link to the data can be found in the header. the files must be unzipped and all extracted in the   
single location.                                                                                                  
Macro function                                                                                                    
Macro Name:		input_data                                                                                        
Arguments:		none - expectation here is outlined in the exam documents for 9 months of data                  
Inputs:			LFS PUMF data labeled PUBMMYY.csv                                                                               
Outputs:		work.PUBMMYY dataset for each month of the PUMF downloaded as specified in the exam                 
                                                                                                                  
iterates from 1 to 9 calling the import procedure to create individual monthly datasets pulling from the location 
defined in the startlocation macrovariable																			


TASK3 Step 2                                                                                                      
Macro function                                                                                                    
Macro Name:		stack_data                                                                                      
Arguments:		none - expectation here is outlined in the exam documents for 9 months of data                  
Inputs:			9 datasets defined in the imput_data macro                                                      
output:			work.master_data                                                                                
                                                                                                                  
This step iterates through the 9 months of data and appends them to a single file										


Task3 Step 3
Creation of a temporary dataset to manipulate for the design specified in the exam documentation
data Master_data_temp;
	set master_data;
run;

TASK3 Step 4                                                                                                      
Macro function                                                                                                    
Macro Name:		ADD_VAR_DESC                                                                                    
Arguments:		T_VAR - variable for concordance swap                                                           
Inputs:			work.Master_data_temp                                                                           
output:			work.Master_data_temp                                                                           
                                                                                                                  
Due to type limitations in SAS the concordance requires merging in with a _temp variable to the dataset           
the concordance is linked through the dictionary by the associated variable as outlined in the exam specifications
                                                                                                                  
Function performs a linkage to the concordance file and replaces the numeric listed in the dataset with           
the english description.                                                                                          
It does this for  LFSSTAT, SEX,FTPTMAIN                                                                           



TASK3 Step5                                                                                                       
Derived Variable Additions                                                                                        
Data Step Function                                                                                                
infile:		work.master_data_temp                                                                                 	 
outfile:		work.master_data_temp                                                                               
                                                                                                                  
This step creates the derived variables based on the specifications outlined in the exam:                         
                                                                                                                  
QUARTER 		String		Derived Column – Bucket months into quarters                                            
VOLUNTARY_PT 	Boolean		Derived Column – TRUE if Part-time is voluntary else FALSE                              
                                                                                                                  
quarters are defined as JAN-MAR, APRIL-JUNE, JULY-SEPT, OCT-DEC which is derived from SURVMNTH on the file        
involuntary part time is defined by statscan to be an individual working PT due to                                
business conditions or the inability to find full-time work. This is described by the variable WHYPT.             
Options 6 and 7 outline involuntary PT while the first 5 options detail conditions where STATCAN                  
deems it voluntary.                                                                                               


TASK3 Step6
Data step 
infile:			work.master_data_temp
outfile:		work.Master_data_revised

This datastep reorders the variables and keeps only the ones listed in the specifications.
master_data_revised reflects the final output for task3.


PART4
Analysis

Part4,1 Step1                                                                                                        
PROC SQL summary statistics                                                                                       
Inputs:			work.Master_data_temp                                                                           
output:			work.part4_1_1                                                                                  
Var Created:	MTHWGT Total weight of eligible workers by month                                                    
                                                                                                                  
This step defines the denominator of people who are eligible to work by the provided weight var. It               
removes any records where  lfsstat is "Not in labour force". It then SUMS the total denominator                   
for a given month into the variable MTHWGT.																		


Part4.1 Step2                                                                                                       
PROC SQL summary statistics                                                                                       
Inputs:			work.part4_1_1                                                                                  
output:			work.part4_1_2                                                                                  
Var Created:	M_UNEMP Rate in % of unemployed records by month                                                    
                                                                                                                  
This step calculates the unemployment rate by month based on the denominators defined in step2.                   
It is the sum of FINALWT in each month of records defined by LFSSTAT to be "Unemployed", which is                 
divided by that month's denominator's total weight, MTHWGHT,then multiplied by 100 to represent a                 
percentage.                                                                                                       


Part4.1 Step3                                                                                                      
PROC SQL summary statistics                                                                                      
Inputs:			work.part4_1_2                                                                                 
output:			work.part4_1_3                                                                                 
Var Created:	Q_UNEMP Rate in % of unemployed records by Quarter                                                 
                                                                                                                 
Summing the rates from the previous step as defined in monthly unemployment, M_UNEMP, for each quarter           
then dividing by 3, the number of months in each quarter, we get the quarterly unemployment rate.                
                                                                                                                 
This dataset represents the result for PART4 question 1                                                          
                                                                                                                 
NOTE: the quarters could be defined further by ratio of days within each and forming a weighted                  
mean for a more accurate result.                                                                                 


Part4.2 Step1                                                                                                    
PROC SQL summary statistics                                                                                      
Inputs:			work.master_data_temp                                                                          
output:			work.part4_2_1                                                                                 
Var Created:		M_PROVWGT denominator weight of 15-29 year olds by month by  province                          
                                                                                                                 
The data is subsetted by those records having a value in the variable age_6 which is only populated by those     
respondents aged 15-29. As the file's weighting is calculated monthly the denominator must be calculated for     
each month. This is further grouped by province to create a denominator variable M_PROVWGT representing          
the total 15-29 year olds in each province in each month.                                                        


Part4.2 Step2                                                                                                    
PROC SQL summary statistics                                                                                      
Inputs:			work.part4_2_1                                                                                 
output:			work.part4_2_2                                                                                 
Var Created:	M_PROVEDU rate of postsecondary + educated 15-29 year olds by month by province                    
                                                                                                                 
The weights of the individuals having a value in the EDUC variable of 4,5,or 6 are summed here.                  
This variable accounts for any records with post secondary+ education. They are summed by month and by year      
and divided by their corresponding monthly provincial weight as defined in part4_2_1. This creates the education 
rate by month for 15-29 year olds, M_PROVEDU.                                                                    


Part4.2 Step3                                                                                                    
PROC SQL summary statistics                                                                                      
Inputs:			work.part4_2_2                                                                                 
output:			work.part4_2_3                                                                                 
Var Created:	PROVEDU rate of postsecondary + educated 15-29 year olds by month by province for first 3Q of 2022 
                                                                                                                 
Averaging the monthly education rate accross the 9 months provided we create the variable PROVEDU.               
This represents the % of respondents aged 15-29 who have post secondary+ education.                              
This dataset represents the result for PART4 question 2



Part4.3 Step1                    
PROC SQL summary statistics      
Inputs:			work.master_data_temp 
output:			work.part4_3_1 
Var Created:	M_INDWGT denominator weight by industry by month

Weights are calculated by month, so denominators need to be calculated by months. We sum the
weights of each of the industries as defined in the NAICS_21 variable by month and output them into 
M_INDWGT monthly industry weight

Part4.3 Step2                    
PROC SQL summary statistics      
Inputs:			work.part4_3_1 
output:			work.part4_3_2 
Var Created:	IND_M_INV_PT involuntary PT rate by month by industry

STATCAN defines involuntary part time having WHYPT = 6,7. Summing the individuals by month, by industry
then dividing by the denominator weight and multiplying by 100 gets us the rate involuntary parttime 
unemployment by month by industry,IND_M_INV_PT



Part4.3 Step3                    
PROC SQL summary statistics      
Inputs:			work.part4_3_2 
output:			work.part4_3_3 
Var Created:	IND_INV_PT involuntary PT rate by industry for first 9 months of 2022


Averaging the monthly involuntary PT rate accross the 9 months provided we create the variable IND_INV_PT.               
This represents the % involuntary PT rate by industry for first 9 months of 2022.                              



Part4.3 Step4
proc sort + data step
inputs:			part4_3_3

to find the top 5 we need to sort by descending rate of IND_INV_PT then take the top 5 results.
data set part4_3_4 represents the result for this question


PART 5

Part5 Step1                    
PROC SQL summary statistics      
Inputs:			work.master_data_temp 
output:			work.part5_1_1 
Var Created:		TOTEMPWGT total denominator of employed individuals by month


Summing the weights of the individuals working (where LFSSTAT is not "Not in labour force")
by month we get the denominator of working people by month

Part5 Step2                    
PROC SQL summary statistics      
Inputs:			work.part5_1_1 
output:			work.part5_1_2 
Var Created:		M_SEXEMP_RATE  rate of employed individuals by sex by month


summing the weights by sex by month then dividing by the total working that month times 100 gets us the rate 
of employment by sex by month.

Part5 Step3                    
PROC SQL summary statistics      
Inputs:			work.part5_1_2 
output:			work.part5_1_3 
Var Created:		SEXEMP_RATE  rate of employed individuals by sex in first 9 months of 2022


averaging the rate employed by sex over the 9 months of data gets us the employment rate by sex
for the first 9 months of 2022

