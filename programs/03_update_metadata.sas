%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

proc format;
  /* this is a very rough mapping, it does not take decimal into account */
  value $datatyp
    text = "string"
    date = "date"
    datetime = "datetime"
    time = "time"
    URI = "string"
    partialDate = "string"
    partialTime = "string"
    partialDatetime = "string"
    durationDatetime = "string"
    intervalDatetime = "string"
    incompleteDatetime = "string"
    incompleteDate = "string"
    incompleteTime = "string"
    integer = "integer"
    float = "float"
    ;
run;
  
/* Some manual ADaM data type updates */
data metaadam.metadata_columns;
  set metaadam.metadata_columns;

  dataType = put(xml_datatype, $datatyp.);
  if dataType = "string" then json_length = length;

  /* Define-XML v2 does not support decimal, but it is supported by Dataset-JSON. */
  /* This update is just to show that it works in Dataset-JSON.                   */
  if xml_datatype in ('float' 'integer') and
     dataset_name in ('ADADAS' 'ADLBC' 'ADLBCPV' 'ADLBH' 'ADLBHPV' 'ADLBHY' 'ADNPIX' 'ADSL' 'ADVS') and
     name in ('PCHG' 'AVAL' 'BASE' 'CHG' 'PCHG' 'R2A1LO' 'R2A1HI' 'BR2A1LO' 'BR2A1HI' 'A1LO' 'A1HI' 'R2A1LO' 'R2A1HI' 'ALBTRVAL' 'LBSTRESN' 'HEIGHTBL' 'WEIGHTBL') 
     then do;
      dataType='decimal';
      targetDataType='decimal';
    end;  
    
/*
  if missing(length) then do;
    if xml_datatype="date" then length=10;
    if xml_datatype="partialDate" then length=10;
    if xml_datatype="partialDatetime" then length=19;
    if xml_datatype="durationDatetime" then length=19;
    if xml_datatype="datetime" then length=19;
  end;    
*/  
  if not missing(displayformat) then do;
    if substr(strip(reverse(upcase(name))), 1, 2) = "TD" then do;
      dataType = "date";
      targetDataType = "integer";
      displayformat = "E8601DA.";
    end;
    if substr(strip(reverse(upcase(name))), 1, 3) = "MTD" then do;
      dataType = "datetime";
      targetDataType = "integer";
      displayformat = "E8601DT.";
    end;
    if substr(strip(reverse(upcase(name))), 1, 2) = "MT" then do;
      dataType = "time";
      targetDataType = "integer";
      displayformat = "E8601TM.";
    end;
  end;  

run;


/* Some manual SDTM data type updates */
data metasdtm.metadata_columns;
  set metasdtm.metadata_columns;

  dataType = put(xml_datatype, $datatyp.);
  if dataType = "string" then json_length = length;

  /* Define-XML v2 does not support decimal, but it is supported by Dataset-JSON. */
  /* This update is just to show that it works in Dataset-JSON.                   */
  if xml_datatype='float' and name ne "VISITNUM" then do;
    dataType='decimal';
    targetdatatype = "decimal";
  end;  
/*
  if missing(length) then do;
    if xml_datatype="date" then length=10;
    if xml_datatype="partialDate" then length=10;
    if xml_datatype="partialDatetime" then length=19;
    if xml_datatype="durationDatetime" then length=19;
    if xml_datatype="datetime" then length=19;
  end;    
*/

run;


/* Some manual SEND data type updates */
data metasend.metadata_columns;
  set metasend.metadata_columns;

  dataType = put(xml_datatype, $datatyp.);
  if dataType = "string" then json_length = length;

  /* Define-XML v2 does not support decimal, but it is supported by Dataset-JSON. */
  /* This update is just to show that it works in Dataset-JSON.                   */
  if xml_datatype='float' and index(name, "STRESN") then do;
    dataType='decimal';
    targetdatatype = "decimal";
  end;  
/*
  if missing(length) then do;
    if xml_datatype="date" then length=10;
    if xml_datatype="partialDate" then length=10;
    if xml_datatype="partialDatetime" then length=19;
    if xml_datatype="durationDatetime" then length=19;
    if xml_datatype="datetime" then length=19;
  end;    
*/

run;


/*
libname metaadam clear;
libname metasdtm clear;
libname metasend clear;
*/  