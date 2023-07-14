local XUiPanelSignBoard = require("XUi/XUiMain/XUiChildView/XUiPanelSignBoard")
local XUiGridCharacterTowerBattleTask = require("XUi/XUiCharacterTower/Battle/XUiGridCharacterTowerBattleTask")
local XUiGridCharacterTowerBattleStar = require("XUi/XUiCharacterTower/Battle/XUiGridCharacterTowerBattleStar")
---@class XUiCharacterTowerTask : XLuaUi
local XUiCharacterTowerTask = XLuaUiManager.Register(XLuaUi, "UiCharacterTowerTask")

local FULL_PROGRESS = 1
local DefaultClicks = 3     -- 默认播放3连击的动画

function XUiCharacterTowerTask:OnAwake()
    self:RegisterUiEvents()
    self.GridTaskItem.gameObject:SetActiveEx(false)
    self.GridProgressList = {}
end

function XUiCharacterTowerTask:OnStart(chapterId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.ChapterId = chapterId
    ---@type XCharacterTowerChapter
    self.ChapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    
    self:InitLoadScene()
    self:InitDynamicTable()
    self:InitProgress()
end

function XUiCharacterTowerTask:OnEnable()
    self:SetupDynamicTable()
    self:RefreshProgress()

    if self.SignBoard then
        local characterId = self.ChapterViewModel:GetChapterCharacterId()
        self.SignBoard:SetDisplayCharacterId(characterId)
        self.SignBoard:OnEnable()
    end
end

function XUiCharacterTowerTask:OnDisable()
    if self.SignBoard then
        self.SignBoard:OnDisable()
    end
end

function XUiCharacterTowerTask:OnDestroy()
    if self.SignBoard then
        self.SignBoard:OnDestroy()
    end
end

function XUiCharacterTowerTask:InitLoadScene()
    local sceneUrl = self.ChapterViewModel:GetChapterTaskSceneUrl()
    local modelUrl = self.ChapterViewModel:GetChapterTaskModelUrl()
    self:LoadUiScene(sceneUrl, modelUrl, handler(self, self.OnUiSceneLoaded), false)
end

function XUiCharacterTowerTask:OnUiSceneLoaded()
    --self:SetGameObject()
    self:InitSignBoard()
end

function XUiCharacterTowerTask:InitSignBoard()
    self.SignBoard = XUiPanelSignBoard.New(self.PanelTaskBoard, self, XUiPanelSignBoard.SignBoardOpenType.FAVOR)
    self.SignBoard.OperateTrigger = false
    self.SignBoard:SetAutoPlay(true)
    -- 特殊动作屏蔽处理
    local characterId = self.ChapterViewModel:GetChapterCharacterId()
    local disabledActionId = XFubenCharacterTowerConfigs.GetDisabledActionId(characterId)
    self.SpecialFilterAnimId = {}
    for _, actionId in pairs(disabledActionId or {}) do
        self.SpecialFilterAnimId[actionId] = true
    end
    self.SignBoard:SetSpecialFilterAnimId(self.SpecialFilterAnimId)
end

-- 领取星级奖励的时候播放角色动画
function XUiCharacterTowerTask:OnPlayCharacterAnim()
    local characterId = self.ChapterViewModel:GetChapterCharacterId()
    local config = XDataCenter.SignBoardManager.GetRandomPlayElementsByClick(DefaultClicks, characterId)
    if not config or (self.SpecialFilterAnimId and self.SpecialFilterAnimId[config.Id]) then
        return
    end
    if not self.SignBoard:IsPlaying() then
        self.SignBoard:ForcePlay(config.Id)
    end
end

function XUiCharacterTowerTask:FilterStageReward()
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

function XUiCharacterTowerTask:CheckStageRewardReceived(stageId)
    local chapterInfo = self.ChapterViewModel:GetChapterInfo()
    return chapterInfo:CheckStageRewardReceived(stageId)
end

function XUiCharacterTowerTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiGridCharacterTowerBattleTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiCharacterTowerTask:SetupDynamicTable()
    self.DataList = self:FilterStageReward()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiCharacterTowerTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index], self.ChapterId)
    end
end

-- 领取完奖励回调
function XUiCharacterTowerTask:OnRewardTaskFinish(isAnim)
    self:SetupDynamicTable()
    if isAnim then
        self:OnPlayCharacterAnim() -- 播放动作
    end
end

function XUiCharacterTowerTask:InitProgress()
    local treasureIds = self.ChapterViewModel:GetChapterTreasureIds()
    for i = 1, #treasureIds do
        local progress = self.GridProgressList[i]
        if not progress then
            local go = i == 1 and self.PanelStarsActive or XUiHelper.Instantiate(self.PanelStarsActive, self.ImgProgress.transform)
            progress = XUiGridCharacterTowerBattleStar.New(go, self, treasureIds[i], self.ChapterId)
            self.GridProgressList[i] = progress
        end
    end
    self.ImgProgressRect = self.ImgProgress:GetComponent("RectTransform")
    self.TemplatePosition = self.PanelStarsActive.transform.localPosition
    self.TemplateRect = self.PanelStarsActive:GetComponent("RectTransform")
    
    local stars, totalStars = self.ChapterViewModel:GetChapterStars()
    self.TxtCurProgress.text = stars
    self.TxtTotalProgress.text = string.format("/%d", totalStars)
end

function XUiCharacterTowerTask:RefreshProgress()
    -- 刷新进度奖励位置
    self:RefreshProgressTransform()

    local stars, totalStars = self.ChapterViewModel:GetChapterStars()
    if not XTool.IsNumberValid(totalStars) then
        return
    end
    -- 当前进度值
    self.TxtCurProgress.text = stars
    local currentProgress = stars * 1.0 / totalStars * FULL_PROGRESS
    self.ImgProgress.fillAmount = (currentProgress > FULL_PROGRESS) and 1 or currentProgress

    for _, progress in pairs(self.GridProgressList) do
        progress:Refresh(stars)
    end
end

function XUiCharacterTowerTask:RefreshProgressTransform()
    -- 异形屏适配需要
    XScheduleManager.ScheduleOnce(function()
        if not self.GameObject or not self.GameObject:Exist() then
            return
        end
        -- 更新位置
        local totalWidth = self.ImgProgressRect.rect.size.x
        local activeWidthOffset = self.TemplateRect.rect.size.x * self.TemplateRect.localScale.x / 2
        local treasureIds = self.ChapterViewModel:GetChapterTreasureIds()
        if XTool.IsTableEmpty(treasureIds) then
            return
        end
        local totalStars = XFubenCharacterTowerConfigs.GetRequireStarByTreasureId(treasureIds[#treasureIds])
        for i = 1, #treasureIds do
            local requireStar = XFubenCharacterTowerConfigs.GetRequireStarByTreasureId(treasureIds[i])
            local currentProgress = requireStar * 1.0 / totalStars * FULL_PROGRESS
            local progress = self.GridProgressList[i]
            if progress then
                progress.Transform:GetComponent("RectTransform").anchoredPosition3D = CS.UnityEngine.Vector3(currentProgress * totalWidth - activeWidthOffset, self.TemplatePosition.y, self.TemplatePosition.z)
            end
        end
    end, 1)
end

function XUiCharacterTowerTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiCharacterTowerTask:OnBtnBackClick()
    self:Close()
end

function XUiCharacterTowerTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiCharacterTowerTask