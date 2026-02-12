# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SAS implementation for converting Dataset-JSON files to/from SAS datasets per the CDISC Dataset-JSON v1.1 specification. Supports ADaM, SDTM, and SEND clinical data standards. Uses metadata-driven conversion with Define-XML.

Requires SAS 9.4 (TS1M7) or later. Tested on Windows 10 and SAS OnDemand (Linux).

## Running the Test Programs

Test programs in `programs/` must run in sequence (each depends on prior outputs):

```text
01_convert_xpt.sas          → XPT files to SAS datasets
02_create_metadata_from_definexml.sas → Extract metadata from Define-XML
03_update_metadata.sas       → Manual metadata type adjustments
04_write_datasetjson.sas     → SAS datasets to Dataset-JSON
05_read_datasetjson.sas      → Dataset-JSON back to SAS datasets
06_compare_data.sas          → Round-trip comparison
07_validate_datasetjson.sas  → JSON schema validation (requires Python)
```

Each program requires `%let project_folder=<path>;` set to the repo root. Shared config is in `programs/config.sas`.

On Windows with local SAS, run all via: `programs/runbatch.cmd` (requires editing the SAS executable path).

## Architecture

### Core Macros (`macros/`)

- **`write_datasetjson.sas`** — Converts a SAS dataset to Dataset-JSON. Delegates to version-specific internal macro (`write_datasetjson_1_1.sas`). Can use metadata from Define-XML or derive from the dataset itself.
- **`read_datasetjson.sas`** — Converts Dataset-JSON back to a SAS dataset. Optionally saves metadata to `metadata_study`, `metadata_tables`, `metadata_columns` tables.
- **`create_metadata_from_definexml.sas`** — Parses Define-XML using Lua (`lua/read_definexml.lua`) via PROC LUA to produce the three metadata tables.
- **`validate_datasetjson.sas`** — Validates JSON against `schema/dataset.schema1-1-0.json` using Python's `jsonschema` package via PROC FCMP.

### Internal Helpers (`macros/internal/`)

Type conversion macros (`convert_*.sas`), JSON map generation (`write_json_map.sas`), metadata array writing (`write_json_metadata_array.sas`), and zero-observation dataset handling (`create_zero_obs_dataset.sas`). The `cstutil*.sas` macros are CDISC utility macros (Apache 2.0 licensed).

### Metadata-Driven Design

The conversion pipeline is driven by three metadata tables:

- **`metadata_study`** — Study-level attributes (studyOID, metaDataVersionOID, etc.)
- **`metadata_tables`** — Dataset-level attributes (name, label, structure)
- **`metadata_columns`** — Variable-level attributes (name, type, length, format, decimal flag)

These are populated from Define-XML (step 02) and consumed by write/read macros.

### Lua Scripts (`lua/`)

- `read_definexml.lua` — Parses Define-XML 2.0/2.1 files to extract metadata
- `fileutils.lua`, `tableutils.lua` — Supporting utilities

### Python Integration

Only used for JSON schema validation (program 07). Requires `MAS_PYPATH` and `MAS_M2PATH` environment variables. Dependencies: `json`, `jsonschema` (see `requirements.txt`).

## Key Conventions

- SAS macro documentation uses Doxygen format (`@file`, `@brief`, `@param[in]`, `@param[out]`). Generate docs with `doxygen Doxyfile`.
- Error messages use split-token pattern: `%put ERR%str(OR):` to avoid triggering SAS error scanning.
- Library naming: `data*` (input data), `out*` (output data), `meta*` (metadata), `metasv*` (saved metadata from JSON), `results` (comparison/validation output). Suffixes: `adam`, `sdtm`, `send`.
- Data flows: `data/*_xpt/` → `data/` → `json_out/` → `data_out/`, with `metadata/` and `metadata_save/` as intermediaries.
