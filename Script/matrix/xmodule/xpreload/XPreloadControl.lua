---@class XPreloadControl : XControl
---@field private _Model XPreloadModel
local XPreloadControl = XClass(XControl, "XPreloadControl")
function XPreloadControl:OnInit()
    --初始化内部变量
end

function XPreloadControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XPreloadControl:RemoveAgencyEvent()

end

function XPreloadControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return XPreloadControl