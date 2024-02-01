---@class XCerberusGameControl : XControl
---@field private _Model XCerberusGameModel
local XCerberusGameControl = XClass(XControl, "XCerberusGameControl")
function XCerberusGameControl:OnInit()
    --初始化内部变量
end

function XCerberusGameControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XCerberusGameControl:RemoveAgencyEvent()

end

function XCerberusGameControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return XCerberusGameControl