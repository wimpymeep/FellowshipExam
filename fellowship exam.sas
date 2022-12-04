/***************************************************************************************************************/
/*Author Cory Ross                                                                                             */
/*Data 3/12/2022                                                                                               */
/*Fellowship Exam.sas                                                                                          */
/*																											   */
/*Written on SAS 9.4                                                                                           */
/*																											   */
/*This code performs the tasks as detailed in the document provided on 2/12/2022 for the Stream 2:             */
/*Data Engineering exam.                                                                                       */
/*																											   */
/*This code requires that you have downloaded the 9 months of data for the Labour Force Survey located here:   */
/*https://www150.statcan.gc.ca/n1/en/catalogue/71M0001X/                                                       */
/*																											   */
/*These need to be extracted into one directory on your PC and the location defined in the macro variable      */
/*StartLocation.                                                                                               */
/*																											   */
/*The program is outlined in 5 sections following the design of the exam document.                             */
/***************************************************************************************************************/

/*INPUT REQUIREMENTS*/

%let StartLocation = C:\Users\roscory\Downloads\exam_data\;

/*TASK1*/
/*Download JAN-SEPT data into the startlocation above from:*/
/*https://www150.statcan.gc.ca/n1/en/catalogue/71M0001X/ */


/*TASK2*/
/*Transform the provided concordance file within the zipped PUMF into something usable*/
/*Also who on labour is responsible for creating such a garbage layout?*/


/*Task 2 Step 1: Import the concord file                                                                             */
/*infile: 				LFS_PUMF_EPA_FGMD_variables.csv                                                              */
/*output directory: 	Work                                                                                         */
/*filename:				dictionary                                                                                   */
/*                                                                                                                   */
/*The provided headers were not usable or readable by SAS, somehow separated by carriage returns                     */
/*over the first 11 rows. Data started on the 12th so that's where the import will begin extracting information.     */

proc import datafile= "&startlocation.\LFS_PUMF_EPA_FGMD_variables.csv"
	out = work.dictionary
	dbms = CSV
	replace;
	getnames=no;
	datarow=12;
	guessingrows=10000;

run;

/*Task 2 Step 2: Fix the layout of the provided Concord                                                              */
/*Data step                                                                                                          */
/*infile:		work.Dictionary                                                                                 	 */
/*outfile:		work.Dictionary1                                                                                     */
/*                                                                                                                   */
/*Variable spacing on the provided concordance was horrific, merging to the file was impossible in the               */
/*original layout. There were null values in the rows supposed to be detailing the variable names                    */
/*associated with the codes and descriptions.                                                                        */
/*This step creates a new variable VARNAME based off of the column describing the variable names on the              */
/*data file(s). It retains its value over the blank fields creating the appropriate specified design.                */

data dictionary1;
	set dictionary;
	retain VARNAME;
	if var5 ne '' then VARNAME=var5;
run;

/*Task 2 Step 3: Rename and reorient the requested mapping (concordance) tables                                      */
/*Macro function                                                                                                     */
/*Macro Name:		map_xfrm                                                                                         */
/*Arguments:		column - name of the variable to make the concordance table and name of outgoing table           */
/*Inputs:			work.dictionary1                                                                                 */
/*Outputs:		work.<column> as defined in the arguement of the function                                            */
/*                                                                                                                   */
/*Datasets in the work directory named: naics_21, prov, educ, noc_40, and age_12 correspond to the specifications    */
/*provided in the exam document.                                                                                     */
/*                                                                                                                   */
/*This function takes the corrected dictionary above and produces a concordance table for the specified              */
/*variable defined by the criteria listed below.                                                                     */
/*                                                                                                                   */
/*Col Name 	Data Type 		Notes                                                                                    */
/*code 		Int 			Code value                                                                               */
/*en_label 	String 			English labels pertaining to the code value                                              */
/*fr_label 	String 			French labels pertaining to the code value                                               */

%macro map_xfrm (column);
data &column.;
	set dictionary1;
/*	this takes out the junk lines with no codes associated with it*/
	if UPCASE (VARNAME) = UPCASE ("&column.") and var12 ne '';
/*	some codes are strings in the document, this resets them to ints as per the requirements*/
	code = input (var12, Best12.);
	en_label = var13;
	fr_label = var14;
	keep code en_label fr_label;
run;
%mend;
/*call the function for each specified variable*/
%map_xfrm (naics_21);
%map_xfrm (prov);
%map_xfrm (educ);
%map_xfrm (noc_40);
%map_xfrm (age_12);


/*TASK 3*/
/*Append the 9 month's worth of data and create a single table according to the specifications provided*/


/*TASK3 Step1: collecting the 9 months of data together                                                             */
/*REQUIREMENT - the files must be downloaded and placed in the directory as specified in the above variable         */
/*startlocation. Link to the data can be found in the header. the files must be unzipped and all extracted in the   */
/*single location.                                                                                                  */
/*Macro function                                                                                                    */
/*Macro Name:		input_data                                                                                      */  
/*Arguments:		none - expectation here is outlined in the exam documents for 9 months of data                  */
/*Inputs:			LFS PUMF data labeled PUBMMYY.csv                                                               */                
/*Outputs:		work.PUBMMYY dataset for each month of the PUMF downloaded as specified in the exam                 */
/*                                                                                                                  */
/*iterates from 1 to 9 calling the import procedure to create individual monthly datasets pulling from the location */
/*defined in the startlocation macrovariable																		*/	

%macro input_data ();
%do i = 1 %to 9;
	proc import datafile="&startlocation\pub0&i.22.csv"
		out = work.pub0&i.22
		dbms = CSV
		replace;
		guessingrows=10000;
	run;
%end;
%mend;
%input_data ();

/*TASK3 Step 2                                                                                                      */
/*Macro function                                                                                                    */
/*Macro Name:		stack_data                                                                                      */
/*Arguments:		none - expectation here is outlined in the exam documents for 9 months of data                  */
/*Inputs:			9 datasets defined in the imput_data macro                                                      */
/*output:			work.master_data                                                                                */
/*                                                                                                                  */
/*This step iterates through the 9 months of data and appends them to a single file									*/	

%macro stack_data ();
%do i = 1 %to 9;
proc append base = master_data data= pub0&i.22;
run;
%end;
%mend;
%stack_data();


/*Task3 Step 3*/
/*Creation of a temporary dataset to manipulate for the design specified in the exam documentation*/
data Master_data_temp;
	set master_data;
run;

/*TASK3 Step 4                                                                                                      */
/*Macro function                                                                                                    */
/*Macro Name:		ADD_VAR_DESC                                                                                    */
/*Arguments:		T_VAR - variable for concordance swap                                                           */
/*Inputs:			work.Master_data_temp                                                                           */
/*output:			work.Master_data_temp                                                                           */
/*                                                                                                                  */
/*Due to type limitations in SAS the concordance requires merging in with a _temp variable to the dataset           */
/*the concordance is linked through the dictionary by the associated variable as outlined in the exam specifications*/
/*                                                                                                                  */
/*Function performs a linkage to the concordance file and replaces the numeric listed in the dataset with           */
/*the english description.                                                                                          */
/*It does this for  LFSSTAT, SEX,FTPTMAIN                                                                           */
%macro ADD_VAR_DESC(T_VAR);
proc sql;
	create table Master_data_temp as select a.*, b.var13 as &T_VAR._temp 
		from master_data_temp a left join dictionary1 b on a.&T_VAR = input (b.var12, best12.)
		where upcase(b.varname) = upcase("&T_VAR.") and b.var12 ne '' ;
quit;

data master_data_temp;
	set master_data_temp;
	drop &T_VAR.;
run;
data master_data_temp;
	set master_data_temp;
	RENAME &T_VAR._temp = &T_VAR.;
run;

%mend;

%ADD_VAR_DESC (LFSSTAT);
%ADD_VAR_DESC (SEX);
%ADD_VAR_DESC (FTPTMAIN);


/*TASK3 Step5                                                                                                       */
/*Derived Variable Additions                                                                                        */
/*Data Step Function                                                                                                */
/*infile:		work.master_data_temp                                                                           */      	 
/*outfile:		work.master_data_temp                                                                               */
/*                                                                                                                  */
/*This step creates the derived variables based on the specifications outlined in the exam:                         */
/*                                                                                                                  */
/*QUARTER 		String		Derived Column – Bucket months into quarters                                            */
/*VOLUNTARY_PT 	Boolean		Derived Column – TRUE if Part-time is voluntary else FALSE                              */
/*                                                                                                                  */
/*quarters are defined as JAN-MAR, APRIL-JUNE, JULY-SEPT, OCT-DEC which is derived from SURVMNTH on the file        */
/*involuntary part time is defined by statscan to be an individual working PT due to                                */
/*business conditions or the inability to find full-time work. This is described by the variable WHYPT.             */
/*Options 6 and 7 outline involuntary PT while the first 5 options detail conditions where STATCAN                  */
/*deems it voluntary.                                                                                               */

data master_data_temp;
	set master_data_temp;
	if 1 le SURVMNTH le 3 then QUARTER = "Q1";
	else if 4 le SURVMNTH le 6 then QUARTER = "Q2";
	else if 7 le SURVMNTH le 9 then QUARTER = "Q3";
	else if 10 le SURVMNTH le 12 then QUARTER = "Q4";

	if whypt in (1:5) then VOLUNTARY_PT = 1; else VOLUNTARY_PT = 0;
run;


/*TASK3 Step6*/
/*Data step */
/*infile:			work.master_data_temp*/
/*outfile:		work.Master_data_revised*/

/*This datastep reorders the variables and keeps only the ones listed in the specifications.*/
/*master_data_revised reflects the final output for task3.*/

data Master_data_revised;

	retain
		SURVMNTH 
		LFSSTAT 
		PROV
		AGE_12
		SEX
		EDUC
		NAICS_21
		NOC_10
		NOC_40
		COWMAIN
		FTPTMAIN 
		QUARTER
		VOLUNTARY_PT
	;
	set master_data_temp;
	keep
		SURVMNTH 
		LFSSTAT 
		PROV
		AGE_12
		SEX
		EDUC
		NAICS_21
		NOC_10
		NOC_40
		COWMAIN
		FTPTMAIN 
		QUARTER
		VOLUNTARY_PT
	;
run;


/*PART4*/
/*Analysis*/

/*Part4,1 Step1                                                                                                        */
/*PROC SQL summary statistics                                                                                       */
/*Inputs:			work.Master_data_temp                                                                           */
/*output:			work.part4_1_1                                                                                  */
/*Var Created:	MTHWGT Total weight of eligible workers by month                                                    */
/*                                                                                                                  */
/*This step defines the denominator of people who are eligible to work by the provided weight var. It               */
/*removes any records where  lfsstat is "Not in labour force". It then SUMS the total denominator                   */
/*for a given month into the variable MTHWGT.																		*/

proc sql;
	create table part4_1_1 as select *, SUM(FINALWT) as MTHWGT from master_data_temp  where  lfsstat   ne "Not in labour force" group by SURVMNTH;
quit;

/*Part4.1 Step2                                                                                                       */
/*PROC SQL summary statistics                                                                                       */
/*Inputs:			work.part4_1_1                                                                                  */
/*output:			work.part4_1_2                                                                                  */
/*Var Created:	M_UNEMP Rate in % of unemployed records by month                                                    */
/*                                                                                                                  */
/*This step calculates the unemployment rate by month based on the denominators defined in step2.                   */
/*It is the sum of FINALWT in each month of records defined by LFSSTAT to be "Unemployed", which is                 */
/*divided by that month's denominator's total weight, MTHWGHT,then multiplied by 100 to represent a                 */
/*percentage.                                                                                                       */

proc sql;
	create table part4_1_2 as select distinct quarter, (SUM(FINALWT)/MTHWGT*100) as M_UNEMP, MTHWGT 
		from part4_1_1 where  lfsstat   = "Unemployed" group by SURVMNTH;
quit;

/*Part4.1 Step3                                                                                                      */
/*PROC SQL summary statistics                                                                                      */
/*Inputs:			work.part4_1_2                                                                                 */
/*output:			work.part4_1_3                                                                                 */
/*Var Created:	Q_UNEMP Rate in % of unemployed records by Quarter                                                 */
/*                                                                                                                 */
/*Summing the rates from the previous step as defined in monthly unemployment, M_UNEMP, for each quarter           */
/*then dividing by 3, the number of months in each quarter, we get the quarterly unemployment rate.                */
/*                                                                                                                 */
/*This dataset represents the result for PART4 question 1                                                          */
/*                                                                                                                 */
/*NOTE: the quarters could be defined further by ratio of days within each and forming a weighted                  */
/*mean for a more accurate result.                                                                                 */

proc sql;
	create table part4_1_3 as select distinct quarter, round (SUM(M_UNEMP)/3,.01) as Q_UNEMP from part4_1_2
	group by quarter;
quit;

/*Part4.2 Step1                                                                                                    */
/*PROC SQL summary statistics                                                                                      */
/*Inputs:			work.master_data_temp                                                                          */
/*output:			work.part4_2_1                                                                                 */
/*Var Created:		M_PROVWGT denominator weight of 15-29 year olds by month by  province                          */
/*                                                                                                                 */
/*The data is subsetted by those records having a value in the variable age_6 which is only populated by those     */
/*respondents aged 15-29. As the file's weighting is calculated monthly the denominator must be calculated for     */
/*each month. This is further grouped by province to create a denominator variable M_PROVWGT representing          */
/*the total 15-29 year olds in each province in each month.                                                        */

proc sql;
	create table part4_2_1 as select *, SUM(FINALWT) as M_PROVWGT from master_data_temp  where age_6 ne . group by SURVMNTH , PROV ;
quit;

/*Part4.2 Step2                                                                                                    */
/*PROC SQL summary statistics                                                                                      */
/*Inputs:			work.part4_2_1                                                                                 */
/*output:			work.part4_2_2                                                                                 */
/*Var Created:	M_PROVEDU rate of postsecondary + educated 15-29 year olds by month by province                    */
/*                                                                                                                 */
/*The weights of the individuals having a value in the EDUC variable of 4,5,or 6 are summed here.                  */
/*This variable accounts for any records with post secondary+ education. They are summed by month and by year      */
/*and divided by their corresponding monthly provincial weight as defined in part4_2_1. This creates the education */
/*rate by month for 15-29 year olds, M_PROVEDU.                                                                    */

proc sql;
	create table part4_2_2 as select distinct prov,SURVMNTH, (SUM(FINALWT)/M_PROVWGT*100) as M_PROVEDU  from part4_2_1 where educ in (4,5,6) group by SURVMNTH, PROV ;
quit;

/*Part4.2 Step3                                                                                                    */
/*PROC SQL summary statistics                                                                                      */
/*Inputs:			work.part4_2_2                                                                                 */
/*output:			work.part4_2_3                                                                                 */
/*Var Created:	PROVEDU rate of postsecondary + educated 15-29 year olds by month by province for first 3Q of 2022 */
/*                                                                                                                 */
/*Averaging the monthly education rate accross the 9 months provided we create the variable PROVEDU.               */
/*This represents the % of respondents aged 15-29 who have post secondary+ education.                              */
/*This dataset represents the result for PART4 question 2*/
proc sql;
	create table part4_2_3 as select distinct prov,round(SUM(M_PROVEDU)/9,.01) as PROVEDU  from part4_2_2  group by PROV ;
quit;



/*Part4.3 Step1                    */
/*PROC SQL summary statistics      */
/*Inputs:			work.master_data_temp */
/*output:			work.part4_3_1 */
/*Var Created:	M_INDWGT denominator weight by industry by month*/
/**/
/*Weights are calculated by month, so denominators need to be calculated by months. We sum the*/
/*weights of each of the industries as defined in the NAICS_21 variable by month and output them into */
/*M_INDWGT monthly industry weight*/

proc sql;
	create table part4_3_1 as select *, SUM(FINALWT) as M_INDWGT from master_data_temp  group by SURVMNTH, naics_21;
quit;

/*Part4.3 Step2                    */
/*PROC SQL summary statistics      */
/*Inputs:			work.part4_3_1 */
/*output:			work.part4_3_2 */
/*Var Created:	IND_M_INV_PT involuntary PT rate by month by industry*/
/**/
/*STATCAN defines involuntary part time having WHYPT = 6,7. Summing the individuals by month, by industry*/
/*then dividing by the denominator weight and multiplying by 100 gets us the rate involuntary parttime */
/*unemployment by month by industry,IND_M_INV_PT*/


proc sql;
	create table part4_3_2 as select distinct naics_21,SURVMNTH, (SUM(FINALWT)/M_INDWGT*100) as IND_M_INV_PT from part4_3_1 
		where whypt in (6,7) group by SURVMNTH, naics_21;
quit;

/**/
/*Part4.3 Step3                    */
/*PROC SQL summary statistics      */
/*Inputs:			work.part4_3_2 */
/*output:			work.part4_3_3 */
/*Var Created:	IND_INV_PT involuntary PT rate by industry for first 9 months of 2022*/
/**/
/**/
/*Averaging the monthly involuntary PT rate accross the 9 months provided we create the variable IND_INV_PT.               */
/*This represents the % involuntary PT rate by industry for first 9 months of 2022.                              */


proc sql;
	create table part4_3_3 as select distinct naics_21, round( (SUM(IND_M_INV_PT)/9),.01) as IND_INV_PT 
		from part4_3_2  group by  naics_21;
quit;

/*Part4.3 Step4*/
/*proc sort + data step*/
/*inputs:			part4_3_3*/
/**/
/*to find the top 5 we need to sort by descending rate of IND_INV_PT then take the top 5 results.*/
/*data set part4_3_4 represents the result for this question*/
/**/
proc sort data = part4_3_3;
by  descending IND_INV_PT;
run;

data part4_3_4;
	set part4_3_3;
	if _N_ <=5;
run;


/*PART 5*/

/*Part5 Step1                    */
/*PROC SQL summary statistics      */
/*Inputs:			work.master_data_temp */
/*output:			work.part5_1_1 */
/*Var Created:		TOTEMPWGT total denominator of employed individuals by month*/
/**/
/**/
/*Summing the weights of the individuals working (where LFSSTAT is not "Not in labour force")*/
/*by month we get the denominator of working people by month*/

proc sql;
	create table part5_1_1 as select *, SUM(FINALWT) as TOTEMPWGT from master_data_temp  where  lfsstat   ne "Not in labour force" group by SURVMNTH;
quit;

/*Part5 Step2                    */
/*PROC SQL summary statistics      */
/*Inputs:			work.part5_1_1 */
/*output:			work.part5_1_2 */
/*Var Created:		M_SEXEMP_RATE  rate of employed individuals by sex by month*/
/**/
/**/
/*summing the weights by sex by month then dividing by the total working that month times 100 gets us the rate */
/*of employment by sex by month.*/


proc sql;
	create table part5_1_2 as select distinct sex ,SURVMNTH, (SUM(FINALWT)/TOTEMPWGT*100) as M_SEXEMP_RATE from part5_1_1 group by SURVMNTH,sex ;
quit;

/*Part5 Step3                    */
/*PROC SQL summary statistics      */
/*Inputs:			work.part5_1_2 */
/*output:			work.part5_1_3 */
/*Var Created:		SEXEMP_RATE  rate of employed individuals by sex in first 9 months of 2022*/
/**/
/**/
/*averaging the rate employed by sex over the 9 months of data gets us the employment rate by sex*/
/*for the first 9 months of 2022*/



proc sql;
	create table part5_1_3 as select distinct sex , round((SUM(M_SEXEMP_RATE)/9),.01) as SEXEMP_RATE from part5_1_2 group by sex ;
quit;

