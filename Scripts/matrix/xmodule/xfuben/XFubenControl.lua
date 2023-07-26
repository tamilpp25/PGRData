---@class XFubenControl : XControl
---@field private _Model XFubenModel
local XFubenControl = XClass(XControl, "XFubenControl")
function XFubenControl:OnInit()
    --初始化内部变量
end

function XFubenControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XFubenControl:RemoveAgencyEvent()

end

function XFubenControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return XFubenControl