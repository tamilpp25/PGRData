---@class XBigWorldGamePlayControl : XControl
---@field private _Model XBigWorldGamePlayModel
local XBigWorldGamePlayControl = XClass(XControl, "XBigWorldGamePlayControl")
function XBigWorldGamePlayControl:OnInit()
    --初始化内部变量
end

function XBigWorldGamePlayControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldGamePlayControl:RemoveAgencyEvent()

end

function XBigWorldGamePlayControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

return XBigWorldGamePlayControl