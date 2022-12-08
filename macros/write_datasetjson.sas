%macro write_datasetjson(dataset=, jsonfile=, usemetadata=, metadatalib=, _studyOID=, _MetaDataVersionOID=);
  %local dataset_name dataset_label records 
    studyOID metaDataVersionOID
    ClinicalReferenceData ItemGroupOID;

  %let dataset_name=%scan(&dataset, -1, %str(.));
  %let dataset_label=;
  %let ItemGroupOID=;
  %let studyOID=;
  %let metaDataVersionOID=;

  %if %utl_varexist(&dataset, usubjid) %then
      %let ClinicalReferenceData=clinicalData;
    %else %let ClinicalReferenceData=referenceData;

  %let records=%utl_nobs(&dataset);

  %if &UseMetadata=1 %then %do;

    /* Get StudyOID and metaDataVersionOID */
    proc sql noprint;
      select studyOID, metaDataVersionOID into :studyOID trimmed, :metaDataVersionOID trimmed
        from &metadatalib..metadata_study;
    /* Get dataset label and ItemGroupOID */
      select label, oid into :dataset_label, :ItemGroupOID trimmed
        from &metadatalib..metadata_tables
          where upcase(name)="%upcase(&dataset_name)";
    quit;
  %end;

  
  %if %sysevalf(%superq(studyOID)=, boolean) %then %let studyOID=&_StudyOId;
  %if %sysevalf(%superq(studyOID)=, boolean) %then %let studyOID=STUDY1;
  %if %sysevalf(%superq(metaDataVersionOID)=, boolean) %then %let metaDataVersionOID=&_MetaDataVersionOID;
  %if %sysevalf(%superq(metaDataVersionOID)=, boolean) %then %let metaDataVersionOID=METADATAVERSION1;
  %if %sysevalf(%superq(ItemGroupOID)=, boolean) %then %let ItemGroupOID=IG.%upcase(&dataset_name);
  %if %sysevalf(%superq(dataset_label)=, boolean) %then 
    %let dataset_label=%cstutilgetattribute(_cstDataSetName=&dataset,_cstAttribute=LABEL);
  %if %sysevalf(%superq(dataset_label)=, boolean) %then 
    %let dataset_label=&dataset_name;
  
  %put ### &=dataset &=records &=ClinicalReferenceData &=ItemGroupOID dslabel=%bquote(&dataset_label);

  %if &UseMetadata=1 %then %do;

    data work.column_metadata(keep=OID name label type length);
      retain OID name label type length;
      set &metadatalib..metadata_columns(
        rename=(json_datatype=type)
        where=(upcase(dataset_name) = %upcase("&dataset_name")));
    run;
  %end;
  %else %do;
    proc contents noprint varnum data=&dataset out=work.column_metadata(keep=varnum name type length label rename=(type=sas_type));
    run;
    
    proc sort data=work.column_metadata;
      by varnum;
    run;
      
    data work.column_metadata(drop=sas_type varnum);
      retain OID name label type length;
      length OID $128 type $32;
      set work.column_metadata;
      OID = cats("IT", ".", upcase("&dataset_name"), ".", upcase(name));
      if sas_type=1 then type="float";
                    else type="string"; 
    run;
      
  %end;
  
  /* Create a 1-obs dataset with the same structure as the column_metadata dataset */
  proc sql noprint;
    create table itemgroupdataseq
      like work.column_metadata;
    insert into itemgroupdataseq
      set OID="ITEMGROUPDATASEQ", name="ITEMGROUPDATASEQ", label="Record Identifier",
        type="integer";
  quit;

  data work.column_metadata;
    set itemgroupdataseq work.column_metadata;
  run;
  
  proc delete data=work.itemgroupdataseq;
  run;

  
  %******************************************************************************;
  data work.column_data;
    length ITEMGROUPDATASEQ 8.;
    set &dataset;
    ITEMGROUPDATASEQ = _n_;
  run;

  filename jsonfout "&jsonfile";

  PROC JSON OUT=jsonfout NOPRETTY NOSASTAGS SCAN TRIMBLANKS
                         NOFMTCHARACTER NOFMTDATETIME NOFMTNUMERIC;
    WRITE OPEN OBJECT;
    WRITE VALUES "&ClinicalReferenceData";
    WRITE OPEN OBJECT;
    WRITE VALUES "studyOID" "&studyOID";
    WRITE VALUES "metaDataVersionOID" "&metaDataVersionOID";
    WRITE VALUE "itemGroupData";
    WRITE OPEN OBJECT;
    WRITE VALUE "&ItemGroupOID";
    WRITE OPEN OBJECT;
    WRITE VALUES "records" &records;
    WRITE VALUES "name" "%upcase(&dataset_name)";
    WRITE VALUES "label" %sysfunc(quote(&dataset_label));

    WRITE VALUE "items";
    %* Use macro to avoid creating null values for missing attributes;
    %* Instead do not create the attribute;
    %write_json_metadata_array(work.column_metadata);
    WRITE CLOSE;

    WRITE VALUE "itemData";
    WRITE OPEN ARRAY;
    EXPORT work.column_data / NOKEYS;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
  RUN;

  filename jsonfout clear;

  proc delete data=work.column_metadata;
  run;

  proc delete data=work.column_data;
  run;

%mend write_datasetjson;
