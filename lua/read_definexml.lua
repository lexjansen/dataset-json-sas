
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

    function writecolumn(dsid_c,itgd,it,itemtbl)
      sas.append(dsid_c)
      sas.put_value(dsid_c, "dataset_name", itgd['@Name'])
      sas.put_value(dsid_c, "OID", it['@ItemOID'])
      sas.put_value(dsid_c, "name", itemtbl[it['@ItemOID']].Name)
      sas.put_value(dsid_c, "label", itemtbl[it['@ItemOID']].Description)
      sas.put_value(dsid_c, "xml_datatype", itemtbl[it['@ItemOID']].DataType)
      sas.put_value(dsid_c, "order", tonumber(it['@OrderNumber']))
      if tonumber(itemtbl[it['@ItemOID']].Length) ~= nil then sas.put_value(dsid_c, "length", itemtbl[it['@ItemOID']].Length) end
      if itemtbl[it['@ItemOID']].DisplayFormat ~= nil then sas.put_value(dsid_c, "DisplayFormat", itemtbl[it['@ItemOID']].DisplayFormat) end
      if it['@KeySequence'] ~= nil then -- Define-XML 2.x
        sas.put_value(dsid_c, "keySequence", tonumber(it['@KeySequence']))
      end
      if itgd['@DomainKeys'] and it['@KeySequence'] == nil then -- Define-XML 1.0
        i = 0
        for key in itgd['@DomainKeys']:gmatch('[^,%s]+') do
          i = i + 1
          if key == itemtbl[it['@ItemOID']].Name then sas.put_value(dsid_c, "keySequence", i) end
        end
      end
      sas.update(dsid_c)
    end

    sas.filename('define', sas.symget("definexml"))

    local metadatalib = sas.symget("metadatalib")
    local define_string = fileutils.read('define')
    local define = sas.xml_parse(define_string)

    sas.submit[[
       %create_template(type=STUDY, out=@metadatalib@.metadata_study);
    ]]
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
    sas.put_value(dsid_s, "definexmlversion", define.Study.MetaDataVersion["@DefineVersion"])
    sas.update(dsid_s)
    sas.close(dsid_s)

    local itemtbl = {}
    for i, it in ipairs(define.Study.MetaDataVersion.ItemDef) do
      items = {}
      items["Name"] = it['@Name']
      if it.Description
        then items["Description"] = it.Description.TranslatedText[1]
      elseif it['@Label']
        then items["Description"] = it['@Label']
      end
      items["DataType"] = it['@DataType']
      items["Length"] = tonumber(it['@Length'])
      items["DisplayFormat"] = it['@DisplayFormat']
      itemtbl[it['@OID']] = items
    end

    -- print(tableutils.tprint(itemtbl))
    -- print(tableutils.tprint(define.Study.MetaDataVersion.ItemGroupDef))

    sas.submit[[
       %create_template(type=TABLES, out=@metadatalib@.metadata_tables);
    ]]
    dsid_t = sas.open(metadatalib..'.metadata_tables', "u")
    sas.submit[[
       %create_template(type=COLUMNS, out=@metadatalib@.metadata_columns);
    ]]
    dsid_c = sas.open(metadatalib..'.metadata_columns', "u")
    local tbl = {}
    for i, itgd in ipairs(define.Study.MetaDataVersion.ItemGroupDef) do
      sas.append(dsid_t)
      sas.put_value(dsid_t, "OID", itgd['@OID'])
      sas.put_value(dsid_t, "name", itgd['@Name'])
      if itgd.Description
        then sas.put_value(dsid_t, "label", itgd.Description.TranslatedText[1])
      elseif itgd['@Label']
        then sas.put_value(dsid_t, "label", itgd['@Label'])
      end
      sas.put_value(dsid_t, "domain", itgd['@Domain'])
      sas.put_value(dsid_t, "repeating", itgd['@Repeating'])
      sas.put_value(dsid_t, "isreferencedata", itgd['@IsReferenceData'])
      sas.put_value(dsid_t, "structure", itgd['@Structure'])
      if itgd['@DomainKeys'] then
        sas.put_value(dsid_t, "domainkeys", itgd['@DomainKeys'])
      end
      if itgd['@IsReferenceData'] == "Yes"
        then sas.put_value(dsid_t, "datasettype", "ReferenceData")
      end
      sas.update(dsid_t)

      if type(itgd.ItemRef) == "table" then
        itemref = itgd.ItemRef
        for j, it in ipairs(itemref) do
          writecolumn(dsid_c,itgd,it,itemtbl)
        end
      elseif itgd['name'] == "ItemRef" then
        writecolumn(dsid_c,define.Study.MetaDataVersion.ItemGroupDef,itgd,itemtbl)
      end

    end
    sas.close(dsid_c)
    sas.close(dsid_t)

sas.filename('define')
