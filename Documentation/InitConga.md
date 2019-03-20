# InitConga

This is the documentation for the InitConga utility included in /Library/Conga/ beginning from Dyalog v17.1.


### Description

InitConga is a utility to initialize Conga 3.0 and later. Many tools like MiServer, HttpCommand, isolates, SAWS, and DFS, use Conga.  Conga 3.0 introduced the feature to allow many Conga "roots" to coexist.  InitConga is a utility that enables an application to initialize Conga when there may be other application components that also use Conga.  Using multiple roots enables the user to safely close his Conga instance without inadvertently impacting other components that also use Conga.  

### Syntax
```
      r ← {protect} InitConga args
```
#### Arguments
```
args is a list of: root {ref} {libpath} {wsname}

root is the Conga root name to look for or create.
    '' means 'DEFAULT' or 'DEFAULTn' if protect=2 (see below)

ref is the reference or character array for where to look for/copy the Conga namespace
    default is #
    '' means the location where the code is running (⎕CS '')

libpath is the optional path to the Conga shared library (.dll or .so file)
    default is '' and indicates to use the shared library in the Dyalog installation folder  
   
wsname is the workspace name from which to copy the Conga namespace if Conga is not found in ref
    default is 'conga'

protect is an optional integer flag indicating what to do when root is or is not found
    0 – (default) create the root if not found, use the existing root if it is found
    1 – create the root if not found, fail if it is found
    2 – create the root if not found, create a new "incremented" root if it is found
    3 – fail if the root is not found, use it if it is found
```
#### Result
```
r is a namespace containing information about the result of the operation and contains elements
   r.(rc msg rootref copied disposition)

r.rc is the return code indicating success (0) or the reason for failure
   0 - success
   1 - error while copying from wsname
   2 - Conga.LIB not found
   3 - invalid Conga reference
   4 - root already exists
   5 - root not found
   6 - Conga initialization failed

r.msg is a string giving more information about the result of the initialization operation

r.rootref is a reference to the created/found Conga.LIB instance

r.disposition is
   0 – root created
   1 – existing root used
   2 – incremented root created
  ¯1 - error

 r.copied indicates whether Conga was copied into the workspace
```

### Usage Notes
The root argument should be a name that is likely to be unique to your application. If you anticipate having only one instance of Conga in your application, it's safe to use '' as the root argument will cause Conga to use the default root name of 'DEFAULT'.

The ref argument indicates where InitConga should look for the Conga APL library.  If Conga is already in use in the workspace, ref can be used to point to the existing copy.

The libpath and wsname arguments will rarely, if ever, be used. They are intended primarily for users who may need to access versions of Conga other than the one installed with Dyalog APL. These users would typically be someone who is testing a new version of Conga.

r.rc should be checked to ensure that the 

r.rootref is the reference to the Conga library instance and should be used for subsequent Conga operations.
```APL
      r ← InitConga 'myApp' ⍝ create a Conga root for my application
      :If 0 ≠ r.rc          ⍝ check the return code
         →0 ⊣ ⎕←'Something went wrong! ',r.msg ⍝ r.msg has more detail as to what went wrong
      :EndIf
      myDRC ← r.rootref     
      myClt ← myDRC.Clt 'myClient' 'some.web.address' port_number ⍝ initialize my Conga client
      ...
```

### Example Use Cases
* The most common use case will be that you want to use Conga safely when other components in your application may also use Conga.
```APL
      r ← InitConga 'myApp'
```
* When you know this is the only use of Conga in your workspace
```APL
      DRC ← (InitConga '').rootref
``` 
* When the Conga namespace is already located somewhere known in the workspace
```APL
      DRC ← (InitConga 'myConga' #.SomewhereKnown).rootref