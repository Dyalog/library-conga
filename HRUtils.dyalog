:Namespace HRUtils
⍝ Description::
⍝ This namespace contains utilities to make it easier to work with HTMLRenderer HTTPRequest events
⍝
⍝ Latest version of this file can be obtained from https://github.com/Dyalog/library-conga
⍝
⍝ Overview::
⍝   Please refer to the HTMLRenderer User Guide for more information

    ∇ r←Version
      r←'HRUtils' '1.0' '2020-05-26'
    ∇

    ⎕IO←⎕ML←1

    ∇ r←Request args
    ⍝ args is the event message from HTTPRequest event
      r←⎕NEW HttpRequest args
    ∇

⍝ ────────────────────────────────────────────────────────────────────────────────

    :class HttpRequest
    ⍝ HttpRequest::
        :field public Headers←0 2⍴⊂''
        :field public QueryData←0 2⍴⊂''   ⍝ data passed in the query portion of the URI
        :field public FormData←0 2⍴⊂''    ⍝ form data passed in the body
        :field public Method←''           ⍝ the HTTP method
        :field public Cookies←0 2⍴⊂''     ⍝ [;1] name, [;2] value
        :field public Uri←''              ⍝ the URI (URL) for the request
        :field public Content←''          ⍝ the content (payload) for the request
        :field public Response            ⍝ instance of HttpResponse
        :field public HttpVersion←'HTTP/1.1'
        :field public HTMLRendererArgs    ⍝ namespace containing original HTTPRequest callback arguments
        :field public BaseUrl←'http://dyalog_root/' ⍝ default base URL

        :field public shared readonly CRLF←⎕UCS 13 10
        :field public shared readonly U←(⊃⊃⎕CLASS ⎕THIS).## ⍝ ref to containing namespace

        ∇ VersionCheck
          'HRUtils requires Dyalog v18.0 or later'⎕SIGNAL 11/⍨18>U.APLVersion
        ∇

        ∇ make
          :Access public
          :Implements constructor
          VersionCheck
        ∇

        ∇ make1 args;h;b;Params
          :Access public
          :Implements constructor
        ⍝  args: 11-element vector as returned in the HTTPRequest event of HTMLRenderer
          VersionCheck
          FromHTMLRenderer args
        ∇

        ∇ {baseUrl}FromHTMLRenderer args
          :Access public
          HTMLRendererArgs←⎕NS''
          HTMLRendererArgs.(obj event op intercept scode stext mime url header content method)←11↑args,⊂''
          :If 0≠⎕NC'baseUrl'
              BaseUrl←baseUrl
          :EndIf
          (Uri QueryData)←BaseUrl ParseUrl HTMLRendererArgs.url
          Method←HTMLRendererArgs.method
          Headers←ParseHeaders HTMLRendererArgs.header
          ProcessCookies
          Headers ParseData HTMLRendererArgs.content ⍝ creates Data and Content
          :If 'GET'≡Method
          :AndIf 0∊⍴FormData ⍝ there should be no form data with a GET, but just to be paranoid...
              FormData←QueryData
          :EndIf
          Response←⎕NEW HttpResponse args
        ∇

        ∇ ProcessCookies;cookie
        ⍝ add cookies from 'cookie' header
          :Access public
          :If ~0∊⍴cookie←GetHeader'cookie'
              AddCookie¨cookie←CookieSplit cookie
          :EndIf
        ∇

        ∇ (page arguments)←baseUrl ParseUrl u;args
        ⍝ Parse the URL element from HTMLRenderer
          (page arguments)←'?'U.splitFirst u
          page←U.UrlDecode{3↓⍵/⍨∨\'://'⍷⍵}page ⍝ drop off http{s}://
          page↓⍨←(≢baseUrl)×baseUrl U.begins page
          arguments←DecodeUrlArgs arguments
        ∇

        ∇ r←GetHeader name
        ⍝ retrieve header values by name
          :Access public
          r←Headers Get name
        ∇

        ∇ hdrs←ParseHeaders h
        ⍝ Parse HTTP headers from HTMLRenderer
          hdrs←↑':'U.splitFirst¨(⎕UCS 10)(≠⊆⊢)h
          hdrs[;1]←U.lc¨hdrs[;1]  ⍝ header names are case insensitive
          hdrs[;2]←U.deb¨hdrs[;2] ⍝ header data
        ∇

        ∇ hdrs ParseData data;z;mask;new;s
        ⍝ Parse any data passed in the request body
        ⍝ we only parse a couple of MIME types
        ⍝ otherwise we put the data in Content
          :If 'multipart/form-data'U.begins z←Headers Get'content-type'
              z←'--',(8+('boundary='⍷z)⍳1)↓z ⍝ boundary string
              FormData←↑U.DecodeMultiPart¨¯1↓z{(⍴⍺)↓¨(⍺⍷⍵)⊂⍵}data ⍝ ¯1↓ because last boundary has '--' appended
          :ElseIf 'application/x-www-form-urlencoded'U.begins z
              FormData←DecodeUrlArgs data
          :Else
              Content←data
          :EndIf
        ∇

        ∇ r←{cs}DecodeUrlArgs args
          :Access Public Shared
          cs←{6::⍵ ⋄ cs}1 ⍝ default to case sensitive
          r←(args∨.≠' ')⌿↑'='∘U.splitFirst¨{(⍵≠'&')⊆⍵},args ⍝ Cut on '&'
          r[;1]←{⍵↓⍨¯6×'%5B%5D'≡¯6↑⍵}¨r[;1] ⍝ remove [] from array args
          r[;2]←U.UrlDecode¨r[;2]
          :If ~cs ⋄ r[;1]←U.lc¨r[;1] ⋄ :EndIf
        ∇

        ∇ value←{table}Get name
          :Access public
          :If 0=⎕NC'table' ⋄ table←FormData ⋄ :EndIf
          value←(table[;1](⍳⍥⎕C)⊂name)⊃table[;2],⊂''
        ∇

        ∇ r←Respond
          :Access public
          r←Response.Respond
        ∇

        ∇ r←CookieSplit cookie
          r←{1↓¨(~'; '⍷⍵)⊆⍵}' ',cookie
        ∇

        ∇ AddCookie cookie
          Cookies⍪←(⎕NEW Cookie cookie).(Name Value)
        ∇

    :EndClass

⍝ ────────────────────────────────────────────────────────────────────────────────

    :Class HttpResponse
        :Field public HttpStatus←200
        :Field public HttpStatusText←'OK'
        :Field public HTMLRendererArgs
        :Field public FileName←''
        :Field public Content←''
        :Field public ContentType←''
        :Field public Headers←0 2⍴⊂''
        :field public Cookies←⍬

        :field public shared readonly CRLF←⎕UCS 13 10
        :field public shared readonly U←(⊃⊃⎕CLASS ⎕THIS).## ⍝ ref to containing namespace

        ∇ make
          :Access public
          :Implements constructor
        ∇

        ∇ make1 args;h;b
          :Access public
          :Implements constructor
        ⍝ args is an 11-element vector as returned in the HTTPRequest event of HTMLRenderer
          HTMLRendererArgs←⎕NS''
          HTMLRendererArgs.(obj event op intercept scode stext mime url header content method)←11↑args,⊂''
        ∇

        ∇ r←Respond
          :Access public
          :If ~0∊⍴FileName ⍝ if we've specified a file name
          :AndIf 0∊⍴Content ⍝ and have not specified content...
              (HttpStatus HttpStatusText Content)←ReadFile FileName
          :EndIf
          r←10⍴⊂''
          r[1 2]←HTMLRendererArgs.(obj event)
          r[4]←1
          r[5 6]←HttpStatus HttpStatusText
          r[7]←⊂'text/html'{(0∊⍴⍵)∧0∊⍴FileName:⍺ ⋄ ⍵}Headers Get'content-type'
          r[9]←⊂FormatHeaders
          r[10]←⊂Content
        ∇

        ∇ (stat msg content)←ReadFile filename
          :Access public shared
          content←'' ⋄ (stat msg)←200 'OK'
          :Trap 22
              content←{(⎕NUNTIE ⍵)⊢⎕NREAD ⍵,83 ¯1}filename ⎕NTIE 0
          :Else
              (stat msg)←404 'Not Found'
          :EndTrap
        ∇

        ∇ value←table Get name
          :Access public
          value←(table[;1](⍳⍥⎕C)⊂name)⊃table[;2],⊂''
        ∇

        ∇ name AddHeader value
        ⍝ add a header unless it's already defined
          :Access public
          Headers←name(Headers addToTable)value
        ∇

        ∇ AddCookie args
        ⍝ add a Cookie to the response
        ⍝ args is either
        ⍝   - a simple string formatted cookie setting
        ⍝   - a vector of attributes - Name Value [Expires Domain Path Secure HttpOnly]
          :Access public
          Cookies,←⎕NEW Cookie args
        ∇

        ∇ r←FormatHeaders
          :Access public
          r←fmtHeaders Headers
          r,←fmtCookies Cookies
        ∇

        firstCaps←{1↓{(¯1*'-'≠⍵) ⎕C¨ ⍵}'-',⍵} ⍝ capitalize first letters e.g. Content-Encoding
        fmtHeaders←{0∊⍴⍵:'' ⋄ ∊{0∊⍴2⊃⍵:'' ⋄ CRLF,⍨(firstCaps 1⊃⍵),': ',⍕2⊃⍵}¨↓⍵} ⍝ formatted HTTP headers
        addToTable←{''≡⍺⍺ Get ⍺:⍺⍺⍪⍺ ⍵ ⋄ ⍺⍺} ⍝ add a header unless it's already defined
        fmtCookies←{0∊⍴⍵:'' ⋄ ∊{CRLF,⍨'Set-Cookie: ' ⍵.Format}¨⍵}
    :EndClass

⍝ ────────────────────────────────────────────────────────────────────────────────

    :Class Cookie

        :field public Name←''
        :field public Value←''
        :field public Expires←''
        :field public Domain←''
        :field public Path←''
        :field public Secure←0
        :field public HttpOnly←0

        U←(⊃⊃⎕CLASS ⎕THIS).## ⍝ ref to containing namespace
        fine←{0∊⍴⍵:'' ⋄  '; ',⍺,'=',⍕⍵}  ⍝ fine = format if not empty

        ∇ make
          :Access public
          :Implements constructor
        ∇

        ∇ make1 args
          :Access public
          :Implements constructor
          :If 1≥|≡args ⍝ simple vec or scalar?
              ParseCookie args
          :Else
              args←U.reifs args
              (Name Value Expires Domain Path Secure HttpOnly)←7↑args,(⍴args)↓Name Value Expires Domain Path Secure HttpOnly
          :EndIf
        ∇

        ∇ ParseCookie str;chunks;chunk;value;name
          :Access public
          chunks←U.deb¨str⊆⍨str≠';'
          (Name Value)←'='U.splitFirst⊃chunks ⍝ name/value is always first
          :For chunk :In 1↓chunks
              (name value)←'='U.splitFirst chunk
              :Select U.lc name
              :Case 'expires'
                  Expires←U.ParseDate value
              :Case 'domain'
                  Domain←value
              :Case 'path'
                  Path←value
              :Case 'secure'
                  Secure←1
              :Case 'httponly'
                  HttpOnly←1
              :EndSelect
          :EndFor
        ∇

        ∇ r←Format
          :Access public
          r←''
          :If 0≠≢Name
              r,←Name,'=',(U.UrlEncode,⍕Value)
              r,←'Expires'fine U.Rfc822Datetime Expires
              r,←'Domain'fine Domain
              r,←'Path'fine Path
              r,←Secure/'; Secure'
              r,←HttpOnly/'; HttpOnly'
          :EndIf
        ∇

    :EndClass

⍝ ────────────────────────────────────────────────────────────────────────────────

    :Class WebSocket
        ∇ make args
          :Access public
          :Implements constructor

        ∇   

    :EndClass

⍝ ────────────────────────────────────────────────────────────────────────────────

    :Section HTTP Request Utilities

    APLVersion←⊃(//)⎕VFI{⍵/⍨2>+\'.'=⍵}2⊃'.'⎕WG'APLVersion'
    begins←{⍺≡(⍴⍺)↑⍵}                        ⍝ 'Dya' begins 'Dyalog'
    lc←⎕C                                ⍝ lower case
    uc←1∘⎕C                              ⍝ upper case
    splitFirst←{⍺←' ' ⋄ i←(⍺⍷⍵)⍳1 ⋄ ((i-1)↑⍵)((i+(≢⍺)-1)↓⍵)} ⍝ '?' splitFirst 'abc?def?ghi' → 'abc' 'def?ghi'
    dlb←{⍵↓⍨+/∧\⍵=' '}                       ⍝ delete leading blanks
    deb←{1↓¯1↓{⍵/⍨~'  '⍷⍵}' ',⍵,' '}         ⍝ delete extraneous blanks
    toNum←{0∊⍴⍵:⍬ ⋄ 1⊃2⊃⎕VFI⍕⍵}             ⍝ simple char to num
    toHex←{⎕IO←0 ⋄ '0123456789ABCDEF'[⍵⊤⍨16⍴⍨{⌈⍵+0=1|⍵}16⍟⍵]}
    quote←{'"'=1↑⍵:⍵ ⋄ '"',⍵,'"'}                                             ⍝ double quote ⍵ if not already so
    reifs←{{2::(,∘⊂)⍣2>|≡⍵ ⋄ ,⊆⍵},⍵}                                          ⍝ ravel and enclose if simple

      base64←{⎕IO ⎕ML←0 1              ⍝ from dfns workspace - Base64 encoding and decoding as used in MIME.
          chars←'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
          bits←{,⍉(⍺⍴2)⊤⍵}             ⍝ encode each element of ⍵ in ⍺ bits, and catenate them all together
          part←{((⍴⍵)⍴⍺↑1)⊂⍵}          ⍝ partition ⍵ into chunks of length ⍺
          0=2|⎕DR ⍵:2∘⊥∘(8∘↑)¨8 part{(-8|⍴⍵)↓⍵}6 bits{(⍵≠64)/⍵}chars⍳⍵  ⍝ decode a string into octets
          four←{                       ⍝ use 4 characters to encode either
              8=⍴⍵:'=='∇ ⍵,0 0 0 0     ⍝   1,
              16=⍴⍵:'='∇ ⍵,0 0         ⍝   2
              chars[2∘⊥¨6 part ⍵],⍺    ⍝   or 3 octets of input
          }
          cats←⊃∘(,/)∘((⊂'')∘,)        ⍝ catenate zero or more strings
          cats''∘four¨24 part 8 bits ⍵
      }

    ∇ r←{cpo}Base64Encode w
    ⍝ Base64 Encode
    ⍝ Optional cpo (code points only) suppresses UTF-8 translation
    ⍝ if w is numeric (single byte integer), skip any conversion
      :Access public shared
      :If 83=⎕DR w ⋄ r←base64 w
      :ElseIf 0=⎕NC'cpo' ⋄ r←base64'UTF-8'⎕UCS w
      :Else ⋄ r←base64 ⎕UCS w
      :EndIf
    ∇

    ∇ r←{cpo}Base64Decode w
    ⍝ Base64 Decode
    ⍝ Optional cpo (code points only) suppresses UTF-8 translation
      :Access public shared
      :If 0=⎕NC'cpo' ⋄ r←'UTF-8'⎕UCS base64 w
      :Else ⋄ r←⎕UCS base64 w
      :EndIf
    ∇


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

    ∇ r←DecodeMultiPart data;hdr;ind;d;name;i;filename
      hdr←data↑⍨ind←¯1+1⍳⍨(4⍴CRLF)⍷data
      hdr←hdr⊆⍨~hdr∊CRLF
      d←⊃(hdr/⍨'Content-Disposition:'∘begins¨hdr),⊂''
      name←filename←''
      :If (⍴d)≥i←5+('name="'⍷d)⍳1
          name←(¯1+name⍳'"')↑name←i↓d
      :EndIf
     
      :If (⍴d)≥i←9+('filename="'⍷d)⍳1
          filename←(¯1+filename⍳'"')↑filename←i↓d
      :EndIf
     
      data←(4+ind)↓data ⍝ Drop up to 1st doubleCR
      data←(¯1+¯1↑{⍵/⍳⍴⍵}CRLF⍷data)↑data ⍝ Drop from last CR
     
      :If ~0∊⍴filename
          data←filename data
      :EndIf
     
      r←name data
    ∇

    :endsection

⍝ ────────────────────────────────────────────────────────────────────────────────

    :section Date Utilities

      DayOfWeek←{ ⍝ day of week for ⎕TS, IDN, or 1=7 (=Mon-Sun)
          ⍺←'__en__'
          fmt←⊃(⍺,'Ddd')∘(1200⌶)
          1<≢⍵:fmt 1 ⎕DT⊂⍵
          fmt ⍵
      }


    Month←{3↑(3×⍵-1)↓'JanFebMarAprMayJunJulAugSepOctNovDec'}                  ⍝ month abbreviation for RFC822 format timestamps
    Zpad←{⍺←2 ⋄ (-⍺)↑(⍺⍴'0'),⍕⍵}                                              ⍝ pad with leading 0 (zeros) - ⍺ is width (default = 2)
    ∇ r←UtcOffset
      r←{'+-'[1+⍵<0],4 Zpad 100⊥0 60⊤|⍵}60÷⍨-/20 ⎕DT'JZ'
    ∇
      Rfc822Datetime←{                                                        ⍝ RFC822 formatted timestamp
          0∊⍴⍵:⍵
          ' '=1↑0⍴⍵:⍵                                                         ⍝ if character, assume it's already formatted
          1<≢⍵:∇ 1 ⎕DT⊂⍵                                                     ⍝ ⎕TS format?
          UtcOffset,⍨⊃'Ddd, DD Mmm YYYY hh:mm:ss '(1200⌶)⍵
      }

    ∇ dt←ParseDate str;pos;mon;t;ymd;tonum;x
     ⍝ str is of the genre "Wed Aug 05 2015 07:30:21 GMT-0400 (Eastern Daylight Time)"
      str←deb str
      tonum←{⊃(//)⎕VFI ⍵}
     ⍝ What kind of string is this?
      :If ~∧/1⊃(x dt)←{b←~⍵∊'/-:' ⋄ ⎕VFI b\b/⍵}str  ⍝ yyyy/mm/dd hh:mm:ss ?
          :If 0∊⍴t←('Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec'⎕S 0 3⍠1)str      ⍝ look for the month as a string. If not found
              ymd←3↑tonum str                ⍝ grab the 1st 3 numbers found
              ymd←ymd[⍒(2×31<ymd)+ymd<12] ⍝ put in correct order
          :Else                           ⍝ otherwise (if found)
              (pos mon)←0 1+1⊃t
              :If ~0∊⍴t←tonum pos↑str        ⍝ any number before the month? (e.g. 2 May 2021)
                  ymd←⌽⍣(31<⍬⍴t)⊢(1↑tonum pos↓str),mon,t
              :Else
                  ymd←¯1⌽mon,2↑tonum pos↓str
              :EndIf
          :EndIf
     ⍝ Now grab the time
          dt←ymd,tonum⍕('(\d+):(\d+):(\d+)'⎕S'\1 \2 \3')str
      :EndIf
    ∇

    :endsection

⍝ ────────────────────────────────────────────────────────────────────────────────

    :section Constant Definitions

    CRLF←⎕UCS 13 10

    HttpStatuses←(100 'Continue')(101 'Switching Protocols')
    HttpStatuses,←(200 'OK')(201 'Created')(202 'Accepted')(203 'Non-Authoritative Information')(204 'No Content')(205 'Reset Content')(206 'Partial Content')
    HttpStatuses,←(300 'Multiple Choices')(301 'Moved Permanently')(302 'Found')(303 'See Other')(304 'Not Modified')(305 'Use Proxy')(307 'Temporary Redirect')
    HttpStatuses,←(400 'Bad Request')(401 'Unauthorized')(402 'Payment Required')(403 'Forbidden')(404 'Not Found')(405 'Method Not Allowed')(406 'Not Acceptable')
    HttpStatuses,←(407 'Proxy Authentication Required')(408 'Request Timeout')(409 'Conflict')(410 'Gone')(411 'Length Required')(412 'Precondition Failed')
    HttpStatuses,←(413 'Request Entity Too Large')(414 'Request-URI Too Long')(415 'Unsupported Media Type')(416 'Requested range not satisfiable')(417 'Expectation Failed')
    HttpStatuses,←(500 'Internal Server Error')(501 'Not Implemented')(502 'Bad Gateway')(503 'Service Unavailable')(504 'Gateway Time-out')(505 'HTTP Version not supported')
    HttpStatuses←↑HttpStatuses

    :endsection

⍝ ────────────────────────────────────────────────────────────────────────────────

    :Section Documentation Utilities
    ⍝ these are generic utilities used for documentation

    ∇ docn←ExtractDocumentationSections what;⎕IO;box;CR;sections;eis;matches
    ⍝ internal utility function
      ⎕IO←1
      eis←{(,∘⊂∘,⍣(1=≡,⍵))⍵}
      CR←⎕UCS 13
      box←{{⍵{⎕AV[(1,⍵,1)/223 226 222],CR,⎕AV[231],⍺,⎕AV[231],CR,⎕AV[(1,⍵,1)/224 226 221]}⍴⍵}(⍵~CR),' '}
      docn←1↓⎕SRC ⎕THIS
      docn←1↓¨docn/⍨∧\'⍝'=⊃¨docn ⍝ keep all contiguous comments
      docn←docn/⍨'⍝'≠⊃¨docn     ⍝ remove any lines beginning with ⍝⍝
      sections←{∨/'::'⍷⍵}¨docn
      :If ~0∊⍴what
          matches←∨⌿∨/¨(eis(819⌶what))∘.⍷(819⌶)sections/docn
          (sections docn)←((+\sections)∊matches/⍳≢matches)∘/¨sections docn
      :EndIf
      (sections/docn)←box¨sections/docn
      docn←∊docn,¨CR
    ∇

    ∇ r←Documentation
    ⍝ return full documentation
      :Access public shared
      r←ExtractDocumentationSections''
    ∇

    ∇ r←Describe
    ⍝ return description only
      :Access public shared
      r←ExtractDocumentationSections'Description::'
    ∇

    ∇ r←ShowDoc what
    ⍝ return documentation sections that contain what in their title
    ⍝ what can be a character scalar, vector, or vector of vectors
      :Access public shared
      r←ExtractDocumentationSections what
    ∇

    :EndSection

:EndNamespace
