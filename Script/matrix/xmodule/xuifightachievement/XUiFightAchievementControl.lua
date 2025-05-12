---@class XUiFightAchievementControl : XControl
---@field private _Model XUiFightAchievementModel
local XUiFightAchievementControl = XClass(XControl, "XUiFightAchievementControl")
function XUiFightAchievementControl:OnInit()
    --初始化内部变量
end

function XUiFightAchievementControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XUiFightAchievementControl:RemoveAgencyEvent()

end

function XUiFightAchievementControl:OnRelease()
    
end

return XUiFightAchievementControl