/* Tourism Project*/
/*******************************************************************/
/* Import Data*/
%let path=~/ECRB94/data;
libname cr "&path";

/*******************************************************************/
/* Data Cleaning - Part I*/
data tourism;
	set cr.tourism;

/* Remove column 1995-2013*/
	drop _1995 - _2013;

/*Create the Country_Name column from values in the Country column. */
	length Country_Name $56;
	if not missing(A) then Country_Name = Country;
	
	/* Retain the last non-missing value of Country_Name within each BY group */
    retain Country_Name_filled;

    /* Initialize Country_Name_filled with first non-missing value within BY group */
    if first.Group_ID then Country_Name_filled = Country_Name;

    /* Fill down non-missing values of Country_Name */
    if not missing(Country_Name) then Country_Name_filled = Country_Name;

    /* Output the filled dataset */
    drop Country_Name; /* Drop original Country_Name if needed */
    rename Country_Name_filled = Country_Name; /* Rename filled variable back to original */
   
   
/*Create the Tourism_Type columns from values in the Country column. */
	length Tourism_Type $20;
	if Country = "Inbound tourism" them Tourism_Type = "Inbound tourism";
	if Country = "Outbound tourism" them Tourism_Type = "Outbound tourism";
	
		/* Retain the last non-missing value of Country_Name within each BY group */
    retain Tourism_Type_filled;

    /* Initialize Country_Name_filled with first non-missing value within BY group */
    if first.Group_ID then Tourism_Type_filled = Tourism_Type;

    /* Fill down non-missing values of Country_Name */
    if not missing(Tourism_Type) then Tourism_Type_filled = Tourism_Type;

    /* Output the filled dataset */
    drop Tourism_Type; /* Drop original Country_Name if needed */
    rename Tourism_Type_filled = Tourism_Type; /* Rename filled variable back to original */

/* Eliminate rows with same values in the Country/Country_Name columns and in the Country/Tourism_Type */
	if Country ne Country_Name and Country ne Tourism_Type;
run;

/*******************************************************************/
/* Data Cleaning - Part II*/
data tourism;
	set tourism;
	
/*Convert the values in Series to uppercase*/
	Series = upcase(Series);
	
/*Change ".." to a missing character value*/
	if Series = ".." then Series = .;
	
/*Create a column to indicate the thousands count*/	
	if scan(Country, -1)="Thousands" then Conversion = 1000;
	else if scan(Country, -1)="Mn" then Conversion = 1000000;
	
/* Change values of ".." to a single period in the _2014 column. */
	if _2014 = ".." then _2014 = .;
	
run;
	
	
/*******************************************************************/
/* Create cleaned_tourism table*/
data cleaned_tourism;
	set tourism;
	
/* Create Y2014 converting character values in _2014 ny multiplying the conversion type*/
	Y2014 = _2014*Conversion;
	format Y2014 comma20.0;
	
/* Create the new Category column from values in the Country column*/
	Category = substr(CATX(' ', of Country), 1, length(CATX(' ', of Country)) - length(scan(Country, -1)));
 	if Category = "Arrivals -" then Category = "Arrivals";
 	if Category = "Departures -" then Category = "Departures";
 	
/* Include only the following columns */
	keep Country_Name Tourism_Type Category Series Y2014; 

run;

/*******************************************************************/
/* Create Final_Tourism table*/

/* Create a format for the Continent column that labels continent IDs with the corresponding continent names  */
proc format;
    value continent_fmt
        1 = 'North America'
        2 = 'South America'
        3 = 'Europe'
        4 = 'Africa'
        5 = 'Asia'
        6 = 'Oceania'
        7 = 'Antarctica'
        other = 'Unknown'; /* Handle any other values not specified */
run;

data country_info;
	set cr.country_info;
run;

proc sort data=country_info;
	by Country;
run;

proc sort data=cleaned_tourism;
    by Country_Name;
run;

/* Combine cleaned_tourism and country_info  */
data Final_Tourism;
    merge cleaned_tourism(in=in_tour rename=(Country_Name=Country))
          country_info(in=in_info);
    by Country;
    if in_tour and in_info; 
    
/*Use a FORMAT statement to format Continent with your new format.*/
	format Continent continent_fmt.;
run;


/* Create the NoCountryFound table that has a list of countries from Cleaned_Tourism that are not found in the country_info table*/
data NoCountryFound;
    merge cleaned_tourism(in=in_tour rename=(Country_Name=Country))
          country_info(in=in_info);
    by Country;
    if in_tour and not in_info;
    if last.Country;
run;

proc freq data=final_tourism;
	table Category;
run;

/* Analyze the number of arrivals in 2014 for each continent. 
Generate mean, minimum, and maximum statistics, rounded to the nearest whole number. */

proc means data=final_tourism mean min max maxdec=0;
	where Category = "Arrivals";
	var Y2014;
	class Continent;
run;
