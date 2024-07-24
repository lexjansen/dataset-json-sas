%macro util_comparedata(
  baselib=, 
  complib=, 
  dsname=, 
  compareoptions=%str(listall criterion=0.00000001 method=absolute),
  resultds=,
  detaillevel=2
  );

  %local compinfo _Random today_iso8601;

  %let _Random=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));
  %let today_iso8601=%sysfunc(datetime(), is8601dt.);
    
  proc compare base=&baselib..&dsname compare=&complib..&dsname %NRBQUOTE(&compareoptions) noprint;
  run;

  %let compinfo=&sysinfo;
  data work.compare_results_&_Random(
    keep=baselib baselib_path complib complib_path dataset_name result_code result_character
    );
    length result_code 8 result_character restmp $512 dataset_name $32 baselib complib $8
           complib_path baselib_path $1024;
    array r(*) 8 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15 r16;
    result_code=&compinfo;
    result_character="";
    restmp='/DSLABEL/DSTYPE/INFORMAT/FORMAT/LENGTH/LABEL/BASEOBS/COMPOBS'||
          '/BASEBY/COMPBY/BASEVAR/COMPVAR/VALUE/TYPE/BYVAR/ER'||'ROR';
    do i=1 to 16;
      if result_code >= 0 then do;
        if band(result_code, 2**(i-1)) then do;
          result_character=trim(result_character)||'/'||scan(restmp,i,'/'); 
          r(i) = 1;
        end;
      end;  
    end;
    if result_code=0 then result_character="NO DIFFERENCES";
    result_character=left(result_character);
    if index(result_character,'/')=1 then result_character=substr(result_character,2);
    call symputx ('result_character', result_character);
    
    dataset_name=upcase("&dsname");
    baselib="&baselib";
    baselib_path="%sysfunc(pathname(&baselib))";
    complib="&complib";
    complib_path="%sysfunc(pathname(&complib))";
    output;
  run;

  %if &compinfo ne 0 %then %do;
    %put %str(WARN)ING: Differences for dataset &dsname - &result_character (SysInfo=&compinfo);
  %end;
  %else %do;
    %put %str(NOT)E: No differences for dataset &dsname - &result_character (SysInfo=&compinfo);
  %end;

  %if &compinfo ge &detaillevel %then %do;
    proc compare base=&baselib..&dsname compare=&complib..&dsname listall %NRBQUOTE(&compareoptions);
      title "Compare results for dataset %upcase(&dsname) - &today_iso8601";
    run;
  %end;

  %if %sysevalf(%superq(resultds)=, boolean)=0 %then %do;
    data &resultds;
      set &resultds work.compare_results_&_Random;
    run;  
  %end;  

  proc delete data=work.compare_results_&_Random;
  run;
  
%mend util_comparedata;