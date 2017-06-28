# library-conga

This repository contains files which provide frequently used tools,
based on the core communication library for Dyalog APL, known as "Conga".

Installations of Dyalog APL from version 16.0 (June 2017) will contain 
the files found in the root of the library-conga repository in the folder
 Library/Conga below the main Dyalog folder.

## Documentation

The Documentation folder (not installed with Dyalog APL but available on
GitHub) contains documentation for the individual files.

## Tests

Tests are based on the v16.0 ]dtest user command. Each subfolder below the Tests contains a set of unit tests, which can be run using for example:

    ]dtest library-conga/Tests/FTPClient/unit
  