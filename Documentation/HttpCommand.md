# HttpCommand

This is the documentation for the HttpCommand utility included with Dyalog APL versions 16.0 and later.

Example of use:

        ]load HttpCommand
    #.HttpCommand
        url←'http://hasthelargehadroncollider'
        url,←'destroyedtheworldyet.com/atom.xml'
        answer←HttpCommand.Get url
        xml←⎕XML answer.Data
        (xml[;2]∊⊂'content')⌿xml[;3] 
    NOPE.

## Tests

Tests are based on the v16.0 ]dtest user command. A normal Dyalog installation does not include
the test and documentation folders, but if you perform a full checkout of the library-conga repository
to a folder called library-conga, you should be able to run the unit tests as follows: 

    )copy conga
	]dtest library-conga/Tests/HttpCommand/unit
  