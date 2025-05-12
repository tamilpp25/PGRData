---@class XDlcWorldControl : XControl
---@field private _Model XDlcWorldModel
local XDlcWorldControl = XClass(XControl, "XDlcWorldControl")
function XDlcWorldControl:OnInit()
    --初始化内部变量
end

function XDlcWorldControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XDlcWorldControl:RemoveAgencyEvent()

end

function XDlcWorldControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

return XDlcWorldControl