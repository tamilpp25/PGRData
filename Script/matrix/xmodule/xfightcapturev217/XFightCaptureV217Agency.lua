---@class XFightCaptureV217Agency : XAgency
---@field private _Model XFightCaptureV217Model
local XFightCaptureV217Agency = XClass(XAgency, "XFightCaptureV217Agency")
function XFightCaptureV217Agency:OnInit()
    --初始化一些变量
end

function XFightCaptureV217Agency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XFightCaptureV217Agency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

return XFightCaptureV217Agency