---@class XCommonCharacterFiltControl : XControl
---@field _Model XCommonCharacterFiltModel
local XCommonCharacterFiltControl = XClass(XControl, "XCommonCharacterFiltControl")
function XCommonCharacterFiltControl:OnInit()
    --初始化内部变量
end

function XCommonCharacterFiltControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XCommonCharacterFiltControl:RemoveAgencyEvent()

end

function XCommonCharacterFiltControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return XCommonCharacterFiltControl