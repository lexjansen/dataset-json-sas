%macro write_json_metadata_array(dset);

 %* This macro avoids creating an attribute when the value is missing;

 %local dset_id nobs nvars varlist vartype i _cnt code _varnum _value dataset_name;
 %let dset_id =%sysfunc(open(&dset.));
 %let nobs=%sysfunc(attrn(&dset_id.,NOBS));
 %let nvars=%sysfunc(attrn(&dset_id, NVARS));
 %syscall set(dset_id);

 %let varlist=;
 %let vartype=;
 %do i=1 %to &nvars;
   %let varlist=&varlist %sysfunc(varname(&dset_id, &i));
   %let vartype=&vartype %sysfunc(vartype(&dset_id, &i));
 %end;
 %*put &=varlist;

 WRITE OPEN ARRAY;

 %do _cnt=1 %to &nobs;
   %let rc=%sysfunc(fetchobs(&dset_id,&_cnt));
   %let code=;

   %do i=1 %to &nvars;
    
     %let _varnum=%sysfunc(varnum(&dset_id, %scan(&varlist, &i)));
     %let _varname=%scan(&varlist, &i);
     
     %if %scan(&vartype, &i) EQ C
       %then %do;
         %let _value=%nrbquote(%sysfunc(getvarc(&dset_id, &_varnum)));
         %if %sysevalf(%superq(_value)=, boolean)=0 %then %let code=&code "&_varname" %sysfunc(quote(%nrbquote(%sysfunc(strip(%nrbquote(&_value))))));
       %end;
       %else %do;
         %let _value=%sysfunc(getvarn(&dset_id, &_varnum));
         %if &_value ne %str(.) %then %let code=&code "&_varname" &_value;
       %end;
   
   %end;

   WRITE OPEN OBJECT;
   WRITE VALUES &code;
   WRITE CLOSE;
   
 %end;
 
 WRITE CLOSE;

 %let dset_id=%sysfunc(close(&dset_id));

%mend write_json_metadata_array;
