# Dataset-JSON SAS Implementation

This repository shows a SAS implementation for converting Dataset-JSON files to and from SAS datasets.
Example programs are in the **programs** folder.
It is recommended to run the test programs in the following order:

- 01_convert_xpt.sas
- 02_create_metadata_from_definexml.sas
- 03_write_datasetjson.sas
- 04_read_datasetjson.sas
- 05_compare_data.sas

The purpose of the test programs is to demonstrate the macros. The user at a minimum has to update the macro variable to points to the location of the clone of the repository:

```SAS
%* update this location to your own location;
%let project_folder=<your project location>;
```

Other updates in the test programs may be needed to make them work in a specific SAS environmnt. The macros should work in any SAS environment with at least SAS 9.4 (TS1M7).
This was tested on Windows 10 and SAS OnDemand (Linux).

Documentation is in the **doc** folder.

The **test_big_xpt** folder contains a SAS program to create a large XPT file (5Gb) from the XPT file **data/sdtm/lb.xpt**. The program will then create a Dataset-JSON file from that large XPT file, and also convert that large Dataset-JSON file back to a SAS dataset.

The **test_datetime** folder contains a SAS program to test numeric date/time variables.

## Issues

When encountering issues, please open an issue at [https://github.com/lexjansen/dataset-json-sas/issues](https://github.com/lexjansen/dataset-json-sas/issues).

## License

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
This project is using the [MIT](http://www.opensource.org/licenses/MIT "The MIT License | Open Source Initiative") license (see [`LICENSE`](LICENSE)).

The macros cstutilcheckvarsexist.sas, cstutilgetattribute.sas, cstutilnobs.sas, cstutilxptread.sas, cstutilxptwrite.sas are licensed under the [`Apache 2.0 License`](Apache-2.0-LICENSE).
