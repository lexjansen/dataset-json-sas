%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;


%let model=sdtm;
filename define "&root/json/&model/define.xml";

%*let model=adam;
*filename define "&root/json/&model/define_2_0.xml";

libname metadata "&root/metadata/&model";
%include "&root/test/config.sas";


%* Get metadata from Define-XML ;
proc lua restart;
  submit;

    print("Lua version: ".._VERSION)
    local fileutils = require "fileutils"
    local tableutils = require "tableutils"

    -- this is a very rough mapping, it does not take decimal into account
    local datatype_mapping = {
            text = "string",
            date = "string",
            datetime = "string",
            time = "string",
            URI = "string",
            partialDate = "string",
            partialTime = "string",
            partialDatetime = "string",
            durationDatetime = "string",
            intervalDatetime = "string",
            incompleteDatetime = "string",
            incompleteDate = "string",
            incompleteTime = "string",
            integer = "integer",
            float = "float"            
          }

    local define_string = fileutils.read('define')
    local define = sas.xml_parse(define_string)
    sas.symput('studyOID',define.Study["@OID"])
    sas.symput('metaDataVersionOID', define.Study.MetaDataVersion["@OID"])

    sas.new_table('metadata.metadata_study', {
      { name="studyoid", label="studyOID", type="C", length=128},
      { name="metadataversionoid", label="metaDataVersionOID", type="C", length=128}
    })

    sas.new_table('metadata.metadata_tables', {
      { name="oid", label="OID", type="C", length=128},
      { name="name", label="Name", type="C", length=32},
      { name="label", label="Label", type="C", length=256},
      { name="domain", label="Name", type="C", length=32},
      { name="repeating", label="Repeating?", type="C", length=3},
      { name="isreferencedata", label="Is reference data?", type="C", length=3},
      { name="structure", label="Structure", type="C", length=256}      
    })

    sas.new_table('metadata.metadata_columns', {
      { name="dataset_name", label="Dataset Name", type="C", length=32},
      { name="oid", label="OID", type="C", length=128},
      { name="name", label="Name", type="C", length=32},
      { name="label", label="Label", type="C", length=256},
      { name="order", label="Order", type="N"},
      { name="xml_datatype", label="Define-XML DataType", type="C", length=32},
      { name="json_datatype", label="Dataset-JSON DataType", type="C", length=32},
      { name="length", label="Length", type="N"},
      { name="displayformat", label="Display format", type="C", length=32} 
    })

    dsid_s = sas.open('metadata.metadata_study', "u")
    sas.append(dsid_s)
    sas.put_value(dsid_s, "studyoid", define.Study["@OID"])
    sas.put_value(dsid_s, "metadataversionoid", define.Study.MetaDataVersion["@OID"])
    sas.update(dsid_s)
    sas.close(dsid_s)

    local itemtbl = {}
    for i, it in ipairs(define.Study.MetaDataVersion.ItemDef) do
      items = {}
      items["Name"] = it['@Name']
      if it.Description then items["Description"] = it.Description.TranslatedText[1] end
      items["DataType"] = it['@DataType']
      items["Length"] = tonumber(it['@Length'])
      items["DisplayFormat"] = it['@DisplayFormat'] 
      itemtbl[it['@OID']] = items
    end

    -- print(tableutils.tprint(itemtbl))
    -- print(tableutils.tprint(define.Study.MetaDataVersion.ItemGroupDef))

    dsid_t = sas.open('metadata.metadata_tables', "u")
    dsid_c = sas.open('metadata.metadata_columns', "u")
    local tbl = {}
    for i, itgd in ipairs(define.Study.MetaDataVersion.ItemGroupDef) do
      sas.append(dsid_t)
      sas.put_value(dsid_t, "OID", itgd['@OID'])
      sas.put_value(dsid_t, "name", itgd['@Name'])
      if itgd.Description then sas.put_value(dsid_t, "label", itgd.Description.TranslatedText[1]) end
      sas.put_value(dsid_t, "domain", itgd['@Domain'])
      sas.put_value(dsid_t, "repeating", itgd['@Repeating'])
      sas.put_value(dsid_t, "isreferencedata", itgd['@IsReferenceData'])
      sas.put_value(dsid_t, "structure", itgd['@Structure'])
      sas.update(dsid_t)
      
      itemref = itgd.ItemRef
      for j, it in ipairs(itemref) do
        sas.append(dsid_c)
        sas.put_value(dsid_c, "dataset_name", itgd['@Name'])
        sas.put_value(dsid_c, "OID", it['@ItemOID'])
        sas.put_value(dsid_c, "name", itemtbl[it['@ItemOID']].Name)
        sas.put_value(dsid_c, "label", itemtbl[it['@ItemOID']].Description)
        sas.put_value(dsid_c, "xml_datatype", itemtbl[it['@ItemOID']].DataType)
        sas.put_value(dsid_c, "order", tonumber(it['@OrderNumber']))
        if tonumber(itemtbl[it['@ItemOID']].Length) ~= nil then sas.put_value(dsid_c, "length", itemtbl[it['@ItemOID']].Length) end
        if itemtbl[it['@ItemOID']].DisplayFormat ~= nil then sas.put_value(dsid_c, "DisplayFormat", itemtbl[it['@ItemOID']].DisplayFormat) end
        sas.put_value(dsid_c, "json_datatype", datatype_mapping[itemtbl[it['@ItemOID']].DataType])
        sas.update(dsid_c)
      end
      
    end
    sas.close(dsid_c)
    sas.close(dsid_t)
    
  endsubmit;
run;


libname metadata clear;


* Some manual data type updates;
libname metasdtm "&root/metadata/sdtm";
data metasdtm.metadata_columns;
  set metasdtm.metadata_columns;
  if xml_datatype='float' then do;
    if name ne 'LBSTRESN' then json_datatype='decimal';
  end;
run;
libname metasdtm clear;

libname metaadam "&root/metadata/adam";
data metaadam.metadata_columns;
  set metaadam.metadata_columns;
  if xml_datatype='float' then do;
    if index(name, 'VISIT') then json_datatype='decimal';
  end;
run;
libname metaadam clear;
  