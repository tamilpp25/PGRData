local XUiPanelEnter = XClass(nil, "XUiPanelEnter")
local XUiGridBossReward = require("XUi/XUiWorldBoss/XUiGridBossReward")
local CSTextManagerGetText = CS.XTextManager.GetText
local ColorBlack = CS.XGame.ClientConfig:GetString("ShopCanBuyColor")
local ProTime = 2
local PanelState = {
    Enter = 1,
    Detail = 2
}

function XUiPanelEnter:Ctor(ui, base, areaId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.AreaId = areaId
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:SetPanelTime()
    self:SetPanelLevel()
    self:InitPhasesRewardGrid()
end

function XUiPanelEnter:SetButtonCallBack()
    self.BtnBoss.CallBack = function()
        self:OnBtnBossClick()
    end
    self.BtnSwich.CallBack = function()
        self:OnBtnSwichClick()
    end
end

function XUiPanelEnter:OnBtnBossClick()
    self.Base:SetPanelState(PanelState.Detail)
end

function XUiPanelEnter:OnBtnSwichClick()
    local curLevel = XDataCenter.WorldBossManager.GetBossStageLevel()
    local bossArea = XDataCenter.WorldBossManager.GetBossAreaById(self.AreaId)
    XLuaUiManager.Open("UiWorldBossLevelSelect", bossArea:GetStageId(), curLevel, function (level)
            XDataCenter.WorldBossManager.SetBossStageLevel(level)
            self:SetPanelLevel()
            self.Base.PanelDetail:UpdateRewardList()
        end)

end

function XUiPanelEnter:SetPanelTime()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    local nowTime = XTime.GetServerNowTimestamp()
    self.TimeText.text = XUiHelper.GetTime(worldBossActivity:GetEndTime() - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiPanelEnter:SetPanelLevel()
    local bossArea = XDataCenter.WorldBossManager.GetBossAreaById(self.AreaId)
    local level = XDataCenter.WorldBossManager.GetBossStageLevel()
    local bossStageCfg = XDataCenter.WorldBossManager.GetBossStageGroupByIdAndLevel(bossArea:GetStageId(), level)
    self.LevelText.text = bossStageCfg.Desc
    self.LevelText.color = XUiHelper.Hexcolor2Color(bossStageCfg.DescColor or ColorBlack)
end

function XUiPanelEnter:InitPhasesRewardGrid()
    self.PhasesRewardGrids = {}
    self.PhasesRewardGridRects = {}
    self.RewardItem.gameObject:SetActiveEx(false)
    local bossArea = XDataCenter.WorldBossManager.GetBossAreaById(self.AreaId)
    local phasesIds = bossArea:GetPhasesRewardIds()
    local rewardCount = #phasesIds
    for i = 1,rewardCount do
        local grid = self.PhasesRewardGrids[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.RewardItem)
            obj.gameObject:SetActiveEx(true)
            obj.transform:SetParent(self.PanelReward, false)
            grid = XUiGridBossReward.New(obj, self, bossArea:GetId())
            self.PhasesRewardGrids[i] = grid
            self.PhasesRewardGridRects[i] = grid.Transform:GetComponent("RectTransform")
        end
    end
end

function XUiPanelEnter:UpdatePanelPhasesReward()
    local bossArea = XDataCenter.WorldBossManager.GetBossAreaById(self.AreaId)
    self.ScheduleImg.fillAmount = bossArea:GetHpPercent()
    local hpProcess = bossArea:GetHpPercent() * 100 -- 海外修改如果小于百分之一，向上取整
    if hpProcess > 1 then
        self.TxtDailyActive.text = string.format("%d%s",math.floor(hpProcess),"%")
    else
        self.TxtDailyActive.text = string.format("%d%s",math.ceil(hpProcess),"%")
    end
    self.ScheduleText.text = CSTextManagerGetText("WorldBossBossAreaSchedule")
    local phasesIds = bossArea:GetPhasesRewardIds()
    local rewardCount = #phasesIds
    for i = 1, rewardCount do
        local reward = bossArea:GetRewardEntityById(phasesIds[i])
        self.PhasesRewardGrids[i]:UpdateData(reward)
    end

    -- 自适应
    local activeProgressRectSize = self.PanelReward.rect.size
    for i = 1, #self.PhasesRewardGrids do
        local reward = bossArea:GetRewardEntityById(phasesIds[i])
        local valOffset = 1 - reward:GetHpPercent() * 0.01
        local adjustPosition = CS.UnityEngine.Vector3(activeProgressRectSize.x * valOffset - activeProgressRectSize.x / 2, 0, 0)
        self.PhasesRewardGridRects[i].anchoredPosition3D = adjustPosition
    end
end

function XUiPanelEnter:SetShow(IsShow)
    self.GameObject:SetActiveEx(IsShow)
end

return XUiPanelEnter