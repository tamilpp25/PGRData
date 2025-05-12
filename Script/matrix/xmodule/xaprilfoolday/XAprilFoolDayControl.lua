---@class XAprilFoolDayControl : XControl
---@field private _Model XAprilFoolDayModel
local XAprilFoolDayControl = XClass(XControl, "XAprilFoolDayControl")
function XAprilFoolDayControl:OnInit()
    --初始化内部变量
end

function XAprilFoolDayControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XAprilFoolDayControl:RemoveAgencyEvent()

end

function XAprilFoolDayControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return XAprilFoolDayControl