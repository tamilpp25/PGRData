local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XLineArithmeticAgency : XFubenActivityAgency
---@field private _Model XLineArithmeticModel
local XLineArithmeticAgency = XClass(XFubenActivityAgency, "XLineArithmeticAgency")
function XLineArithmeticAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
end

function XLineArithmeticAgency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyLineArithmeticActivity = handler(self, self.NotifyLineArithmeticActivity)
end

function XLineArithmeticAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XLineArithmeticAgency:RequestStart(stageId)
    XNetwork.Call("LineArithmeticStartRequest", { StageId = stageId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local gameData = {
            StageId = stageId,
            StageStartTime = XTime.GetServerNowTimestamp(),
            OperatorRecords = {}
        }
        self._Model:SetCurrentGameData(gameData)
    end)
end

function XLineArithmeticAgency:RequestOperation(stageId, round, star, points)
    self._Model:SetRequesting(true)
    star = self._Model:HideExtraStar(star)
    local content = {
        StageId = stageId,
        Round = round,
        FinishTargetCount = star,
        Points = points,
    }
    XNetwork.Call("LineArithmeticOperatorRequest", content, function(res)
        self._Model:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

function XLineArithmeticAgency:RequestSettle(stageId, star, operationCount, useHelp, jsonRecord)
    star = self._Model:HideExtraStar(star)
    local content = {
        StageId = stageId,
        SettleType = 1,
        FinishTargetCount = star,
        LineCount = operationCount,
        TipType = useHelp and 1 or 0,
        GridInfo = jsonRecord,
    }
    XNetwork.Call("LineArithmeticSettleRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        XLuaUiManager.SafeClose("UiLineArithmeticTargetPopupTips")
        XLuaUiManager.Open("UiLineArithmeticTargetPopup")
        self._Model:SetCurrentGameData(false)
    end)
end

function XLineArithmeticAgency:RequestRestart(stageId)
    local content = {
        StageId = stageId,
        SettleType = 2,
        FinishTargetCount = 0,
    }
    XNetwork.Call("LineArithmeticSettleRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

function XLineArithmeticAgency:RequestAbandon(stageId)
    local content = {
        StageId = stageId,
        SettleType = 3,
        FinishTargetCount = 0,
    }
    XNetwork.Call("LineArithmeticSettleRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetCurrentGameData(false)
        XEventManager.DispatchEvent(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_STAGE)
    end)
end

function XLineArithmeticAgency:NotifyLineArithmeticActivity(data)
    self._Model:SetDataFromServer(data)
end

function XLineArithmeticAgency:OpenMainUi()
    if not self._Model:CheckInTime() then
        XUiManager.TipText("FubenRepeatNotInActivityTime")
        return
    end
    if not XFunctionManager.DetectionFunction(self:ExGetFunctionNameType()) then
        return
    end
    XLuaUiManager.Open("UiLineArithmeticMain")
end

function XLineArithmeticAgency:ExCheckInTime()
    return self._Model:CheckInTime()
end

function XLineArithmeticAgency:ExGetProgressTip()
    local chapters = self._Model:GetAllChaptersCurrentActivity()
    local starAmount = 0
    local maxStarAmount = 0
    for i, chapterConfig in pairs(chapters) do
        local chapterId = chapterConfig.Id
        starAmount = starAmount + self._Model:GetStarAmount(chapterId)
        maxStarAmount = maxStarAmount + self._Model:GetMaxStarAmount(chapterId)
    end
    return XUiHelper.GetText("LineArithmeticProgress", math.floor(starAmount / maxStarAmount * 100) .. "%")
end

function XLineArithmeticAgency:ExGetFunctionNameType()
    return XFunctionManager.FunctionName.LineArithmetic
end

function XLineArithmeticAgency:IsShowRedDot()
    if self:ExGetIsLocked() then
        return false
    end

    local chapters = self._Model:GetAllChaptersCurrentActivity()
    for i, chapterConfig in pairs(chapters) do
        local chapterId = chapterConfig.Id
        if self._Model:IsChapterOpen(chapterId) then
            local isNewChapter = self._Model:IsNewChapter(chapterId)
            if isNewChapter then
                return true
            end
        end
    end

    local taskDataList = XDataCenter.TaskManager.GetLineArithmeticTaskList()
    for i = 1, #taskDataList do
        local taskData = taskDataList[i]
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end

    return false
end

function XLineArithmeticAgency:SaveCurrentGameData2Config()
    self._Model:SaveCurrentGameData2Config()
end

function XLineArithmeticAgency:IsOnStage(stageId)
    if self._Model:IsOnGame(stageId) then
        return true
    end
    return false
end

return XLineArithmeticAgency