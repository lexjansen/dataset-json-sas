proc fcmp outlib=&fcmplib..datasetjson_funcs.python;

  subroutine validate_datasetjson(jsonfile $, jsonschema $, result_code, result_character $, result_path $);
  
    length jsonfile jsonschema $ 1024 
           result_character resultMessage result_path resultPath $ 255 
           result_code 8;
    outargs result_code, result_character, result_path;
    declare object py4(python);
    submit into py4;
    def validatejson(jsonfile, jsonschema):
      """Output: resultCode, resultMessage, resultPath"""
      
      import json
      import jsonschema as JSD
      
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
      return resultCode, resultMessage, resultPath
        
    endsubmit;
    
    rc = py4.publish();
    rc = py4.call('validatejson', jsonfile, jsonschema);
    result_code = py4.results['resultCode'];
    result_character = py4.results['resultMessage'];
    result_path = py4.results['resultPath'];
  endsub;

run;
