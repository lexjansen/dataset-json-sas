proc fcmp outlib=&fcmplib..datasetjson_funcs.python;

  subroutine validate_datasetjson(jsonfile $, jsonschema $, result_code, result_character $);
  
    length jsonfile jsonschema $ 1024 result_character resultMessage $ 2000 result_code 8;
    outargs result_code, result_character;
    declare object py4(python);
    submit into py4;
    def validatejson(jsonfile, jsonschema):
      """Output: resultCode, resultMessage"""
      
      import json
      import jsonschema as JSD
      
      try:
        jsonf = json.load(open(jsonfile, encoding="utf8"))
        with open(jsonschema) as s:
           schema = json.load(s)
        JSD.validate(jsonf, schema=schema)
        resultCode = 0
        resultMessage = "The document validated successfully"
        return resultCode, resultMessage
      except Exception as e:
        resultMessage = str(e)
        resultCode = 1
        return resultCode, resultMessage
        
    endsubmit;
    
    rc = py4.publish();
    rc = py4.call('validatejson', jsonfile, jsonschema);
    result_code = py4.results['resultCode'];
    result_character = py4.results['resultMessage'];
  endsub;

run;
