local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
-- 剧情章节关卡界面
local XUiPanelCharacterTowerPlotChapter = require("XUi/XUiCharacterTower/Plot/XUiPanelCharacterTowerPlotChapter")
local XUiPanelCharacterTowerPlotReward = require("XUi/XUiCharacterTower/Plot/XUiPanelCharacterTowerPlotReward")
---@class XUiCharacterTowerPlot : XLuaUi
local XUiCharacterTowerPlot = XLuaUiManager.Register(XLuaUi, "UiCharacterTowerPlot")
-- 子ui
local ChildUiName = "UiCharacterTowerPlotDetail"

function XUiCharacterTowerPlot:OnAwake()
    self:RegisterUiEvents()
    self.PanelCheckReward.gameObject:SetActiveEx(false)
    -- 取消隐藏Ui按钮默认隐藏
    self.BtnUnHide.gameObject:SetActiveEx(false)
end

function XUiCharacterTowerPlot:OnStart(chapterId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.ChapterId = chapterId
    ---@type XCharacterTowerChapter
    self.ChapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    self:InitUiData()
    
    ---@type XUiPanelCharacterTowerPlotReward
    self.PanelPlotReward = XUiPanelCharacterTowerPlotReward.New(self.PanelCheckReward, self)
end

function XUiCharacterTowerPlot:OnEnable()
    self:UpdateCurrentChapter()
    self:UpdateCurrentProgress()
    self:UpdateBtnFightShowRed()
end

function XUiCharacterTowerPlot:OnGetEvents()
    return {
        XEventId.EVENT_CHARACTER_TOWER_RECEIVE_REWARD,
        XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL,
    }
end

function XUiCharacterTowerPlot:OnNotify(event, ...)
    if event == XEventId.EVENT_CHARACTER_TOWER_RECEIVE_REWARD then
        self:UpdateCurrentProgress()
    elseif event == XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL then
        self:OnCloseStageDetail()
    end
end

function XUiCharacterTowerPlot:OnDisable()
    self:CloseChildUi(ChildUiName)
    self:OnCloseStageDetail()
end

function XUiCharacterTowerPlot:InitUiData()
    -- 章节名
    self.TxtTitle.text = self.ChapterViewModel:GetChapterName()
    -- 挑战跳转按钮
    local relatedChapterId = self.ChapterViewModel:GetChapterRelatedChapterId()
    self.BtnFight.gameObject:SetActiveEx(XTool.IsNumberValid(relatedChapterId))
    -- 预览奖励
    self:InitPanelReward()
    -- 设置Spine动画的资源路径
    local spinePrefab = self.PanelSpine:GetComponent("XLoadSpinePrefab")
    spinePrefab.AssetUrl = self.ChapterViewModel:GetChapterStorySpineBg()
    -- 设置背景图片
    if self.RImgFull then
        self.RImgFull:SetRawImage(self.ChapterViewModel:GetChapterPassedBg())
    end
end

function XUiCharacterTowerPlot:InitPanelReward()
    self.ChapterRewardGrids = self.ChapterRewardGrids or {}
    local rewardId = self.ChapterViewModel:GetChapterPreviewRewardId()
    local rewards = XRewardManager.GetRewardList(rewardId)
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.ChapterRewardGrids[i]
        if not grid then
            local go = i == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.PanelList)
            grid = XUiGridCommon.New(self, go)
            self.ChapterRewardGrids[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.ChapterRewardGrids do
        self.ChapterRewardGrids[i].GameObject:SetActiveEx(false)
    end
end

function XUiCharacterTowerPlot:UpdateCurrentProgress()
    local finishCount, totalCount = self.ChapterViewModel:GetChapterProgress()
    self.TxtStarNum.text = XUiHelper.GetText("CharacterTowerChapterRewardProgressDesc", finishCount, totalCount)
    self.ImgJindu.fillAmount = finishCount / totalCount
    self.ImgLingqu.gameObject:SetActiveEx(finishCount == totalCount)
    self.ImgRedProgress.gameObject:SetActiveEx(self.ChapterViewModel:CheckChapterRewardAchieved())
    -- 隐藏UI按钮
    self.BtnHide.gameObject:SetActiveEx(self.ChapterViewModel:CheckChapterStageIdsPassed())
end

function XUiCharacterTowerPlot:UpdateCurrentChapter()
    local data = {
        ChapterId = self.ChapterId,
        StageList = self.ChapterViewModel:GetChapterStageIds(),
        ShowStageCb = handler(self, self.ShowStageDetail),
    }
    if not self.CurChapterGrid then
        local prefabName = self.ChapterViewModel:GetChapterPrefab()
        local gameObject = self.PanelChapter:LoadPrefab(prefabName)
        if gameObject == nil or not gameObject:Exist() then
            return
        end
        self.CurChapterGrid = XUiPanelCharacterTowerPlotChapter.New(gameObject, self)
    end
    self.CurChapterGrid:Refresh(data)
    self.CurChapterGrid:Show()
end

function XUiCharacterTowerPlot:UpdateBtnFightShowRed()
    local relatedChapterId = self.ChapterViewModel:GetChapterRelatedChapterId()
    local hasRedPoint = false
    if XTool.IsNumberValid(relatedChapterId) then
        hasRedPoint = XDataCenter.CharacterTowerManager.CheckRedPointByChapterId(relatedChapterId)
    end
    self.BtnFight:ShowReddot(hasRedPoint)
end

function XUiCharacterTowerPlot:ShowStageDetail(stageId)
    if not XLuaUiManager.IsUiShow(ChildUiName) then
        self:OpenOneChildUi(ChildUiName)
    end
    self:FindChildUiObj(ChildUiName):Refresh(stageId)
end

function XUiCharacterTowerPlot:OnCloseStageDetail()
    if self.CurChapterGrid then
        self.CurChapterGrid:CancelSelect()
    end
end

function XUiCharacterTowerPlot:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHide, self.OnBtnHideClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUnHide, self.OnBtnUnHideClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTreasure, self.OnBtnTreasureClick)
    self:BindHelpBtn(self.BtnHelp, "CharacterTowerPlot")
end

function XUiCharacterTowerPlot:OnBtnBackClick()
    self:Close()
end

function XUiCharacterTowerPlot:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 切换到挑战模式
function XUiCharacterTowerPlot:OnBtnFightClick()
    local relatedChapterId = self.ChapterViewModel:GetChapterRelatedChapterId()
    if XTool.IsNumberValid(relatedChapterId) then
        XDataCenter.CharacterTowerManager.OpenChapterUi(relatedChapterId, true)
    end
end

-- 隐藏UI
function XUiCharacterTowerPlot:OnBtnHideClick()
    self:PlayAnimationWithMask("UiDisable",function()
        self.BtnUnHide.gameObject:SetActiveEx(true)
    end)
end

-- 取消隐藏UI
function XUiCharacterTowerPlot:OnBtnUnHideClick()
    self.BtnUnHide.gameObject:SetActiveEx(false)
    self:PlayAnimationWithMask("UiEnable")
end

-- 打开奖励界面
function XUiCharacterTowerPlot:OnBtnTreasureClick()
    self.PanelPlotReward:Refresh(self.ChapterId)
    self.PanelPlotReward.GameObject:SetActiveEx(true)
    self.PanelPlotReward:OnEnable()
end

return XUiCharacterTowerPlot