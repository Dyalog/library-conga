# FtpClient

This is the documentation for the FtpClient utility included with Dyalog APL versions 16.0 and later.

Example of use:

            )copy conga
	  saved...
            ]load FtpClient
	  #.FtpClient
	        ms←⎕NEW #.FtpClient(host user pass) 
			ms.List 'pub/'
      0  pub/FreeBSD
      pub/GNOME
      pub/NetBSD
      ...

## Tests

Tests are based on the v16.0 ]dtest user command. A normal Dyalog installation does not include
the test and documentation folders, but if you perform a full checkout of the library-conga repository
to a folder called library-conga, you should be able to run the unit tests as follows: 

    )copy conga
	]dtest library-conga/Tests/FTPClient/unit
  