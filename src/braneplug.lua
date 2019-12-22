--require("mobdebug").start()
require 'copas'
local http = require 'socket.http'
--local https = require("ssl.https")
mime = require("mime")
local lfs = require 'lfs'   
local ltn12 = require("ltn12");


-- plain text replacement
string.replace=function (text, old, new)
  local b,e = text:find(old,1,true)
  if b==nil then
	 return text
  else
	 return text:sub(1,b-1) .. new .. text:sub(e+1):replace(old, new)
  end
end


local function ensureDir(path)
  local part, index = path:match("([/\\]?[^/\\]+[/\\])()")
  local subPath = ""
  
  while part do
    subPath = subPath .. part
    lfs.mkdir(subPath)
    part, index = path:match("([^/\\]+[/\\])()", index)
  end
end



local function FixReloaLuaAPIBugOnLinux(script)
	return string.replace(script,"ReloadLuaAPI()","if(ReloadLuaAPI~=nil) then ReloadLuaAPI() end")
end
	
	
local Installer = {
  download = function(source, target)
    local contents = http.request(source)
    
	if(not source:match("braneplug%.lua$")) then
		contents=FixReloaLuaAPIBugOnLinux(contents)
	end
	
    ensureDir(target)
	print("File",target)

    local file = io.open(target, "wb")
    file:write(contents)
    file:close()
  end
}

----[[       Repository stuff             ]]------

	local Repository = {}  
	Repository.from = "http://zerobranestore.blob.core.windows.net/"
	Repository.to =  Repository.from
	
	--Wrapped version of http.request(url) with error handling
	function httprequest(url)
		
		local response_body = {}
		
		local res, code, response_headers = http.request{
			url = url,
			method = "GET", 
			sink = ltn12.sink.table(response_body)
		}

		local s=""

		if(res ~= nil) then	
			
			if type(response_body) == "table" then
				s=table.concat(response_body)
			else
				s="Not a table:", type(response_body)
			end
				
			if(code ~= 200) then
				res=code
			else
				res="OK"
			end
		else
			--Unreachable
			res=code
		end
		return s, res
	end
		
	function Repository:GetSource(url)
		local s, res=httprequest(url)
		return s, res
	end
	
	function Repository:GetLocalUrl()
		return self.to.."repository/zbrepository.lua"
	end
	
	
	function Repository:GetOriginalUrl()
		return self.from.."repository/zbrepository.lua"
	end

	--retrieve repository table that contains plugins registered within this repository
	function Repository:Get(urlrepository)
		local source, res = Repository:GetSource(urlrepository)--http.request(urlrepository)
		local repository = assert(loadstring(source))()
		if(repository==nil) then
			repository={}
			res="EMPTY/FAILED TO RETRIEVE"
		end
		if(type(repository) ~= "table") then
			res="INVALID"
		end
		return repository,res
	end
	
	function Repository:Relocate(url)
		return string.replace(url,Repository.from,Repository.to)
	end
 
	function Repository:SetCustom(url)
		self.to=url
	end
 
     --Main function to load repository, this will install lugins registered within this repository 
	function Repository:Load()
		
		 urlrepository=Repository:GetOriginalUrl()
		if(self.from ~= self.to) then
				urlrepository=Repository:GetLocalUrl()
		end
			
		 local repository, res = Repository:Get(urlrepository)
		 
		if(res == "OK") then
			
		  print ("Repository",urlrepository,res)
		  
		  local nt=0
		  for name, plugin in pairs(repository.plugins) do
			if(async) then  
				installpluginasync(plugin)
			else
				installplugin(plugin) 	
			end
			nt=nt+1
		  end

		   dispatcher()   -- main loop
		   print("Ok "..nr .. "/"..nt)
		else
			print ("Repository",urlrepository,res)
		end
		return repository
	end

----[[       Repositories stuff             ]]------

local braneplug = {}
local frame
local Repositories = {}  

function Repositories:Add(url)
	table.insert(Repositories, url)
end

function Repositories:Fetch()
	local r = table.getn(Repositories)
	if r == 0 then return end   -- no more threads to run
	for i=1,r do
		local url=Repositories[i]
		Repository.to=url
		repository=Repository:Load()
		braneplug.plugins=repository.plugins
	end
end


----[[        Plugin stuff             ]]------

local Plugin = {}
Plugin.__index = Plugin
Plugin.from = "http://zerobranestore.blob.core.windows.net/"
Plugin.to =  Plugin.from



function braneplug:Fetch()
	
	Repositories:Fetch()
	
  --local source = http.request("http://zerobranestore.blob.core.windows.net/repository/zbrepository.lua")
 
	--[[local urlrepository = Repository:GetOriginalUrl()
	
	 if(Repository.from ~=Repository.to) then
		urlrepository = Repository:Relocate(urlrepository)
	end

     local source = Repository:GetSource(urlrepository) 
  
  local repository = assert(loadstring(source))()  
  
  for name, plugin in pairs(repository.plugins) do
    plugin.name = name
    setmetatable(plugin, Plugin)
  end
  
  self.plugins = repository.plugins]]
  
end


	function Plugin:GetSource(url)
		local s, res=httprequest(url)
		return s, res
	end
	
	
	function Plugin:Relocate(url)
		return string.replace(url,Plugin.from,Plugin.to)
	end

	
	--this function comes from https://stackoverflow.com/questions/23590304/finding-a-url-in-a-string-lua-pattern
	function Plugin:ExtractUrlsFromSource(text_with_URLs)
	
		local domains = [[.ac.ad.ae.aero.af.ag.ai.al.am.an.ao.aq.ar.arpa.as.asia.at.au
		   .aw.ax.az.ba.bb.bd.be.bf.bg.bh.bi.biz.bj.bm.bn.bo.br.bs.bt.bv.bw.by.bz.ca
		   .cat.cc.cd.cf.cg.ch.ci.ck.cl.cm.cn.co.com.coop.cr.cs.cu.cv.cx.cy.cz.dd.de
		   .dj.dk.dm.do.dz.ec.edu.ee.eg.eh.er.es.et.eu.fi.firm.fj.fk.fm.fo.fr.fx.ga
		   .gb.gd.ge.gf.gh.gi.gl.gm.gn.gov.gp.gq.gr.gs.gt.gu.gw.gy.hk.hm.hn.hr.ht.hu
		   .id.ie.il.im.in.info.int.io.iq.ir.is.it.je.jm.jo.jobs.jp.ke.kg.kh.ki.km.kn
		   .kp.kr.kw.ky.kz.la.lb.lc.li.lk.lr.ls.lt.lu.lv.ly.ma.mc.md.me.mg.mh.mil.mk
		   .ml.mm.mn.mo.mobi.mp.mq.mr.ms.mt.mu.museum.mv.mw.mx.my.mz.na.name.nato.nc
		   .ne.net.nf.ng.ni.nl.no.nom.np.nr.nt.nu.nz.om.org.pa.pe.pf.pg.ph.pk.pl.pm
		   .pn.post.pr.pro.ps.pt.pw.py.qa.re.ro.ru.rw.sa.sb.sc.sd.se.sg.sh.si.sj.sk
		   .sl.sm.sn.so.sr.ss.st.store.su.sv.sy.sz.tc.td.tel.tf.tg.th.tj.tk.tl.tm.tn
		   .to.tp.tr.travel.tt.tv.tw.tz.ua.ug.uk.um.us.uy.va.vc.ve.vg.vi.vn.vu.web.wf
		   .ws.xxx.ye.yt.yu.za.zm.zr.zw]]
		local tlds = {}
		for tld in domains:gmatch'%w+' do
		   tlds[tld] = true
		end
		local function max4(a,b,c,d) return math.max(a+0, b+0, c+0, d+0) end
		local protocols = {[''] = 0, ['http://'] = 0, ['https://'] = 0, ['ftp://'] = 0}
		local finished = {}

		for pos_start, url, prot, subd, tld, colon, port, slash, path in
		   text_with_URLs:gmatch'()(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w+)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))'
		do
		   if protocols[prot:lower()] == (1 - #slash) * #path and not subd:find'%W%W'
			  and (colon == '' or port ~= '' and port + 0 < 65536)
			  and (tlds[tld:lower()] or tld:find'^%d+$' and subd:find'^%d+%.%d+%.%d+%.$'
			  and max4(tld, subd:match'^(%d+)%.(%d+)%.(%d+)%.$') < 256)
		   then
			  finished[pos_start] = true
			  print(pos_start, url)
		   end
		end


		for pos_start, url, prot, dom, colon, port, slash, path in
		   text_with_URLs:gmatch'()((%f[%w]%a+://)(%w[-.%w]*)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))'
		do
		   if not finished[pos_start] and not (dom..'.'):find'%W%W'
			  and protocols[prot:lower()] == (1 - #slash) * #path
			  and (colon == '' or port ~= '' and port + 0 < 65536)
		   then
			  print(pos_start, url)
		   end
		end
	
	end

	nr=0;
	
	function Plugin:Install()
		
	   local url=self.url
	   
	   if(Plugin.from ~=Plugin.to) then
	 	  url= Plugin:Relocate(url)
	   end
	 
	  local script, res = Plugin:GetSource(url)
	
	
	  print("Plugin", url, res)
	
	  if(res=="OK") then
		
		if(Plugin.from ~=Plugin.to) then
	 	  script= Plugin:Relocate(script)
		end
			
		
		 --Plugin:ExtractUrlsFromSource(script)
		
		  local installer = assert(loadstring(script))()
  
	  
		  setfenv(installer.install, Installer)
		  installer:install()
	  
		  nr=nr+1 
	  else
		--Error
		if(wx == nil) then require("wx") end
		if(frame == nil) then frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, 'Brane Plug', wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxRESIZE_BORDER + wx.wxFRAME_NO_TASKBAR + wx.wxFRAME_FLOAT_ON_PARENT) end
		local dialogBox = wx.wxMessageDialog(frame,
							   "Plugin Installation impossible of "..url.."\nReason given is "..res,
							   "Warning", wx.wxOK+wx.wxICON_EXCLAMATION)
		local resultat = dialogBox:ShowModal()
		dialogBox:Destroy()
	  end
	  return res  
	end
 
	function installplugin(plugin) 
		setmetatable(plugin, Plugin)
		plugin:Install()
	end
		
	function installpluginasync(plugin)
		local thread = function ()
			installplugin(plugin)
		end
		install(thread)  
    end
	
----[[       Thread support            ]]-------

	function receive (connection)
      connection:timeout(0)   -- do not block
      local s, status = connection:receive(2^10)
      if status == "timeout" then
        coroutine.yield(connection)
      end
      return s, status
    end 

	threads = {}    -- list of all live threads

	function install(thread)
	-- create coroutine
      local co = coroutine.create(thread)
      -- insert it in the list
      table.insert(threads, co)
	end
		
	function dispatcher ()
      while true do
        local n = table.getn(threads)
        if n == 0 then break end   -- no more threads to run
        local connections = {}
        for i=1,n do
          local status, res =coroutine.resume(threads[i])
          if not res then    -- thread finished its task?
            table.remove(threads, i)
            break
          else    -- timeout
            table.insert(connections, res)
          end
        end
        if table.getn(connections) == n then
          socket.select(connections)
        end
      end
    end
	
----[[       Gui stuff             ]]------

local gui = {}

function gui:Initialize()
  self.CreateMenuItem()
end

function gui:CreateMenuItem()
  local editMenu = ide:GetMenuBar():GetMenu(ide:GetMenuBar():FindMenu(TR("&Edit")))
  local menuItem = editMenu:Append(wx.wxID_ANY, "Plugins...")
  ide:GetMainFrame():Connect(menuItem:GetId(), wx.wxEVT_COMMAND_MENU_SELECTED, function()
    gui:CreateFrame()
    gui:LoadPlugins()
  end)
end

function gui:CreateFrame()
  frame = wx.wxFrame(ide:GetMainFrame(), wx.wxID_ANY, 'Brane Plug', wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxRESIZE_BORDER + wx.wxFRAME_NO_TASKBAR + wx.wxFRAME_FLOAT_ON_PARENT)
  local panel = wx.wxPanel(frame, wx.wxID_ANY)
  
  local plugins = wx.wxListCtrl(
    panel,
    wx.wxID_ANY,
    wx.wxDefaultPosition,
    wx.wxDefaultSize,
    wx.wxLC_REPORT + wx.wxLC_SINGLE_SEL)
  
  plugins:InsertColumn(0, "")
  plugins:InsertColumn(1, "Name")
  plugins:InsertColumn(2, "Version")
  plugins:InsertColumn(3, "Description")
  plugins:InsertColumn(4, "Author")
  
  local images = wx.wxImageList(16, 16, true, 2)
  images:Add(wx.wxBitmap("packages/installing.png"), wx.wxColour(255, 255, 255))
  images:Add(wx.wxBitmap("packages/done.png"), wx.wxColour(255, 255, 255))
  images:Add(wx.wxBitmap("packages/warning.png"), wx.wxColour(255, 255, 255))  
  plugins:AssignImageList(images, wx.wxIMAGE_LIST_SMALL)
  
  local buttons = wx.wxPanel(panel, wx.wxID_ANY)
  local install = wx.wxButton(buttons, wx.wxID_ANY, "Install")
  local remove = wx.wxButton(buttons, wx.wxID_ANY, "Remove")
  install:Disable()
  remove:Hide()
  
  local frameSizer = wx.wxBoxSizer(wx.wxVERTICAL)
  frameSizer:Add(plugins, 1, wx.wxEXPAND)
  frameSizer:Add(buttons, 0, wx.wxALIGN_CENTER_HORIZONTAL)
  
  local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
  buttonSizer:Add(install, 0, wx.wxALL + wx.wxALIGN_LEFT, 4)
  buttonSizer:Add(remove, 0, wx.wxALL + wx.wxALIGN_RIGHT, 4)
  
  buttons:SetSizer(buttonSizer)
  panel:SetSizerAndFit(frameSizer)
  
  plugins:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED, function(event)
    install:Enable(true)
  end)

  install:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    local selected = plugins:GetNextItem(-1, wx.wxLIST_NEXT_ALL, wx.wxLIST_STATE_SELECTED)
    local item = wx.wxListItem()
    item:SetId(selected)
    item:SetColumn(1)
    item:SetMask(wx.wxLIST_MASK_TEXT + wx.wxLIST_MASK_IMAGE)
    plugins:GetItem(item)
    
    local name = item:GetText()
    local plugin = braneplug.plugins[name]
    
    plugins:SetItemImage(selected, 0)
    
    local timer = wx.wxTimer(frame)
    frame:Connect(wx.wxEVT_TIMER, function()
      if(plugin:Install() == "OK") then
		plugins:SetItemImage(selected, 1)
	  else
		plugins:SetItemImage(selected, 2)
	  end  
    end)
    timer:Start(0, wx.wxTIMER_ONE_SHOT)
  end)
  
  frame:Show()
  
  gui.plugins = plugins
end

function gui:LoadPlugins()
  braneplug:Fetch()
  
  local function string(value)
    if value then
      return tostring(value)
    else
      return ""
    end
  end
  
  for name, plugin in pairs(braneplug.plugins) do
    local item = gui.plugins:InsertItem(0, "")
    gui.plugins:SetItem(item, 1, string(plugin.name))
    gui.plugins:SetItem(item, 2, string(plugin.version))
    gui.plugins:SetItem(item, 3, string(plugin.description))
    gui.plugins:SetItem(item, 4, string(plugin.author))
    gui.plugins:SetItemImage(item, -1)
  end
  
  gui.plugins:SetColumnWidth(0, 20)
  gui.plugins:SetColumnWidth(1, wx.wxLIST_AUTOSIZE)
  gui.plugins:SetColumnWidth(2, wx.wxLIST_AUTOSIZE_USEHEADER)
  gui.plugins:SetColumnWidth(3, wx.wxLIST_AUTOSIZE)
  gui.plugins:SetColumnWidth(4, wx.wxLIST_AUTOSIZE)
end


async=true
-- TEST CASE 
--[[  
	async=false -- ZeroBraneStudio Debugger has problem with async, switch it off
	idePath="/opt/zbstudio/"
	Installer.idePath = idePath 
	--Repositories:Add("http://zerobranestore.blob.core.windows.net/") 
	Repositories:Add("http://localhost/zerobranestore.blob.core.windows.net/") 
	Repositories:Fetch()
--]]

return {
  name = "Brane Plug",
  description = "A plugin manager for ZeroBrane Studio.",
  author = "6",

  onRegister = function(self)
    
    -- Let the installers know where ZeroBrane Studio is located.
    local idePath=ide.editorFilename:match(".*\\")     
    if( idePath == null) then --If not windoze scheme C:\path\to\ide
      idePath=ide.editorFilename:match(".*/")  --don't forget to switch to Linux path ie /opt/zbstudio
    end
    Installer.idePath = idePath 
    ide:AddConsoleAlias("braneplug", braneplug)             -- Make the plugin manager accessible from the local console.
    gui:Initialize()
  end,
  
  onUnRegister = function(self)
    ide:RemoveConsoleAlias("braneplug")
  end
}
