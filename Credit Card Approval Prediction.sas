libname project "/home/u63693354/myproj";
*libname project "D:\DataScience\07SAS\SAS_Library";

/* Business Problem */
/* What factors influence credit card approval? */
/* Clients with higher annual incomes are more likely to be approved.
Clients who own property are less likely to be high credit risks.
Education level is positively correlated with creditworthiness.
Gender may influence the choice of housing type and education level.
Clients with a longer employment history are more likely to be approved for credit cards. */

/* Import Data */
PROC IMPORT OUT= project.CreditCard 
            DATAFILE= '/home/u63693354/myproj/Credit_card.csv'
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     GUESSINGROWS=1000;
     *MIXED=NO;
     *SCANTEXT=YES;
     *USEDATE=YES;
     *SCANTIME=YES;
RUN;
*DATAFILE= '/home/u63517891/Library/Credit_card.csv';
Proc Print data=project.CreditCard; 
Run;

/* variable identification */
Proc Contents data= project.CreditCard;
Run;
/* =============================================================================================== */

/* Missing Values */
proc freq data=project.CreditCard;
tables _CHARACTER_ / missing;
run;

proc means data=project.CreditCard nmiss;
var _numeric_;
run;
*have missing value:
GENDER Type_Occupation
Annual_income Birthday_count;

/* Replace Numeric Missing Values with Median*/
* Calculate Median;
proc summary data=project.CreditCard nway;
    var Annual_income Birthday_count;
    output out=MedianValues median=Annual_income_median Birthday_count_median;
run;

data project.CreditCard2;
    set project.CreditCard;
    if _N_ = 1 then set MedianValues;
    if missing(Annual_income) then Annual_income = Annual_income_median;
    if missing(Birthday_count) then Birthday_count = Birthday_count_median;
run;
proc means data=project.CreditCard2 nmiss;
var _numeric_;
run;

/* Replace Missing Values for Gender with Mode */
proc freq data=project.CreditCard2 noprint;
    table GENDER / out=Mode(drop=percent count) noprint;
    where GENDER is not missing;
run;

data project.CreditCard2;
    set project.CreditCard2;
    if missing(GENDER) then GENDER = 'F';
run;

proc freq data=project.CreditCard2;
tables _CHARACTER_ / missing;
run;

/* Replace Missing Values for Gender with "Unknown" */
data project.CreditCard2;
    set project.CreditCard2;
    if missing(Type_Occupation) then Type_Occupation = "Unknown";
run;

/* Replace the value for less than 100 in each category with "Others" */
proc sql;
   create table OccupationCounts as
   select Type_Occupation, count(*) as count
   from project.CreditCard2
   group by Type_Occupation;
quit;

data project.CreditCard2;
    if _N_ = 1 then do;
        declare hash h(dataset: "OccupationCounts");
        h.defineKey("Type_Occupation");
        h.defineData("count");
        h.defineDone();
    end;

    set project.CreditCard2;

    rc = h.find();
    if rc = 0 then do;
        if count < 100 then Type_Occupation = "Others";
    end;
run;
/* =============================================================================================== */

/* Univariate Analysis*/
data project.CreditCard3;
set project.CreditCard2;
Age = int(abs(Birthday_count) / 365.25);
if Employed_days = 365243 then do;
  Employed_Day = 0;
  Employed_Year = 0;
end;
else do;
  Employed_Day = abs(Employed_days);
  Employed_Year = round(Employed_Day / 365.25, 0.1);
end;
drop Ind_ID _TYPE_ _FREQ_ Annual_income_median Birthday_count_median count rc Mobile_phone;
run;
Proc Print data=project.CreditCard3; 
Run;

* Categorical variables;
proc freq data=project.CreditCard3;
table GENDER Car_Owner Propert_Owner CHILDREN Type_Income EDUCATION Marital_status 
Housing_type Work_Phone Phone EMAIL_ID Type_Occupation Family_Members label/missing;
run;
proc sgplot data=project.CreditCard3;
vbar Car_Owner / missing;
run;
proc sgplot data=project.CreditCard3;
vbar Propert_Owner / missing;
run;
proc sgplot data=project.CreditCard3;
vbar CHILDREN / missing;
run;
proc sgplot data=project.CreditCard3;
vbar Type_Income / missing;
run;
proc sgplot data=project.CreditCard3;
vbar EDUCATION / missing;
run;
proc sgplot data=project.CreditCard3;
vbar Marital_status / missing;
run;
proc sgplot data=project.CreditCard3;
vbar Housing_type / missing;
run;
proc sgplot data=project.CreditCard3;
vbar Work_Phone / missing;
run;
proc sgplot data=project.CreditCard3;
vbar Phone / missing;
run;
proc sgplot data=project.CreditCard3;
vbar EMAIL_ID / missing;
run;
proc sgplot data=project.CreditCard3;
vbar Type_Occupation / missing;
run;
proc sgplot data=project.CreditCard3;
vbar Family_Members / missing;
run;
proc sgplot data=project.CreditCard3;;
vbar label / missing;
run;
    

* Numerical variables;
title "Annual Income Distribution";
proc sgplot data=project.CreditCard3;
histogram Annual_income;
density Annual_income /type=kernel;
run;

title "Birthday_count Distribution";
proc sgplot data=project.CreditCard3;
histogram Birthday_count;
density Birthday_count /type=kernel;
run;

title "Age Distribution";
proc sgplot data=project.CreditCard3;
histogram Age;
density Age /type=kernel;
run;

title "Employed Days Distribution";
proc sgplot data=project.CreditCard3;
histogram Employed_Day;
density Employed_Day /type=kernel;
run;

title "Employed Years Distribution";
proc sgplot data=project.CreditCard3;
histogram Employed_Year;
density Employed_Year /type=kernel;
run;

proc univariate data=project.CreditCard3;
var Annual_income;
histogram Annual_income/ normal (mu=est sigma=est color=black) 
kernel (color=blue);
qqplot Annual_income/ normal (mu=est sigma=est color=black);
run;

proc univariate data=project.CreditCard3;
var Age;
histogram Age/ normal (mu=est sigma=est color=black) 
kernel (color=blue);
qqplot Age/ normal (mu=est sigma=est color=black);
run;

proc univariate data=project.CreditCard3;
var Employed_Day;
histogram Employed_Day/ normal (mu=est sigma=est color=black) 
kernel (color=blue);
qqplot Employed_Day/ normal (mu=est sigma=est color=black);
run;

proc univariate data=project.CreditCard3;
var Employed_Year;
histogram Employed_Year/ normal (mu=est sigma=est color=black) 
kernel (color=blue);
qqplot Employed_Year/ normal (mu=est sigma=est color=black);
run;
/* =============================================================================================== */

/* Bivariate Analysis */
* categrical;
* GENDER VS label ;
proc freq data=project.CreditCard3;
 table GENDER * label / norow nocol nopct
    out=project.FreqOut(where=(percent^=.));
run; 
* heatmap;
proc sgplot data=project.FreqOut noautolegend;
heatmap x=GENDER y=label / freq=Count 
         discretex discretey
         colormodel=TwoColorRamp outline;
text x=GENDER y=label text=Count / textattrs=(size=16pt);
yaxis display=(nolabel) reverse;
xaxis display=(nolabel);
run;
proc freq data=project.CreditCard3;
tables GENDER*Car_Owner / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables GENDER*Car_Owner / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by GENDER;
proc freq data=credit2 noprint;
by GENDER;
tables Car_Owner / out=freqout;
run;
proc sgplot data=freqout;
vbar GENDER / response=percent
	group=Car_Owner groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of Car_Owner";
run;

* Marital_status VS label ;
proc freq data=project.CreditCard3;
 table Marital_status * label / norow nocol nopct
    out=project.FreqOut(where=(percent^=.));
run; 
* heatmap;
proc sgplot data=project.FreqOut noautolegend;
heatmap x=Marital_status y=label / freq=Count 
         discretex discretey
         colormodel=TwoColorRamp outline;
text x=Marital_status y=label text=Count / textattrs=(size=16pt);
yaxis display=(nolabel) reverse;
xaxis display=(nolabel);
run;

* Housing_type VS label ;
proc freq data=project.CreditCard3;
 table Housing_type * label / norow nocol nopct
    out=project.FreqOut(where=(percent^=.));
run; 
* heatmap;
proc sgplot data=project.FreqOut noautolegend;
heatmap x=Housing_type y=label / freq=Count 
         discretex discretey
         colormodel=TwoColorRamp outline;
text x=Housing_type y=label text=Count / textattrs=(size=16pt);
yaxis display=(nolabel) reverse;
xaxis display=(nolabel);
run;

* Family_Members VS label ;
proc freq data=project.CreditCard3;
 table Family_Members * label / norow nocol nopct
    out=project.FreqOut(where=(percent^=.));
run; 
* heatmap;
proc sgplot data=project.FreqOut noautolegend;
heatmap x=Family_Members y=label / freq=Count 
         discretex discretey
         colormodel=TwoColorRamp outline;
text x=Family_Members y=label text=Count / textattrs=(size=16pt);
yaxis display=(nolabel) reverse;
xaxis display=(nolabel);
run;

* vbar and chisq;
proc freq data=project.CreditCard3;
tables CHILDREN*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables CHILDREN*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by CHILDREN;
proc freq data=credit2 noprint;
by CHILDREN;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar CHILDREN / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables Family_Members*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables Family_Members*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by Family_Members;
proc freq data=credit2 noprint;
by Family_Members;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar Family_Members / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables Work_Phone*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables Work_Phone*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by Work_Phone;
proc freq data=credit2 noprint;
by Work_Phone;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar Work_Phone / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables EMAIL_ID*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables EMAIL_ID*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by EMAIL_ID;
proc freq data=credit2 noprint;
by EMAIL_ID;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar EMAIL_ID / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables GENDER*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables GENDER*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by GENDER;
proc freq data=credit2 noprint;
by GENDER;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar GENDER / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables Car_Owner*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables Car_Owner*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by Car_Owner;
proc freq data=credit2 noprint;
by Car_Owner;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar Car_Owner / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables Propert_Owner*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables Propert_Owner*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by Propert_Owner;
proc freq data=credit2 noprint;
by Propert_Owner;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar Propert_Owner / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables Type_Income*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables Type_Income*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by Type_Income;
proc freq data=credit2 noprint;
by Type_Income;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar Type_Income / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables EDUCATION*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables EDUCATION*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by EDUCATION;
proc freq data=credit2 noprint;
by EDUCATION;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar EDUCATION / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables Marital_status*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables Marital_status*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by Marital_status;
proc freq data=credit2 noprint;
by Marital_status;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar Marital_status / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables Housing_type*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables Housing_type*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by Housing_type;
proc freq data=credit2 noprint;
by Housing_type;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar Housing_type / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;

proc freq data=project.CreditCard3;
tables Type_Occupation*label / norow nocol nopercent;
run;
proc freq data=project.CreditCard3;
tables Type_Occupation*label / chisq fisher;
run;
proc sort data=project.CreditCard3
	out=credit2;
by Type_Occupation;
proc freq data=credit2 noprint;
by Type_Occupation;
tables label / out=freqout;
run;
proc sgplot data=freqout;
vbar Type_Occupation / response=percent
	group=label groupdisplay=stack;
xaxis discreteorder=data;
	yaxis grid values=(0 to 100 by 10)
	label="percentage of label";
run;



* mumerical;
* Employed_Day VS label ;
proc freq data=project.CreditCard3;
 table Employed_Day * label / norow nocol nopct
    out=project.FreqOut(where=(percent^=.));
run; 
* heatmap;
proc sgplot data=project.FreqOut noautolegend;
heatmap x=Employed_Day y=label / freq=Count 
         discretex discretey
         colormodel=TwoColorRamp outline;
text x=Employed_Day y=label text=Count / textattrs=(size=16pt);
yaxis display=(nolabel) reverse;
xaxis display=(nolabel);
run;

*Annual_income VS label;
proc sgplot data=project.CreditCard3;
vbox Annual_income/group=label;
run;
proc sgplot data=project.CreditCard3;
histogram Annual_income;
density Annual_income/group=label  type=kernel;
run;
proc means data=project.CreditCard3 n nmiss min max mean median p1 p10 q1 median mean q3 p90 p99 maxdec=2;
class label;
var Annual_income;
run;

*Annual_income VS Gender;
proc sgplot data=project.CreditCard3;
vbox Annual_income/group=GENDER;
run;
proc sgplot data=project.CreditCard3;
histogram Annual_income;
density Annual_income/group=GENDER  type=kernel;
run;
proc means data=project.CreditCard3 n nmiss min max mean median p1 p10 q1 median mean q3 p90 p99 maxdec=2;
class GENDER;
var Annual_income;
run;

*Annual_income VS CHILDREN;
proc sgplot data=project.CreditCard3;
vbox Annual_income/group=CHILDREN;
run;
proc sgplot data=project.CreditCard3;
histogram Annual_income;
density Annual_income/group=CHILDREN  type=kernel;
run;
proc means data=project.CreditCard3 n nmiss min max mean median p1 p10 q1 median mean q3 p90 p99 maxdec=2;
class CHILDREN;
var Annual_income;
run;

*Annual_income VS Type_Income;
proc sgplot data=project.CreditCard3;
vbox Annual_income/group=Type_Income;
run;
proc sgplot data=project.CreditCard3;
vbox Annual_income/category=Type_Income group=EDUCATION groupdisplay=cluster;
run;
proc sgplot data=project.CreditCard3;
histogram Annual_income;
density Annual_income/group=Type_Income  type=kernel;
run;
proc means data=project.CreditCard3 n nmiss min max mean median p1 p10 q1 median mean q3 p90 p99 maxdec=2;
class Type_Income;
var Annual_income;
run;

*Annual_income VS EDUCATION;
proc sgplot data=project.CreditCard3;
vbox Annual_income/group=EDUCATION;
run;
proc sgplot data=project.CreditCard3;
vbox Annual_income/category=EDUCATION group=label groupdisplay=cluster;
run;
proc sgplot data=project.CreditCard3;
histogram Annual_income;
density Annual_income/group=EDUCATION  type=kernel;
run;
proc means data=project.CreditCard3 n nmiss min max mean median p1 p10 q1 median mean q3 p90 p99 maxdec=2;
class EDUCATION;
var Annual_income;
run;

*Annual_income VS Marital_status;
proc sgplot data=project.CreditCard3;
vbox Annual_income/group=Marital_status;
run;
proc sgplot data=project.CreditCard3;
histogram Annual_income;
density Annual_income/group=Marital_status  type=kernel;
run;
proc means data=project.CreditCard3 n nmiss min max mean median p1 p10 q1 median mean q3 p90 p99 maxdec=2;
class Marital_status;
var Annual_income;
run;

*Annual_income VS Housing_type;
proc sgplot data=project.CreditCard3;
vbox Annual_income/group=Housing_type;
run;
proc sgplot data=project.CreditCard3;
histogram Annual_income;
density Annual_income/group=Housing_type  type=kernel;
run;
proc means data=project.CreditCard3 n nmiss min max mean median p1 p10 q1 median mean q3 p90 p99 maxdec=2;
class Housing_type;
var Annual_income;
run;

*Annual_income VS Type_Occupation;
proc sgplot data=project.CreditCard3;
vbox Annual_income/group=Type_Occupation;
run;
proc sgplot data=project.CreditCard3;
histogram Annual_income;
density Annual_income/group=Type_Occupation  type=kernel;
run;
proc means data=project.CreditCard3 n nmiss min max mean median p1 p10 q1 median mean q3 p90 p99 maxdec=2;
class Type_Occupation;
var Annual_income;
run;

*Age VS label;
proc sgplot data=project.CreditCard3;
vbox Age/group=label;
run;
proc sgplot data=project.CreditCard3;
histogram Age;
density Age/group=label  type=kernel;
run;
proc means data=project.CreditCard3 n nmiss min max mean median p1 p10 q1 median mean q3 p90 p99 maxdec=2;
class label;
var Age;
run;

*Employed_Year VS label;
proc sgplot data=project.CreditCard3;
vbox Employed_Year/group=label;
run;
proc sgplot data=project.CreditCard3;
histogram Employed_Year;
density Employed_Year/group=label  type=kernel;
run;
proc means data=project.CreditCard3 n nmiss min max mean median p1 p10 q1 median mean q3 p90 p99 maxdec=2;
class label;
var Employed_Year;
run;



*Chi-Square;
proc freq data=project.CreditCard3 order=data;
table  (GENDER Car_Owner Propert_Owner CHILDREN Type_Income EDUCATION Marital_status Housing_type
Work_Phone Phone EMAIL_ID Type_Occupation Family_Members) * label / chisq OUT=resptabl;
output all out= outfreq chisq;
run;

*Correlation;
proc corr data=project.CreditCard3;
var Annual_income Age  Employed_Year;
run;

proc sgscatter data=project.CreditCard3; 
matrix Annual_income Age  Employed_Year / diagonal=(histogram kernel);
run;
/* =============================================================================================== */

/* Outliers */
* PCA;
proc princomp data=project.CreditCard3 out=project.pcaout;
var Annual_income Age  Employed_Year;
run;
* Visualize PCA scores;
proc  sgscatter data=project.pcaout;
 plot prin2 * prin1;
run;
data outliers1 outliers2;
set project.pcaout;
obsnumber=_n_;
if prin1>5 then output outliers1;
if prin2>4 then output outliers2;
run;
proc print data=outliers1;run;
proc print data=outliers2;run;

proc corr data=project.pcaout;
var Annual_income Age  Employed_Year;
with prin1 prin2 prin3;
run;
/* =============================================================================================== */

/* Hypothesis Testing */
* Centering & Standardizing Values;
proc standard data=project.CreditCard3 out=project.CreditCard3stand mean=0 std=1;
var Annual_income Age Employed_Year;
run;
proc print data=project.CreditCard3stand;run;

* Mean and 95% Confidence Interva;
proc means data=project.CreditCard3 lclm mean uclm maxdec=2 alpha=0.05;
var Annual_income Age Employed_Year;
run;
proc ttest data=project.CreditCard3 alpha=0.05 H0=0;
 var Annual_income Age Employed_Year;
run;

* Values by Label_Means;
proc means data=project.CreditCard3 lclm mean uclm maxdec=2 alpha=0.05;
class label;
var Annual_income Age Employed_Year;
run;

* Values by Label_T-Test;
proc ttest data=project.CreditCard3 alpha=0.05;
 class label;
 var Annual_income Age Employed_Year;
run;

* Mean comparison for more than 2 groups: Proc Anova: ;
proc anova data=project.CreditCard3 ;
 class label;
 model Annual_income=label;
 means label;
run;

* proc glm_Same as above;
proc glm data=project.CreditCard3;
 class label;
 model Annual_income=label;
 means label;
run;

* proc mixed;
proc mixed data=project.CreditCard3;
 class label;
 model Annual_income=label;
 lsmeans label;
run;

proc anova data=project.CreditCard3 ;
 class Type_Occupation;
 model Annual_income=Type_Occupation;
 means Type_Occupation;
run;

proc anova data=project.CreditCard3 ;
 class GENDER;
 model Annual_income=GENDER;
 means GENDER;
run;

proc anova data=project.CreditCard3 ;
 class CHILDREN;
 model Annual_income=CHILDREN;
 means CHILDREN;
run;

proc anova data=project.CreditCard3 ;
 class Type_Income;
 model Annual_income=Type_Income;
 means Type_Income;
run;

proc anova data=project.CreditCard3 ;
 class EDUCATION;
 model Annual_income=EDUCATION;
 means EDUCATION;
run;

proc anova data=project.CreditCard3 ;
 class Marital_status;
 model Annual_income=Marital_status;
 means Marital_status;
run;

proc anova data=project.CreditCard3 ;
 class Housing_type;
 model Annual_income=Housing_type;
 means Housing_type;
run;


* Test for Equal Variance & Normality;
* Test for Normality;
ods select testsfornormality;
proc univariate data=project.CreditCard3 normal;
class Label;
var Annual_income;
run;
ods select off;

* Test for equal variance for Annual_income by Label;
proc glm data=project.CreditCard3;
 class Label;
 model Annual_income=Label;
 means Label / hovtest=levene;
run;

* Nonparametric Test;
proc npar1way data=project.CreditCard3 wilcoxon ;
 class Label;
 var age;
run;

* Proportion with Confidence Interval;
proc freq data=project.CreditCard3;
 table Label/ binomial;
run;

* Bivariate analysis for categorical (with proportion) with confidence interval;
proc freq data=project.CreditCard3 order=data;
 table Label* GENDER/ chisq relrisk ;
run;

proc logistic data=project.CreditCard3;
class GENDER;
model Label(event="1") = GENDER;
ods output PredictedProbabilities=pred;
run;

proc logistic data=project.CreditCard3;
class GENDER;
model Label(event="1") = GENDER;
estimate 'Gender Effect' GENDER 1 / ilink;
run;

proc logistic data=project.CreditCard3;
class Type_Income (ref="State servant");
model Label(event="1") = Type_Income;
run;

proc logistic data=project.CreditCard3;
class Housing_type (ref="With parents");
model Label(event="1") = Housing_type;
run;

proc logistic data=project.CreditCard3;
class Marital_status (ref="Civil marriage");
model Label(event="1") = Marital_status;
run;

proc logistic data=project.CreditCard3 plots(only)=(effect oddsratio);
class Type_Income (ref="State servant") Housing_type (ref="With parents") 
	Marital_status (ref="Civil marriage") ;
model  label (event="1")= Employed_Day Type_Income Housing_type Marital_status;
run;

/* =============================================================================================== */

/* Model Building */
proc pls data=project.CreditCard3 plots=all;
class  GENDER Car_Owner Propert_Owner CHILDREN Type_Income EDUCATION Marital_status 
Housing_type Work_Phone Phone EMAIL_ID Type_Occupation Family_Members;
model label= GENDER Car_Owner Propert_Owner CHILDREN Annual_income Type_Income EDUCATION Marital_status 
Housing_type Work_Phone Phone EMAIL_ID Type_Occupation Family_Members Age Employed_Day/ solution  ;
run;

proc logistic data=project.CreditCard3 plots(only)=(effect oddsratio);
class GENDER (ref="M") CHILDREN (ref="0") Type_Income (ref="Pensioner") EDUCATION (ref="Lower secondary") 
	Marital_status (ref="Single / not married") Housing_type (ref="Municipal apartment") 
	Type_Occupation (ref="Core staff") Family_Members (ref="1") ;
model  label (event="1")= GENDER CHILDREN Type_Income EDUCATION Marital_status Housing_type Family_Members;
run;

proc logistic data=project.CreditCard3 plots(only)=(effect oddsratio);
class GENDER (ref="M") Type_Income (ref="Pensioner") Marital_status (ref="Single / not married") 
	Housing_type (ref="Municipal apartment") Type_Occupation (ref="Core staff") Family_Members (ref="1") ;
model  label (event="1")= GENDER Type_Income Marital_status Housing_type Family_Members;
run;
*Significant predictors include: GENDER, Type_Income, Marital_status, Housing_type and Family_Members. 
The P values of these variables are less than 0.05, indicating that they have a statistically significant impact on label.
Other variables such as CHILDREN and EDUCATION did not show significant effects.;

*  Proc GLM;
proc glm data=project.CreditCard3;
class  GENDER Type_Income Marital_status Housing_type Family_Members;
model label= GENDER Annual_income Type_Income Marital_status Housing_type Family_Members Age Employed_Day/ solution  ss3 clparm;
lsmeans GENDER Type_Income Marital_status Housing_type Family_Members/ pdiff stderr cl;
output out = outstat1
 p = Predicted 
 r = Residual 
 stdr = se_resid 
 student = RStudent 
 h = Leverage 
 cookd = CooksD 
 lcl=lcl_label; 
 ods output ParameterEstimates=ParamEst;  
run;
quit;

* visualization of coeffcient;
title "Parameter Estimates with 95% Confidence Limits";
proc sgplot data=ParamEst;
where Parameter ne "Intercept";
 scatter y=Parameter x=Estimate / xerrorlower=LowerCl xerrorupper=UpperCl  markerattrs=(symbol=diamondfilled) ;
 refline 0 / axis=x;
 xaxis grid;
 yaxis grid;
run;
title;

proc corr data=project.CreditCard3;
var Annual_income Age Employed_Day;
run;

* label vs Housing_type;
* relationship label vs Housing_type for bivariate interpretation purpose;
proc glm data=project.CreditCard3;
class Housing_type;
model label=Housing_type/ solution  clparm ;
lsmeans Housing_type;
ods output ParameterEstimates=ParamEstType;
run;

proc sgplot data=ParamEstType;
where Parameter ne "Intercept";
 scatter y=Parameter x=Estimate / xerrorlower=LowerCl xerrorupper=UpperCl  markerattrs=(symbol=diamondfilled) ;
 refline 0 / axis=x;
 xaxis grid;
 yaxis grid;
run;

/* Split Data_Train Data and Test Data*/
*  use of surveyselect for sampling;
proc surveyselect data=project.CreditCard3 rate=0.70 outall out=result seed=1234; 
run;
data traindata testdata;
set result;
if selected=1 then output traindata;
else output testdata;
run;
proc print data=traindata;run;

/* Data Selection */
* use of glmselect ;
proc glmselect data=traindata testdata=testdata plots(stepaxis=number)=ASEPlot; 
class GENDER Type_Income Marital_status Housing_type Family_Members;
model label= GENDER Annual_income Type_Income Marital_status Housing_type Family_Members Age Employed_Day;
score data=testdata out=testpred;
output out=outputedata p=prob_predicted r=residual;
run; 

* use of glmselect with Backward Selection;
proc glmselect data=traindata testdata=testdata plots(stepaxis=number)=ASEPlot; 
class GENDER Type_Income Marital_status Housing_type Family_Members;
model label= GENDER Annual_income Type_Income Marital_status Housing_type Family_Members Age Employed_Day /
	selection=backward(select=sl slstay=0.01);  
score data=testdata out=testpred;
output out=outputedata p=prob_predicted r=residual;
run; 
quit;

* use of glmselect with LASSO selectiont;
proc glmselect data=traindata testdata=testdata plots=all; 
class GENDER Type_Income Marital_status Housing_type Family_Members;
model label= GENDER Annual_income Type_Income Marital_status Housing_type Family_Members Age Employed_Day / 
	selection=lasso( stop=none);  
score data=testdata out=testpred;
output out=outputedata p=prob_predicted r=residual ;
run; 

/* Categorical variable prediction */
* visualize prediction by categorical var;
proc summary data=testpred;
  class Housing_type;
  var label p_label;
output out= preddata  mean=;
*output out= preddata (drop= _freq_ _type_ _type_) sum=;
quit;
proc sgplot data=preddata ;
 vbar Housing_type / response=_freq_;
 vline Housing_type  / response=label  y2axis stat=mean;
 vline Housing_type /  response=p_label y2axis stat=mean;
run;

* comparison predictions and output by variables;
proc means data=testpred;
class Housing_type;
var label p_label;
run;

* Data Partitioning with Lasso Regression;
proc glmselect data=project.CreditCard3 plots=all;
 partition fraction (test=0.25 validate=0.25);
 class Housing_type;
model label= Annual_income Age Employed_Day Housing_type / selection=lasso(choose=cv stop=none) cvmethod=random(3); 
output out=outDataForward; 
run; 

/* Split Data_Train Data, Test Data and Valid Data*/
data traindata2 testdata2 validate2;
set outDataForward;
if _ROLE_="VALIDATE" then output validate2;
else if _ROLE_="TEST" then output testdata2;
else output traindata2;
run;

/* Partial Least Squares Regression */
proc pls data=traindata2 plots=all;
class  GENDER Type_Income Marital_status Housing_type Family_Members;
model label= GENDER Annual_income Type_Income Marital_status Housing_type Family_Members Age Employed_Day/ solution  ;
run;
quit;

* use of continous variables;
* compute percentiles and compare predictions;
proc means data=testpred n min p10 p20 p30 p40 p50 p60 p70 p80 p90 max maxdec=2;
var Annual_income;
run;
proc rank data=testpred out=testpred_percent groups=10;
 var Annual_income;
 ranks rank;
run;

proc summary data=testpred_percent;
  class rank;
  var label p_label;
output out= preddata  mean=;
quit;

proc sgplot data=preddata ;
 vbar rank / response=_freq_;
 vline rank  / response=label  y2axis stat=mean;
 vline rank /  response=p_label y2axis stat=mean;
run;

* comparison predictions and output by variables;
proc means data=preddata n  mean ;
class rank;
var label p_label;
run;
/* =============================================================================================== */

/* logistic regression */
proc logistic data=project.CreditCard3 plots(only)=(effect oddsratio); 
class   GENDER (ref="M") Type_Income (ref="Pensioner") Marital_status (ref="Single / not married") 
	Housing_type (ref="Municipal apartment") Type_Occupation (ref="Core staff") Family_Members (ref="1") /param=ref ;
model label(event="1")= Housing_type GENDER Type_Income Marital_status Family_Members 
	Annual_income Age Employed_Day / details lackfit; 
output out=pred p=phat lower=lcl upper=ucl predprob=(individual crossvalidate);
ods output Association=Association; 
run; 
quit;

* ROC Curve and Sensitivity Analysis;
proc logistic data=traindata plots=ROC; 
class Housing_type(ref="Municipal apartment") GENDER Type_Income Marital_status Family_Members /param=ref ;
model label(event="1")= Housing_type GENDER Type_Income Marital_status Family_Members 
	Annual_income Age Employed_Day / details lackfit outroc=troc;
score data=testdata out=testpred outroc=vroc;
roc; roccontrast;
output out=outputedata p=prob_predicted xbeta=linpred;
run; 
quit;

* Confusion matrix;
proc sort data=testpred;
by descending F_label descending I_label;
run;

proc freq data=testpred order=data;
tables  F_label*I_label / senspec out=CellCounts;
run;

data CellCounts;
set CellCounts;
Match=0;
if F_label=I_label  then Match=1;
run;
proc means data=CellCounts mean;
freq count;
var Match;
run;
quit;





