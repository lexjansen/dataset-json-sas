
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

    sas.filename('define', sas.symget("definexml"))
    
    local metadatalib = sas.symget("metadatalib")
    
    local define_string = fileutils.read('define')
    local define = sas.xml_parse(define_string)
    sas.symput('studyOID',define.Study["@OID"])
    sas.symput('metaDataVersionOID', define.Study.MetaDataVersion["@OID"])

    sas.new_table(metadatalib..'.metadata_study', {
      { name="fileoid", label="fileOID", type="C", length=128},
      { name="creationdatetime", label="CreationDatetime", type="C", length=32},
      { name="asofdatetime", label="AsOfDatetime", type="C", length=32},
      { name="originator", label="Originator", type="C", length=128},
      { name="sourcesystem", label="SourceSystem", type="C", length=128},
      { name="sourcesystemversion", label="SourceSystemVersion", type="C", length=128},
      { name="studyoid", label="studyOID", type="C", length=128},
      { name="metadataversionoid", label="metaDataVersionOID", type="C", length=128}
    })

    sas.new_table(metadatalib..'.metadata_tables', {
      { name="oid", label="OID", type="C", length=128},
      { name="name", label="Name", type="C", length=32},
      { name="label", label="Label", type="C", length=256},
      { name="domain", label="Name", type="C", length=32},
      { name="repeating", label="Repeating?", type="C", length=3},
      { name="isreferencedata", label="Is reference data?", type="C", length=3},
      { name="structure", label="Structure", type="C", length=256}      
    })

    sas.new_table(metadatalib..'.metadata_columns', {
      { name="dataset_name", label="Dataset Name", type="C", length=32},
      { name="oid", label="OID", type="C", length=128},
      { name="name", label="Name", type="C", length=32},
      { name="label", label="Label", type="C", length=256},
      { name="order", label="Order", type="N"},
      { name="xml_datatype", label="Define-XML DataType", type="C", length=32},
      { name="json_datatype", label="Dataset-JSON DataType", type="C", length=32},
      { name="length", label="Length", type="N"},
      { name="displayformat", label="Display format", type="C", length=32},
      { name="keysequence", label="Key sequence", type="N"}
    })

    dsid_s = sas.open(metadatalib..'.metadata_study', "u")
    sas.append(dsid_s)
    sas.put_value(dsid_s, "fileoid", define["@FileOID"])
    sas.put_value(dsid_s, "creationdatetime", define["@CreationDateTime"])
    if define["@AsOfDateTime"] then sas.put_value(dsid_s, "asofdatetime", define["@AsOfDateTime"]) end
    if define["@Originator"] then sas.put_value(dsid_s, "originator", define["@Originator"]) end
    if define["@SourceSystem"] then sas.put_value(dsid_s, "sourcesystem", define["@SourceSystem"]) end
    if define["@SourceSystemVersion"] then sas.put_value(dsid_s, "sourcesystemversion", define["@SourceSystemVersion"]) end
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

    dsid_t = sas.open(metadatalib..'.metadata_tables', "u")
    dsid_c = sas.open(metadatalib..'.metadata_columns', "u")
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
        if it['@KeySequence'] ~= nil then sas.put_value(dsid_c, "keySequence", tonumber(it['@KeySequence'])) end
        sas.put_value(dsid_c, "json_datatype", datatype_mapping[itemtbl[it['@ItemOID']].DataType])
        sas.update(dsid_c)
      end
      
    end
    sas.close(dsid_c)
    sas.close(dsid_t)
    
sas.filename('define')
