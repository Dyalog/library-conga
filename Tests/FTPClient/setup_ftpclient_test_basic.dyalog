 r←setup_ftpclient_test_basic dummy;home
⍝ Setup test
 ⎕IO←⎕ML←r←1
 :If 0=#.⎕NC'DRC' ⋄ 'DRC'#.⎕CY'conga' ⋄ :EndIf  ⍝ make sure conga is there...
 ⍝home←1⊃⎕NPARTS⊃(5177⌶⍬){∪((⊂⍵)≡¨1⊃¨⍺)/4⊃¨⍺}1⊃⎕si   ⍝ find source-file of current fn ()
 home←##.TESTSOURCE  ⍝ hopefully good enough...
 'Fixed ',#.⎕FIX'file://',home,'..\..\Conga\Library\FTPClient.dyalog'
 ⎕←'setup done'
