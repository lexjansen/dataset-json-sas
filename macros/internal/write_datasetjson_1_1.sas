%macro write_datasetjson_1_1(
  outRef=,
  technicalMetadata=,
  tableMetadata=work.table_metadata,
  columnMetadata=work.column_metadata,
  rowdata=,
  prettyNoPretty=NOPRETTY
  );
  
  %local
    fileOID
    creationDateTime
    asOfDateTime
    modifiedDateTime
    datasetJSONVersion
    originator
    sourceSystem
    sourceSystemVersion
    studyOID
    metaDataVersionOID
    metaDataRef
    itemGroupOID
    records
    datasetName
    datasetLabel
    ;  

  data _null_;
    set &technicalMetadata;
    call symputx('fileOID', fileOID);
    call symputx('creationDateTime', creationDateTime);
    call symputx('modifiedDateTime', modifiedDateTime);
    call symputx('datasetJSONVersion', datasetJSONVersion);
    call symputx('originator', originator);
    call symputx('sourceSystem', sourceSystem);
    call symputx('sourceSystemVersion', sourceSystemVersion);
    call symputx('studyOID', studyOID);
    call symputx('metaDataVersionOID', metaDataVersionOID);
    call symputx('metaDataRef', metaDataRef);
  run;

  data _null_;
    set &tableMetadata;
    call symputx('itemGroupOID', oid);
    call symputx('records', records);
    call symputx('datasetName', name);
    call symputx('datasetLabel', label);
  run;

  PROC JSON OUT=&outRef &prettyNoPretty NOSASTAGS SCAN TRIMBLANKS
                         NOFMTCHARACTER NOFMTDATETIME NOFMTNUMERIC;
    WRITE OPEN OBJECT;

    WRITE VALUES "datasetJSONCreationDateTime" "&creationDateTime";
    WRITE VALUES "datasetJSONVersion" "&datasetJSONVersion";
    %if %sysevalf(%superq(fileOID)=, boolean)=0 %then
      WRITE VALUES "fileOID" "&fileOID";
    ;
    %if %sysevalf(%superq(modifiedDateTime)=, boolean)=0 %then
      WRITE VALUES "dbLastModifiedDateTime" "&modifiedDateTime";
    ;
    %if %sysevalf(%superq(originator)=, boolean)=0 %then
      WRITE VALUES "originator" "&originator";
    ;
    %if %sysevalf(%superq(sourceSystem)=, boolean)=0 or %sysevalf(%superq(sourceSystemVersion)=, boolean)=0 %then %do;
      WRITE VALUES "sourceSystem";
      WRITE OPEN OBJECT;
      
      %if %sysevalf(%superq(sourceSystem)=, boolean)=0 %then
        WRITE VALUES "name" "&sourceSystem";
      ;
      %if %sysevalf(%superq(sourceSystemVersion)=, boolean)=0 %then
        WRITE VALUES "version" "&sourceSystemVersion";
      ;
      WRITE CLOSE;
    %end;
    %if %sysevalf(%superq(_studyOID)=, boolean)=0 %then
      WRITE VALUES "studyOID" "&studyOID";
    ;
    %if %sysevalf(%superq(_metaDataVersionOID)=, boolean)=0 %then
      WRITE VALUES "metaDataVersionOID" "&metaDataVersionOID";
    ;
    %if %sysevalf(%superq(metaDataRef)=, boolean)=0 %then
      WRITE VALUES "metaDataRef" "&metaDataRef";
    ;
    %if %sysevalf(%superq(itemGroupOID)=, boolean)=0 %then
      WRITE VALUES "itemGroupOID" "&itemGroupOID";
    ;  
    WRITE VALUES "records" &records;
    WRITE VALUES "name" "&datasetName";
    %if %sysevalf(%superq(datasetLabel)=, boolean)=0 %then
      WRITE VALUES "label" "%nrbquote(&datasetLabel)";
    ;
    WRITE VALUES "columns";
    %* Use macro to avoid creating null values for missing attributes;
    %* Instead do not create the attribute;
    %write_json_metadata_array(&columnMetadata);
    /*
    WRITE OPEN ARRAY;
      EXPORT work.column_metadata / KEYS;
    WRITE CLOSE
    */

    WRITE VALUES "rows";
    WRITE OPEN ARRAY;
    EXPORT &rowData / NOKEYS FMTDATETIME;
    WRITE CLOSE;
    WRITE CLOSE;
  RUN;

%mend write_datasetjson_1_1;
