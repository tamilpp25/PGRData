local XUiGridBabelStageItem = require("XUi/XUiFubenBabelTower/XUiGridBabelStageItem")
local XUiBabelTowerMainReproduce = XClass(XSignalData, "XUiBabelTowerMainReproduce")

function XUiBabelTowerMainReproduce:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    -- XBabelTowerReproduceManager
    self.ReproduceManager = nil
    -- 章节格子数据
    self.ChapterStageGrids = nil
    self.FubenBabelTowerManager = XDataCenter.FubenBabelTowerManager
    self.ReproduceManager = self.FubenBabelTowerManager.GetReproduceManager()
    self:RegisterUiEvents()
end

function XUiBabelTowerMainReproduce:Open()
    self.GameObject:SetActiveEx(true)
    -- 排行榜状态
    self.BtnRank.gameObject:SetActiveEx(self.ReproduceManager:GetIsShowRank())
    -- 刷新关卡信息数据
    self:RefreshStageInfo()
    -- 检查任务红点
    XRedPointManager.CheckOnceByButton(self.BtnAchievement, { XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD }
        , XFubenBabelTowerConfigs.ActivityType.Extra)
    -- 检查按钮小红点
    XRedPointManager.CheckOnceByButton(self.BtnNormal
        , { XRedPointConditions.Types.CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD }, XFubenBabelTowerConfigs.ActivityType.Normal)
end

function XUiBabelTowerMainReproduce:Hide()
    self.GameObject:SetActiveEx(false)
    self:EmitSignal("Hide")
end

--######################## 私有方法 ########################

function XUiBabelTowerMainReproduce:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnRank, self.OnBtnRankClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAchievement, self.OnBtnAchievementClick)
    XUiHelper.RegisterClickEvent(self, self.BtnNormal, self.OnBtnNormalClicked)
    XUiHelper.RegisterHelpButton(self.BtnReprintHelp, "BabelTower")
end

function XUiBabelTowerMainReproduce:OnBtnNormalClicked()
    self:Hide()
end

function XUiBabelTowerMainReproduce:OnBtnAchievementClick()
    XLuaUiManager.Open("UiBabelTowerTask",  XFubenBabelTowerConfigs.ActivityType.Extra)
end

function XUiBabelTowerMainReproduce:OnBtnRankClick()
    self.FubenBabelTowerManager.GetRank(self.ReproduceManager:GetId(), function()
        XLuaUiManager.Open("UiFubenBabelTowerRank", XFubenBabelTowerConfigs.ActivityType.Extra)
    end)
end

function XUiBabelTowerMainReproduce:RefreshStageInfo()
    self:UpdateStageDataItems()
    self:UpdateStageScores()
end

-- 更新当前分数和最大分数等级
function XUiBabelTowerMainReproduce:UpdateStageScores()
    self.TxtTotalLevel.text = self.ReproduceManager:GetCurrentScore()
    -- self.TxtName.text = XFubenBabelTowerConfigs.GetActivityName(self.CurrentActivityNo)
    self.TxtHighest.text = XUiHelper.GetText("BabelTowerCurMaxScore", self.ReproduceManager:GetMaxScore())
end

-- 更新章节数据
function XUiBabelTowerMainReproduce:UpdateStageDataItems()
    if not self.ChapterStageGrids then self.ChapterStageGrids = {} end
    local stageIds = self.ReproduceManager:GetStageIds()
    local go = nil
    for i = 1, #stageIds do
        if not self.ChapterStageGrids[i] then
            go = self.PanelStageContent:Find(string.format("Stage%d", i))
            table.insert(self.ChapterStageGrids, XUiGridBabelStageItem.New(go, self, stageIds[i]))
        end
        self.ChapterStageGrids[i].GameObject:SetActiveEx(true)
        self.ChapterStageGrids[i]:UpdateStageInfo(stageIds[i])
    end
    for i = #stageIds + 1, #self.ChapterStageGrids do
        self.ChapterStageGrids[i].GameObject:SetActiveEx(false)
    end
end

function XUiBabelTowerMainReproduce:OnStageClick(stageId, grid)
    local isStageUnlock, desc = self.FubenBabelTowerManager.IsBabelStageUnlock(stageId)
    if not isStageUnlock then
        XUiManager.TipMsg(desc)
        return
    end
    local stageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(stageId)
    local currentSelectGuideId = stageTemplate.StageGuideId[1]
    -- 锁住return
    local isUnlock = self.FubenBabelTowerManager.IsBabelStageGuideUnlock(stageId, currentSelectGuideId)
    if not isUnlock then
        if not isStageUnlock then
            XUiManager.TipMsg(desc)
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerPassLastGuide"))
        end
        return
    end
    XLuaUiManager.Open("UiBabelTowerSelectTeam", stageId)
    RunAsyn(function()
        local signalCode = XLuaUiManager.AwaitSignal("UiBabelTowerSelectTeam", "_", self)
        if signalCode ~= XSignalCode.RELEASE then return end
        self:UpdateStageScores()
        self:UpdateStageDataItems()
    end)
end

function XUiBabelTowerMainReproduce:RefreshReward(rootUi)
    self.ChapterRewardGrids = self.ChapterRewardGrids or {}
    local rewardId = self.ReproduceManager:GetRewardId()
    local rewards = XRewardManager.GetRewardList(rewardId)

    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.ChapterRewardGrids[i]
        if not grid then
            local go = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelItem)
            grid = XUiGridCommon.New(rootUi, go)
            self.ChapterRewardGrids[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.ChapterRewardGrids do
        self.ChapterRewardGrids[i].GameObject:SetActiveEx(false)
    end
end

return XUiBabelTowerMainReproduce