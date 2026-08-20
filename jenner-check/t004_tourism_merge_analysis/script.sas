/* Tourism Project - Final_Tourism merge & analysis stage (jenner-check bundle) */
/* Adapted from tourism.sas: the original built cleaned_tourism and country_info */
/* from external libname cr (~/ECRB94/data, cr.tourism / cr.country_info), a     */
/* path only the author's machine has. Substituted here with small inline       */
/* DATALINES shaped like the columns their own DATA steps produce/expect        */
/* (Country_Name, Tourism_Type, Category, Series, Y2014 / Country, Continent) so */
/* the PROC FORMAT, PROC SORT, MERGE BY, and PROC MEANS logic below — copied      */
/* verbatim from the "Create Final_Tourism table" section of their script —      */
/* runs unmodified.                                                              */

data cleaned_tourism;
	length Country_Name $56 Tourism_Type $20 Category $20 Series $40;
	input Country_Name & $56. Tourism_Type & $20. Category & $20. Series & $40. Y2014;
	datalines;
United States      Inbound tourism    Arrivals    NUMBER OF ARRIVALS         74757900
United States      Inbound tourism    Arrivals    TOURISM EXPENDITURE        215760000
United States      Outbound tourism   Departures  NUMBER OF DEPARTURES       68967000
France             Inbound tourism    Arrivals    NUMBER OF ARRIVALS         83700000
France             Inbound tourism    Arrivals    TOURISM EXPENDITURE        66116000
Japan              Inbound tourism    Arrivals    NUMBER OF ARRIVALS         13413000
Japan              Outbound tourism   Departures  NUMBER OF DEPARTURES       16903000
Brazil             Inbound tourism    Arrivals    NUMBER OF ARRIVALS         6429852
Egypt              Inbound tourism    Arrivals    NUMBER OF ARRIVALS         9908000
Nigeria            Inbound tourism    Arrivals    NUMBER OF ARRIVALS         5548000
Nomanistan         Inbound tourism    Arrivals    NUMBER OF ARRIVALS         12345
;
run;

data country_info;
	length Country $56;
	input Country & $56. Continent;
	datalines;
United States      1
France             3
Japan              5
Brazil             2
Egypt              4
Nigeria            4
;
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

proc print data=Final_Tourism;
run;

proc print data=NoCountryFound;
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
