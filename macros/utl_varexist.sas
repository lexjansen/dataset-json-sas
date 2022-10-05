%macro utl_varexist(dsname,varname);

	%local dsid rc return;

	%* Set default result as failure;
	%let return=0;

	%* Open dataset;
	%let dsid = %sysfunc(open(&dsname));
	%if &dsid %then
		%do;
			%* Test if variable found;
			%let return=%eval(0<%sysfunc(varnum(&dsid,&varname)));
			%* Close dataset;
			%let rc=%sysfunc(close(&dsid));
		%end;

	%*;&return%*;
%mend utl_varexist;