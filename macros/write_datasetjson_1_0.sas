%macro write_datasetjson_1_0(
  outRef=,
  technicalMetadata=,
  tableMetadata=work.table_metadata,
  columnMetadata=work.column_metadata,
  rowData=,
  prettyNoPretty=NOPRETTY
  );

  %local
    fileOID
    creationDateTime
    asOfDateTime
    datasetJSONVersion
    originator
    sourceSystem
    sourceSystemVersion
    studyOID
    metaDataVersionOID
    metaDataRef
    itemGroupOID
    dataseType
    records
    datasetName
    datasetLabel
    ;  

  data _null_;
    set &technicalMetadata;
    call symputx('fileOID', fileOID);
    call symputx('creationDateTime', creationDateTime);
    call symputx('asOfDateTime', asOfDateTime);
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
    call symputx('dataseType', datasetType)
    call symputx('records', records);
    call symputx('datasetName', name);
    call symputx('datasetLabel', label);
  run;

  PROC JSON OUT=&outRef &prettyNoPretty NOSASTAGS SCAN TRIMBLANKS
                         NOFMTCHARACTER NOFMTDATETIME NOFMTNUMERIC;
    WRITE OPEN OBJECT;

    WRITE VALUES "creationDateTime" "&creationDateTime";
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

    WRITE VALUES "&datasetType";
    WRITE OPEN OBJECT;
    %if %sysevalf(%superq(_studyOID)=, boolean)=0 %then
      WRITE VALUES "studyOID" "&studyOID";
    ;
    %if %sysevalf(%superq(_metaDataVersionOID)=, boolean)=0 %then
      WRITE VALUES "metaDataVersionOID" "&metaDataVersionOID";
    ;
    %if %sysevalf(%superq(metaDataRef)=, boolean)=0 %then
      WRITE VALUES "metaDataRef" "&metaDataRef";
    ;
    WRITE VALUE "itemGroupData";
    WRITE OPEN OBJECT;
    WRITE VALUE "&itemGroupOID";
    WRITE OPEN OBJECT;
    WRITE VALUES "records" &records;
    WRITE VALUES "name" "&datasetName";
    WRITE VALUES "label" "%nrbquote(&datasetLabel)";

    WRITE VALUE "items";
    %* Use macro to avoid creating null values for missing attributes;
    %* Instead do not create the attribute;
    %write_json_metadata_array(&columnMetadata);
    /*
    WRITE OPEN ARRAY;
      EXPORT work.column_metadata / KEYS;
    WRITE CLOSE
    */

    WRITE VALUE "itemData";
    WRITE OPEN ARRAY;
    EXPORT &rowData / NOKEYS;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
  RUN;

%mend write_datasetjson_1_0;
