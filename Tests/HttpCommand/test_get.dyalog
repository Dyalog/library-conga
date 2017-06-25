 {r}←test_get dummy;t
 t←#.test_httpcommand
 r←0 200 t.check(#.HttpCommand.Get t._httpbin,'/get').(rc HttpStatus)
