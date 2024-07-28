/* TSA Project*/
/*******************************************************************/
/* Import Data*/
%let path=~/ECRB94/data;
libname tsa "&path";

option validvarname=v7;

proc import datafile="&path/TSAClaims2002_2017.csv" out=tsa_claims dbms=csv replace;
	guessingrows=max;
run;


/*******************************************************************/
/* Explore Data*/

proc print data=tsa_claims(obs=20);
run;

proc contents data=tsa_claims varnum;
run;

proc freq data=tsa_claims;
	tables Claim_Site
			Disposition
			Claim_Type
			Date_Received
			Incident_Date / nocum nopercent;
	format Incident_Date Date_Received Year4.;
run;

proc print data=tsa_claims;
	where Date_Received < Incident_Date;
	format Date_Received Incident_Date date9.;
run;


/*******************************************************************/
/*Data Cleaning*/

/***1. Remove duplicate rows*/

proc sort data=tsa_claims out=tsa_nodupkey noduprecs;
	by _all_;
run;

/***2. Sort by incidents date*/

proc sort data=tsa_nodupkey;
	by Incident_Date;
run;

data claims_cleaned;
	set tsa_nodupkey;
	
/***3. Clean the Claim_Site column*/
	if Claim_Site="-" or missing(Claim_Site) then
		Claim_Site="Unknown";
		
/***4. Clean the Disposition column*/
	if Disposition="-" or missing(Disposition) then Disposition="Unknown";
		else if Disposition = "Closed: Canceled" then Disposition = "Closed:Canceled";
		else if	Disposition="losed: Contractor Claim" then Disposition = "Closed:Contractor Claim";
	
/***5. Clean the Claim_Type column*/

	Claim_Type=substr(Claim_Type, 1, index(Claim_Type, "/") - 1);
	if Claim_Type="-" or missing(Claim_Type) then Claim_Type="Unknown";

/***6. Convert all State values to uppercase and all StateName values to proper case*/
	
	StateName=propcase(StateName);
	State=upcase(State);

/***7. Create a new column to incidate date issues*/

	if (missing(Incident_Date) or 
		missing(Date_Received) or 
		year(Incident_Date) < 2002 or 
		year(Incident_Date) > 2017 or 
		year(Date_Received) < 2002 or 
		year(Date_Received) > 2017 or 
		Incident_Date > Date_Received) then Date_Issues="Needs Review";

/***8. Add permenant labesl and formats*/

	format Close_Amount dollar20.2;
    format Date_Received Incident_Date date9.;
    label Claim_Number = "Claim Number";
    label Date_Received = "Date Received";
    label Incident_Date = "Incident Date";
    label Airport_Code = "Airport Code";
    label Airport_Name = "Airport_Name";
    label Claim_Type = "Claim Type";
    label Claim_Site = "Claim Site";
    label Item_Category = "Item Category";
    label Close_Amount = "Close Amount";
    
/***9. Drop Country and City*/
    
    drop County City;
	
run;

proc freq data=claims_cleaned order=freq;
	tables Claim_Site
			Disposition
			Claim_Type
			Date_Issues / nopercent nocum;
run;

/*******************************************************************/
/* Analyze Data*/

%let outpath=~/ECRB94/output;
ods pdf file="&outpath/ClaimsReport.pdf" style=meadow pdftoc=1; 
ods noproctitle;

/***1. How many date issues are in the overall data?*/
ods proclabel "Overall Date Issues";
title "Overall Date Issues in the Data";
proc freq data=claims_cleaned;
    tables Date_Issues/ missing nocum nofreq;
run;
title;

/***2. How many claims per year of Incident_Date are in the overall date? Be sure to include a plot*/
ods graphics on;
ods proclabel "Overall Claims by year";
title "Number of Claims by Year";
proc freq data=claims_cleaned;
	tables Incident_Date / nocum nopercent plots=freqplot;
	format Incident_Date year4.;
	where Date_Issues is null;
run;
title;

/***3. Specific state analysis*/

/******3.0 User input*/

%let selected_state=Hawaii;

/******3.1 What are the frequency values for Claim_Type for the selected state?*/
/******3.2 What are the frequency values for Claim_Site for the selected state?*/
/******3.3 What are the frequency values for Disposition for the selected state?*/
ods proclabel "&selected_state Claims Overview";
title "&selected_state Claim Types, Claim Sites and Disposition";
proc freq data=claims_cleaned order=freq;
	where StateName = "&selected_state" and Date_Issues is null;
	tables Claim_Type Claim_Site Disposition;
run;
title;

/******3.4 What is the mean, min, max, and sum of Close_Amount for the selected state? Round to the nearest integer*/
ods proclabel "&selected_state Claims Stats";
title "Close Amount in &selected_state";
proc means data=claims_cleaned mean min max sum maxdec=0;
	where StateName = "&selected_state" and Date_Issues is null;
	var Close_Amount;
run;
title;

ods pdf close;


