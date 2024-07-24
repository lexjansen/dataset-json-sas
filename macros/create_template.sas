%macro create_template(type=, out=);

  %if %upcase(&type) eq STUDY %then %do;
    proc sql;
      create table &out
        (
         fileoid char(128),
         creationdatetime char(32),
         asofdatetime char(32),
         modifieddatetime char(32),
         datasetJSONVersion char(32),
         originator char(128),
         sourcesystem char(128),
         sourcesystemversion char(128),
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
         records num,
         name char(32),
         label char(256),
         domain char(32),
         datasettype char(128),
         repeating char(3),
         isreferencedata char(3),
         structure char(256),
         domainkeys char(256)
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
       targetDataType char(32),
       length num,
       json_length num,
       displayFormat char(32),
       keySequence num
      );
    quit;
  %end;
  
  %if %upcase(&type) eq COMPARE_RESULTS %then %do;
    proc sql;
    create table &out
      (
       dataset_name char(32) label="SAS Dataset Name",
       baselib char(8) label="Base Library",
       baselib_path char(1024) label="Base Library Path",
       complib char(8) label="Compare Library",
       complib_path char(1024) label="Compare Library Path",
       result_code num label="Compare Result (Numeric)",
       result_character char(512) label="Compare Result (Character)"
      );
    quit;
  %end;
  
  %if %upcase(&type) eq VALIDATION_RESULTS %then %do;
    proc sql;
    create table &out
      (
       json_file char(1024) label="Dataset-JSON File",
       json_schema char(1024) label="Dataset-JSON Schema",
       result_code num label="Validation Result (Numeric)",
       result_character char(255) label="Validation Result (Character)",
       result_path char(255) label="JSON Path"
      );
    quit;
  %end;

%mend;
  