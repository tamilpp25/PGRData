---@class XFightLevelMusicGameAgency : XAgency
---@field private _Model XFightLevelMusicGameModel
local XFightLevelMusicGameAgency = XClass(XAgency, "XFightLevelMusicGameAgency")
function XFightLevelMusicGameAgency:OnInit()
    --初始化一些变量
end

function XFightLevelMusicGameAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XFightLevelMusicGameAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

return XFightLevelMusicGameAgency