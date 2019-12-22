return {
  description = "A plugin manager for ZeroBrane Studio.",
  author = "William Willing,Olivier Lutzwiller",
  version = 6,

  install = function()
    local remotePath = "http://zerobranestore.blob.core.windows.net/braneplug/"
    download(remotePath .. "braneplug.lua", idePath .. "packages/braneplug.lua")
    download(remotePath .. "done.png", idePath .. "packages/done.png")
    download(remotePath .. "installing.png", idePath .. "packages/installing.png")
	download(remotePath .. "warning.png", idePath .. "packages/warning.png")
  end
}
