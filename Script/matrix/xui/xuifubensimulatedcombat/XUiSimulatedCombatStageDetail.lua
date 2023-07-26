--玩法关卡点击后的关卡详细
local XUiGridStageBuffIcon = require("XUi/XUiFubenSimulatedCombat/ChildItem/XUiGridStageBuffIcon")
local XUiSimulatedCombatStageDetail = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatStageDetail")
function XUiSimulatedCombatStageDetail:OnAwake()
    XTool.InitUiObject(self)
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, true)
    self.AssetActivityPanel:SetQueryFunc(XDataCenter.FubenSimulatedCombatManager.GetCurrencyByItem)
end

function XUiSimulatedCombatStageDetail:OnStart(chapter)
    self.Chapter = chapter
    self.RootUi = chapter.RootUi
end

function XUiSimulatedCombatStageDetail:SetStageDetail(stageInterId)
    self.Data = XFubenSimulatedCombatConfig.GetStageInterData(stageInterId)
    self.StageId = self.Data.StageId
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.ActTemplate = XDataCenter.FubenSimulatedCombatManager.GetCurrentActTemplate()
    self.StageType = self.Data.Type
    self.StageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    self.IsPassed =  self.StageInfo and self.StageInfo.Passed
    self.ClgMap = XDataCenter.FubenSimulatedCombatManager.GetClgMap(self.StageId)

    self:SetUi()
end

function XUiSimulatedCombatStageDetail:SetUi()
    local panelDetail
    if self.StageType == XFubenSimulatedCombatConfig.StageType.Normal then
        panelDetail = self.PanelDetailNor
    elseif self.StageType == XFubenSimulatedCombatConfig.StageType.Challenge then
        panelDetail = self.PanelDetailHard
    end

    XTool.InitUiObjectByUi(self, panelDetail)
    self.PanelDetailNor.gameObject:SetActiveEx(self.StageType == XFubenSimulatedCombatConfig.StageType.Normal)
    self.PanelDetailHard.gameObject:SetActiveEx(self.StageType == XFubenSimulatedCombatConfig.StageType.Challenge)

    self:SetDropList()
    self:SetBuffList()
    self:SetNormalStage()
    self:SetHardStage()
    
    self.TxtTitle.text = self.StageCfg.Name
    --ImgCostIcon
    self.TxtATNums.text = self.IsPassed and 0 or XDataCenter.FubenManager.GetRequireActionPoint(self.StageId)
    self.BtnClose.CallBack = function() self:OnBtnClose()  end
    self.BtnEnter.CallBack = function() self:OnBtnEnter()  end
    self.AssetActivityPanel:Refresh(self.ActTemplate.ConsumeIds)

end

function XUiSimulatedCombatStageDetail:SetNormalStage()
    if self.StageType ~= XFubenSimulatedCombatConfig.StageType.Normal then return end
    local target = self.StageCfg.StarDesc
    local gridStage = {}
    for i = 1, 3 do
        gridStage[i] = self["GridStageStar" .. i]
        gridStage[i].gameObject:SetActiveEx(false)
    end
    for i = 1, #target do
        if target[i] then
            gridStage[i].gameObject:SetActiveEx(true)
            gridStage[i]:Find("TxtTip"):GetComponent("Text").text = string.gsub(target[i], "【Consume%d】", "       ")
            local currencyNo = string.match(string.match(target[i], "【Consume%d】") or "", "%d")
            local currencyIcon = XDataCenter.FubenSimulatedCombatManager.GetCurrencyIcon(currencyNo)
            local rImgCurrencyIcon = gridStage[i]:Find("RImgCurrencyIcon")
            if currencyIcon then
                rImgCurrencyIcon.gameObject:SetActiveEx(true)
                rImgCurrencyIcon:GetComponent("RawImage"):SetRawImage(currencyIcon)
            else
                rImgCurrencyIcon.gameObject:SetActiveEx(false)
            end
        end
    end

    -- 掉落特殊处理
    self.PanelDropNone.gameObject:SetActiveEx(self.IsPassed)
    if self.IsPassed then
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActiveEx(false)
        end
        return
    end
    --------
end

function XUiSimulatedCombatStageDetail:SetHardStage()
    if self.StageType ~= XFubenSimulatedCombatConfig.StageType.Challenge then return end
    -- 进阶挑战
    self.BtnClgList = {}
    -- 读取上一次状态
    for i, passed in ipairs(self.StageInfo.StarsMap) do
        local grid = self["GridStage"..i]
        grid:Find("IconStar").gameObject:SetActiveEx(passed)
        grid:Find("IconStarNone").gameObject:SetActiveEx(not passed)
        local clgCfg = XFubenSimulatedCombatConfig.GetChallengeById(self.Data.ChallengeIds[i])
        local btn = grid:Find("BtnCondition"):GetComponent("XUiButton")
        self.BtnClgList[i] = btn
        if clgCfg then 
            grid.gameObject:SetActiveEx(true)
            btn:SetNameByGroup(0, clgCfg.Description)
            btn:SetButtonState(self.ClgMap[i] and XUiButtonState.Select or XUiButtonState.Normal)
            btn.CallBack = function(value) self:OnSelectIndex(i, value) end
        else
            grid.gameObject:SetActiveEx(false)
        end
    end
    local star = XDataCenter.FubenSimulatedCombatManager.GetStageStar(self.StageId)
    if star then
        self.TxtFinishChallengeStar.text =  CS.XTextManager.GetText("SimulatedCombatStarChallengeFinish", star)
    else
        self.TxtFinishChallengeStar.text =  CS.XTextManager.GetText("SimulatedCombatStarChallengeNotFinish")
    end
    local remainTime = XDataCenter.FubenSimulatedCombatManager.GetDailyRewardRemainCount()
    self.TxtDropTime.text = CS.XTextManager.GetText("SimulatedCombatRewardTime", remainTime)
end

function XUiSimulatedCombatStageDetail:OnSelectIndex(i, value)
    self.ClgMap[i] = value == 1
    self:SetDropList()
end

function XUiSimulatedCombatStageDetail:OnBtnClose()
    self:Close()
    self.Chapter:CloseStageDetails()
end

function XUiSimulatedCombatStageDetail:OnBtnEnter()
    if self.StageType == XFubenSimulatedCombatConfig.StageType.Challenge and self.StarCount == 0 then
        local title = CSXTextManagerGetText("TipTitle")
        local content = CSXTextManagerGetText("SimulatedCombatStarChallengeNoneConfirm")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal,nil, function()
            self:EnterShop()
        end)
    else
        self:EnterShop()
    end
end

function XUiSimulatedCombatStageDetail:EnterShop()
    XDataCenter.FubenSimulatedCombatManager.SaveClgMap(self.StageId, self.ClgMap)
    -- 保存当前选中的状态
    if not XDataCenter.FubenManager.CheckPreFight(self.StageCfg) then
        return
    end
    self:OnBtnClose()
    XLuaUiManager.Remove("UiSimulatedCombatResAllo")
    XLuaUiManager.Open("UiSimulatedCombatResAllo", self.Data.Id)
end

function XUiSimulatedCombatStageDetail:SetDropList()
    if not self.GridList then self.GridList = {} end
    --由当前模式和星级确定奖励id
    local rewardId = self.StageCfg.FirstRewardId
    if self.StageType == XFubenSimulatedCombatConfig.StageType.Challenge then
        self.StarCount = 0
        for _, v in ipairs(self.ClgMap) do
            if v then
                self.StarCount = self.StarCount + 1
            end
        end
        self.TxtFirstDrop.text = CS.XTextManager.GetText("SimulatedCombatRewardStar", self.StarCount)
        rewardId = self.Data.StarRewardIds[self.StarCount]
    end
    if not rewardId or rewardId == 0 then
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActiveEx(false)
        end
        return
    end
     
    self.GridCommon.gameObject:SetActive(false)
    local rewards = XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self.RootUi, ui)
                self.GridList[i] = grid
            end
            grid.Transform.localScale = self.GridCommon.localScale
            grid.Transform:SetParent(self.PanelDropContent, false)
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

function XUiSimulatedCombatStageDetail:SetBuffList()
    if not self.BuffList then self.BuffList = {} end
    local buffList = self.Data.ShowFightEventIds
    self.GridBuff.gameObject:SetActiveEx(false)
    self.StageBuffCfgList = {}
    for i = 1, #buffList do
        if not self.BuffList[i] then
            local prefab = CS.UnityEngine.GameObject.Instantiate(self.GridBuff.gameObject)
            self.BuffList[i] = XUiGridStageBuffIcon.New(prefab, self.RootUi)
        end
    end
    for i = 1, #self.BuffList do
        self.BuffList[i].Transform:SetParent(self.PanelBuffContent, false)
        if buffList[i] then
            self.BuffList[i]:RefreshData(buffList[i])
            self.BuffList[i]:Show()
            table.insert(self.StageBuffCfgList, buffList[i])
        else
            self.BuffList[i]:Hide()
        end
    end
    
    self.BtnBuffTip.CallBack = function()
        self:OnBtnBuffTip()
    end
    self.PanelBuffNone.gameObject:SetActiveEx(#buffList == 0)
end

function XUiSimulatedCombatStageDetail:OnBtnBuffTip()
    local buffList = self.Data.ShowFightEventIds
    if buffList and next(buffList) then
        XLuaUiManager.Open("UiSimulatedCombatBossBuffTips", buffList)
    end
end

return XUiSimulatedCombatStageDetail