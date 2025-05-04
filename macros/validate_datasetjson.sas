proc fcmp outlib=&fcmplib..datasetjson_funcs.python;

  subroutine validate_datasetjson(jsonfile $, jsonschema $, datetime $, result_code, result_character $, result_path $);
  
    length jsonfile jsonschema $ 1024 
           datetime $32
           result_character resultMessage result_path resultPath $ 255 
           result_code 8;
    outargs datetime, result_code, result_character, result_path;
    declare object py4(python);
    submit into py4;
    def validatejson(jsonfile, jsonschema):
      """Output: dateTime, resultCode, resultMessage, resultPath"""
      
      import datetime
      import json
      import jsonschema as JSD
      
      dateTime = datetime.datetime.now().replace(microsecond=0).isoformat()
      try:
        jsonf = json.load(open(jsonfile, encoding="utf8"))
        with open(jsonschema) as s:
           schema = json.load(s)
        JSD.validate(jsonf, schema=schema)
        resultCode = 0
        resultMessage = "The document validated successfully"
        resultPath = ""
      except Exception as e:
        resultCode = 1
        resultMessage = str(e.message) + " (" + (e.schema['description']) +")"
        resultPath = str(e.json_path)
      return dateTime, resultCode, resultMessage, resultPath
        
    endsubmit;
    
    rc = py4.publish();
    rc = py4.call('validatejson', jsonfile, jsonschema);
    datetime = py4.results['dateTime'];
    result_code = py4.results['resultCode'];
    result_character = py4.results['resultMessage'];
    result_path = py4.results['resultPath'];
  endsub;

run;
