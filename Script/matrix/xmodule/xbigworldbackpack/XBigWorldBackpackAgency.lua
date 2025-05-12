---@class XBigWorldBackpackAgency : XAgency
---@field private _Model XSkyGardenBackpackModel
local XBigWorldBackpackAgency = XClass(XAgency, "XBigWorldBackpackAgency")

function XBigWorldBackpackAgency:OnInit()
    --初始化一些变量
end

function XBigWorldBackpackAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XBigWorldBackpackAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

return XBigWorldBackpackAgency