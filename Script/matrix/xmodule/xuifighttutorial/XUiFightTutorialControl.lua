---@class XUiFightTutorialControl : XControl
---@field private _Model XUiFightTutorialModel
local XUiFightTutorialControl = XClass(XControl, "XUiFightTutorialControl")
function XUiFightTutorialControl:OnInit()
    --初始化内部变量
end

function XUiFightTutorialControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XUiFightTutorialControl:RemoveAgencyEvent()

end

function XUiFightTutorialControl:OnRelease()
    
end

return XUiFightTutorialControl