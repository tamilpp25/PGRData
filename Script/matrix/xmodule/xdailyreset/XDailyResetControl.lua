---@class XDailyResetControl : XControl
---@field private _Model XDailyResetModel
local XDailyResetControl = XClass(XControl, "XDailyResetControl")
function XDailyResetControl:OnInit()
    --初始化内部变量
end

function XDailyResetControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XDailyResetControl:RemoveAgencyEvent()

end

function XDailyResetControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

return XDailyResetControl