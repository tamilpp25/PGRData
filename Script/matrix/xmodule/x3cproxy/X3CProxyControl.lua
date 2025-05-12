---@class X3CProxyControl : XControl
---@field private _Model X3CProxyModel
local X3CProxyControl = XClass(XControl, "X3CProxyControl")
function X3CProxyControl:OnInit()
    --初始化内部变量
end

function X3CProxyControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function X3CProxyControl:RemoveAgencyEvent()

end

function X3CProxyControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return X3CProxyControl