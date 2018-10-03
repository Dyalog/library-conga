 {r}←test_get_url dummy;t;z
 ⍝ test url arguments
 t←#.httpcommand_test
 →0↓⍨0∊⍴r←0 200 t.check(z←#.HttpCommand.Get t._httpbin,'get?one=test&two=two%20words').(rc HttpStatus)
 :Trap 0
     r←(⎕JSON z.Data).args.(one two)t.check'test' 'two words'
 :Else
     r←''t.check(⊃⎕DM)
 :EndTrap
