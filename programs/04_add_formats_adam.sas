%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";


%add_formats(
  metadata = metaadam.metadata_columns,
  datalib = dataadam,
  condition = %str(not missing(displayFormat) and dataType = "date" and targetDataType = "integer"),
  format = "E8601DA."
);