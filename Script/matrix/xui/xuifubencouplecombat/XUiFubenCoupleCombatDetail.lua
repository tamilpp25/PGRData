-- v1.32 关卡介绍
--====================================================================
local XGridStageDesc  = XClass(nil, "XGridStageDesc")

function XGridStageDesc:Ctor(ui, featureId, clickCB)
    self.Ui = ui
    self.FeatureId = featureId
    self.ClickCB = clickCB
    XUiHelper.InitUiClass(self, ui)
    self:AddClickListener()
end

function XGridStageDesc:AddClickListener()
    XUiHelper.RegisterClickEvent(self, self.RImgIcon, self.Click)
end

function XGridStageDesc:Refresh(desc, featureId)
    self.FeatureId = featureId
    if XTool.IsNumberValid(featureId) then
        self.RImgIcon:SetRawImage(XFubenCoupleCombatConfig.GetFeatureIcon(featureId))
    end
    self.TxtDesc.text = desc
end

function XGridStageDesc:Click()
    if self.ClickCB then
        self.ClickCB(self.FeatureId)
    end
end

function XGridStageDesc:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

--====================================================================

local XUiGridStageBuff = require("XUi/XUiFubenCoupleCombat/ChildItem/XUiGridStageBuff")
local XUiFubenCoupleCombatDetail = XLuaUiManager.Register(XLuaUi, "UiFubenCoupleCombatDetail")

function XUiFubenCoupleCombatDetail:OnAwake()
    self:AutoAddListener()
    self.GridBuffList = {}
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiFubenCoupleCombatDetail:OnStart(rootUi)
    self.GridList = {}
    self.DescList = {}
    self.RootUi = rootUi
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenCoupleCombatDetail:OnEnable()
    self.IsOpen = true
end

function XUiFubenCoupleCombatDetail:OnDisable()
    self.IsOpen = false
end

function XUiFubenCoupleCombatDetail:SetStageDetail(stageId)
    self.StageId = stageId
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)

    self.StageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    self.StageInterInfo = XFubenCoupleCombatConfig.GetStageInfo(self.StageId)
    self.IsPassed =  self.StageInfo and self.StageInfo.Passed
    if not self.StageInterInfo then return end

    local showReset = false
    local useList = XDataCenter.FubenCoupleCombatManager.GetStageUsedCharacter(self.StageId)
    if useList and next(useList) then
        showReset = true
    end

    self.BtnEnter.gameObject:SetActiveEx(not showReset)
    self.BtnReset.gameObject:SetActiveEx(showReset)

    self:UpdateDesc()
    self:UpdateCommon()
    self:UpdateRewards()
    self:UpdateFeature()
    --self:UpdateStageFightControl()--更新战力限制提示
end

function XUiFubenCoupleCombatDetail:InitStarPanels()
    self.GridStarList = {}
    for i = 1, 3 do
        local ui = self.Transform:Find("SafeAreaContentPane/PanelDetail/PanelTargetList/GridStageStar" .. i)
        ui.gameObject:SetActive(true)
        local grid = XUiGridStageStar.New(ui)
        self.GridStarList[i] = grid
    end
end

function XUiFubenCoupleCombatDetail:UpdateDesc()
    self.Skill.gameObject:SetActiveEx(false)
    for i, desc in ipairs(self.StageInterInfo.Intro) do
        local featureId = self.StageInterInfo.Feature[i]
        if not self.DescList[i] then
            self.DescList[i] = XGridStageDesc.New(XUiHelper.Instantiate(self.Skill, self.DescContent), featureId, function(id) self:ShowInfo(id) end)
        end
        self.DescList[i]:Refresh(desc, featureId)
        self.DescList[i]:SetActive(true)
    end

    -- 隐藏多余
    for i = #self.StageInterInfo.Intro + 1, #self.DescList do
        self.DescList[i]:SetActive(false)
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.DescContent)
end

function XUiFubenCoupleCombatDetail:ShowInfo(featureId)
    if not XTool.IsNumberValid(featureId) then
        return
    end
    local name = XFubenCoupleCombatConfig.GetFeatureName(featureId)
    local desc = XFubenCoupleCombatConfig.GetFeatureDescription(featureId)
    XUiManager.UiFubenDialogTip(name, desc)
end

function XUiFubenCoupleCombatDetail:AutoAddListener()
    self.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
    self.BtnReset.CallBack = function() self:OnBtnResetClick() end
    self.BtnCloseDetail.CallBack = function() self:OnBtnCloseDetailClick() end
end
-- auto
function XUiFubenCoupleCombatDetail:OnBtnResetClick()
    XUiManager.DialogTip(nil, CSXTextManagerGetText("CoupleCombatResetStageTip"), XUiManager.DialogType.Normal, nil, function()
        XDataCenter.FubenCoupleCombatManager.ResetStage(self.StageId, function()
            XUiManager.TipText("CoupleCombatResetStageSucc")
            self:Hide()
        end)
    end)
end

function XUiFubenCoupleCombatDetail:OnBtnCloseDetailClick()
    self:Hide()
end

function XUiFubenCoupleCombatDetail:OnBtnEnterClick()
    if self.IsPlaying then
        return
    end

    if XDataCenter.FubenManager.CheckPreFight(self.StageCfg) then
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE)

        -- 如果有第五期，请务必转移到UiBattleRoleRoom
        -- proxy需要兼容
        XLuaUiManager.Open("UiBattleRoleRoom", self.StageId)
        self:Close()
    end
end

function XUiFubenCoupleCombatDetail:Hide()
    if self.IsPlaying or not self.IsOpen then
        return
    end

    self.IsPlaying = true
    self:PlayAnimation("AnimEnd", handler(self, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.IsPlaying = false
        self:Close()

        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
    end))
end

function XUiFubenCoupleCombatDetail:UpdateCommon()
    local stageId = self.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)

    self.TxtTitle.text = stageCfg.Name
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(stageId)

    local firstDrop = false
    if not stageInfo.Passed then
        local cfg = XDataCenter.FubenManager.GetStageLevelControl(stageId)
        if cfg and cfg.FirstRewardShow > 0 or stageCfg.FirstRewardShow > 0 then
            firstDrop = true
        end
    end
    self.TxtFirstDrop.gameObject:SetActive(firstDrop)
    self.TxtDrop.gameObject:SetActive(not firstDrop)
end

function XUiFubenCoupleCombatDetail:UpdateFeature()
    local stageId = self.StageId
    local showFightEventIds = XFubenCoupleCombatConfig.GetStageShowFightEventIds(stageId)
    local gridBuff
    for i, eventId in ipairs(showFightEventIds) do
        gridBuff = self.GridBuffList[i]
        if not gridBuff then
            local grid = i == 1 and self.GridBuff or CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject, self.PanelBuff)
            gridBuff = XUiGridStageBuff.New(self, grid)
            self.GridBuffList[i] = gridBuff
        end
        gridBuff:Refresh(eventId)
        gridBuff.GameObject:SetActiveEx(true)
    end

    local showFightEventIdsCount = #showFightEventIds
    for i = showFightEventIdsCount + 1, #self.GridBuffList do
        self.GridBuffList[i].GameObject:SetActiveEx(false)
    end

    if self.PanelBuffList then
        self.PanelBuffList.gameObject:SetActiveEx(XTool.IsNumberValid(showFightEventIdsCount))
    end
end

function XUiFubenCoupleCombatDetail:UpdateRewards()
    self.GridCommon.gameObject:SetActiveEx(false)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)

    -- 获取显示奖励Id
    local rewardId = 0
    local IsFirst = false
    local cfg = XDataCenter.FubenManager.GetStageLevelControl(self.StageId)
    if not stageInfo.Passed then
        rewardId = cfg and cfg.FirstRewardShow or self.StageCfg.FirstRewardShow
        if cfg and cfg.FirstRewardShow > 0 or self.StageCfg.FirstRewardShow > 0 then
            IsFirst = true
        end
    end
    if rewardId == 0 then
        rewardId = cfg and cfg.FinishRewardShow or self.StageCfg.FinishRewardShow
    end
    if rewardId == 0 then
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActive(false)
        end
        return
    end

    local rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelDropContent, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActive(false)
        end
    end
end

function XUiFubenCoupleCombatDetail:UpdateStageFightControl()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if self.StageFightControl == nil then
        self.StageFightControl = XUiStageFightControl.New(self.PanelStageFightControl, self.StageCfg.FightControlId)
    end
    if not stageInfo.Passed and stageInfo.Unlock then
        self.StageFightControl.GameObject:SetActive(true)
        self.StageFightControl:UpdateInfo(self.StageCfg.FightControlId)
    else
        self.StageFightControl.GameObject:SetActive(false)
    end
end