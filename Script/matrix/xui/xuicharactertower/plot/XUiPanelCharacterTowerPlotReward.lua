local XUiGridCharacterTowerPlotReward = require("XUi/XUiCharacterTower/Plot/XUiGridCharacterTowerPlotReward")
---@class XUiPanelCharacterTowerPlotReward
local XUiPanelCharacterTowerPlotReward = XClass(nil, "XUiPanelCharacterTowerPlotReward")

function XUiPanelCharacterTowerPlotReward:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnTreasureBg, self.OnBtnTreasureBgClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGift, self.OnBtnGiftClick)
    self.PanelRewardGift.gameObject:SetActiveEx(false)
    self.GridPrequelCheckPointReward.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiPanelCharacterTowerPlotReward:Refresh(chapterId)
    self.ChapterId = chapterId
    ---@type XCharacterTowerChapter
    self.ChapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    self:RefreshCharacterInfo()
    self:RefreshChapterReward()
    self:SetupDynamicTable()
    self:CheckRewardReceiveStatus()
end

function XUiPanelCharacterTowerPlotReward:RefreshCharacterInfo()
    local characterId = self.ChapterViewModel:GetChapterCharacterId()
    local characterIcon = XMVCA.XCharacter:GetCharHalfBodyBigImage(characterId)
    self.RImgRole:SetRawImage(characterIcon)
    self.RImgRoleGift:SetRawImage(characterIcon)
    local characterName = XEntityHelper.GetCharacterName(characterId)
    local chapterInfo = self.ChapterViewModel:GetChapterInfo()
    if chapterInfo:CheckChapterRewardReceived(self.ChapterId) then
        self.RoleTxtTitle.text = XUiHelper.GetText("CharacterTowerChapterRewardFinishDesc", characterName)
    else
        local finishCount, totalCount = self.ChapterViewModel:GetChapterStageProgress()
        self.RoleTxtTitle.text = XUiHelper.GetText("CharacterTowerChapterRewardDesc", finishCount, totalCount, characterName)
    end
end

-- 刷新章节最终奖励
function XUiPanelCharacterTowerPlotReward:RefreshChapterReward()
    local chapterRewardId = self.ChapterViewModel:GetChapterRewardId()
    local rewards = XRewardManager.GetRewardList(chapterRewardId)
    if not self.ChapterRewardGrid then
        self.ChapterRewardGrid = XUiGridCommon.New(self.RootUi, self.GridReward)
    end
    self.ChapterRewardGrid:Refresh(rewards[1])
    self.ChapterRewardGrid.GameObject:SetActiveEx(true)
    -- 章节最终奖励图标
    if self.RImgRewardIcon then
        self.RImgRewardIcon:SetRawImage(self.ChapterViewModel:GetChapterRewardIcon())
    end
end

function XUiPanelCharacterTowerPlotReward:FilterStageReward()
    local stageIds = self.ChapterViewModel:GetChapterStageIds()
    local rewardStages = {}
    for _, stageId in pairs(stageIds) do
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if stageCfg.FirstRewardShow > 0 then
            table.insert(rewardStages, stageId)
        end
    end
    -- 排序
    table.sort(rewardStages,function(a, b)
        local isFinishA = self:CheckStageRewardReceived(a)
        local isFinishB = self:CheckStageRewardReceived(b)
        if isFinishA ~= isFinishB then
            return isFinishB
        end
        return a < b
    end)
    return rewardStages
end

function XUiPanelCharacterTowerPlotReward:CheckStageRewardReceived(stageId)
    local chapterInfo = self.ChapterViewModel:GetChapterInfo()
    return chapterInfo:CheckStageRewardReceived(stageId)
end

function XUiPanelCharacterTowerPlotReward:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRewardList)
    self.DynamicTable:SetProxy(XUiGridCharacterTowerPlotReward, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelCharacterTowerPlotReward:SetupDynamicTable()
    self.DataList = self:FilterStageReward()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelCharacterTowerPlotReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index], self.ChapterId)
    end
end

function XUiPanelCharacterTowerPlotReward:OnBtnTreasureBgClick()
    self:Close()
end

-- 领取最终奖励
function XUiPanelCharacterTowerPlotReward:OnBtnGiftClick()
    if not self.ChapterId then
        return
    end
    XDataCenter.CharacterTowerManager.CharacterTowerGetChapterRewardRequest(self.ChapterId, function(rewards)
        XUiManager.OpenUiObtain(rewards, CS.XTextManager.GetText("DailyActiveRewardTitle"), function()
            self:OnRewardTaskFinish()
        end, nil)
    end)
end

function XUiPanelCharacterTowerPlotReward:OnRewardTaskFinish()
    -- 刷新
    self:CheckRewardReceiveStatus()
    self:RefreshCharacterInfo()
    self:SetupDynamicTable()
end

function XUiPanelCharacterTowerPlotReward:CheckRewardReceiveStatus()
    local chapterInfo = self.ChapterViewModel:GetChapterInfo()
    -- 检测剧情最终奖励是否领取
    if chapterInfo:CheckChapterRewardReceived(self.ChapterId) then
        self:PanelActive(true, false)
    elseif self.ChapterViewModel:CheckChapterStageRewardFinish() then
        self:PanelActive(false, true)
    else
        self:PanelActive(true, false)
    end
end

-- UiCharacterTowerPlot
function XUiPanelCharacterTowerPlotReward:OnEnable()
    XDataCenter.UiPcManager.OnUiEnable(self, "OnBtnTreasureBgClick")
end

function XUiPanelCharacterTowerPlotReward:OnDisable()
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
end

function XUiPanelCharacterTowerPlotReward:PanelActive(isPanelReward, isPanelRewardGift)
    self.PanelReward.gameObject:SetActiveEx(isPanelReward)
    self.PanelRewardGift.gameObject:SetActiveEx(isPanelRewardGift)
end

function XUiPanelCharacterTowerPlotReward:Close()
    self:OnDisable()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelCharacterTowerPlotReward