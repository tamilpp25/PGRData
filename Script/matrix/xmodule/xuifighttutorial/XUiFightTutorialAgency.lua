---@class XUiFightTutorialAgency : XAgency
---@field private _Model XUiFightTutorialModel
local XUiFightTutorialAgency = XClass(XAgency, "XUiFightTutorialAgency")
function XUiFightTutorialAgency:OnInit()
    --初始化一些变量
end

function XUiFightTutorialAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XUiFightTutorialAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

function XUiFightTutorialAgency:GetConfig(templateId)
    return self._Model:GetConfig(templateId)
end

----------public end----------

----------private start----------


----------private end----------

return XUiFightTutorialAgency