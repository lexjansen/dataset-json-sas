%macro utl_nobs(dsname);

%local dsid rc return;

%if %sysfunc(exist(&dsname,data)) and &dsname ne
  %then %do;    

	%* Open dataset;
    %let dsid = %sysfunc(open(&dsname));
    %if &dsid %then %do;
      %let return  = %sysfunc(attrn(&dsid,nobs));
			%* Close dataset;      
			%let rc = %sysfunc(close(&dsid));
    %end;
  %end;
  %else %let return=-1;

  %*;&return%*;
%mend utl_nobs;
