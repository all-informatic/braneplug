# Brane Plug

A plugin manager for ZeroBrane Studio.

HISTORY:
--------

Before version 6 (2014): Original Plugin from William Willing
Since version 6 (28.08.2019) : a sos-productions.com extension for aegisos by Olivier Lutzwiller
  -Linux support and bug fixes
  -Repository relocation possible with Repository:SetCustom(url)
  -Async Thread support added
  -Test case for debug in sync mode
  -Install steps below ;-)  
  -Error an warning support on plugin install (cover https://github.com/williamwilling/braneplug/issues/1)

INSTALL:
--------

  It has to be done manually imho once:
  1)Copy all the src files into Zerobrane's packages dir (for linux it is /opt/zbstudio/packages)
  2)Ensure this directory has writting rights as well as lualibs and myprograms  
  3)Open zerobrane studio you should see in menu Edit a new entry "Plugins..." 
  4)when Brane Plug window opens Select an item and Click the Install button...
  
  Enjoy and watch an important video on my homepage sos-productions.com to thank me for this extension

TODO:
------

  luvit/lit package import as respository https://lit.luvit.io/packages ?
