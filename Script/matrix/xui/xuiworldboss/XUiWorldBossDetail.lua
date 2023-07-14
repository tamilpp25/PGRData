local XUiWorldBossDetail = XLuaUiManager.Register(XLuaUi, "UiWorldBossDetail")
local XUiGridBuff = require("XUi/XUiWorldBoss/XUiGridBuff")
local CSTextManagerGetText = CS.XTextManager.GetText
local Normal = CS.UiButtonState.Normal
local Disable = CS.UiButtonState.Disable
function XUiWorldBossDetail:OnStart(stageData, areaId, cb, rwardCb)
    self.GridList = {}
    self.BuffGridList = {}
    self.StageData = stageData
    self.AreaId = areaId
    self.Stage = stageData:GetStageCfg()
    self.CallBack = cb
    self.RwardCb = rwardCb
    self:SetButtonCallBack()
    self.BuffItem.gameObject:SetActiveEx(false)
    self.DropGridCommon.gameObject:SetActiveEx(false)
    self:InitStarPanels()
end

function XUiWorldBossDetail:OnEnable()
    XDataCenter.WorldBossManager.CheckWorldBossActivityReset()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("AnimBegin", handler(self, function()
        XLuaUiManager.SetMask(false)
    end))
    self:Refresh()
end

function XUiWorldBossDetail:InitStarPanels()
    self.GridStarList = {
        XUiGridStageStar.New(self.GridStageStar1),
        XUiGridStageStar.New(self.GridStageStar2),
        XUiGridStageStar.New(self.GridStageStar3),
    }
end

function XUiWorldBossDetail:SetButtonCallBack()
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
    self.BtnMask.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnFinish.CallBack = function()
        self:OnBtnFinishClick()
    end
end

function XUiWorldBossDetail:OnBtnCloseClick()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("AnimEnd", handler(self, function()
        XLuaUiManager.SetMask(false)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        if self.CallBack then
            self.CallBack()
        end
        self:Close()
    end))
end

function XUiWorldBossDetail:OnBtnFinishClick()
    XDataCenter.WorldBossManager.GetAttributeAreaStageReward(self.AreaId, self.Stage.StageId, function()
        self:Refresh()
        if self.RwardCb then
            self.RwardCb()
        end

    end)
end

function XUiWorldBossDetail:OnBtnEnterClick()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    local attributeArea = XDataCenter.WorldBossManager.GetAttributeAreaById(self.AreaId)
    local actionPointId = worldBossActivity:GetActionPointId()
    local challengeCount = attributeArea:GetChallengeCount()
    local maxChallengeCount = attributeArea:GetMaxChallengeCount()
    local usePowerCount = self.StageData:GetConsumeCount()
    local powerCount = XDataCenter.ItemManager.GetCount(actionPointId)

    if self.BtnEnter.ButtonState == Disable then
        XUiManager.TipMsg(self.StageData:GetLockDesc())
        return
    end

    if maxChallengeCount - challengeCount == 0 then
        XUiManager.TipText("WorldBossNoChallengeCount")
        return
    end

    if powerCount < usePowerCount then
        XUiManager.TipText("WorldBossNoPower")
        return
    end

    if self.Stage == nil then
        XLog.Error("XUiWorldBossDetail.OnBtnEnterClick: Can not find stage!")
        return
    end

    local attributeArea = XDataCenter.WorldBossManager.GetAttributeAreaById(self.AreaId)
    local IsFinish = self.StageData:GetIsFinish()
    local data = { WorldBossTeamDatas = attributeArea:GetCharacterDatas() }
    if IsFinish then
        self:TipDialog(nil, function()
            XLuaUiManager.Open("UiNewRoomSingle", self.Stage.StageId, data)
        end)
    else
        XLuaUiManager.Open("UiNewRoomSingle", self.Stage.StageId, data)
    end



end

function XUiWorldBossDetail:TipDialog(cancelCb, confirmCb)
    local tipTitle = CSTextManagerGetText("TipTitle")
    local content = CSTextManagerGetText("WorldBossFinishStageFightHint")

    XLuaUiManager.Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, cancelCb, confirmCb)
end

function XUiWorldBossDetail:Refresh()
    self:UpdateCommon()
    self:UpdateSchedule()
    --self:UpdateBuffs()
    self:UpdateRewards()
    self:UpdateDrop()
    self:UpdateDifficulty()
    self:UpdateStageFightControl()--更新战力限制提示
    self:UpdateBtnEnter()
    self:UpdateBtnFinish()
end

function XUiWorldBossDetail:UpdateCommon()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    local attributeArea = XDataCenter.WorldBossManager.GetAttributeAreaById(self.AreaId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.Stage.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.Stage.StageId)
    local stageTitle = XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(stageInfo.ChapterId)
    local actionPointId = worldBossActivity:GetActionPointId()
    local maxPowerCount = worldBossActivity:GetMaxActionPoint()
    local challengeCount = attributeArea:GetChallengeCount()
    local maxChallengeCount = attributeArea:GetMaxChallengeCount()
    local usePowerCount = self.StageData:GetConsumeCount()

    self.TxtTitle.text = self.Stage.Name
    self.TxtDesc.text = self.Stage.Description

    self.ChallengText.text = CSTextManagerGetText("WorldBossAttributeChallengeText")
    self.ChallengNum.text = string.format("%d/%d", maxChallengeCount - challengeCount, maxChallengeCount)

    local item = XUiGridCommon.New(self, self.PowerItemGrid)
    item:Refresh(actionPointId)
    local powerCount = XDataCenter.ItemManager.GetCount(actionPointId)
    self.PowerText.text = CSTextManagerGetText("WorldBossActionPoint")
    self.PowerNum.text = string.format("%d/%d", powerCount, maxPowerCount)


    local useItem = XUiGridCommon.New(self, self.UsePowerItemGrid)
    useItem:Refresh(actionPointId)
    self.UsePowerNum.text = usePowerCount

    for i = 1, 3 do
        self.GridStarList[i]:Refresh(self.Stage.StarDesc[i], true)
    end
end

function XUiWorldBossDetail:UpdateDifficulty()
    local nanDuIcon = XDataCenter.FubenManager.GetDifficultIcon(self.Stage.StageId)
    self.RImgNandu:SetRawImage(nanDuIcon)
end

function XUiWorldBossDetail:UpdateSchedule()
    local finishPercent = self.StageData:GetFinishPercent()
    local IsLock = self.StageData:GetIsLock()
    self.ScheduleImg.fillAmount = finishPercent
    self.TxtScheduleNum.text = string.format("%d%s", math.floor(finishPercent * 100), "%")
    self.TextScheduleName.text = CSTextManagerGetText("WorldBossExploreScheduleText")
    self.PanelBossSchedule.gameObject:SetActiveEx(not IsLock)
end

function XUiWorldBossDetail:UpdateBtnEnter()
    self.BtnEnter:SetButtonState(self.StageData:GetIsLock() and Disable or Normal)
end

function XUiWorldBossDetail:UpdateBtnFinish()
    local IsGeted = self.StageData:GetIsRewardGeted()
    local IsCanGet = self.StageData:GetIsFinish()
    local rewardId = self.StageData:GetFinishReward()
    self.RwardPanel.gameObject:SetActiveEx(rewardId ~= 0)
    self.RwardEffect.gameObject:SetActiveEx(not IsGeted and IsCanGet)
    self.RwardFinish.gameObject:SetActiveEx(IsGeted)
    self.BtnFinish.gameObject:SetActiveEx(not IsGeted and IsCanGet)
end

function XUiWorldBossDetail:UpdateBuffs()
    local buffIds = self.StageData:GetBuffIds()
    if buffIds then
        for i, id in pairs(buffIds) do
            local grid
            if self.BuffGridList[i] then
                grid = self.BuffGridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.BuffItem, self.PanelDropContent)
                grid = XUiGridBuff.New(ui, true)
                self.BuffGridList[i] = grid
            end
            local buffData = XDataCenter.WorldBossManager.GetWorldBossBuffById(id)
            grid:UpdateData(buffData)
            grid.GameObject:SetActiveEx(true)
        end
    end

    local buffsCount = 0
    if buffIds then
        buffsCount = #buffIds
    end

    for j = 1, #self.BuffGridList do
        if j > buffsCount then
            self.BuffGridList[j].GameObject:SetActiveEx(false)
        end
    end
end

function XUiWorldBossDetail:UpdateRewards()
    local rewardId = self.StageData:GetFinishReward()
    if rewardId == 0 then
        return
    end
    local rewards = XRewardManager.GetRewardList(rewardId)
    if rewards then
        for i, item in pairs(rewards) do
            local grid = XUiGridCommon.New(self, self.RwardGridCommon)
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
            break
        end
    end
end

function XUiWorldBossDetail:UpdateDrop()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageData:GetId())
    local rewards = XRewardManager.GetRewardListNotCount(stageCfg.FinishRewardShow)
    if rewards then
        for i, item in pairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.DropGridCommon, self.PanelDropContent)
                grid = XUiGridCommon.New(self, ui)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActiveEx(false)
        end
    end
end

function XUiWorldBossDetail:UpdateStageFightControl()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.Stage.StageId)
    if self.StageFightControl == nil then
        self.StageFightControl = XUiStageFightControl.New(self.PanelStageFightControl, self.Stage.FightControlId)
    end
    if not stageInfo.Passed and stageInfo.Unlock then
        self.StageFightControl.GameObject:SetActiveEx(true)
        self.StageFightControl:UpdateInfo(self.Stage.FightControlId)
    else
        self.StageFightControl.GameObject:SetActiveEx(false)
    end
end