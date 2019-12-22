# Brane Plug

A plugin manager for ZeroBrane Studio, the Lua script debugger https://studio.zerobrane.com/

HISTORY:
--------

Before version 6 (2014): Original Plugin from William Willing
Since version 6 (28.08.2019) : a sos-productions.com extension for aegisos project (http://aegisos.sos-productions.com/) by Olivier Lutzwiller.

Features/Improvements:
* Linux support and bug fixes
* Repository relocation possible with Repository:SetCustom(url)
* Async Thread support added
* Test case for debug in sync mode
* Install steps below ;-)  
* Error with icon warning on plugin install failure (covers https://github.com/williamwilling/braneplug/issues/1)

INSTALL:
--------

  It has to be done manually imho once:
  1. Copy all the src files into Zerobrane's packages dir (for linux it is /opt/zbstudio/packages)
  2. Ensure this directory has writting rights as well as lualibs and myprograms  
  3. Open zerobrane studio you should see in menu Edit a new entry "Plugins..." 
  4. when Brane Plug window opens Select an item and Click the Install button...
  
  Enjoy and have a nice watch of the video [based on a True Story That Affected 100 Million People](https://watch.ntdfilms.com/programs/comingforyou)

TODO:
------

  luvit/lit package import as respository https://lit.luvit.io/packages ?
