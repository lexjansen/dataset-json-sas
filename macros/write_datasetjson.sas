/**
  @file write_datasetjson.sas
  @brief Write a SAS dataset to a Dataset-JSON file.

  @details This macro creates a Dataset-JSON file from a SAS dataset<br />
  Metadata is taken from the dataset or from a number of metadata tables:
  @li metadata_study
  @li metadata_tables
  @li metadata_columns

  Some metadata can be specified as parameters
  (fileOID, originator, sourceSystem, sourceSystemVersion,
  studyOID, metaDataVersionOID, metaDataRef, datasetlabel).

  Example usage:

      %write_datasetjson(
          dataset=datasdtm.dm,
          jsonpath=&project_folder/json_out/sdtm/dm.json);

      %write_datasetjson(
          dataset=datasdtm.dm,
          jsonpath=&project_folder/json_out/sdtm/dm.json,
          usemetadata=Y,
          metadatalib=metasdtm);

  @author Lex Jansen

  @param[in] dataset= (libname.)memname of the SAS data set
  @param[out] jsonpath= Path to Dataset-JSON file
  @param[out] jsonfref= File reference for the Dataset-JSON file.
                        Either jsonpath or jsonfref has to be sppecified.
  @param[in] usemetadata= (N) Use Define-XML metadata? (Y/N)
  @param[in] metadatalib= Define-XML metadata library
    The following datasets are expected:
    @li metadata_study
    @li metadata_tables
    @li metadata_columns
  @param[in] decimalVariables= List of numeric variables to write as decimal strings.
    Not used when usemetadata=Y. Separated by blanks.
  @param[in] datasetJSONVersion= (1.1.0) Dataset-JSON version. Allowed values: 1.1.*
  @param[in] originator= The organization that generated the Dataset-JSON dataset.
  @param[in] sourceSystem= The name of the information system from which the content of this dataset was sourced
  @param[in] sourceSystemVersion= The version of the information system from which the content of this dataset was sourced
  @param[in] studyOID= Unique identifier for the study that may also function as a foreign key to a Study/\@OID in an associated Define-XML file
  @param[in] metaDataVersionOID= Unique identifier for the metadata version that may also function as a foreign key to a MetaDataVersion/\@OID in an associated Define-XML file
  @param[in] metaDataRef= URI for a metadata file describing the dataset (e.g., a Define-XML file)
  @param[in] datasetlabel= Dataset label
  @param[in] pretty= (NOPRETTY) Format Dataset-JSON file (PRETTY/NOPRETTY).

  <h4> Related Macros </h4>
  @li write_datasetjson_1_0.sas
  @li write_datasetjson_1_1.sas

**/

%macro write_datasetjson(
  dataset=,
  jsonpath=,
  jsonfref=,
  usemetadata=N,
  metadatalib=,
  decimalVariables=,
  datasetJSONVersion=1.1.0,
  fileOID=,
  originator=,
  sourceSystem=,
  sourceSystemVersion=,
  studyOID=,
  metaDataVersionOID=,
  metaDataRef=,
  datasetlabel=,
  pretty=NOPRETTY
  ) / des = 'Write a SAS dataset to a Dataset-JSON file';

  %local
    _Random
    _SaveOptions1
    _SaveOptions2
    _Missing
    _create_temp_dataset_sas
    dataset_new dataset_name dataset_label _records
    _studyOID _metaDataVersionOID
    _itemGroupOID _isReferenceData
    creationDateTime modifiedDateTime
    releaseCreated hostCreated
    _decimal_variables _iso8601_variables _format
    _dataset_to_write;


  %let _Random=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));

  %* Save options;
  %let _SaveOptions1 = %sysfunc(getoption(dlcreatedir));
  %let _SaveOptions2 = %sysfunc(getoption(compress, keyword)) %sysfunc(getoption(reuse, keyword));
  options dlcreatedir;
  options compress=Yes reuse=Yes;

  %if %sysevalf(%superq(datasetJSONVersion)=, boolean) %then %let datasetJSONVersion = %str(1.1.0);

  %let dataset_label=;
  %let _itemGroupOID=;
  %let _studyOID=;
  %let _metaDataVersionOID=;
  %let creationDateTime=%sysfunc(datetime(), is8601dt.);
  %let modifiedDateTime=;
  %let releaseCreated=;
  %let hostCreated=;
  %let _create_temp_dataset_sas=0;

  %******************************************************************************;
  %* Parameter checks                                                           *;
  %******************************************************************************;

  %* Check for missing parameters ;
  %let _Missing=;
  %if %sysevalf(%superq(dataset)=, boolean) %then %let _Missing = &_Missing dataset;
  %if %sysevalf(%superq(usemetadata)=, boolean) %then %let _Missing = &_Missing usemetadata;

  %if %length(&_Missing) gt 0
    %then %do;
      %put ERR%str(OR): [&sysmacroname] Required macro parameter(s) missing: &_Missing;
      %goto exit_macro;
    %end;

  %* Check for non-existing dataset ;
  %if not %sysfunc(exist(&dataset)) %then %do;
    %put ERR%str(OR): [&sysmacroname] Dataset &=dataset does not exist.;
    %goto exit_macro;
  %end;

  %* Specify either jsonpath or jsonfref;
  %if %sysevalf(%superq(jsonpath)=, boolean) and %sysevalf(%superq(jsonfref)=, boolean) %then %do;
      %put ERR%str(OR): [&sysmacroname] Both jsonpath and jsonfref are missing. Specify one of them.;
      %goto exit_macro;
  %end;


  %* Specify either jsonpath or jsonfref;
  %if %sysevalf(%superq(jsonpath)=, boolean)=0 and %sysevalf(%superq(jsonfref)=, boolean)=0 %then %do;
      %put ERR%str(OR): [&sysmacroname] Specify either jsonpath or jsonfref, but not both.;
      %goto exit_macro;
  %end;

  %* Check for non-assigned jsonfref;
  %if %sysevalf(%superq(jsonfref)=, boolean)=0 %then %do;
    %if %sysfunc(fileref(&jsonfref)) gt 0 %then %do;
      %put ERR%str(OR): [&sysmacroname] JSON file reference &=jsonfref is not assigned.;
      %put %sysfunc(sysmsg());
      %goto exit_macro;
    %end;
  %end;

  %* Rule: usemetadata has to be Y or N  *;
  %if "%substr(%upcase(&usemetadata),1,1)" ne "Y" and "%substr(%upcase(&usemetadata),1,1)" ne "N" %then
  %do;
    %put ERR%str(OR): [&sysmacroname] Required macro parameter &=usemetadata must be Y or N.;
    %goto exit_macro;
  %end;

  %* Rule: when usemetadata eq Y then metadatalib can not be empty *;
  %if "%substr(%upcase(&usemetadata),1,1)" eq "Y" and %sysevalf(%superq(metadatalib)=, boolean) %then
  %do;
    %put ERR%str(OR): [&sysmacroname] When usemetadata=Y, then parameter metadatalib can not be empty.;
    %goto exit_macro;
  %end;

  %if %sysevalf(%superq(metadatalib)=, boolean)=0 %then %do;
    %if (%sysfunc(libref(&metadatalib)) ne 0 ) %then %do;
      %put ERR%str(OR): [&sysmacroname] metadatalib library &=metadatalib has not been assigned.;
      %put %sysfunc(sysmsg());
      %goto exit_macro;
    %end;
  %end;

  %* Rule: when usemetadata eq Y then metadata datasets need to exist in the metadatalib library *;
  %if "%substr(%upcase(&usemetadata),1,1)" eq "Y" %then %do;
    %if not %sysfunc(exist(&metadatalib..metadata_study)) %then %do;
      %put ERR%str(OR): [&sysmacroname] usemetadata=Y, but &metadatalib..metadata_study does not exist.;
      %goto exit_macro;
    %end;
    %if not %sysfunc(exist(&metadatalib..metadata_tables)) %then %do;
      %put ERR%str(OR): [&sysmacroname] usemetadata=Y, but &metadatalib..metadata_tables does not exist.;
      %goto exit_macro;
    %end;
    %if not %sysfunc(exist(&metadatalib..metadata_columns)) %then %do;
      %put ERR%str(OR): [&sysmacroname] usemetadata=Y, but &metadatalib..metadata_columns does not exist.;
      %goto exit_macro;
    %end;
  %end;

  %* Rule: when usemetadata eq Y then decimalVariables will not be used *;
  %if "%substr(%upcase(&usemetadata),1,1)" eq "Y" %then %do;
    %if %sysevalf(%superq(decimalVariables)=, boolean)=0
        %then %put WAR%str(NING): [&sysmacroname] When macro parameter &=usemetadata then parameter decimalVariables will not be used.;
  %end;

  %* Rule: allowed versions *;
  %if %substr(&datasetJSONVersion,1,3) ne %str(1.1) %then
  %do;
    %put ERR%str(OR): [&sysmacroname] Macro parameter &=datasetJSONVersion. Allowed values: 1.1.x.;
    %goto exit_macro;
  %end;

  %******************************************************************************;
  %* End of parameter checks                                                    *;
  %******************************************************************************;

  /* Get modifiedDateTime, releaseCreated, hostCreated, number of records */
  ods listing close;
  ods output Attributes=Attributes EngineHost=EngineHost Variables=Variables;
    proc contents data=&dataset;
    run;
  ods output close;
  ods listing;

  data _null_;
      set Attributes;
      if Label1 = "Last Modified" then call symputx('modifiedDateTime', put(nValue1, E8601DT.));
  run;

  data _null_;
      set EngineHost;
      if Label1 = "Release Created" then call symputx('releaseCreated', cValue1);
      if Label1 = "Host Created" then call symputx('hostCreated', cValue1);
    run;

  %let _records=%cstutilnobs(_cstDataSetName=&dataset);

  proc delete data=work.Attributes work.EngineHost;
  run;

  %if %sysevalf(%superq(sourceSystem)=, boolean) and
    %sysevalf(%superq(hostCreated)=, boolean)=0 %then %let sourceSystem = %str(SAS on &hostCreated);
  %if %sysevalf(%superq(sourceSystemVersion)=, boolean) and
    %sysevalf(%superq(releaseCreated)=, boolean)=0 %then %let sourceSystemVersion = %str(&releaseCreated);


  /* Create temp SAS dataset */
  %let dataset_name=%scan(&dataset, -1, %str(.));
  %let dataset_new=&dataset;
  libname sas&_Random "%sysfunc(pathname(work))/sas&_Random";
  proc copy in=%scan(&dataset, 1, %str(.)) out=sas&_Random memtype=data datecopy;
    select &dataset_name;
  run;
  %let dataset_new=sas&_Random..&dataset_name;

  %let _create_temp_dataset_sas=1;

  %if %substr(%upcase(&UseMetadata),1,1) eq Y %then %do;
    /* Get StudyOID and metaDataVersionOID from the metadata */
    proc sql noprint;
      %if %sysfunc(exist(&metadatalib..metadata_study)) %then %do;
        select studyOID, metaDataVersionOID into :_studyOID trimmed, :_metaDataVersionOID trimmed
          from &metadatalib..metadata_study;
      %end;
    /* Get dataset label and _itemGroupOID from the metadata */
      %if %sysfunc(exist(&metadatalib..metadata_tables)) %then %do;
        select label, oid into :dataset_label trimmed, :_temGroupOID trimmed
          from &metadatalib..metadata_tables
            where upcase(name)="%upcase(&dataset_name)";
        select isReferenceData into :_isReferenceData trimmed
          from &metadatalib..metadata_tables
            where upcase(name)="%upcase(&dataset_name)";
      %end;
    quit;
  %end;

  /* Get StudyOID, metaDataVersionOID, itemGroupOID, and dataset label */
  %if %sysevalf(%superq(_studyOID)=, boolean) and %sysevalf(%superq(studyOId)=, boolean)=0 %then
    %let _studyOID=&studyOId;

  %if %sysevalf(%superq(_metaDataVersionOID)=, boolean) and %sysevalf(%superq(metaDataVersionOID)=, boolean)=0 %then
    %let _metaDataVersionOID=&metaDataVersionOID;

  %if %sysevalf(%superq(_itemGroupOID)=, boolean) %then %let _itemGroupOID=IG.%upcase(&dataset_name);

  %if %sysevalf(%superq(dataset_label)=, boolean) %then
    %let dataset_label=%cstutilgetattribute(_cstDataSetName=&dataset_new,_cstAttribute=LABEL);
  %if %sysevalf(%superq(dataset_label)=, boolean) %then
    %let dataset_label=&datasetlabel;

  %if %sysevalf(%superq(dataset_label)=, boolean) %then %do;
    %put %str(WAR)NING: [&sysmacroname] Dataset &dataset has no dataset label.;
  %end;

  %put NOTE: DATASET=&dataset_name &=_records &=_isReferenceData &=_itemGroupOID dslabel=%bquote(&dataset_label);



  %if %substr(%upcase(&UseMetadata),1,1) eq Y %then %do;
    /* Get column metadata - oid, label, type, length, displayformat, keysequence  */
    data work._column_metadata(keep=OID name label order datatype targetdatatype length displayFormat keySequence);
      retain OID name label datatype length displayFormat keySequence;
      set &metadatalib..metadata_columns(
          where=(upcase(dataset_name) = %upcase("&dataset_name"))
          drop=length
          rename=(json_length=length)
        );
        if missing(oid) then putlog "WAR" "NING: [&sysmacroname] Missing oid for variable: &dataset." name ;
        if missing(name) then putlog "WAR" "NING: [&sysmacroname] Missing name for variable in dataset &dataset: " oid ;
        if missing(label) then do;
          putlog "WAR" "NING: [&sysmacroname] Missing label for variable: &dataset.." name +(-1) ", " oid= +(-1) ".";
        end;
        if missing(datatype) then putlog "WAR" "NING: [&sysmacroname] Missing dataType for variable: &dataset.." name +(-1) ", " oid=;

        if dataType in ("date", "datetime", "time") and targetDataType = "integer" and missing(displayFormat)
          then putlog "WAR" "NING: [&sysmacroname] Missing displayFormat for variable: &dataset.." name +(-1) ", " oid= +(-1) ", " dataType= +(-1) ", " targetDataType=;

    run;


    /* Check lengths */
    proc contents noprint varnum data=&dataset_new
      out=work.column_metadata_sas(keep=name type length varnum);
    run;

    proc sql noprint;
      create table work.column_metadata as
      select
        t2.name as sas_name,
        t2.length as sas_length,
        t2.type as sas_type,
        t2.varnum,
        t1.*
        from work.column_metadata_sas t2
          left join work._column_metadata t1
        on t1.name = t2.name
        order by varnum
        ;
    quit ;

    data work.column_metadata(drop=sas_type sas_length sas_name order varnum);
      set work.column_metadata;
      if (sas_type=2) and (not missing(length)) and (length lt sas_length)
        then putlog 'WAR' 'NING:' " [&sysmacroname] &dataset.." name +(-1) ": metadata length is smaller than SAS length - "
                    length= +(-1) ", SAS length=" sas_length;
      if missing(name) then do;
        putlog 'WAR' 'NING:' "[&sysmacroname] &dataset.." sas_name
                +(-1) ": variable is missing from metadata. SAS metadata will be used.";
        OID = cats("IT", ".", upcase("&dataset_name"), ".", upcase(sas_name));
        name = sas_name;
        length = sas_length;
        if sas_type=1 then dataType="float";
                      else dataType="string";
        label = propcase(name);
      end;
    run;

    proc delete data=work._column_metadata;
    run;
    proc delete data=work.column_metadata_sas;
    run;

  %end;
  %else %do; %* UseMetadata ne N;

    %create_template(type=COLUMNS, out=work.column_metadata_template);
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
      retain OID name label dataType targetDataType length;
      length OID $ 128 dataType targetDataType $ 32;
      set work.column_metadata_template work.column_metadata;
      targetDataType = "";
      OID = cats("IT", ".", upcase("&dataset_name"), ".", upcase(name));
      if sas_type=1 then do;
        dataType="float";
        length = .;
      end;
      else do;
        dataType="string";
      end;
      /* Numeric datetime, date, and time variables will be transfered as ISO 8601 strings */
      if not (missing(displayFormat)) then do;
        if sas_type = 1 and (find(displayFormat, "E8601DA", 'it') or find(displayFormat, "DATE", 'it')) then do;
          dataType = "date";
          targetDataType = "integer";
        end;
        if sas_type = 1 and (find(displayFormat, "E8601TM", 'it') or find(displayFormat, "TIME", 'it')) then do;
          dataType = "time";
          targetDataType = "integer";
        end;
        if sas_type = 1 and (find(displayFormat, "E8601DT", 'it') or find(displayFormat, "DATETIME", 'it')) then do;
          dataType = "datetime";
          targetDataType = "integer";
        end;
      end;

      if formatl gt 0 then displayFormat=cats(displayFormat, put(formatl, best.), ".");
      if formatd gt 0 then displayFormat=cats(displayFormat, put(formatd, best.));
      %* put a dot on the end of format if we are still missing it;
      if (not missing(displayFormat)) and index(displayFormat,'.')=0 then displayFormat=strip(displayFormat)||'.';
      if missing(label) then do;
        putlog "WAR" "NING: [&sysmacroname] Missing label for variable &dataset.." name +(-1) ", " oid= +(-1) ".";
      end;
      if missing(dataType) then putlog "WAR" "NING: [&sysmacroname] Missing type for variable &dataset.." name +(-1) ", "  oid=;
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
          dataType="integer";
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

  %************************************************************;
  /* Convert numeric variables to decimal strings if needed */
  %************************************************************;
  %if "%substr(%upcase(&usemetadata),1,1)" eq "Y" %then %do;
    %let _decimal_variables=;
    proc sql noprint;
      select name into :_decimal_variables separated by ' '
        from work.column_metadata
        where dataType='decimal' and targetDataType='decimal';
    quit;
  %end;
  %else %do;
    %if %sysevalf(%superq(decimalVariables)=, boolean)=0 %then %do;
      data work.column_metadata;
        set work.column_metadata;
          %do _count=1 %to %sysfunc(countw(&decimalVariables, %str(' ')));
            if upcase(name)=upcase("%scan(&decimalVariables, &_count)") then do;
              dataType="decimal";
              targetDataType="decimal";
            end;
          %end;
      run;
      %let _decimal_variables=&decimalVariables;
    %end;
  %end;
  %if %sysevalf(%superq(_decimal_variables)=, boolean)=0 %then %do;
    %put NOTE: [&sysmacroname] &dataset: numeric variables converted to strings: &_decimal_variables;
    %convert_num_to_char(ds=&_dataset_to_write, outds=&_dataset_to_write, varlist=&_decimal_variables);
  %end;

  %************************************************************;
  /* Convert numeric ISO 8601 variables to strings if needed  */
  %************************************************************;
  %let _iso8601_variables=;
  proc sql noprint;
    select name into :_iso8601_variables separated by ' '
      from work.column_metadata
      where (datatype in ('datetime', 'date', 'time')) and (targetdatatype = 'integer');
  quit;

  %if %sysevalf(%superq(_iso8601_variables)=, boolean)=0 %then %do;
    %put NOTE: [&sysmacroname] &dataset: numeric ISO 8601 variables converted to strings: &_iso8601_variables;
  %end;

  /* Attach the right formats */

  data work.column_metadata_formats;
    length dataset_name $32;
     set work.column_metadata(where=((datatype in ('datetime', 'date', 'time')) and (targetdatatype = 'integer')));
     dataset_name = "column_data";
     if dataType = "date" and find(displayFormat, "E8601DA", 'it')=0 then displayFormat = "E8601DA.";
     if dataType = "datetime" and find(displayFormat, "E8601DT", 'it')=0 then displayFormat = "E8601DT.";
     if dataType = "time" and find(displayFormat, "E8601TM", 'it')=0 then displayFormat = "E8601TM.";
  run;

  %add_formats_to_datasets(
    metadata=work.column_metadata_formats,
    datalib=work,
    condition = %str(not missing(displayFormat)),
    format=displayFormat
    );

  proc delete data=work.column_metadata_formats;
  run;

  %******************************************************************************;

  %create_template(type=STUDY, out=work.study_metadata);

  proc sql;
  insert into work.study_metadata
    set fileoid = "&fileOID",
        creationdatetime = "&creationdatetime",
        modifiedDateTime = "&modifiedDateTime",
        datasetJSONVersion = "&datasetJSONVersion",
        originator = "&originator",
        sourcesystem = "&sourceSystem",
        sourcesystemversion = "&sourceSystemVersion",
        studyoid = "&_studyOID",
        metadataversionoid = "&_metaDataVersionOID",
        metaDataRef = "&metaDataRef"
    ;
  quit;

  %create_template(type=TABLES, out=work.table_metadata);

  /* Derive _isReferenceData */
  %if %cstutilcheckvarsexist(_cstDataSetName=&dataset, _cstVarList=usubjid)=0 %then
    %do;
      %let _isReferenceData=Yes;
    %end;
    %else %do;
      %let _isReferenceData=No;
    %end;

  proc sql;
  insert into work.table_metadata
    set oid = "&_itemGroupOID"
        , isReferenceData = "&_isReferenceData"
        , records = &_records
        , name = "%upcase(&dataset_name)"
        %if %sysevalf(%superq(dataset_label)=, boolean)=0 %then , label = "%nrbquote(&dataset_label)";
    ;
  quit;

  %if %sysevalf(%superq(jsonpath)=, boolean)=0 %then
    filename json&_random "&jsonpath";;
  %if %sysevalf(%superq(jsonfref)=, boolean)=0 %then
    filename json&_random "%sysfunc(pathname(&jsonfref))";;

  data work.column_metadata;
    retain itemOID name label dataType targetDataType length displayFormat keySequence;
    set work.column_metadata(rename=(oid=itemOID));
  run;

  %write_datasetjson_1_1(
    outRef=json&_random,
    technicalMetadata=work.study_metadata,
    tableMetadata=work.table_metadata,
    columnMetadata=work.column_metadata,
    rowdata=&_dataset_to_write,
    prettyNoPretty=&pretty
  );

  filename json&_random clear;

  %if &_create_temp_dataset_sas=1 %then %do;
    proc delete data=sas&_Random..&dataset_name;
    run;

    %put %sysfunc(filename(fref,%sysfunc(pathname(sas&_Random))));
    %put %sysfunc(fdelete(&fref));
    libname sas&_Random clear;

  %end;

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
