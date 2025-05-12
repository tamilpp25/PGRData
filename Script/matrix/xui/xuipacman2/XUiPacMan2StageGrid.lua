local XUiPacMan2StarGrid = require("XUi/XUiPacMan2/XUiPacMan2StarGrid")

---@class XUiPacMan2StageGrid : XUiNode
---@field _Control XPacMan2Control
local XUiPacMan2StageGrid = XClass(XUiNode, "XUiPacMan2StageGrid")

function XUiPacMan2StageGrid:OnStart()
    self._GridStar = {}
    XUiHelper.RegisterClickEvent(self, self.BtnChapter, function()
        self:OnClick()
    end)
    self._GridRewards = {}
    self.GridStar.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
end

---@param data XUiPacMan2StageGridData
function XUiPacMan2StageGrid:Update(data)
    self._Data = data
    self.TxtName.text = data.Name

    if data.IsPassed then
        self.CommonClear.gameObject:SetActiveEx(true)
        self.PanelLock.gameObject:SetActiveEx(false)
    else
        self.CommonClear.gameObject:SetActiveEx(false)
        if data.IsLock then
            if data.IsLock4Time then
                self.TxtLock.text = self:GetTime(data.Time) .. XUiHelper.GetText("PacMan2Unlock")
            elseif data.IsLock4PreStage then
                self.TxtLock.text = XUiHelper.GetText("PacMan2PreStage")
            end
            self.PanelLock.gameObject:SetActiveEx(true)
        else
            self.PanelLock.gameObject:SetActiveEx(false)
        end
    end

    local star = data.Star
    for i = 1, 3 do
        local grid = self._GridStar[i]
        if not grid then
            local uiStar = CS.UnityEngine.Object.Instantiate(self.GridStar, self.PanelStar)
            grid = XUiPacMan2StarGrid.New(uiStar, self)
            self._GridStar[i] = grid
        end
        grid:Open()
        grid:Update(star >= i)
    end

    local rewardId = data.RewardId
    if rewardId and rewardId ~= 0 then
        local rewardGoodList = XRewardManager.GetRewardList(data.RewardId)
        XTool.UpdateDynamicGridCommon(self._GridRewards, rewardGoodList, self.GridReward)
    else
        for i = 1, #self._GridRewards do
            self._GridRewards[i]:Close()
        end
    end
end

function XUiPacMan2StageGrid:OnClick()
    if self._Data.IsLock then
        if self._Data.IsLock4Time then
            XUiManager.TipMsg(self:GetTime(self._Data.Time) .. XUiHelper.GetText("PacMan2Unlock"))
            return
        end
        if self._Data.IsLock4PreStage then
            XUiManager.TipText("PacMan2PreStage")
            return
        end
        return
    end
    XLuaUiManager.Open("UiPacMan2PopupStageDetail", self._Data.StageId)
end

function XUiPacMan2StageGrid:GetStageId()
    if self._Data then
        return self._Data.StageId
    end
end

function XUiPacMan2StageGrid:CheckInTime()
    if self._Data.IsLock4Time then
        local time = XTime.GetServerNowTimestamp()
        if time >= self._Data.Time then
            return true
        end
    end
    return false
end

function XUiPacMan2StageGrid:UpdateTime()
    if self._Data.IsLock4Time then
        local time = XTime.GetServerNowTimestamp()
        if self._Data.Time - time < 86400 then
            self.TxtLock.text = self:GetTime(self._Data.Time) .. XUiHelper.GetText("PacMan2Unlock")
            return true
        end
    end
    return false
end

function XUiPacMan2StageGrid:GetTime(time)
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = time - currentTime

    if remainTime < 86400 then
        return XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
    end
    return XUiHelper.GetTimeMonthDay(time)
end

return XUiPacMan2StageGrid