---@class XBigWorldCommonControl : XControl
---@field private _Model XBigWorldCommonModel
local XBigWorldCommonControl = XClass(XControl, "XBigWorldCommonControl")
function XBigWorldCommonControl:OnInit()
    --初始化内部变量
end

function XBigWorldCommonControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldCommonControl:RemoveAgencyEvent()

end

function XBigWorldCommonControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

return XBigWorldCommonControl