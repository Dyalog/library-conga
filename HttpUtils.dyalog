:Namespace HttpUtils  
⍝ Description::
⍝ This namespace is a work in progress and will contain utilities
⍝ to make it easier to manipulate and compose HTTP messages from Conga and HTMLRenderer
⍝ Expected release date is 26 June 2017 
⍝ Latest version can be obtained from https://github.com/Dyalog/library-conga 

    ⎕IO←⎕ML←1


    :section Constant Definitions

    CRLF←⎕UCS 13 10

    HttpStatuses←(200 'OK')(201 'Created')(204 'No Content')(301 'Moved Permanently')(302 'Found')(303 'See Other')(304 'Not Modified')(305 'Use Proxy')(307 'Temporary Redirect')
    HttpStatuses,←(400 'Bad Request')(401 'Unauthorized')(403 'Forbidden')(404 'Not Found')(405 'Method Not Allowed')(406 'Not Acceptable')(408 'Request Timeout')(409 'Conflict')
    HttpStatuses,←(410 'Gone')(411 'Length Required')(412 'Precondition Failed')(413 'Request Entity Too Large')(414 'Request-URI Too Long')(415 'Unsupported Media Type')
    HttpStatuses,←(500 'Internal Server Error')(501 'Not Implemented')(503 'Service Unavailable')
    HttpStatuses←↑HttpStatuses

    :endsection

    :section Date Utilities

    DateToIDN←{(2 ⎕NQ'.' 'DateToIDN'(3↑⍵))+86400000÷⍨24 60 60 1000⊥4↑3↓⍵}
    IDNToDate←{(3↑2 ⎕NQ '.' 'IDNToDate' (⌊⍵)),⌊.5+24 60 60 1000⊤86400000×1|⍵} ⍝ enhanced IDNToDate, inverse of DateToIDN
      DayOfWeek←{                                                             ⍝ day of week for ⎕TS, IDN, or 0-6 (=Mon-Sun)
          1<≢⍵:∇ 4⊃2 ⎕NQ'.' 'IDNToDate'(2 ⎕NQ'.' 'DateToIDN'(3↑⍵))
          ⍵>6:∇ 4⊃2 ⎕NQ'.' 'IDNToDate'(⌊⍵)
          3↑(⍵×3)↓'MonTueWedThuFriSatSun'
      }
    Month←{3↑(3×⍵-1)↓'JanFebMarAprMayJunJulAugSepOctNovDec'}                  ⍝ month abbreviation for RFC822 format timestamps
    Zpad←{⍺←2 ⋄ (-⍺)↑(⍺⍴'0'),⍕⍵}                                              ⍝ pad with leading 0 (zeros) - ⍺ is width (default = 2)
      Rfc822Datetime←{                                                        ⍝ RFC822 formatted timestamp
          0∊⍴⍵:⍵
          1=≢⍵:∇ IDNToDate ⍵
          (DayOfWeek ⍵),', ',(Zpad 3⊃⍵),' ',(Month 2⊃⍵),' ',(⍕1⊃⍵),' ',(1↓∊':',¨Zpad¨3↑3↓⍵),' GMT'}
    Quote←{'"'=1↑⍵:⍵ ⋄ '"',⍵,'"'}                                             ⍝ double quote ⍵ if not already so
    fine←{0∊⍴⍵:'' ⋄ '; ',⍺,'=',quote⍕⍵}                                       ⍝ fine = format if not empty
    reifs←{{2::(,∘⊂)⍣2>|≡⍵ ⋄ ,⊆⍵},⍵}                                          ⍝ ravel and enclose if simple

    :endsection

    :Class Cookie

        :field public name←''
        :field public value←''
        :field public expires←''
        :field public domain←''
        :field public path←''
        :field public secure←0
        :field public httpOnly←0

        U←(⊃⊃⎕CLASS ⎕THIS).## ⍝ ref to containing namespace

        ∇ make
          :Access public
          :Implements constructor
        ∇

        ∇ make1 args
          :Access public
          :Implements constructor
        ∇

        ∇ r←Format
          :Access public
          r←''
          :If 0≠≢name
              r,←name,'=',(U.Quote U.UrlEncode,⍕value)
              r,←'Expires'U.fine U.Rfc822Datetime expires
              r,←'Domain'U.fine domain
              r,←'Path'U.fine path
              r,←secure/'; Secure'
              r,←httpOnly/'; HttpOnly'
          :EndIf
        ∇

    :EndClass

    :class HttpRequest : HttpMessage
        :field public command
        :field public uri
        :field public host

        ∇ make
          :Access public
          :Implements constructor
        ∇

        ∇ make1 args
          :Access public
          :Implements constructor
        ⍝ args is one of:
        ⍝ '
        ∇

        ∇ {r}←AddHttpHeader hdr
          :Access public

        ∇

        ∇ {r}←AddHttpChunk chnk
          :Access public
        ∇

        ∇ {r}←AddHttpBody bod
          :Access public
        ∇

        ∇ {r}←AddHttpTrailer trl
          :Access public
        ∇

        ∇ {r}←AddHtmlRenderer args
          :Access public
          (url arguments)←ParseUrl 8⊃args
          headers←ParseHeaders 9⊃args
          cookies←ParseCookies headers
          headers ParseData 10⊃args ⍝ creates Data and Content
        ∇

        ∇ r←Format
          :Access public
          r←
        ∇

    :endclass

    :class HttpResponse : HttpMessage
        :field public httpStatus
        :field public httpStatusText

    :endclass

    :Class HttpMessage
    ⍝ this class can be used for both HTTP requests and responses
        :field public headers←0 2⍴⊂''
        :field public arguments←0 2⍴⊂''
        :field public data←0 2⍴⊂''
        :field public command←''
        :field public cookies←⍬
        :field public chunked←0
        :field public contentLength←¯1
        :field public contentType←''
        :field public transferEncoding←''
        :field public body←''
        :field public httpVersion←'HTTP/1.1'

        :field public shared readonly CRLF←⎕UCS 13 10



    :EndClass


    ∇ r←MakeChunk data
      ⍝ Make a block to send using "chunked" transfer-encoding
      :Access public shared
      r←(toHex≢data),CRLF,data,CRLF
    ∇

      Base64Encode←{
          ⎕IO←0
          raw←⊃,/11∘⎕DR¨⍵
          cols←6
          rows←⌈(⊃⍴raw)÷cols
          mat←rows cols⍴(rows×cols)↑raw
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'[⎕IO+2⊥⍉mat],(4|-rows)⍴'='
      }

      Base64Decode←{
          ⎕IO←0
          {
              80=⎕DR' ':⎕UCS ⍵  ⍝ Unicode
              82 ⎕DR ⍵          ⍝ Classic
          }2⊥{⍉((⌊(⍴⍵)÷8),8)⍴⍵}(-6×'='+.=⍵)↓,⍉(6⍴2)⊤'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='{⍺⍳⍵∩⍺}⍵
      }


    ∇ r←{name}UrlEncode data;⎕IO;z;ok;nul;m;noname
      ⍝
      ⍝ data is one of:
      ⍝      - a character vector to be encoded
      ⍝      - two character vectors of [name] [data to be encoded]
      ⍝      - a namespace containing variable(s) to be encoded
      ⍝ name is the optional name
      ⍝ r    is a character vector of the URLEncoded data
     
      ⎕IO←0
      noname←0
      :If 9.1=⎕NC⊂'data'
          data←{0∊⍴t←⍵.⎕NL ¯2:'' ⋄ ↑⍵{⍵(⍕,⍺⍎⍵)}¨t}data
      :Else
          :If 1≥|≡data
              :If noname←0=⎕NC'name' ⋄ name←'' ⋄ :EndIf
              data←name data
          :EndIf
      :EndIf
      nul←⎕UCS 0
      ok←nul,∊⎕UCS¨(⎕UCS'aA0')+⍳¨26 26 10
     
      z←⎕UCS'UTF-8'⎕UCS∊nul,¨,data
      :If ∨/m←~z∊ok
          (m/z)←↓'%',(⎕D,⎕A)[⍉16 16⊤⎕UCS m/z]
          data←(⍴data)⍴1↓¨{(⍵=nul)⊂⍵}∊z
      :EndIf
     
      r←noname↓¯1↓∊data,¨(⍴data)⍴'=&'
    ∇

    ∇ r←UrlDecode r;rgx;rgxu;i;j;z;t;m;⎕IO;lens;fill
      ⎕IO←0
      ((r='+')/r)←' '
      rgx←'[0-9a-fA-F]'
      rgxu←'%[uU]',(4×⍴rgx)⍴rgx ⍝ 4 characters
      r←(rgxu ⎕R{{⎕UCS 16⊥⍉16|'0123456789ABCDEF0123456789abcdef'⍳⍵}2↓⍵.Match})r
      :If 0≠⍴i←(r='%')/⍳⍴r
      :AndIf 0≠⍴i←(i≤¯2+⍴r)/i
          z←r[j←i∘.+1 2]
          t←'UTF-8'⎕UCS 16⊥⍉16|'0123456789ABCDEF0123456789abcdef'⍳z
          lens←⊃∘⍴¨'UTF-8'∘⎕UCS¨t  ⍝ UTF-8 is variable length encoding
          fill←i[¯1↓+\0,lens]
          r[fill]←t
          m←(⍴r)⍴1 ⋄ m[(,j),i~fill]←0
          r←m/r
      :EndIf
    ∇

    toHex←{⎕IO←0 ⋄ '0123456789ABCDEF'[⍵⊤⍨16⍴⍨{⌈⍵+0=1|⍵}16⍟⍵]}


    :Section Documentation Utilities
    ⍝ these are generic utilities used for documentation

    ∇ docn←ExtractDocumentationSections describeOnly;⎕IO;box;CR;sections
    ⍝ internal utility function
      ⎕IO←1
      CR←⎕UCS 13
      box←{{⍵{⎕AV[(1,⍵,1)/223 226 222],CR,⎕AV[231],⍺,⎕AV[231],CR,⎕AV[(1,⍵,1)/224 226 221]}⍴⍵}(⍵~CR),' '}
      docn←1↓⎕SRC ⎕THIS
      docn←1↓¨docn/⍨∧\'⍝'=⊃¨docn⍝ keep all contiguous comments
      docn←docn/⍨'⍝'≠⊃¨docn     ⍝ remove any lines beginning with ⍝⍝
      sections←{∨/'::'⍷⍵}¨docn
      :If describeOnly
          (sections docn)←((2>+\sections)∘/¨sections docn)
      :EndIf
      (sections/docn)←box¨sections/docn
      docn←∊docn,¨CR
    ∇

    ∇ r←Documentation
    ⍝ return full documentation
      :Access public shared
      r←ExtractDocumentationSections 0
    ∇

    ∇ r←Describe
    ⍝ return description only
      :Access public shared
      r←ExtractDocumentationSections 1
    ∇
    :EndSection
:EndNamespace
