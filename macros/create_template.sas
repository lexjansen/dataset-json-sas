%macro create_template(type=, out=);

  %if %upcase(&type) eq STUDY %then %do;
    proc sql;
      create table &out
        (
         fileoid char(128),
         creationdatetime char(32),
         asofdatetime char(32),
         datasetJSONVersion char(32),
         originator char(128),
         sourcesystem char(128),
         sourcesystemversion char(129),
         studyoid char(128),
         metadataversionoid char(128),
         metaDataRef char(256)
        );
    quit;
  %end;


  
  %if %upcase(&type) eq TABLES %then %do;
    proc sql;
      create table &out
        (
         oid char(128),
         name char(32),
         label char(256),
         domain char(32),
         repeating char(3),
         isreferencedata char(3),
         structure char(256)
        );
    quit;
  %end;

  %if %upcase(&type) eq COLUMNS %then %do;
    proc sql;
    create table &out
      (
       dataset_name  char(32),
       oid  char(128),
       name char(32),
       label char(256),
       order num,
       xml_datatype char(32),
       json_datatype char(32),
       length num,
       displayformat char(32),
       keysequence num
      );
    quit;
  %end;
  
  
%mend;
  