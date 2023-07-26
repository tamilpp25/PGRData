local XUiPracticeCharacterDetail = XLuaUiManager.Register(XLuaUi,"UiPracticeCharacterDetail")

function XUiPracticeCharacterDetail:OnAwake()
    self:InitViews()
    self:AddBtnsListeners()
end

function XUiPracticeCharacterDetail:AddBtnsListeners()
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

function XUiPracticeCharacterDetail:InitViews()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.PanelNums.gameObject:SetActiveEx(false)
    self.GridList = {}
    self.GridListTag = {}
end

function XUiPracticeCharacterDetail:Refresh(stageId)
    self.StageId = stageId

    self:UpdateCommon()
    self:UpdateReward()
end

function XUiPracticeCharacterDetail:UpdateCommon()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local nanDuIcon = XDataCenter.FubenManager.GetDifficultIcon(self.StageId)

    self.TxtTitle.text = stageCfg.Name
    self.RImgNandu:SetRawImage(nanDuIcon)

    for i = 1, 3 do
        self[string.format("TxtActive%d", i)].text = stageCfg.StarDesc[i]
    end

    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(self.StageId)
end

function XUiPracticeCharacterDetail:OnBtnEnterClick()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if XDataCenter.FubenManager.CheckPreFight(stageCfg) then
        if XTool.USENEWBATTLEROOM then
            XLuaUiManager.Open("UiBattleRoleRoom", stageCfg.StageId)
        else
            XLuaUiManager.Open("UiNewRoomSingle", stageCfg.StageId)
        end
        self:Close()
    end
end

function XUiPracticeCharacterDetail:CloseWithAnimation()
    self:PlayAnimation("AnimDisableEnd", function()
        self:Close()
    end)
end

function XUiPracticeCharacterDetail:UpdateReward()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local stageLevelControl = XDataCenter.FubenManager.GetStageLevelControl(self.StageId)

    local rewardId = stageLevelControl and stageLevelControl.FirstRewardShow or stageCfg.FirstRewardShow

    if rewardId == 0 then
        for i = 1, #self.GridList do
            self.GridList[i].GameObject:SetActiveEx(false)
        end
        return
    end

    local rewards = XRewardManager.GetRewardList(rewardId)
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
                self.GridListTag[i] = grid.Transform:Find("Received")
            end
            grid:Refresh(item)
            grid:SetReceived(XDataCenter.PracticeManager.CheckPracticeStageIsUnlock(self.StageId))
            grid.GameObject:SetActiveEx(true)
            if self.GridListTag[i] then
                self.GridListTag[i].gameObject:SetActiveEx(stageInfo.Passed)
            end
        end
    end

    for i = #rewards + 1, #self.GridList do
        self.GridList[i].GameObject:SetActiveEx(false)
    end
end

return XUiPracticeCharacterDetail