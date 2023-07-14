local XUiTRPGPanelEnter = XClass(nil, "XUiTRPGPanelEnter")
local XUiTRPGGridBossReward = require("XUi/XUiTRPG/XUiTRPGWorldBoss/XUiTRPGGridBossReward")
local CSTextManagerGetText = CS.XTextManager.GetText
local PanelState = {
    Enter = 1,
    Detail = 2
}

function XUiTRPGPanelEnter:Ctor(ui, setPanelStateCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.SetPanelStateCb = setPanelStateCb
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:SetPanelTime()
    self:InitPhasesRewardGrid()
end

function XUiTRPGPanelEnter:SetButtonCallBack()
    self.BtnBoss.CallBack = function()
        self:OnBtnBossClick()
    end
    self.BtnTalent.CallBack = function()
        self:OnBtnTalentClick()
    end
end

function XUiTRPGPanelEnter:OnBtnBossClick()
    if self.SetPanelStateCb then
        self.SetPanelStateCb(PanelState.Detail)
    end
end

function XUiTRPGPanelEnter:OnBtnTalentClick()
    XLuaUiManager.Open("UiTRPGTalentOverView")
end

function XUiTRPGPanelEnter:SetPanelTime()
    local openState, time = XDataCenter.TRPGManager.GetWorldBossOpenState()
    self.TimeText.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiTRPGPanelEnter:InitPhasesRewardGrid()
    local UpdatePanelPhasesRewardCb = function()
        self:UpdatePanelPhasesReward()
    end

    self.PhasesRewardGrids = {}
    self.PhasesRewardGridRects = {}
    self.RewardItem.gameObject:SetActiveEx(false)
    local rewardCount = XTRPGConfigs.GetBossPhasesRewardMaxNum()
    for i = 1, rewardCount do
        local grid = self.PhasesRewardGrids[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.RewardItem)
            obj.gameObject:SetActiveEx(true)
            obj.transform:SetParent(self.PanelReward, false)
            grid = XUiTRPGGridBossReward.New(obj, UpdatePanelPhasesRewardCb, i)
            self.PhasesRewardGrids[i] = grid
            self.PhasesRewardGridRects[i] = grid.Transform:GetComponent("RectTransform")
        end
    end
end

function XUiTRPGPanelEnter:UpdatePanelPhasesReward()
    local percent = XDataCenter.TRPGManager.GetWorldBossCurHpPercer()
    self.ScheduleImg.fillAmount = percent
    self.TxtDailyActive.text = string.format("%d%s", math.ceil(percent * 100), "%")
    self.ScheduleText.text = CSTextManagerGetText("WorldBossBossAreaSchedule")

    -- 自适应
    local activeProgressRectSize = self.PanelReward.rect.size
    for i = 1, #self.PhasesRewardGrids do
        local rewardPercent = XTRPGConfigs.GetBossPhasesRewardPercent(i)
        local valOffset = 1 - rewardPercent * 0.01
        local adjustPosition = CS.UnityEngine.Vector3(activeProgressRectSize.x * valOffset - activeProgressRectSize.x / 2, 0, 0)
        self.PhasesRewardGridRects[i].anchoredPosition3D = adjustPosition

        self.PhasesRewardGrids[i]:UpdateData()
    end
end

function XUiTRPGPanelEnter:SetShow(IsShow)
    self.GameObject:SetActiveEx(IsShow)
end

return XUiTRPGPanelEnter