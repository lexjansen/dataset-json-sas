%macro write_datasetjson(
  dataset=,
  xptpath=,
  jsonpath=,
  usemetadata=,
  metadatalib=,
  datasetJSONVersion=1.0.0,
  fileOID=,
  asOfDateTime=,
  originator=,
  sourceSystem=,
  sourceSystemVersion=,
  studyOID=,
  metaDataVersionOID=,
  metaDataRef=,
  pretty=NOPRETTY
  ) / des = 'Write a SAS dataset to a Dataset-JSON file';

  %local
    _Random
    _SaveOptions1
    _SaveOptions2
    _Missing
    _delete_temp_dataset
    dataset_new dataset_name dataset_label records
    _studyOID _metaDataVersionOID
    _clinicalReferenceData _itemGroupOID
    CurrentDataTime
    _dataset_to_write;

  
  %let _Random=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));

  %* Save options;
  %let _SaveOptions1 = %sysfunc(getoption(dlcreatedir));
  %let _SaveOptions2 = %sysfunc(getoption(compress, keyword)) %sysfunc(getoption(reuse, keyword));
  options dlcreatedir;
  options compress=Yes reuse=Yes;

  %if %sysevalf(%superq(datasetJSONVersion)=, boolean) %then %let datasetJSONVersion = %str(1.0.0);

  %let dataset_label=;
  %let _itemGroupOID=;
  %let _studyOID=;
  %let _metaDataVersionOID=;
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
    %put ERR%str(OR): [&sysmacroname] Macro parameter datasetJSONVersion=&datasetJSONVersion. Allowed values: 1.0.0.;
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
      %let _clinicalReferenceData=clinicalData;
    %else %let _clinicalReferenceData=referenceData;

  %let records=%cstutilnobs(_cstDataSetName=&dataset_new);

  %if %substr(%upcase(&UseMetadata),1,1) eq Y %then %do;
    /* Get StudyOID and metaDataVersionOID from the metadata */
    proc sql noprint;
      %if %sysfunc(exist(&metadatalib..metadata_study)) %then %do;
        select studyOID, metaDataVersionOID into :_studyOID trimmed, :_metaDataVersionOID trimmed
          from &metadatalib..metadata_study;
      %end;
    /* Get dataset label and _itemGroupOID from the metadata */
      %if %sysfunc(exist(&metadatalib..metadata_tables)) %then %do;
        select label, oid into :dataset_label, :_temGroupOID trimmed
          from &metadatalib..metadata_tables
            where upcase(name)="%upcase(&dataset_name)";
      %end;
    quit;
  %end;


  %if %sysevalf(%superq(_studyOID)=, boolean) and %sysevalf(%superq(studyOId)=, boolean)=0 %then
    %let _studyOID=&studyOId;

  %if %sysevalf(%superq(_metaDataVersionOID)=, boolean) and %sysevalf(%superq(metaDataVersionOID)=, boolean)=0 %then
    %let _metaDataVersionOID=&metaDataVersionOID;

  %if %sysevalf(%superq(_itemGroupOID)=, boolean) %then %let _itemGroupOID=IG.%upcase(&dataset_name);

  %if %sysevalf(%superq(dataset_label)=, boolean) %then
    %let dataset_label=%cstutilgetattribute(_cstDataSetName=&dataset_new,_cstAttribute=LABEL);

  %if %sysevalf(%superq(dataset_label)=, boolean) %then %do;
    %let dataset_label=%sysfunc(lowcase(&dataset_name));
    %if %sysevalf(%superq(xptpath)=, boolean) %then %put %str(WAR)NING: [&sysmacroname] Dataset &dataset has no dataset label. "&dataset_label" will be used as label.;
                                              %else %put %str(WAR)NING: [&sysmacroname] Dataset &dataset_name (&xptpath) has no dataset label. "&dataset_label" will be used as label.;
  %end;

  %put NOTE: [&sysmacroname] &=dataset &=records &=_clinicalReferenceData &=_itemGroupOID dslabel=%bquote(&dataset_label);

  %if %substr(%upcase(&UseMetadata),1,1) eq Y %then %do;
    /* Get column metadata - oid, label, type, length, displayformat, keysequence  */
    data work.column_metadata(keep=OID name label type length displayFormat keySequence);
      retain OID name label type length displayFormat keySequence;
      length _label $ 32;
      set &metadatalib..metadata_columns(
        rename=(json_datatype=type)
        where=(upcase(dataset_name) = %upcase("&dataset_name")));
        _label = "";
        if missing(oid) then putlog "WAR" "NING: [&sysmacroname] Missing oid for variable: " name ;
        if missing(name) then putlog "WAR" "NING: [&sysmacroname] Missing name for variable: " oid ;
        if missing(label) then do;
          _label = lowcase(name);
          putlog "WAR" "NING: [&sysmacroname] Missing label for variable: " name +(-1) ", " oid= +(-1) ". " _label "will be used as label.";
          label = _label;
        end;  
        if missing(type) then putlog "WAR" "NING: [&sysmacroname] Missing type for variable: " name +(-1) ", " oid=;
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

    data work.column_metadata(drop=sas_type varnum formatl formatd _label);
      retain OID name label type length;
      length OID $ 128 type _label $ 32;
      set work.column_metadata;
      _label = "";
      OID = cats("IT", ".", upcase("&dataset_name"), ".", upcase(name));
      if sas_type=1 then type="float";
                    else type="string";
      if formatl gt 0 then displayFormat=cats(displayFormat, put(formatl, best.), ".");
      if formatd gt 0 then displayFormat=cats(displayFormat, put(formatd, best.));
      if missing(label) then do;
        _label = propcase(name);
        putlog "WAR" "NING: [&sysmacroname] Missing label for variable " name +(-1) ", " oid= +(-1) ". " _label "will be used as label.";
        label = _label;
      end;  
      if missing(type) then putlog "WAR" "NING: [&sysmacroname] Missing type for variable " name +(-1) ", "  oid=;
    run;

  %end;

  %if %cstutilcheckvarsexist(_cstDataSetName=&dataset_new, _cstVarList=ITEMGROUPDATASEQ) %then %do;
  /* There already is a ITEMGROUPDATASEQ variable */  
    %put %str(WAR)NING: [&sysmacroname] Dataset &dataset_new already contains a variable ITEMGROUPDATASEQ.;
    %if %cstutilgetattribute(_cstDataSetName=&dataset_new, _cstVarName=ITEMGROUPDATASEQ, _cstAttribute=VARTYPE) eq C %then %do;
      /* The datatype of the ITEMGROUPDATASEQ variable is character*/
      %put %str(ERR)OR: [&sysmacroname] The ITEMGROUPDATASEQ in the dataset &dataset_new is a character variable.;
      %put %str(ERR)OR: [&sysmacroname] It is required to drop this variable.;
    %end;
    %let _dataset_to_write = &dataset_new;
  %end;
  %else %do;
    /* Create the numeric ITEMGROUPDATASEQ variable */
    /* Create a 1-obs dataset with the same structure as the column_metadata dataset */
    proc sql noprint;
      create table itemgroupdataseq_metadata
        like work.column_metadata;
      insert into itemgroupdataseq_metadata
        set OID="ITEMGROUPDATASEQ", name="ITEMGROUPDATASEQ", label="Record Identifier",
          type="integer";
    quit;

    data work.column_metadata;
      set itemgroupdataseq_metadata 
          work.column_metadata(where=(upcase(name) ne "ITEMGROUPDATASEQ"));
    run;

    data work.column_data;
      length ITEMGROUPDATASEQ 8.;
      set &dataset_new;
      ITEMGROUPDATASEQ = _n_;
    run;
    %let _dataset_to_write = work.column_data;

    proc delete data=work.itemgroupdataseq_metadata;
    run;

  %end;



  %******************************************************************************;

  %if &_delete_temp_dataset=1 %then %do;
    proc delete data=xpt&_Random..&dataset_name;
    run;

    %put %sysfunc(filename(fref,%sysfunc(pathname(xpt&_Random))));
    %put %sysfunc(fdelete(&fref));
    libname xpt&_Random clear;
    
  %end;

  filename json&_random "&jsonpath";

  PROC JSON OUT=json&_random &pretty NOSASTAGS SCAN TRIMBLANKS
                         NOFMTCHARACTER NOFMTDATETIME NOFMTNUMERIC;
    WRITE OPEN OBJECT;

    WRITE VALUES "creationDateTime" "&CurrentDateTime";
    WRITE VALUES "datasetJSONVersion" "&datasetJSONVersion";
    %if %sysevalf(%superq(fileOID)=, boolean)=0 %then
      WRITE VALUES "fileOID" "&fileOID";
    ;
    %if %sysevalf(%superq(asOfDateTime)=, boolean)=0 %then
      WRITE VALUES "asOfDateTime" "&asOfDateTime";
    ;
    %if %sysevalf(%superq(originator)=, boolean)=0 %then
      WRITE VALUES "originator" "&originator";
    ;
    %if %sysevalf(%superq(sourceSystem)=, boolean)=0 %then
      WRITE VALUES "sourceSystem" "&sourceSystem";
    ;
    %if %sysevalf(%superq(sourceSystemVersion)=, boolean)=0 %then
      WRITE VALUES "sourceSystemVersion" "&sourceSystemVersion";
    ;

    WRITE VALUES "&_clinicalReferenceData";
    WRITE OPEN OBJECT;
    %if %sysevalf(%superq(_studyOID)=, boolean)=0 %then
      WRITE VALUES "studyOID" "&_studyOID";
    ;
    %if %sysevalf(%superq(_metaDataVersionOID)=, boolean)=0 %then
      WRITE VALUES "metaDataVersionOID" "&_metaDataVersionOID";
    ;
    %if %sysevalf(%superq(metaDataRef)=, boolean)=0 %then
      WRITE VALUES "metaDataRef" "metaDataRef";
    ;
    WRITE VALUE "itemGroupData";
    WRITE OPEN OBJECT;
    WRITE VALUE "&_itemGroupOID";
    WRITE OPEN OBJECT;
    WRITE VALUES "records" &records;
    WRITE VALUES "name" "%upcase(&dataset_name)";
    WRITE VALUES "label" "%nrbquote(&dataset_label)";

    WRITE VALUE "items";
    %* Use macro to avoid creating null values for missing attributes;
    %* Instead do not create the attribute;
    %write_json_metadata_array(work.column_metadata);
    /*
    WRITE OPEN ARRAY;
      EXPORT work.column_metadata / KEYS;
    WRITE CLOSE
    */
 
    WRITE VALUE "itemData";
    WRITE OPEN ARRAY;
    EXPORT &_dataset_to_write / NOKEYS;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
  RUN;

  filename json&_random clear;

  %if %sysfunc(exist(work.column_metadata)) %then %do;
    proc delete data=work.column_metadata;
    run;
  %end;
  %if %sysfunc(exist(work.column_data)) %then %do;
    proc delete data=work.column_data;
    run;
  %end;

  %exit_macro:

  %* Restore options;
  options &_SaveOptions1;
  options &_SaveOptions2;

%mend write_datasetjson;
