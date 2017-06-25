 r←setup_httpcommand_test_basic dummy;home
⍝ Setup test
 ⎕IO←⎕ML←1
 r←''
 :Trap 0
     home←##.TESTSOURCE  ⍝ hopefully good enough...
     {}#.⎕FIX'file://',home,'../../HttpCommand.dyalog'
     {}#.⎕FIX'file://',home,'test_httpcommand.dyalog'
 :Else
     r←,⍕⎕DM
 :EndTrap
