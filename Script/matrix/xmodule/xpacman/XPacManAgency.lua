---@class XPacManAgency : XAgency
---@field private _Model XPacManModel
local XPacManAgency = XClass(XAgency, "XPacManAgency")
function XPacManAgency:OnInit()
    --初始化一些变量
end

function XPacManAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XPacManAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XPacManAgency:OpenMainUi()
    XLuaUiManager.Open("UiPacMan")
end

return XPacManAgency