local XUiAwarenessMainDetail = XLuaUiManager.Register(XLuaUi, "UiAwarenessMainDetail")

function XUiAwarenessMainDetail:OnAwake()
    self:InitButton()

    self.GridList = {}
end

function XUiAwarenessMainDetail:InitButton()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnEnter, function () XLuaUiManager.PopThenOpen("UiAwarenessDeploy", self.ChapterId) end) 

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiAwarenessMainDetail:OnStart(chapterId)
    self.ChapterId = chapterId
    self.ChapterData = XDataCenter.FubenAwarenessManager.GetChapterDataById(chapterId)
end

function XUiAwarenessMainDetail:OnEnable()
    self:Refresh()
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_ASSIGN_STAGE_CLICK, self.ChapterId)
end

function XUiAwarenessMainDetail:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_ASSIGN_STAGE_DETAIL_CLOSE)
end

function XUiAwarenessMainDetail:Refresh()
    local baseStageId = self.ChapterData:GetBaseStageId()
    self.StageData = XDataCenter.FubenManager.GetStageData(baseStageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(baseStageId)
    self.StageInfo = XDataCenter.FubenManager.GetStageInfo(baseStageId)
    self.IsPassed = self.ChapterData:IsPass()

    -- 通关目标
    for i = 1, 3 do
        self["TxtStarActive" .. i].text = self.StageCfg.StarDesc[i]
    end

    -- 奖励
    local rewardId
    local IsFirst = (not self.IsPassed)
    local cfg = self.StageCfg
    if IsFirst then
        rewardId = cfg.FirstRewardShow
    else
        rewardId = cfg.FinishRewardShow
    end
    self.TxtDrop.gameObject:SetActiveEx(not IsFirst)
    self.TxtFirstDrop.gameObject:SetActiveEx(IsFirst)
    if not rewardId or rewardId == 0 then
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActiveEx(false)
        end
    end

    local rewards = nil
    if XTool.IsNumberValid(rewardId) then
        rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    end
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

    -- 难度
    local nanDuIcon = XDataCenter.FubenManager.GetDifficultIcon(self.BaseStageId)
    self.RImgNandu:SetRawImage(nanDuIcon)

    -- 挑战次数/血清/标题
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(baseStageId)
    self.TxtTitle.text = self.ChapterData:GetName()
    self.TxtAllNums.text = ""
end