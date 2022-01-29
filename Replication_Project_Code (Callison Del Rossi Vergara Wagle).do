**********************Loading the file**********************************************
*If you opened stata via the Data file provided, there is no need to import the excel dataset

*If you opened new stata window, use this code below to import the dataset

**********Initial Set Up**********

*Using Apps on Demand: 
*Open a new Stata session
*Upload the .dta file to apps on demand 
*set up the log file
*change the working directory to the correct folder (Temporary Files) 
*****************************************************
*cd "C:\Users\PhotonUser\My Files\Temporary Files"
*capture log close
*log using "6120_Replication_Code", replace 
*clear all

**********Import Data**********

*Note that you will need to rename the .dta file after downloading it from Canvas or Stata cannot read it correctly. We added underscores.
*use Brazil_PNCF_final_data.dta


***********Variable Evaluation**********

*Export the variables and their labels. Consider the use case of each before proceeding. See the attached excel file for our group's interpretation of each variable. 
preserve
    describe, replace
    list
    export excel using key.xlsx, replace first(var)
restore



**********Data Cleaning**********

*Keep only the observations in the balanced panel used in the paper analysis (individuals interviewed in both the baseline and follow-up periods)
*re: Observations included in panel data set
xtset fid t
by fid: gen frequency = [_N]
keep if frequency == 2
move fid t

*Dummy variable generation for length of land ownership:  

gen lo_lessThanEq3 = 0
replace lo_lessThanEq3 = 1 if (gr[_n] == 3 | gr[_n+1]==3) & t == 1
label var lo_lessThanEq3 "LO 0-3 Years"
gen lo_4 = 0
replace lo_4 = 1 if (gr[_n] == 4 | gr[_n+1]==4) & t == 1
label var lo_4 "LO 4 Years"
gen lo_5or6 = 0
replace lo_5or6 = 1 if (gr[_n] == 5| gr[_n+1]==5) & t == 1
label var lo_5or6 "LO 5-6 Years"

*Descriptive variables for observation category (pipeline, beneficiary, length of land ownership)
gen test_grp = "Pipeline NB"
replace test_grp = "LO 0-3 Years" if lo_lessThanEq3 == 1
replace test_grp = "LO 4 Years" if lo_4 == 1
replace test_grp = "LO 5-6 Years" if lo_5or6 == 1
gen ben_status = "Pipeline NB"
replace ben_status = "Beneficiary" if ben == 1
move ben_status sex 


*Variables for agricultrual production and earned income, common across almost all tables. 
gen agri_product_per_capita = totagropec_r/npt
label var agri_product_per_capita "Agricultural Production"
rename eirpc earned_income_household
label var earned_income_household "Earned Income"

*Remove data outliers
drop if agri_product_per_capita >= 28000
drop if earned_income_household  >= 15000
sort fid
by fid: gen frequency2 = [_N]
keep if frequency2 == 2
move fid t

*Variables for Table 1, Descriptive Statistics:

*individual characteristic variables
gen white = 0
replace white = 1 if race == 2
label var white "White"
gen married = 0
replace married = 1 if ms == 4
label var married "Married"
rename school years_of_schooling
label var years_of_schooling "Years of Schooling"
rename exp years_of_experience
label var years_of_experience "Years of Experience"


*social capital variables
gen position_held = 0
replace position_held = 1 if cargo == 1
label var position_held "Position Held"
rename meet freq_of_meeting
label var freq_of_meeting "Frequency of Meeting"


*individual agricultural variables
rename ta technical_assist
label var technical_assist "Technical Assistance"

*local agricultural variables
rename ycorn corn_yield
label var corn_yield "Yield of Corn"
rename w_agd daily_ag_wage
label var daily_ag_wage "Daily Agricultural Wage"

*Variable for Table 2, Probits for Probability: 

*Create dependent variable pipeline nonbeneficiaries = 1 if acquired land between baseline and follow-up; = 0 if did not 
gen LB_enroll = 0
replace LB_enroll = 1 if t == 1 & status == 2
*replaced 162 values which matches what the authors had for "switchers"


*Variables for Table 3, Difference in Difference: 

*Time*Beneficiary
gen Post_Ben = t * ben
label var Post_Ben "Time*Status"
gen Post_LO_3 = t * lo_lessThanEq3
gen Post_LO_4 = t * lo_4
gen Post_LO_5 = t * lo_5or6

****Table 1 Testing***

*************************************************Agricultural Production Tables
*create table of agricultural production mean & se by status (beneficiary or  pipeline NB)  w/ p-value test
encode ben_status, gen(benStatus)
quietly: collect table ( benStatus ) () () if t==0, statistic(frequency) statistic(mean agri_product_per_capita) statistic(semean agri_product_per_capita) command(r(p): ttest agri_product_per_capita, by(benStatus)) nformat(%9.5g  mean) nformat(%9.4g  semean) name(agtab1) stars( _r_p 0.01 "***" 0.05 "**" 0.1 "*", attach(_r_p) )
quietly: collect layout (colname) (benStatus#result)
collect label values result frequency "N", modify
collect label values result semean "SE", modify
collect label values result p "p-value", modify
collect style header, title(hide)
collect preview, name(agtab1)
collect export Table1_ag_product_total_ds.xlsx


*create table of agricultural production mean & se by status and length of land ownership. 
encode test_grp, gen (testGroup)

quietly: collect table ( benStatus ) (testGroup) () if (lo_lessThanEq3==1 | lo_4==1 | lo_5or6==1), nototals statistic(frequency) statistic(mean  agri_product_per_capita) statistic(semean agri_product_per_capita) nformat(%9.5g  mean) nformat(%9.4g  semean) name(agtab2)
quietly: collect layout (testGroup) (benStatus#result)
collect label values result frequency "N", modify
collect label values result semean "SE", modify
collect label values result p "p-value", modify
collect style header, title(hide)
collect preview, name(agtab2)
collect export Table1_ag_product_LO_ds.xlsx

*p-values comparing means of each LO category to beneficiary mean
ttesti 562 789.38 60.78 100  792.27  88.86
ttesti 562 789.38 60.78 315  979.02  88.01
ttesti 562 789.38 60.78 147  1055.1  176.5


*IMPORTANT: need p-values comparing means of each LO to pipeline mean. Note, these are in different time periods!
*p-values for agricultural production mean & se by status and length of land ownership
*ttesti (obs 1, mean1 se 1) (obs 2 mean1 se1)

**************************************************Earned Income Table

*create table of earned income mean & se by status (beneficiary or  pipeline NB) w/ p-value test
quietly: collect table ( benStatus ) () () if t==0, statistic(frequency) statistic(mean earned_income_household) statistic(semean earned_income_household) command(r(p): ttest earned_income_household, by(benStatus)) nformat(%9.5g  mean) nformat(%9.4g  semean) name(ehtab1) stars( _r_p 0.01 "***" 0.05 "**" 0.1 "*", attach(_r_p) )
quietly: collect layout (colname) (benStatus#result)
collect label values result frequency "N", modify
collect label values result semean "SE", modify
collect label values result p "p-value", modify
collect style header, title(hide)
collect preview, name(ehtab1)
collect export Table1_earned_income_total_ds.xlsx

*create table of earned income mean & se by status and length of land ownership.
quietly: collect table ( benStatus ) (testGroup) () if (lo_lessThanEq3==1 | lo_4==1 | lo_5or6==1), nototals statistic(frequency) statistic(mean  earned_income_household) statistic(semean earned_income_household) name(ehtab2)
quietly: collect layout (testGroup) (benStatus#result)
collect label values result frequency "N", modify
collect label values result semean "SE", modify
collect label values result p "p-value", modify
collect style header, title(hide)
collect preview, name(ehtab2)
collect export Table1_earned_income_LO_ds.xlsx

*p-values comparing means of each LO category to beneficiary mean
ttesti 562 1474.2 66.18 100 1241.457 116.7457
ttesti 562 1474.2 66.18 315 1406.077 107.5488 
ttesti 562 1474.2 66.18 147 1793.163 196.307

*IMPORTANT: need p-values comparing means of each LO to pipeline mean. Note, these are in different time periods!
*p-values for agricultural production mean & se by status and length of land ownership
*ttesti (obs 1, mean1 se 1) (obs 2 mean1 se1)

**************************************************Individual Characteristics Table

*create table of means and se for each characteristic. p-values are in the table below because placing them together caused overrides. IMPORTANT: Needs to be merged.
quietly: collect table () ( benStatus ) () if t==0, nototals statistic(mean  age sex white married urban years_of_schooling years_of_experience) statistic(semean age sex white married urban years_of_schooling years_of_experience) nformat(%9.5g  mean) nformat(%9.4g  semean) name(indtab)
quietly: collect layout (colname) (benStatus#result)
collect label values result frequency "N", modify
collect label values result semean "SE", modify
collect style header, title(hide)
collect preview, name(indtab)
collect export Table1_indiv_char_total_ds.xlsx


quietly: collect table () ( benStatus ) () if t==0, command(r(p): ttest age, by(benStatus)) command(r(p): ttest sex, by(benStatus)) command(r(p): ttest white, by(benStatus)) command(r(p): ttest married, by(benStatus)) command(r(p): ttest urban, by(benStatus)) command(r(p): ttest years_of_schooling, by(benStatus)) command(r(p): ttest years_of_experience, by(benStatus)) nformat(%9.2g _r_p) name(indtab2)
collect label values statcmd 1 "Age", modify
collect label values statcmd 2 "Sex", modify
collect label values statcmd 3 "White", modify
collect label values statcmd 4 "Married", modify
collect label values statcmd 5 "Urban", modify
collect label values statcmd 6 "Years of Schooling", modify
collect label values statcmd 7 "Years of Experience", modify
collect label levels ben_status .m "p-value", modify
collect style header, title(hide)
collect preview, name(indtab2)
collect export Table1_indiv_char_pvalues_ds.xlsx

***************************************************Social Capital Table

*create table of means and se for each social capital variable. p-values are in the table below because placing them together caused overrides. IMPORTANT: Needs to be merged.
quietly: collect table () ( benStatus ) () if t==0, nototals statistic(mean position_held freq_of_meeting trust) statistic(semean position_held freq_of_meeting trust) nformat(%9.5g  mean) nformat(%9.4g  semean) name(soctab)
quietly: collect layout (colname) (benStatus#result)
collect label values result frequency "N", modify
collect label values result semean "SE", modify
collect style header, title(hide)
collect preview, name(soctab)
collect export Table1_social_char_total_ds.xlsx

quietly: table () ( benStatus ) () if t==0, command(r(p): ttest position_held, by(benStatus)) command(r(p): ttest freq_of_meeting, by(benStatus)) command(r(p): ttest trust, by(benStatus)) nformat(%9.2g _r_p) name(soctab2)
collect label values statcmd 1 "Position Held", modify
collect label values statcmd 2 "Frequency of Meeting", modify
collect label values statcmd 3 "Trust", modify
collect label levels benStatus .m "p-value", modify
collect style header, title(hide)
collect preview, name(soctab2)
collect export Table1_social_char_pvalues_ds.xlsx

***************************************************Individual Agricultural Variables Table

*create table of means and se for each individual agricultural variable. p-values are in the table below because placing them together caused overrides. IMPORTANT: Needs to be merged.

quietly: collect table () ( benStatus ) () if t==0, nototals statistic(mean technical_assist pronaf) statistic(semean technical_assist pronaf) nformat(%9.5g  mean) nformat(%9.4g  semean) name(indagtab)
quietly: collect layout (colname) (benStatus#result)
collect label values result frequency "N", modify
collect label values result semean "SE", modify
collect style header, title(hide)
collect preview, name(indagtab)
collect export Table1_indiv_agri_total_ds.xlsx


quietly: table () ( benStatus ) () if t==0, command(r(p): ttest technical_assist, by(benStatus)) command(r(p): ttest pronaf, by(benStatus)) nformat(%9.2g _r_p) name(indagtab2)
collect label values statcmd 1 "Technical Assistance", modify
collect label values statcmd 2 "PRONAF", modify
collect label levels benStatus .m "p-value", modify
collect style header, title(hide)
collect preview, name(indagtab2)
collect export Table1_indiv_agri_pvalues_ds.xlsx

***************************************************Local Agricultural Variables Table

*create table of means and se for each individual agricultural variable. p-values are in the table below because placing them together caused overrides.

quietly: collect table () ( benStatus ) () if t==0, nototals statistic(mean corn_yield dayw_mr) statistic(semean corn_yield dayw_mr) nformat(%9.5g  mean) nformat(%9.4g  semean) name(locagtab) 
quietly: collect layout (colname) (benStatus#result)
collect label values result frequency "N", modify
collect label values result semean "SE", modify
collect style header, title(hide)
collect preview, name(locagtab)
collect export Table1_local_agri_total_ds.xlsx


quietly: table () ( benStatus ) () if t==0, command(r(p): ttest corn_yield, by(benStatus)) command(r(p): ttest dayw_mr, by(benStatus)) nformat(%9.2g _r_p) name(locagtab2)
collect label values statcmd 1 "Yield of Corn", modify
collect label values statcmd 2 "Daily Agricultural Wage", modify
collect label levels benStatus .m "p-value", modify
collect style header, title(hide)
collect preview, name(locagtab2)
collect export Table1_local_agri_pvalues_ds.xlsx

************* PROBIT *******************************************************


*regression 1: just explanatory variable (agricultural production)

probit LB_enroll agri_product_per_capita if status == 2, cluster(projcode)
eststo model1

*regression 2: just explanatory variable (earned income)

probit LB_enroll earned_income_household if status == 2, cluster(projcode) 
eststo model2

*regression 3: agricultural production, state FE, plus controls 

probit LB_enroll agri_product_per_capita i.UF age sex white married years_of_schooling years_of_experience urban position_held freq_of_meeting trust technical_assist pronaf corn_yield daily_ag_wage if status == 2, cluster(muni)
eststo model3
*clustered SE's at the municipal level create smaller SE's for this regression

*regression 4: earned income, state FE, plus controls

probit LB_enroll earned_income_household age i.UF sex white married years_of_schooling years_of_experience urban position_held freq_of_meeting trust technical_assist pronaf corn_yield daily_ag_wage if status == 2, cluster(projcode)
eststo model4

esttab using Table2_probit.csv, se

*******************DIFFERENCE IN DIFFERENCE*********************************

**********areg foing fixed effects regression with municipal fe************
areg agri_product_per_capita t ben Post_Ben ,absorb(muni) cluster(muni)
estimates store vals1, title(eqn1)
******************
areg agri_product_per_capita t ben Post_Ben age sex i.race i.ms years_of_schooling years_of_experience urban,absorb(muni) cluster(muni)
estimate store vals2, title(eqn2)
*******************
areg agri_product_per_capita t ben Post_Ben age sex i.race i.ms years_of_schooling years_of_experience urban cargo freq_of_meeting trust,absorb(muni) cluster(muni)
estimate store vals3, title(eqn3)
*******************
areg agri_product_per_capita t ben Post_Ben age sex i.race i.ms years_of_schooling years_of_experience urban cargo freq_of_meeting trust dayw_mr ycrn,absorb(muni) cluster(muni)
estimate store vals4, title(eqn4)
*******************
areg agri_product_per_capita t ben Post_Ben ,absorb(fid) cluster(muni)
estimate store vals5, title(eqn5)
*******************
areg agri_product_per_capita t ben Post_Ben dayw_mr ycrn,absorb(fid) cluster(muni)
estimate store vals6, title(eqn6)
*********Combines all eqns as a table and outputs as a table in csv************
esttab vals1 vals2 vals3 vals4 vals5 vals6 using Table3_one.csv, drop(t ben age sex *.race *.ms years_of_schooling years_of_experience urban cargo freq_of_meeting trust dayw_mr ycrn _cons) cells(b(star fmt(2)) se(par fmt(2))) legend label varlabels(_cons Constant)
************Panel 2
***********Labeling the variables for naming in the table**********
label var lo_lessThanEq3 "LO 0-3 Years"
label var lo_4 "LO 4 Years"
label var lo_5or6 "LO 5-6 Years"

*************Regression for each column of data in table************
areg agri_product_per_capita t ben lo_lessThanEq3 lo_4 lo_5or6, absorb(muni) cluster(muni)
estimate store vals7, title(eqn7)
**********************
areg agri_product_per_capita t ben lo_lessThanEq3 lo_4 lo_5or6 age sex i.race i.ms years_of_schooling years_of_experience urban, absorb(muni) cluster(muni)
estimate store vals8, title(eqn8)
**********************
areg agri_product_per_capita t ben lo_lessThanEq3 lo_4 lo_5or6 age sex i.race i.ms years_of_schooling years_of_experience urban cargo freq_of_meeting trust, absorb(muni) cluster(muni)
estimate store vals9, title(eqn9)
**********************
areg agri_product_per_capita t ben lo_lessThanEq3 lo_4 lo_5or6 age sex i.race i.ms years_of_schooling years_of_experience urban cargo freq_of_meeting trust dayw_mr ycrn, absorb(muni) cluster(muni)
estimate store vals10, title(eqn10)
**********************
areg agri_product_per_capita t lo_lessThanEq3 lo_4 lo_5or6, absorb(muni) cluster(muni)
estimate store vals11, title(eqn11)
**********************
areg agri_product_per_capita t lo_lessThanEq3 lo_4 lo_5or6 ycrn dayw_mr, absorb(muni) cluster(muni)
estimate store vals12, title(eqn12)
**********Combines all eqns as a table and outputs as a table in csv************
esttab vals7 vals8 vals9 vals10 vals11 vals12 using Table3_two.csv, drop(t ben age sex *.race *.ms years_of_schooling years_of_experience urban cargo freq_of_meeting trust dayw_mr ycrn _cons) cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons Constant)



