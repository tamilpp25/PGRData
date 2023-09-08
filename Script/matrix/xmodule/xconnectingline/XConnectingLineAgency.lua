---@class XConnectingLineAgency : XAgency
---@field private _Model XConnectingLineModel
local XConnectingLineAgency = XClass(XAgency, "XConnectingLineAgency")
function XConnectingLineAgency:OnInit()
    --初始化一些变量
end

function XConnectingLineAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyConnectingLineData = Handler(self, self.NotifyConnectingLineData)
end

function XConnectingLineAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------
function XConnectingLineAgency:IsShowRedPoint()
    self._Model:InitStage()
    return self._Model:IsNextStageCanChallenge()
end

function XConnectingLineAgency:GetGame()
    return self._Model:GetGame()
end
----------public end----------

----------private start----------

function XConnectingLineAgency:NotifyConnectingLineData(data)
    self._Model:SetDataFromServer(data.ConnectingLineData)
end

----------private end----------

return XConnectingLineAgency