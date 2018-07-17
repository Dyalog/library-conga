:Namespace HttpUtils
⍝ Description::
⍝ This namespace contains utilities to make it easier to manipulate and compose HTTP messages.
⍝ It is intended to be used in conjunction with Conga v3.0's HTTP mode
⍝ and with the HTMLRenderer introduced in Dyalog v16.0
⍝ Typical use cases include:
⍝   ∘ Compose an HTTP request to send to a server
⍝   ∘ Parse an HTTP request received using by a server
⍝   ∘ Compose an HTTP response to send to a client
⍝   ∘ Parse an HTTP response received from a server
⍝   ∘ Parse the callback data from HTMLRenderer's onHTTPRequest event
⍝
⍝ Latest version of this file can be obtained from https://github.com/Dyalog/library-conga
⍝
⍝ Overview::
⍝ HttpUtils contains two primary classes, HttpRequest and HttpResponse.
⍝ Both are based on a base class HttpMessage, as both HTTP requests and responses
⍝ share a common structure with some minor differences.
⍝
⍝ We envision 3 use cases for HttpUtils
⍝   1) When used in the context of an HTTP client:
⍝      - use HttpRequest to construct your HTTP request and send that to the server
⍝      - use HttpResponse to receive the response from the server
⍝   2) When used in the context of an HTTP server:
⍝      - use HttpRequest to receive requests from clients
⍝      - use HttpResponse to construct responses to send back to the clients
⍝   3)
⍝



    ∇ r←Version
      r←'HttpUtils' '2.0' '2018-07-16'
    ∇


    ⎕IO←⎕ML←1

⍝ ────────────────────────────────────────────────────────────────────────────────

    :Class HttpMessage
    ⍝ this class can be used for both HTTP requests and responses
        :field public Headers←0 2⍴⊂''
        :field public QueryData←0 2⍴⊂''   ⍝ data passed in the query portion of the URI
        :field public FormData←0 2⍴⊂''    ⍝ form data passed in the body
        :field public Command←''
        :field public Cookies←⍬
        :field public Content←''
        :field public HttpVersion←'HTTP/1.1'

        :field public HTMLRendererArgs←⍬                 ⍝ used only in conjunction with HTMLRenderer
        :field public HTMLRendererBaseUrl←'dyalog_home'  ⍝ used only in conjunction with HTMLRenderer


⍝ Future Fields: (currently available in Headers)
⍝        :field public Chunked←0
⍝        :field public ContentLength←¯1
⍝        :field public ContentType←''
⍝        :field public TransferEncoding←''

        :field public _Type←''
        :field _IsComplete←0   ⍝ keep track of when have received the complete message

        :field public shared readonly CRLF←⎕UCS 13 10

        :field public shared readonly U←(⊃⊃⎕CLASS ⎕THIS).## ⍝ ref to containing namespace

        ∇ r←MessageType
          :Access public
          r←({⍵↑⍨1-(⌽⍵)⍳'.'}⍕⊃⊃⎕CLASS ⎕THIS)_Type
        ∇

        ∇ r←IsComplete
          :Access public
          r←_IsComplete
        ∇

⍝ Overridable methods

        ∇ r←FormatCookies
          :Access public overridable
          r←''
        ∇

        ∇ r←FormatFirstLine
        ⍝ format varies for response and request
          :Access public overridable
          r←''
        ∇

        ∇ r←AddFirstLine line
        ⍝ add either request command line, or response status line via overridden method in derived classes
          :Access public overridable
          r←''
        ∇

        ∇ r←FormatHeaders
        ⍝ requests and responses may insert additional headers
          :Access public overridable
          r←fmtHeaders Headers
        ∇

        ∇ r←FormatBody
          :Access public overridable
          r←CRLF,CRLF,Content
          Headers←'Content-Length'(Headers addHeader)⍕≢Content
        ∇

        ∇ {r}←ProcessCookies
          :Access public overridable
          r←⎕THIS
        ∇

        ∇ ProcessAdditionalHeaders
          :Access public overridable
        ∇

⍝ Common methods

        ∇ r←{name}AddCookie args
          :Access public
          :If 0=⎕NC'name'
              Cookies,←⎕NEW U.reifs args
          :Else
              Cookies,←⎕NEW(U.reifs name),U.reifs args
          :EndIf
        ∇

        ∇ DelCookie name
          :Access public
          :If ~0∊⍴Cookies
              Cookies/⍨←~Cookies.Name∊U.reifs name
          :EndIf
        ∇

        ∇ r←Format;body
          :Access public
          r←FormatFirstLine ⍝ may update headers (authorization)
          body←FormatBody   ⍝ may update headers (content-length)
          r,←FormatHeaders
          r,←FormatCookies
          r,←body
        ∇

        ∇ {r}←CongaHttpHeader hdr;line;header;chunked;contentLength
        ⍝ add the data from Conga's HTTPHeader event
          :Access public
          :If _Type≢''
              ⎕←'Message type expected to be "", but is actually "',(_Type),'"'
          :EndIf
          (line header)←CRLF U.splitFirst hdr
          {}AddFirstLine line  ⍝ only one will be active for either a request or response
          r←ProcessHeaders header  ⍝!!!
          chunked←∨/'chunked'⍷Headers Get'Transfer-Encoding'
          contentLength←⊃(U.toNum Headers Get'Content-Length'),¯1
          _IsComplete←chunked<contentLength<1
          ProcessAdditionalHeaders
          r←⎕THIS
        ∇

        ∇ {r}←CongaHttpChunk chnk
        ⍝ add the data from Conga's HTTPChunk event
          :Access public
          :If _Type≢'Conga'
              ⎕←'Message type expected to be "Conga", but is actually "',(_Type),'"'
          :EndIf
          Content,←chnk
          _IsComplete←0∊⍴chnk
          r←⎕THIS
        ∇

        ∇ {r}←CongaHttpBody bod
        ⍝ add the data from Conga's HTTPBody event
          :Access public
          :If _Type≢'Conga'
              ⎕←'Message type expected to be "Conga", but is actually "',(_Type),'"'
          :EndIf
          Content,←bod
         
          _IsComplete←1
          r←⎕THIS
        ∇

        ∇ {r}←CongaHttpTrailer trl
        ⍝ add the data from Conga's HTTPTrailer event
          :Access public
          :If _Type≢'Conga'
              ⎕←'Message type expected to be "Conga", but is actually "',(_Type),'"'
          :EndIf
          ProcessHeaders trl
          _IsComplete←1
          r←⎕THIS
        ∇

        ∇ {r}←ProcessHeaders headers;h;cookie
        ⍝ add headers from HTTP Request/Response
          :Access public
          h←U.deb¨↑':'U.splitFirst¨{⍵⊆⍨~⍵∊CRLF}headers
          h[;1]←U.lc h[;1]
          Headers←makeHeaders h
          {}ProcessCookies
          r←⎕THIS
        ∇

        ∇ {r}←name AddHeader value
        ⍝ add a header unless it's already defined
          :Access public
          Headers←name(Headers addHeader)value
          r←⎕THIS
        ∇

        ∇ r←GetHeader name
        ⍝ retrieve header values by name
          :Access public
          r←Headers Get name
        ∇

        ∇ r←GetAllHeaders name
        ⍝ retrieve all header values for a name
          :Access public
          :If 0∊⍴name
              r←Headers
          :Else
              r←((U.lc name)∘≡¨Headers[;1])/Headers[;2]
          :EndIf
        ∇

        ∇ DelHeader name
        ⍝ delete header(s) by name
          :Access public
          :If ~0∊⍴Headers
              Headers⌿⍨←~(U.lc¨Headers[;1])∊U.lc¨U.reifs name
          :EndIf
        ∇

        makeHeaders←{0∊⍴⍵:0 2⍴⊂'' ⋄ 2=⍴⍴⍵:⍵ ⋄ {2=|≡⍵:((⌈.5×≢⍵),2)⍴(,¨⍵),⊂'' ⋄ 3=|≡⍵:↑⍵}U.reifs ⍵} ⍝ create header structure [;1] name [;2] value
        fmtHeaders←{0∊⍴⍵:'' ⋄ ∊{0∊⍴2⊃⍵:'' ⋄ CRLF,⍨(firstCaps 1⊃⍵),': ',⍕2⊃⍵}¨↓⍵} ⍝ formatted HTTP headers
        firstCaps←{1↓{(¯1↓0,'-'=⍵) (819⌶)¨ ⍵}'-',⍵} ⍝ capitalize first letters e.g. Content-Encoding
        addHeader←{''≡⍺⍺ Get ⍺:⍺⍺⍪⍺ ⍵ ⋄ ⍺⍺} ⍝ add a header unless it's already defined

        ∇ r←table Get name
        ⍝ lookup a name/value-table value by name, return '' if not found
          :Access Public Shared
          r←table{(⍺[;2],⊂'')⊃⍨(U.lc¨⍺[;1])⍳U.reifs U.lc ⍵}name
        ∇

        ∇ r←CookieSplit cookie
          :Access public
          r←{(⎕IO ⎕ML)←0 3   ⍝ Split cookies
              {{db←{⍵/⍨∨\⍵≠' '} ⋄ ⌽db⌽db ⍵}¨⍵⊂⍨~<\'='=⍵}¨⍵⊂⍨⍵≠';'}cookie
        ∇

        ∇ r←DecodeCookie cookie
          :Access public
          r←←{(⎕IO ⎕ML)←0 3              ⍝ Decode Special chars in HTML string.
              hex←'0123456789ABCDEF'     ⍝ Hex chars.
              {                          ⍝ Convert numbers.
                  v f←⎕VFI ⍵             ⍝ Check for numbers.
                  ~∧/v:⍵                 ⍝ Not all numbers: char vec.
                  1=⍴f:↑f ⋄ f            ⍝ Numeric scalar or vector.
              }∊{                        ⍝ Enlist of segments.
                  '%'≠↑⍵:⍵               ⍝ 1st seg may not contain special char.
                  (⎕UCS 16⊥hex⍳1↓3↑⍵),3↓⍵  ⍝ Hex code replaced with corresp. ⎕AV char.
              }¨(1+⍵='%')⊂,⍵             ⍝ Segments split at '%' char.
          }cookie
        ∇

    :EndClass

⍝ ────────────────────────────────────────────────────────────────────────────────

    :class HttpRequest : HttpMessage
    ⍝ HttpRequest::
    ⍝ Can be used to either create and format an HTTP request for transmission to a server
    ⍝ or to parse an HTTP request for processing by a server

        :field public Command←''
        :field public Uri←''
        :field public Host←''

        ∇ make
          :Access public
          :Implements constructor
        ∇

        ∇ make1 args;h;b;Params
          :Access public
          :Implements constructor
        ⍝ args is one of:
        ⍝  character vector containing either the header or entire request
        ⍝  vector of [Command Uri Params Headers]
        ⍝  10 or 11-element vector as returned in the HTTPRequest event of HTMLRenderer
          :If 1=|≡args
              (h b)←U.(CRLF,CRLF)U.splitFirst args
              CongaHttpHeader h
              CongaHttpBody b
              _Type←''
          :ElseIf 10 11∊⍨≢args ⍝ from HTMLRenderer/HTTPRequest?
              FromHtmlRenderer args
          :Else
              args←U.reifs args
              (Command Uri Params Headers)←4↑args,(⍴args)↓Command Uri Params Headers
              Command←U.uc Command
              :If 'GET'≡Command
                  QueryData←Params
              :Else
                  FormData←Params
              :EndIf
          :EndIf
        ∇

        ∇ r←AddFirstLine line;t
          :Access public override
          ⍝ first line for a request is Command Url HttpVersion
          (Command t)←U.splitFirst line
          Command←U.uc Command
          (Uri HttpVersion)←U.splitFirst t
          (Uri QueryData)←'?'U.splitFirst Uri
          QueryData←DecodeUrlArgs QueryData
          r←⎕THIS
        ∇

        ∇ r←FormatFirstLine;params;args;b;url;host;page;p
        ⍝ formats the start line of an HTTP request
          :Access public override
          url←Uri↓⍨(∨/b)×1+(b←'//'⍷Uri)⍳1                   ⍝ Remove HTTP[s]:// if present
          (host page)←'/'U.splitFirst url,(~'/'∊url)/'/'    ⍝ Extract host and page from url
          :If '@'∊host ⍝ Handle user:password@host...       ⍝ any authorization being done?
              Headers←'Authorization'(Headers addHeader)'Basic ',U.Base64Encode(¯1+p←host⍳'@')↑host
              host←p↓host
          :EndIf
          Headers←'Host'(Headers addHeader)host            ⍝ add the Host header
         
          params←''
          args←QueryData
          :If 'GET'≡U.uc Command                            ⍝ GET method - all data is passed in querystring
              args⍪←FormData
          :EndIf
          params←(0∊⍴args)↓'?',U.UrlEncode args
          r←Command,' ',page,params,' ',HttpVersion
        ∇

        ∇ r←FormatHeaders
          :Access public override
          Headers←'User-Agent'(Headers addHeader)'Dyalog/Conga'
          Headers←'Accept'(Headers addHeader)'*/*'
          r←fmtHeaders
        ∇

        ∇ r←FormatCookies
          :Access public override
          r←''
          :If ~0∊⍴Cookies
              r←CRLF,'Cookie:',∊' ',¨Cookies.Format 1
          :EndIf
        ∇

        ∇ r←FormatBody;formContentType;parms
          :Access public override
          r←CRLF,CRLF,Content
          :If ~0∊⍴FormData      ⍝ if we have any formdata
              :If Command≢'GET' ⍝ and not a GET command
              ⍝↓↓↓ specify the default content type (if not already specified)
                  Headers←'Content-Type'(Headers addHeader)'application/x-www-form-urlencoded'
                  :If formContentType≡hdrs Get'Content-Type'
                      r,←UrlEncode FormData
                  :EndIf
              :EndIf
          :EndIf
          Headers←'Content-Length'(Headers addHeader)¯4+≢r
        ∇

        ∇ {r}←ProcessCookies;cookie
        ⍝ add cookies from 'cookie' header
          :Access public override
          :If ~0∊⍴cookie←GetHeader'cookie'
              AddCookie¨cookie←CookieSplit cookie
          :EndIf
          r←⎕THIS
        ∇

        ∇ ProcessAdditionalHeaders
          :Access public override
          Host←Headers Get'host'
        ∇

        ∇ {r}←{baseUrl}FromHtmlRenderer args
        ⍝ Parse request based on callback data from HTMLRenderer's onHTTPRequest event
          :Access public
          :If _Type≢''
              ⎕←'Message type expected to be "", but is actually "',(_Type),'"'
          :EndIf
         
          _Type←'HTMLRenderer'
         
          :If 9≠⎕NC'HTMLRendererArgs'
              HTMLRendererArgs←⎕NS''
              HTMLRendererArgs.(obj event op intercept scode stext mime url header content method)←11↑args,⊂'' ⍝ add method for v17.0
          :EndIf
         
          :If 0≠⎕NC'baseUrl'
              HTMLRendererBaseUrl←baseUrl
          :EndIf
          (Uri QueryData)←HTMLRendererBaseUrl ParseUrl 8⊃args
          Headers←ParseHeaders 9⊃args
          {}ProcessCookies
          Headers ParseData 10⊃args ⍝ creates Data and Content
        ∇

        ∇ (page arguments)←baseUrl ParseUrl u;args
        ⍝ Parse the URL element from HTMLRenderer
          (page arguments)←'?'U.splitFirst u
          page←U.UrlDecode{3↓⍵/⍨∨\'://'⍷⍵}page ⍝ drop off http{s}://
          page↓⍨←(≢baseUrl)×baseUrl U.begins page
          arguments←DecodeUrlArgs arguments
        ∇

        ∇ hdrs←ParseHeaders h
        ⍝ Parse HTTP headers from HTMLRenderer
          hdrs←↑':'U.splitFirst¨{⍵⊆⍨⍵≠⎕UCS 10}h
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


    :EndClass

⍝ ────────────────────────────────────────────────────────────────────────────────

    :Class HttpResponse : HttpMessage
        :Field public HttpStatus←200
        :Field public HttpStatusText←'OK'

        ∇ make
          :Access public
          :Implements constructor
        ∇

        ∇ make1 args;h;b
          :Access public
          :Implements constructor
        ⍝ args is one of:
        ⍝  character vector containing either the header or entire request
        ⍝  vector of [Command Uri Params Headers]
        ⍝  10 or 11-element vector as returned in the HTTPRequest event of HTMLRenderer
        ⍝  an instance of HttpUtils.HttpRequest that was
          :If 9.2=⎕NC⊂'args'
              FromHtmlRenderer args.HTMLRendererArgs.(obj event op intercept scode stext mime url header content method)
          :ElseIf 1=|≡args ⍝
              (h b)←U.(CRLF,CRLF)U.splitFirst args
              CongaHttpHeader h
              CongaHttpBody b
              _Type←''
          :ElseIf 10 11∊⍨≢args ⍝ from HTMLRenderer/HTTPRequest?
              FromHtmlRenderer args
          :Else
              args←U.reifs args
              (Content Headers)←2↑args,(⍴args)↓Content Headers
          :EndIf
        ∇

        ∇ r←AddFirstLine line;t
          :Access public override
          ⍝ first line for a response is HttpVersion HttpStatus HttpStatusText
          (HttpVersion t)←U.splitFirst line
          (HttpStatus HttpStatusText)←U.splitFirst t
          r←⎕THIS
        ∇

        ∇ r←FormatFirstLine
          :Access public override
          r←HttpVersion,' ',(⍕HttpStatus),' ',HttpStatusText
        ∇

        ∇ r←FormatBody
          :Access public override
          r←CRLF,CRLF,Content
          Headers←'Content-Length'(Headers addHeader)¯4+≢r
        ∇

        ∇ {r}←ProcessCookies;cookies
          :Access public override
          :If ~0∊⍴cookies←GetAllHeaders'set-cookie'
              Cookies,←{⎕NEW Cookie ⍵}¨cookies
          :EndIf
          r←⎕THIS
        ∇

        ∇ r←FromHtmlRenderer args
          :Access public
          HTMLRendererArgs←⎕NS''
          HTMLRendererArgs.(obj event op intercept scode stext mime url header content method)←11↑args,⊂''
        ∇

        ∇ r←ToHtmlRenderer
        ⍝ args is either an instance of HttpRequest or a 10-element vector of the onHTTPRequest event
          :Access public
          r←10⍴0
          r[1 2 3 8]←HTMLRendererArgs.(obj event op url)
          r[4]←1
          r[5 6]←HttpStatus HttpStatusText
          r[7]←⊂'text/html'{0∊⍴⍵:⍺ ⋄ ⍵}Headers Get'content-type'
          r[9 10]←FormatHeaders(U.UnicodeToHTML Content)
        ∇

    :endclass

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

        ∇ r←Format type
        ⍝ type is 1 for request, 2 for response
          :Access public
          r←''
          :If 0≠≢Name
              r,←Name,'=',(U.UrlEncode,⍕Value)
              :If 1=type
                  r,←';'
              :Else
                  r,←'Expires'fine U.Rfc822Datetime Expires
                  r,←'Domain'fine Domain
                  r,←'Path'fine Path
                  r,←Secure/'; Secure'
                  r,←HttpOnly/'; HttpOnly'
              :EndIf
          :EndIf
        ∇

    :EndClass

⍝ ────────────────────────────────────────────────────────────────────────────────

    :section Http Message Utilities

    begins←{⍺≡(⍴⍺)↑⍵}                        ⍝ 'Dya' begins 'Dyalog'
    lc←(819⌶)                                ⍝ lower case
    uc←1∘(819⌶)                              ⍝ upper case
    splitFirst←{⍺←' ' ⋄ i←(⍺⍷⍵)⍳1 ⋄ ((i-1)↑⍵)((i+(≢⍺)-1)↓⍵)} ⍝ '?' splitFirst 'abc?def?ghi' → 'abc' 'def?ghi'
    dlb←{⍵↓⍨+/∧\⍵=' '}                       ⍝ delete leading blanks
    deb←{1↓¯1↓{⍵/⍨~'  '⍷⍵}' ',⍵,' '}         ⍝ delete extraneous blanks
    toNum←{0∊⍴⍵:⍬ ⋄ 1⊃2⊃⎕VFI ⍕⍵}             ⍝ simple char to num
    toHex←{⎕IO←0 ⋄ '0123456789ABCDEF'[⍵⊤⍨16⍴⍨{⌈⍵+0=1|⍵}16⍟⍵]}
    quote←{'"'=1↑⍵:⍵ ⋄ '"',⍵,'"'}                                             ⍝ double quote ⍵ if not already so
    reifs←{{2::(,∘⊂)⍣2>|≡⍵ ⋄ ,⊆⍵},⍵}                                          ⍝ ravel and enclose if simple

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

    ∇ r←UnicodeToHTML txt;u;ucs
    ⍝ converts chars ⎕UCS >127 to HTML safe format
      r←,⎕FMT txt
      u←127<ucs←⎕UCS r
      (u/r)←(~∘' ')¨↓'G<&#ZZZ9;>'⎕FMT u/ucs
      r←∊r
    ∇

    :endsection

⍝ ────────────────────────────────────────────────────────────────────────────────

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
          ' '=1↑0⍴⍵:⍵                                                         ⍝ if character, assume it's already formatted
          1=≢⍵:∇ IDNToDate ⍵                                                  ⍝ single number means it's in IDN format
          (DayOfWeek ⍵),', ',(Zpad 3⊃⍵),' ',(Month 2⊃⍵),' ',(⍕1⊃⍵),' ',(1↓∊':',¨Zpad¨3↑3↓⍵),' GMT'
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
