%macro utl_gettree(dir=, outds=work.dirtree, where=);

  /*
  credit:
   Tom:
   https://communities.sas.com/t5/SAS-Programming/listing-all-files-of-all-types-from-all-subdirectories/m-p/334113/highlight/true#M75419
  */
  
  data &outds ;
    length dir 8 ext filename dirname $256 fullpath $512;
    call missing(of _all_);
    fullpath = "&dir";
  run;
  
  data &outds;
    modify &outds ;
    sep='/';
    if "&sysscp"="WIN" or "&sysscp"="DNTHOST" then sep='\';
    rc=filename('tmp',fullpath);
    dir_id=dopen('tmp');
    dir = (dir_id ne 0);
    if dir then dirname=cats(fullpath,sep);
    else do;
      filename=scan(fullpath,-1,sep);
      dirname =substrn(fullpath,1,length(fullpath)-length(filename));
      if index(filename,'.')>1 then ext=scan(filename,-1,'.');
    end;
    replace;
    if dir then do;
      do i=1 to dnum(dir_id);
        fullpath=cats(dirname,dread(dir_id,i));
        output;
      end;
      rc=dclose(dir_id);
    end;
    rc=filename('tmp');
  run;
  
  data &outds;
    set &outds %if %sysevalf(%superq(where)=, boolean)=0 %then (where=(&where));;
  run;  

  
%mend utl_gettree ;
