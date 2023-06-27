import argparse
from os import listdir, getenv
from os.path import isfile, join
import json
import jsonschema as JSD

def validate_json(json_data, schema_file):
    """
    Validates a Dataset-JSON file against a defined json schema, given a schema_file

    Arguments:
        json_data: The resulting Dataset-JSON file to validate
        schema_file: Path to a schema file defining dataset-JSON schema
    """
    try:
        with open(schema_file) as f:
            schema = json.load(f)
        JSD.validate(json_data, schema=schema)
        print("  Ok!")
        return True
    except Exception as e:
        print(f"Error encountered while validating json schema: {e}")
        return False

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument( "-d", "--directory", help="Directory location for .json files", dest="directory", required=True)
    parser.add_argument( "-s", "--schemafile", help="Location for .json schema", dest="schemafile", required=True)
    return parser.parse_args()

if __name__ == "__main__":

    args = parse_args()

    schemafile = args.schemafile

    files = [join(args.directory,f) for f in listdir(args.directory) if isfile(join(args.directory, f))]
    print(f"Validating against schemafile {schemafile}")
    for f in files:
          isJson = f.find(".json")
          if isJson > 0:
            print(f"Validating {f}")
            validate_json(json.load(open(f, encoding="utf8")), schemafile)

