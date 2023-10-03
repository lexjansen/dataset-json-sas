%macro utl_comparedata(
  baselib=, 
  complib=, 
  dsname=, 
  compareoptions=%str(listall criterion=0.00000001 method=absolute),
  resultds=
  );

  %local compinfo _Random;

  %let _Random=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));
    
  proc compare base=&baselib..&dsname compare=&complib..&dsname %NRBQUOTE(&compareoptions);
  run;

  %let compinfo=&sysinfo;
  data work.compare_results_&_Random(
    keep=baselib baselib_path complib complib_path dataset_name result resultc
    );
    length result 8 resultc restmp $512 dataset_name $32 baselib complib $8
           complib_path baselib_path $1024;
    array r(*) 8 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15 r16;
    result=&compinfo;
    resultc="";
    restmp='/DSLABEL/DSTYPE/INFORMAT/FORMAT/LENGTH/LABEL/BASEOBS/COMPOBS'||
          '/BASEBY/COMPBY/BASEVAR/COMPVAR/VALUE/TYPE/BYVAR/ER'||'ROR';
    do i=1 to 16;
      if result >= 0 then do;
        if band(result, 2**(i-1)) then do;
          resultc=trim(resultc)||'/'||scan(restmp,i,'/'); 
          r(i) = 1;
        end;
      end;  
    end;
    if result=0 then resultc="NO DIFFERENCES";
    resultc=left(resultc);
    if index(resultc,'/')=1 then resultc=substr(resultc,2);
    call symputx ('resultc', resultc);
    
    dataset_name="&dsname";
    baselib="&baselib";
    baselib_path="%sysfunc(pathname(&baselib))";
    complib="&complib";
    complib_path="%sysfunc(pathname(&complib))";
    output;
  run;

  %if &compinfo ne 0 %then %do;
    %put %str(WARN)ING: Differences for dataset &dsname - &resultc (SysInfo=&compinfo);
  %end;
  %else %do;
    %put %str(NOT)E: No differences for dataset &dsname - &resultc (SysInfo=&compinfo);
  %end;

  %if %sysevalf(%superq(resultds)=, boolean)=0 %then %do;
    data &resultds;
      set &resultds work.compare_results_&_Random;
    run;  
  %end;  

  proc delete data=work.compare_results_&_Random;
  run;
  
%mend utl_comparedata;