/**  
  @file create_template.sas
  @brief Create a SAS dataset template.

  @author Lex Jansen

  @param[in] type= The template type:
    @li STUDY
    @li TABLES
    @li COLUMNS
    @li COMPARE_RESULTS
    @li VALIDATION_RESULTS
  @param[out] out= Output dataset

**/

%macro create_template(type=, out=) / des = 'Create a SAS dataset template';

  %if %upcase(&type) eq STUDY %then %do;
    proc sql;
      create table &out
        (
         fileOID char(128),
         creationDateTime char(32),
         modifiedDateTime char(32),
         defineXMLVersion char(32),
         datasetJSONVersion char(32),
         originator char(256),
         sourceSystem char(256),
         sourceSystemVersion char(256),
         studyOID char(128),
         metaDataVersionOID char(128),
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
         records num,
         domain char(32),
         repeating char(3),
         isReferenceData char(3),
         structure char(256),
         domainKeys char(256)
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
       dataType char(32),
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
       datetime char(32) label="Time stamp",
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
       datetime char(32) label="Time stamp",
       json_file char(1024) label="Dataset-JSON File",
       json_schema char(1024) label="Dataset-JSON Schema",
       result_code num label="Validation Result (Numeric)",
       result_character char(255) label="Validation Result (Character)",
       result_path char(255) label="JSON Path"
      );
    quit;
  %end;

%mend;
  