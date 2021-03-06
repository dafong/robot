require"june.extension"
local sformat  = string.format
local dgetinfo = debug.getinfo
local FILE_NAME= "app.log"
local shorts = {
   [ngx.STDERR] = "f",
   [ngx.EMERG] = "f",
   [ngx.ALERT] = "f",
   [ngx.CRIT] = "f",
   [ngx.ERR] = "e",
   [ngx.WARN] = "w",
   [ngx.NOTICE] = "n",
   [ngx.INFO] = "i",
   [ngx.DEBUG] = "d"
}

local _M = {
    level  = ngx.DEBUG,  -- same as https://github.com/openresty/lua-nginx-module#nginx-log-level-constants ngx.ERR = 4  ngx.DEBUG=8
    rolling= false,      -- if make the log rolling
    path   = "logs",     -- log path
    filename= FILE_NAME
}
local fd     = nil

local function get_log_path()
    local fn = _M.filename
    local fp = _M.path
    if not fp:start_with("/") then
        fp = sformat("%s/%s",ngx.var.document_root,fp)
    end
    if _M.rolling then
        local nt = ngx.localtime():sub(1,10)
        fn = sformat("%s.%s",fn,nt)
    end
    return sformat("%s/%s",fp,fn)
end

local function write(lv,s)
    local info=dgetinfo(3,"Sl")
    local s = sformat("[%s][%d][%s][%s:%d] %s\n",ngx.localtime(),ngx.worker.id(),shorts[lv],info.short_src,info.currentline,s)
    if fd == nil then
        fd  = io.open(get_log_path(),"a+")
    end
    fd:write(s)
    fd:flush()
end

function _M:i(s)
    if ngx.INFO > self.level then return end
    write(ngx.INFO,s)
end

function _M:d(s)
    if ngx.DEBUG > self.level   then return end
    write(ngx.DEBUG,s)
end

function _M:e(s)
    if ngx.ERR  > self.level then return end
    write(ngx.ERR,s)
end

function _M:override_ngx_log()
    ngx.log = function(lv,...)
        write(lv,...)
    end
end

return _M
