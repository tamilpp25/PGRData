---@class XUiFightAchievementAgency : XAgency
---@field private _Model XUiFightAchievementModel
local XUiFightAchievementAgency = XClass(XAgency, "XUiFightAchievementAgency")
function XUiFightAchievementAgency:OnInit()
    --初始化一些变量
end

function XUiFightAchievementAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XUiFightAchievementAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

function XUiFightAchievementAgency:GetConfig(templateId)
    return self._Model:GetConfig(templateId)
end

----------public end----------

----------private start----------


----------private end----------

return XUiFightAchievementAgency