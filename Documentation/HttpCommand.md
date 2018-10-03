# HttpCommand

This is the documentation for the HttpCommand utility included with Dyalog APL versions 16.0 and later.


### Description

 HttpCommand is a stand alone utility to issue HTTP commands and return their
 results.  HttpCommand can be used to retrieve the contents of web pages,
 issue calls to web services, and communicate with any service which uses the
 HTTP protocol for communications.

 N.B. requires Conga - the TCP/IP utility library (see Notes below)

### Overview

 HttpCommand can be used in two ways:
   
1. Create an instance of HttpCommand using `⎕NEW`  
This gives you very fine control to specify the command's parameters.  
You then use the Run method to execute the request.  For example:

```APL
      h←⎕NEW HttpCommand                      ⍝ create an instance
      h.(Command URL)←'get' 'www.dyalog.com'   ⍝ set the command parameters
      r←h.Run                                  ⍝ run the request
```
2. Alternatively you can use the "Get" or "Do" methods which make it easier to execute some of the more common use cases.
```APL
      r←HttpCommand.Get 'www.dyalog.com'  
      r←HttpCommand.Do 'get' 'www.dyalog.com'
```
### Constructor

```APL 
      cmd←⎕NEW HttpCommand [(Command [URL [Params [Headers [Cert [SSLFlags [Priority]]]]]])]
```
#### Constructor Arguments

 All of the constructor arguments are also exposed as Public Fields
```
   Command  - the case-insensitive HTTP command to issue
              typically one of 'GET' 'POST' 'PUT' 'OPTIONS' 'DELETE' 'HEAD'

   URL      - the URL to direct the command at
              format is:  [HTTP[S]://][user:pass@]url[:port][/page[?query_string]]

   Params   - the parameters to pass with the command
              this can be one of
              - a properly URLEncoded simple character vector
              - a namespace containing the named parameters
              - a vector of an even number of character vectors representing name/value pairs

   Headers  - the HTTP headers for the request
              this can be one of
              - an empty array - this means that only the HttpCommand default headers will be sent
              - a vector of 2-element vectors containing name/value pairs
              - a matrix of [;1] header-name [;2] values

              these are any additional HTTP headers to send with the request
              or headers whose default values you wish to override
              headers that HttpCommand will set by default are:
               User-Agent     : Dyalog/Conga
               Accept         : */*
               Content-Type   : application/x-www-form-urlencoded
               Content-Length : length of the request body
               Accept-Encoding: gzip, deflate

   Cert     - if using SSL, this is an instance of the X509Cert class (see Conga SSL documentation)

   SSLFlags - if using SSL, these are the SSL flags as described in the Conga documentation

   Priority - if using SSL, this is the GNU TLS priority string (generally you won't change this from the default)

 Notes on Params and query_string:
 When using the 'GET' HTTP command, you may specify parameters using either the query_string or Params
 Hence, the following are equivalent
     HttpCommand.Get 'www.someplace.com?userid=fred'
     HttpComment.Get 'www.someplace.com' ('userid' 'fred')
```
### Additional Public Fields
```
   LDRC            - if set, this is a reference to the DRC namespace from Conga - otherwise, we look for DRC in the workspace root
   WaitTime        - time (in seconds) to wait for the response (default 30)
   CongaMode       - 'http' for Conga 3.0 and later, 'text' for Conga before 3.0 or if forcing text mode when using Conga 3.0 and later
   SuppressHeaders - Boolean which, if set to 1, will suppress all HttpCommand-generated headers
                     you may still supply your own headers in the Headers field


 The methods that execute HTTP requests - Do, Get, and Run - return a namespace containing the variables:
   Data          - the response message payload
   HttpVer       - the server HTTP version
   HttpStatus    - the response HTTP status code (200 means OK)
   HttpMessage   - the response HTTP status message
   Headers       - the response HTTP headers
   PeerCert      - the server (peer) certificate if running secure
   Redirections  - a vector (possibly empty) of redirection links
   rc            - the Conga return code (0 means no error, ¯1 means failure to initialize Conga)
   msg           - status/error msg (non-HTTP)  Empty indicates no non-HTTP error
   Command       - the request's HTTP command
   URL           - the request's URL
```
### Public Instance Methods
```
   result←Run            - executes the HTTP request
   name AddHeader value  - add a header value to the request headers if it doesn't already exist
```
### Public Shared Methods
```APL
   result←Get URL [Params [Headers [Cert [SSLFlags [Priority]]]]]

   result←Do  Command URL [Params [Headers [Cert [SSLFlags [Priority]]]]]
     Where the arguments are as described in the constructor parameters section.
     Get and Do are shortcut methods to make it easy to execute an HTTP request on the fly.

   r←Base64Decode vec     - decode a Base64 encoded string

   r←Base64Encode vec     - Base64 encode a character vector

   r←UrlDecode vec        - decodes a URL-encoded character vector

   r←{name} UrlEncode arg - URL-encodes string(s)
     name is an optional name
     arg can be one of
       - a character vector
       - a vector of character vectors of name/value pairs
       - a 2-column matrix of name/value pairs
       - a namespace containing named variables
     Examples:
       UrlEncode 'Hello World!'
 Hello%20World%21
      'phrase' UrlEncode 'Hello World!'
 phrase=Hello%20World%21
       UrlEncode 'company' 'dyalog' 'language' 'APL'
 company=dyalog&language=APL
       UrlEncode 2 2⍴'company' 'dyalog' 'language' 'APL'
 company=dyalog&language=APL
       (ns←⎕NS '').(company language)←'dyalog' 'APL'
       UrlEncode ns
 company=dyalog&language=APL
```
### Notes
 * HttpCommand uses Conga for TCP/IP communications and supports both Conga 2 and Conga 3.  
 * Conga 2 uses the DRC namespace  
 * Conga 3 uses either the Conga namespace or DRC namespace for backwards compatibility  
 * HttpCommand will search for #.Conga and #.DRC and use them if they exist - or try to ⎕CY them if they're not found
 * You can set the CongaRef public field to have HttpCommand use Conga or DRC located other than in the root of the workspace.
 Otherwise HttpCommand will attempt to copy Conga or DRC from the conga workspace supplied with Dyalog APL

 Normally HttpCommand will specify an "Accept-Encoding" request header so that the server can use gzip or deflate compression in the response.
 However, if you use the HEAD HTTP method, this header is not set, so that the content-length header will
   reflect the uncompressed length of the response's body.
   You can add the header manually if you want the compressed message length, e.g.:
   `r←HttpCommand.Do 'HEAD' 'someurl' '' (1 2⍴'Accept-Encoding' 'gzip, deflate')`

### Example Use Cases
* Retrieve the contents of a web page
```APL
   result←HttpCommand.Get 'www.dyalog.com'
```
* Update a record in a web service
```APL
   cmd←⎕NEW HttpCommand                        ⍝ create an instance
   cmd.(Command URL)←'PUT' 'www.somewhere.com' ⍝ set a couple of fields
   (cmd.Params←⎕NS '').(id name)←123 'Fred'    ⍝ set the parameters for the "PUT" command
   result←cmd.Run                              ⍝ and run it
``` 
