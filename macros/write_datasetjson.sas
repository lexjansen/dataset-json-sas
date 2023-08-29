%macro write_datasetjson(
  dataset=,
  xptpath=,
  jsonpath=,
  usemetadata=,
  metadatalib=,
  datasetJSONVersion=1.0.0,
  _FileOID=,
  _AsOfDateTime=,
  _Originator=,
  _SourceSystem=,
  _SourceSystemVersion=,
  _studyOID=,
  _MetaDataVersionOID=,
  _MetaDataRef=
  ) / des = 'Write a SAS dataset to a Dataset-JSON file';

  %local
    _Random
    _SaveOptions1
    _SaveOptions2
    _Missing
    _delete_temp_dataset
    dataset_new dataset_name dataset_label records
    studyOID metaDataVersionOID
    ClinicalReferenceData ItemGroupOID
    CurrentDataTime;

  
  %let _Random=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));

  %* Save options;
  %let _SaveOptions1 = %sysfunc(getoption(dlcreatedir));
  %let _SaveOptions2 = %sysfunc(getoption(compress, keyword)) %sysfunc(getoption(reuse, keyword));
  options dlcreatedir;
  options compress=Yes reuse=Yes;

  %if %sysevalf(%superq(datasetJSONVersion)=, boolean) %then %let datasetJSONVersion = %str(1.0.0);

  %let dataset_label=;
  %let ItemGroupOID=;
  %let studyOID=;
  %let metaDataVersionOID=;
  %let CurrentDateTime=%sysfunc(datetime(), is8601dt.);

  %******************************************************************************;
  %* Parameter checks                                                           *;
  %******************************************************************************;

  %* Check for missing parameters ;
  %let _Missing=;
  %if %sysevalf(%superq(jsonpath)=, boolean) %then %let _Missing = &_Missing jsonpath;
  %if %sysevalf(%superq(usemetadata)=, boolean) %then %let _Missing = &_Missing usemetadata;

  %if %length(&_Missing) gt 0
    %then %do;
      %put ERR%str(OR): [&sysmacroname] Required macro parameter(s) missing: &_Missing;
      %goto exit_macro;
    %end;

  %* Rule: usemetadata has to be Y or N  *;
  %if "%substr(%upcase(&usemetadata),1,1)" ne "Y" and "%substr(%upcase(&usemetadata),1,1)" ne "N" %then
  %do;
    %put ERR%str(OR): [&sysmacroname] Required macro parameter usemetadata=&usemetadata must be Y or N.;
    %goto exit_macro;
  %end;

  %* Rule: usemetadata has to be Y or N  *;
  %if "&datasetJSONVersion" ne "1.0.0" %then
  %do;
    %put ERR%str(OR): [&sysmacroname] Required macro parameter datasetJSONVersion=&datasetJSONVersion must be 1.0.0.;
    %goto exit_macro;
  %end;

  %******************************************************************************;
  %* End of parameter checks                                                    *;
  %******************************************************************************;

  %let _delete_temp_dataset=0;

  %if %sysevalf(%superq(dataset)=, boolean)=0
    %then %do;
      %let dataset_name=%scan(&dataset, -1, %str(.));
      %let dataset_new=&dataset;
    %end;
    %else %do;
      %let dataset_name=%scan(&xptpath, -2, %str(/\.));
      %if %sysfunc(libname(xpti&_Random, &xptpath, xport)) ne 0
        %then %put %sysfunc(sysmsg());
      libname xpt&_Random "%sysfunc(pathname(work))/xpt&_Random";

      proc copy in=xpti&_Random out=xpt&_Random memtype=data;
      run;

      %if %sysfunc(libname(xpti&_Random)) ne 0
        %then %put %sysfunc(sysmsg());
      %let dataset_new=xpt&_Random..&dataset_name;
      %let _delete_temp_dataset=1;
    %end;

  %if %cstutilcheckvarsexist(_cstDataSetName=&dataset_new, _cstVarList=usubjid) %then
      %let ClinicalReferenceData=clinicalData;
    %else %let ClinicalReferenceData=referenceData;

  %let records=%cstutilnobs(_cstDataSetName=&dataset_new);

  %if %substr(%upcase(&UseMetadata),1,1) eq Y %then %do;
    /* Get StudyOID and metaDataVersionOID from the metadata */
    proc sql noprint;
      %if %sysfunc(exist(&metadatalib..metadata_study)) %then %do;
        select studyOID, metaDataVersionOID into :studyOID trimmed, :metaDataVersionOID trimmed
          from &metadatalib..metadata_study;
      %end;
    /* Get dataset label and ItemGroupOID from the metadata */
      %if %sysfunc(exist(&metadatalib..metadata_tables)) %then %do;
        select label, oid into :dataset_label, :ItemGroupOID trimmed
          from &metadatalib..metadata_tables
            where upcase(name)="%upcase(&dataset_name)";
      %end;
    quit;
  %end;


  %if %sysevalf(%superq(studyOID)=, boolean) and %sysevalf(%superq(_StudyOId)=, boolean)=0 %then
    %let studyOID=&_StudyOId;

  %if %sysevalf(%superq(metaDataVersionOID)=, boolean) and %sysevalf(%superq(_MetaDataVersionOID)=, boolean)=0 %then
    %let metaDataVersionOID=&_MetaDataVersionOID;

  %if %sysevalf(%superq(ItemGroupOID)=, boolean) %then %let ItemGroupOID=IG.%upcase(&dataset_name);

  %if %sysevalf(%superq(dataset_label)=, boolean) %then
    %let dataset_label=%cstutilgetattribute(_cstDataSetName=&dataset_new,_cstAttribute=LABEL);

  %if %sysevalf(%superq(dataset_label)=, boolean) %then %do;
    /* %let dataset_label=&dataset_name; */
    %put %str(WAR)NING: &dataset_name: no dataset label.;
  %end;

  %put ### &=dataset &=records &=ClinicalReferenceData &=ItemGroupOID dslabel=%bquote(&dataset_label);

  %if %substr(%upcase(&UseMetadata),1,1) eq Y %then %do;
    /* Get column metadata - oid, label, type, length, displayformat, keysequence  */
    data work.column_metadata(keep=OID name label type length displayFormat keySequence);
      retain OID name label type length displayFormat keySequence;
      set &metadatalib..metadata_columns(
        rename=(json_datatype=type)
        where=(upcase(dataset_name) = %upcase("&dataset_name")));
        if missing(oid) then putlog 'WAR' 'NING: Missing oid for variable: ' name= ;
        if missing(name) then putlog 'WAR' 'NING: Missing name for variable: ' oid= ;
        if missing(label) then putlog 'WAR' 'NING: Missing label for variable: ' oid= name= ;
        if missing(type) then putlog 'WAR' 'NING: Missing type for variable: ' oid= name= ;
    run;
  %end;
  %else %do;
    /* Get column metadata from the datasets - label, type, length, format and derive as much as we can */
    proc contents noprint varnum data=&dataset_new
      out=work.column_metadata(
        keep=varnum name type format formatl formatd length label
        rename=(format=displayFormat type=sas_type)
      );
    run;

    proc sort data=work.column_metadata;
      by varnum;
    run;

    data work.column_metadata(drop=sas_type varnum formatl formatd);
      retain OID name label type length;
      length OID $128 type $32;
      set work.column_metadata;
      OID = cats("IT", ".", upcase("&dataset_name"), ".", upcase(name));
      if sas_type=1 then type="float";
                    else type="string";
      if formatl gt 0 then displayFormat=cats(displayFormat, put(formatl, best.), ".");
      if formatd gt 0 then displayFormat=cats(displayFormat, put(formatd, best.));
      if missing(label) then putlog 'WAR' 'NING: Missing label for variable: ' oid= name= ;
      if missing(type) then putlog 'WAR' 'NING: Missing type for variable: ' oid= name= ;
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
    set itemgroupdataseq work.column_metadata(where=(upcase(name) ne "ITEMGROUPDATASEQ"));
  run;

  proc delete data=work.itemgroupdataseq;
  run;


  %******************************************************************************;
  data work.column_data;
    length ITEMGROUPDATASEQ 8.;
    set &dataset_new;
    ITEMGROUPDATASEQ = _n_;
  run;

  %if &_delete_temp_dataset=1 %then %do;
    proc delete data=xpt&_Random..&dataset_name;
    run;

    %put %sysfunc(filename(fref,%sysfunc(pathname(xpt&_Random))));
    %put %sysfunc(fdelete(&fref));
    libname xpt&_Random clear;
    
  %end;

  filename json&_random "&jsonpath";

  PROC JSON OUT=json&_random NOPRETTY NOSASTAGS SCAN TRIMBLANKS
                         NOFMTCHARACTER NOFMTDATETIME NOFMTNUMERIC;
    WRITE OPEN OBJECT;

    WRITE VALUES "creationDateTime" "&CurrentDateTime";
    WRITE VALUES "datasetJSONVersion" "&datasetJSONVersion";
    %if %sysevalf(%superq(_FileOID)=, boolean)=0 %then
      WRITE VALUES "fileOID" "&_FileOID";
    ;
    %if %sysevalf(%superq(_AsOfDateTime)=, boolean)=0 %then
      WRITE VALUES "asOfDateTime" "&_AsOfDateTime";
    ;
    %if %sysevalf(%superq(_Originator)=, boolean)=0 %then
      WRITE VALUES "originator" "&_Originator";
    ;
    %if %sysevalf(%superq(_SourceSystem)=, boolean)=0 %then
      WRITE VALUES "sourceSystem" "&_SourceSystem";
    ;
    %if %sysevalf(%superq(_SourceSystemVersion)=, boolean)=0 %then
      WRITE VALUES "sourceSystemVersion" "&_SourceSystemVersion";
    ;

    WRITE VALUES "&ClinicalReferenceData";
    WRITE OPEN OBJECT;
    %if %sysevalf(%superq(studyOID)=, boolean)=0 %then
      WRITE VALUES "studyOID" "&studyOID";
    ;
    %if %sysevalf(%superq(metaDataVersionOID)=, boolean)=0 %then
      WRITE VALUES "metaDataVersionOID" "&metaDataVersionOID";
    ;
    %if %sysevalf(%superq(_MetaDataRef)=, boolean)=0 %then
      WRITE VALUES "metaDataRef" "&_MetaDataRef";
    ;
    WRITE VALUE "itemGroupData";
    WRITE OPEN OBJECT;
    WRITE VALUE "&ItemGroupOID";
    WRITE OPEN OBJECT;
    WRITE VALUES "records" &records;
    WRITE VALUES "name" "%upcase(&dataset_name)";
    /* WRITE VALUES "label" %sysfunc(quote(&dataset_label)); */
    WRITE VALUES "label" "%nrbquote(&dataset_label)";

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

  filename json&_random clear;

  proc delete data=work.column_metadata work.column_data;
  run;

  %exit_macro:

  %* Restore options;
  options &_SaveOptions1;
  options &_SaveOptions2;

%mend write_datasetjson;
