 r←{protect}InitConga args;root;ref;libpath;wsname;ref∆;roots;index;found
⍝ Initialize a Conga (3.0 or later) instance
⍝ Version: 1.0 21-March-2019
⍝
⍝ args is a list of: root {ref} {libpath} {wsname}
⍝
⍝ root is the Conga root name to look for or create.
⍝    '' means 'DEFAULT' or 'DEFAULTn' if protect=2 (see below)
⍝
⍝ ref is the reference or character array for where to look for/copy the Conga namespace
⍝    default is #
⍝    '' means the location where the code is running (⎕CS '')
⍝
⍝ libpath is the optional path to the Conga shared library
⍝    this would rarely be used, but it's useful in the case of trying to use a version of the library
⍝    other than what's in the used by someone wanting to run something other than the
⍝    default library – e.g. someone testing newer or older library versions.
⍝
⍝ wsname is the workspace name to ⎕CY Conga from if Conga is not found in ref
⍝    this is also an argument only someone using a new/old version of Conga might use
⍝    default is 'conga'
⍝
⍝ protect is an optional integer flag indicating what to do when root is or is not found
⍝    0 – (default) create the root if not found, use the existing root if it is found
⍝    1 – create the root if not found, fail if it is found
⍝    2 – create the root if not found, create a new "incremented" root if it is found
⍝    3 – fail if the root is not found, use it if it is found
⍝
⍝ r is a namespace containing information about the result of the operation
⍝
⍝ r.rc is the return code indicating success (0) or the reason for failure
⍝    0 - success
⍝    1 - error while copying from wsname
⍝    2 - Conga.LIB not found
⍝    3 - invalid Conga reference
⍝    4 - root already exists
⍝    5 - root not found
⍝    6 - Conga initialization failed
⍝
⍝ r.msg is
⍝
⍝ r.rootref is a reference to the created/found Conga.LIB instance
⍝
⍝ r.disposition is
⍝    0 – root created
⍝    1 – existing root used
⍝    2 – incremented root created
⍝   ¯1 - error
⍝
⍝ r.copied indicates whether Conga was copied into the workspace

 (root ref libpath wsname)←4↑(⊆args),'' '' '' ''

 :If 0=≢ref ⋄ ref←⎕CS'' ⋄ :EndIf
 :If 0=≢wsname ⋄ wsname←'conga' ⋄ :EndIf
 :If 0=⎕NC'protect' ⋄ protect←0 ⋄ :EndIf
 :If 0=≢root ⋄ root←'DEFAULT' ⋄ :EndIf

 r←⎕NS''
 r.(rootref rc disposition found copied msg)←⍬ ¯1 ¯1 0 0 ''  ⍝ initialize

sel:
 :Select ⎕NC⊂'ref'
 :Case 2.1 ⍝ variable
     ref←⍎∊⍕ref ⋄ →sel
 :CaseList 9.1 9.2 9.4 ⍝ namespace, class, or instance
     :If r.found←9.1=ref.⎕NC⊂'Conga'
         ref∆←ref.Conga
     :Else
         :Trap 0
             'Conga'ref.⎕CY libpath,wsname
             r.copied←1 ⋄ ref∆←ref.Conga
         :Else ⋄ →0⊣r.(rc msg)←1 ⎕DMX.(2↓∊': '∘,¨EM Message)
         :EndTrap
     :EndIf
 :Else
     →0⊣r.(rc msg)←3 '"ref" is not a valid reference location for Conga' ⍝ invalid reference
 :EndSelect

 :If 9.4≠ref∆.⎕NC⊂'LIB' ⋄ →0⊣r.(rc msg)←2 '"ref" does not refer to a valid Conga namespace' ⋄ :EndIf

 :If 0<≢roots←⎕INSTANCES ref∆.LIB
     (index found)←roots.RootName{(≢⍺){⍵,⍵≤⍺}⍺⍳⍵}⊆root
     :If found ⋄ r.rootref←index⊃roots ⋄ :EndIf
 :Else
     (index found)←1 0
 :EndIf

 r.disposition←found

 :Select protect
 :Case 0 ⍝    0 (default) – create the root if not found, use the existing root if it is found
     :If found
         →r.(rc msg)←0('Existing Conga root "',r.rootref.RootName,'" used')
     :EndIf

 :Case 1 ⍝    1 – create the root if not found, fail if it is found
     :If found
         →0⊣r.(rc disposition rootref msg)←4 ¯1 ⍬('Conga root "',r.rootref.RootName,' already exists')
     :EndIf

 :Case 2 ⍝    2 – create the root if not found, create a new "incremented" root if it is found
     :If found ⍝ Increment root
         root,←,'ZI4'⎕FMT 1+⌈/∊0,2⊃¨⎕VFI¨(≢root)↓¨root{⍵/⍨⊃¨⍺∘⍷¨⍵}roots.RootName
         r.disposition←2
     :EndIf

 :Case 3 ⍝    3 – fail if the root is not found, use it if it is found
     :If ~found
         →0⊣r.(rc msg)←5('Conga root "',root,'" not found')
     :EndIf
 :EndSelect

 :Trap 999
     r.rootref←libpath ref∆.Init root
     r.(rc msg)←0('Conga root "',r.rootref.RootName,'" created')
 :Else
     r.(rc msg)←6('Error attempting to initialize Conga root "',root,'"')
 :EndTrap
