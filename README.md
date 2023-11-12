# Dataset-JSON SAS Implementation

This repository shows a SAS implementation for converting Dataset-JSON files to and from SAS datasets.
Test programs are in the **programs** folder.
It is recommended to run the test programs in the following order:

- 01_convert_xpt.sas
- 02_create_metadata_from_definexml.sas
- 03_write_datasetjson.sas
- 04_read_datasetjson.sas
- 05_compare_data.sas
- 06_validate_datasetjson.sas

The purpose of the test programs is to demonstrate the macros. The user at a minimum has to update the macro variable that points to the location of the repository clone:

```SAS
%* update this location to your own location;
%let project_folder=<your project location>;
```

Other updates in the test programs may be needed to make them work in a specific SAS environment. The macros should work in any SAS environment with at least SAS 9.4 (TS1M7).
This was tested on Windows 10 and SAS OnDemand (Linux).

The **06_validate_datasetjson.sas** program assumes that your SAS environment is able to run Python objects. 
Check the programs/config.sas file for the Python cofiguration.
Python objects require environment variables to be set before you can use Python objects in your SAS environment. 
If the environment variables have not been set, or if they have been set incorrectly, 
SAS returns an error when you publish your Python code. 
Environment variable related errors can look like these examples:

```TEXT
ERROR: MAS_PYPATH environment variable is undefined.
ERROR: The executable C:\file-path\python.exe cannot be located
       or is not a valid executable.
```

In the **06_validate_datasetjson.sas** program you will need to update the evironment variables that configure the Python environment:

```TEXT
options set=MAS_PYPATH="<your Python executable>";
options set=MAS_M2PATH="<your SAS system root>/tkmas/sasmisc/mas2py.py";
```

Also, this program assumes that your Python environment has the following packages:

- json
- jsonschema

More information:

- [Using PROC FCMP Python Objects](https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/lecompobjref/p18qp136f91aaqn1h54v3b6pkant.htm)
- [Configuring SAS to Run the Python Language](https://go.documentation.sas.com/doc/en/bicdc/9.4/biasag/n1mquxnfmfu83en1if8icqmx8cdf.htm)

## Documentation

Documentation is in the **doc** folder:

- [CDISC COSA presentation, October 2023](doc/CDISC_COSA_webinar_20231005_dataset-json_SAS.pdf)
- [CDISC COSA Hackathon summary](doc/Dataset-JSON-Hackathon-SAS-implementation-LexJansen.pdf)
- [Detailed paper about this SAS Dataset-JSON implementation](doc/Working_with_Dataset-JSON_using_SAS.pdf)
- [Detailed slides about this SAS Dataset-JSON implementation](doc/Dataset-JSON-SAS-implementation.pdf)

## Additional programs

The **test_big_xpt** folder contains a SAS program to create a large XPT file (5Gb) from the XPT file **data/sdtm/lb.xpt**. The program will then create a Dataset-JSON file from that large XPT file, and also convert that large Dataset-JSON file back to a SAS dataset.

The **test_datetime** folder contains a SAS program to test numeric date/time variables.

## Issues

When encountering issues, please open an issue at [https://github.com/lexjansen/dataset-json-sas/issues](https://github.com/lexjansen/dataset-json-sas/issues).

## License

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
This project is using the [MIT](http://www.opensource.org/licenses/MIT "The MIT License | Open Source Initiative") license (see [`LICENSE`](LICENSE)).

The macros cstutilcheckvarsexist.sas, cstutilgetattribute.sas, cstutilnobs.sas, cstutilxptread.sas, cstutilxptwrite.sas are licensed under the [`Apache 2.0 License`](Apache-2.0-LICENSE).
