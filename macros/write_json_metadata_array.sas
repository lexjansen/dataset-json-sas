%macro write_json_metadata_array(dset);

 %* This macro avoids creating an attribute when the value is missing; 

 %local xldset_id nobs nvars varlist vartype i xl_cnt code _varnum _value;
 %let xldset_id =%sysfunc(open(&dset.)); 
 %let nobs=%sysfunc(attrn(&xldset_id.,NOBS)); 
 %let nvars=%sysfunc(attrn(&xldset_id, NVARS));
 %syscall set(xldset_id); 
 
 %let varlist=;
 %let vartype=;
 %do i=1 %to &nvars;
   %let varlist=&varlist %sysfunc(varname(&xldset_id, &i));
   %let vartype=&vartype %sysfunc(vartype(&xldset_id, &i));
 %end;
 %*put &=varlist;

  WRITE OPEN ARRAY; 

 %do xl_cnt=1 %to &nobs; 
   %let rc=%sysfunc(fetchobs(&xldset_id,&xl_cnt)); 
   %let code=;
   %do i=1 %to &nvars;
     %let _varnum=%sysfunc(varnum(&xldset_id, %scan(&varlist, &i)));
     %let _varname=%scan(&varlist, &i);
     %if %scan(&vartype, &i) EQ C 
       %then %do; 
         %let _value=%nrbquote(%sysfunc(getvarc(&xldset_id, &_varnum)));
         %if %sysevalf(%superq(_value)=, boolean)=0 %then %let code=&code "&_varname" %sysfunc(quote(%nrbquote(%sysfunc(strip(%nrbquote(&_value)))))); 
       %end;
       %else %do; 
         %let _value=%sysfunc(getvarn(&xldset_id, &_varnum));
         %if &_value ne %str(.) %then %let code=&code "&_varname" &_value;
       %end;
   %end; 
   
   WRITE OPEN OBJECT;
   WRITE VALUES &code;
   WRITE CLOSE;
    
 %end; 

 %let xldset_id=%sysfunc(close(&xldset_id));
 
%mend write_json_metadata_array;
