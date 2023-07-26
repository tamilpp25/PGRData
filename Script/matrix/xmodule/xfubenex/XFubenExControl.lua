---@class XFubenExControl : XControl
---@field private _Model XFubenExModel
local XFubenExControl = XClass(XControl, "XFubenExControl")
function XFubenExControl:OnInit()
    --初始化内部变量
end

function XFubenExControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XFubenExControl:RemoveAgencyEvent()

end

function XFubenExControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

return XFubenExControl