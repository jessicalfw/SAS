/* TSA Project - Analyze Data stage (jenner-check bundle) */
/* Adapted from TSA.sas: original read "&path/TSAClaims2002_2017.csv" via a  */
/* PROC IMPORT off a libname pointed at ~/ECRB94/data, and wrote an ODS PDF  */
/* report to &outpath. The jenner-check runner uploads script text only (no */
/* data files), so the import is replaced with an inline pipe-delimited     */
/* DATALINES block shaped like the same 16-column TSA claims layout, and    */
/* the ODS PDF wrapper is dropped in favor of plain listing output;         */
/* everything else -- the %let selected_state macro variable and the       */
/* date-issues / state-breakdown / PROC MEANS logic -- runs unmodified.     */

option validvarname=v7;

data tsa_claims;
	length Claim_Number 8 Date_Received Incident_Date 8 Airport_Code $3
	       Airport_Name $40 Claim_Type $32 Claim_Site $15 Item_Category $27
	       Claim_Amount 8 Status $8 Close_Amount 8 Disposition $23
	       County $11 City $11 State $2 StateName $13;
	infile datalines dlm='|' dsd;
	informat Date_Received Incident_Date mmddyy10.;
	input Claim_Number Date_Received Incident_Date Airport_Code
	      Airport_Name Claim_Type Claim_Site Item_Category
	      Claim_Amount Status Close_Amount Disposition County City State StateName;
	datalines;
2003100440953|10/22/2003|10/17/2003|HNL|Honolulu International|Property Damage/Personal Injury|Checked Baggage|Cosmetics/Grooming Products|50|Approved|50|Approve in Full|Honolulu|Honolulu|HI|Hawaii
2003081603783|08/16/2003|08/06/2003|HNL|Honolulu International|Property Damage|Checked Baggage|-|150|Settled|100|Settle|Honolulu|Honolulu|HI|Hawaii
2005042212345|04/22/2005|04/20/2005|LAX|Los Angeles International|-|Checked Baggage|Jewelry & Watches|300|Denied|0|Deny|Los Angeles|Los Angeles|CA|California
2010010500001|01/05/2010|01/03/2010|ORD|Chicago O'Hare International|Passenger Property Loss|Checkpoint|Electronics|220|Approved|220|Approve in Full|Cook|Chicago|IL|Illinois
1999120100002|12/01/1999|11/28/1999|JFK|John F Kennedy International|Property Damage|Checked Baggage|Luggage|90|Settled|60|Settle|Queens|New York|NY|New York
2016020200003|02/02/2016|01/30/2016|SEA|Seattle-Tacoma International|Property Damage|Checked Baggage|-|75|Approved|75|Approve in Full|King|Seattle|WA|Washington
2007030300004|03/03/2007|03/05/2007|HNL|Honolulu International|Property Damage|Checked Baggage|Electronics|180|Denied|0|Deny|Honolulu|Honolulu|HI|Hawaii
2008090500006|09/05/2008|09/01/2008|HNL|Honolulu International|Property Damage|Motor Vehicle|Cosmetics/Grooming Products|40|Settled|25|losed: Contractor Claim|Honolulu|Honolulu|HI|Hawaii
2011110600007|11/06/2011|11/02/2011|BOS|Boston Logan International|Property Damage|Checked Baggage|Jewelry & Watches|500|Approved|500|Approve in Full|Suffolk|Boston|MA|Massachusetts
2014010700008|01/07/2014|01/06/2014|HNL|Honolulu International|Property Damage|Checked Baggage|Electronics|60|Settled|40|Closed: Canceled|Honolulu|Honolulu|HI|Hawaii
2003060800009|06/08/2003|06/10/2003|DEN|Denver International|Property Damage|Checked Baggage|-|110|Denied|0|Deny|Denver|Denver|CO|Colorado
2017123100010|12/31/2017|12/29/2017|HNL|Honolulu International|Property Damage|Checked Baggage|Luggage|95|Approved|95|Approve in Full|Honolulu|Honolulu|HI|Hawaii
2009081000012|08/10/2009|08/09/2009|HNL|Honolulu International|Property Damage|Checked Baggage|Cosmetics/Grooming Products|35|Settled|20|Settle|Honolulu|Honolulu|HI|Hawaii
;
run;

proc sort data=tsa_claims out=tsa_nodupkey noduprecs;
	by _all_;
run;

proc sort data=tsa_nodupkey;
	by Incident_Date;
run;

data claims_cleaned;
	set tsa_nodupkey;
	if Claim_Site="-" or missing(Claim_Site) then
		Claim_Site="Unknown";
	if Disposition="-" or missing(Disposition) then Disposition="Unknown";
		else if Disposition = "Closed: Canceled" then Disposition = "Closed:Canceled";
		else if	Disposition="losed: Contractor Claim" then Disposition = "Closed:Contractor Claim";
	Claim_Type=substr(Claim_Type, 1, index(Claim_Type, "/") - 1);
	if Claim_Type="-" or missing(Claim_Type) then Claim_Type="Unknown";
	StateName=propcase(StateName);
	State=upcase(State);
	if (missing(Incident_Date) or
		missing(Date_Received) or
		year(Incident_Date) < 2002 or
		year(Incident_Date) > 2017 or
		year(Date_Received) < 2002 or
		year(Date_Received) > 2017 or
		Incident_Date > Date_Received) then Date_Issues="Needs Review";
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
    drop County City;
run;

/*******************************************************************/
/* Analyze Data*/

/***1. How many date issues are in the overall data?*/
title "Overall Date Issues in the Data";
proc freq data=claims_cleaned;
    tables Date_Issues/ missing nocum nofreq;
run;
title;

/***2. How many claims per year of Incident_Date are in the overall date? Be sure to include a plot*/
title "Number of Claims by Year";
proc freq data=claims_cleaned;
	tables Incident_Date / nocum nopercent;
	format Incident_Date year4.;
	where Date_Issues is null;
run;
title;

/***3. Specific state analysis*/

/******3.0 User input*/

%let selected_state=Hawaii;

/******3.1-3.3 Claim_Type / Claim_Site / Disposition breakdown for the selected state*/
title "&selected_state Claim Types, Claim Sites and Disposition";
proc freq data=claims_cleaned order=freq;
	where StateName = "&selected_state" and Date_Issues is null;
	tables Claim_Type Claim_Site Disposition;
run;
title;

/******3.4 Mean, min, max, and sum of Close_Amount for the selected state*/
title "Close Amount in &selected_state";
proc means data=claims_cleaned mean min max sum maxdec=0;
	where StateName = "&selected_state" and Date_Issues is null;
	var Close_Amount;
run;
title;
