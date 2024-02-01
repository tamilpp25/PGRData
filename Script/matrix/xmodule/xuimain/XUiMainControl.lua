---@class XUiMainControl : XControl
---@field private _Model XUiMainModel
local XUiMainControl = XClass(XControl, "XUiMainControl")
function XUiMainControl:OnInit()
    --初始化内部变量
end

function XUiMainControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XUiMainControl:RemoveAgencyEvent()

end

function XUiMainControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return XUiMainControl