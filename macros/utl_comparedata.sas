%macro utl_comparedata(baselib=, complib=, dsname=);
  
proc compare base=&baselib..&dsname compare=&complib..&dsname(drop=ITEMGROUPDATASEQ) listall
  criterion=1e-8 method=absolute;
run;

%let compinfo=&sysinfo;
data _null_;
  length result 8 resultc restmp $200;
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
run;

%put ### &dsname - &compinfo - &resultc;


%mend utl_comparedata;