local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local XRedPointConditionConnectingLine = require("XRedPoint/XRedPointConditions/XRedPointConditionConnectingLine")

---@class XConnectingLineAgency : XAgency
---@field private _Model XConnectingLineModel
local XConnectingLineAgency = XClass(XFubenActivityAgency, "XConnectingLineAgency")
function XConnectingLineAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
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
    return self._Model:IsNextStageCanChallenge4RedPoint()
            or self:IsChapterJustUnlock()
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

function XConnectingLineAgency:ExCheckIsShowRedPoint()
    return XRedPointConditionConnectingLine.Check()
end

function XConnectingLineAgency:ExCheckInTime()
    return self._Model:IsActivityOpen()
end

function XConnectingLineAgency:IsChapterJustUnlock()
    local chapterList = self._Model:GetChapterList()
    for i = 1, #chapterList do
        local config = chapterList[i]
        local chapterId = config.Id
        if chapterId then
            if self._Model:IsChapterUnlock(chapterId) then
                local timeId = self._Model:GetChapterTimeId(chapterId)
                if XFunctionManager.CheckInTimeByTimeId(timeId, true) then
                    if self._Model:IsChapterJustUnlock(chapterId) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function XConnectingLineAgency:GetItemId()
    return self._Model:GetCoinItemId()
end

return XConnectingLineAgency