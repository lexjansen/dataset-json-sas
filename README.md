# Dataset-JSON SAS Implementation

This repository shows a SAS implementation for converting Dataset-JSON files to and from SAS datasets.
Example programs are in the **programs** folder.
It is recommended to run the test programs in the following order:

- 01_convert_xpt.sas
- 02_create_metadata_from_definexml.sas
- 03_test_write_json.sas
- 04_test_read_json.sas
- 05_compare_data.sas

Documentation in the **doc** folder is based on an earlier version of the code.

## License

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
This project is using the [MIT](http://www.opensource.org/licenses/MIT "The MIT License | Open Source Initiative") license (see [`LICENSE`](LICENSE)).
The macros cstutilcheckvarsexist.sas, cstutilgetattribute.sas, cstutilnobs.sas, cstutilxptread.sas, cstutilxptwrite.sas are licensed under the [`Apache 2.0 License`](Apache-2.0-LICENSE).
