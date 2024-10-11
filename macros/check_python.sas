/**
  @file check_python.sas
  @brief Checks that your SAS environment is able to run Python objects.

  @details
  This macro checks that your SAS environment is able to run Python objects.
  Check the programs/config.sas file for the Python configuration.

  It will check that the following environment variables have been defined
  and reference existing files:
      @li MAS_PYPATH
      @li MAS_M2PATH

  Python objects require environment variables to be set before you can use Python objects in your SAS environment.
  If the environment variables have not been set, or if they have been set incorrectly,
  SAS returns an error when you publish your Python code. Environment variable related errors can look like these examples:

      ERROR: MAS_PYPATH environment variable is undefined.
      ERROR: The executable /file-path/python.exe cannot be located or is not a valid executable.

  Python code may require specific Python packages to be in your Python environment.
  For example, the validate_datasetjson.sas macro assumes that your Python environment has the following packages:
    - json
    - jsonschema

  More information:
    Using PROC FCMP Python Objects:
    https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/lecompobjref/p18qp136f91aaqn1h54v3b6pkant.htm

    Configuring SAS to Run the Python Language:
    https://go.documentation.sas.com/doc/en/bicdc/9.4/biasag/n1mquxnfmfu83en1if8icqmx8cdf.htm

  @author Lex Jansen

**/
%macro check_python() / des = 'Checks that your SAS environment is able to run Python objects';

  %local
    _MAS_PYPATH
    _MAS_M2PATH
    ;

  %if %symexist(python_installed) %then %do;
  %end;
  %else %do;
    %global python_installed;
  %end;   
  %let python_installed = 0;

  %let _MAS_PYPATH = %sysget(MAS_PYPATH);
  %let _MAS_M2PATH = %sysget(MAS_M2PATH);

  %if %sysevalf(%superq(_MAS_PYPATH)=, boolean) %then %do;
    %put ERR%str(OR): [&sysmacroname] Environment variable MAS_PYPATH has not been defined. %str
      ()As a result, Python scripts cannot be executed.;
    %goto exit_macro;
  %end;
  %if %sysevalf(%superq(_MAS_M2PATH)=, boolean) %then %do;
    %put ERR%str(OR): [&sysmacroname] Environment variable MAS_M2PATH has not been defined. %str
      ()As a result, Python scripts cannot be executed.;
    %goto exit_macro;
  %end;

  %if %sysfunc(fileexist(&_MAS_PYPATH)) = 0 %then %do;
    %put ERR%str(OR): [&sysmacroname] File &_MAS_PYPATH does not exist. %str
      ()As a result, Python scripts cannot be executed.;
    %goto exit_macro;
  %end;

  %if %sysfunc(fileexist(&_MAS_M2PATH)) = 0 %then %do;
    %put ERR%str(OR): [&sysmacroname] File &_MAS_M2PATH does not exist. %str
      ()As a result, Python scripts cannot be executed.;
    %goto exit_macro;
  %end;

  %put MAS_PYPATH = &_MAS_PYPATH;
  %put MAS_M2PATH = &_MAS_M2PATH;

  %let python_installed = 1;

  %exit_macro:
  
  %put &=python_installed;

%mend check_python;
