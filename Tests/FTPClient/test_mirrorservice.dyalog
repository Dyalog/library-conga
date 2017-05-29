r←test_mirrorservice;z;pub;readme;host;user;pass;folder;file;sub;path;NL;CR
⍝ Test the FTP Client
⎕←'Test started!'
            NL←⎕UCS 13 10 ⋄ CR←1⊃NL

            (host user pass)←'ftp.mirrorservice.org' 'anonymous' 'testing'
            path←∊(folder sub file)←'pub/' 'FreeBSD/' 'README.TXT'

            :Trap 0
                z←⎕NEW #.FtpClient(host user pass)     ⍝ Create a new object
            :Else
                r←'Unable to connect to ',host ⋄ →0
            :EndTrap


            :If 0≠1⊃pub←z.List folder ⍝ retrieve contents of a folder
                r←'Unable to list contents of folder: ',,⍕pub ⋄ →0
            :EndIf

            :If ~∨/(¯1↓sub)⍷2⊃pub   ⍝ does it contain the subfolder we're expecting?
                r←'Sub folder ',sub,' not found in folder ',folder,': ',file ⋄ →0
            :EndIf

            :If 0≠1⊃readme←z.Get path   ⍝ retrieve file README.TXT
                r←'File not found in folder ',folder,': ',file ⋄ →0
            :EndIf


            ⎕←path,' from ',host,':',CR
            ⎕←(⍕⍴2⊃readme),' characters read'  ⍝ maybe we should also check if the file has the expected length? (Assuming it does not change over time - not sure if that is a valid assumption)
r←''