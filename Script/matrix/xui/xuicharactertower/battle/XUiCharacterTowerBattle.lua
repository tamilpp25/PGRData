local XUiGridCharacterTowerBattleStage = require("XUi/XUiCharacterTower/Battle/XUiGridCharacterTowerBattleStage")
---@class XUiCharacterTowerBattle : XLuaUi
local XUiCharacterTowerBattle = XLuaUiManager.Register(XLuaUi, "UiCharacterTowerBattle")

local MAX_STAGE_COUNT = XUiHelper.GetClientConfig("CharacterTowerBattleStageMaxCount", XUiHelper.ClientConfigType.Int)
local XUguiDragProxy = CS.XUguiDragProxy
local ChildUiName = "UiFubenCharacterTowerDetail"

function XUiCharacterTowerBattle:OnAwake()
    self:RegisterUiEvents()
    self.GridStageList = {}
    self.GridStageParentList = {}
    self.LineList = {}
end

function XUiCharacterTowerBattle:OnStart(chapterId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.ChapterId = chapterId
    ---@type XCharacterTowerChapter
    self.ChapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    self:InitUiData()
end

function XUiCharacterTowerBattle:OnEnable()
    self:UpdateStageList()
    self:UpdateCurrentProgress()
    self:UpdateRelationProgress()
    self:UpdateBtnFightShowRed()
    self:GotoLastPassStage()
end

function XUiCharacterTowerBattle:OnGetEvents()
    return {
        XEventId.EVENT_CHARACTER_TOWER_RECEIVE_REWARD,
        XEventId.EVENT_FUBEN_ENTERFIGHT,
    }
end

function XUiCharacterTowerBattle:OnNotify(event, ...)
    if event == XEventId.EVENT_CHARACTER_TOWER_RECEIVE_REWARD then
        self:UpdateCurrentProgress()
    elseif event == XEventId.EVENT_FUBEN_ENTERFIGHT then
        self:EnterFight(...)
    end
end

function XUiCharacterTowerBattle:OnDisable()
    self:CloseChildUi(ChildUiName)
    self:CancelSelect()
    for _, stage in pairs(self.GridStageList) do
        stage.IconDisable:PlayTimelineAnimation()
    end
end

function XUiCharacterTowerBattle:InitUiData()
    -- 背景
    if self.ImgBg then
        self.ImgBg:SetRawImage(self.ChapterViewModel:GetChapterBattleBg())
    end
    -- 章节名
    self.TxtTitle.text = self.ChapterViewModel:GetChapterName()
    -- 挑战跳转按钮
    local relatedChapterId = self.ChapterViewModel:GetChapterRelatedChapterId()
    self.BtnFight.gameObject:SetActiveEx(XTool.IsNumberValid(relatedChapterId))
    -- 预览奖励
    self:InitPanelReward()

    local dragProxy = self.PaneStageList:GetComponent(typeof(XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.PaneStageList.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
    
    -- 关卡父节点 和 关卡连线
    self.GridStageParentList = {}
    self.LineList = {}
    for i = 1, MAX_STAGE_COUNT do
        local parent = XUiHelper.TryGetComponent(self.PanelStageContent, string.format("Stage%d", i))
        if parent then
            self.GridStageParentList[i] = parent
        end
        local line = XUiHelper.TryGetComponent(self.PanelStageContent, string.format("Line%d", i))
        if line then
            self.LineList[i] = line
        end
    end
end

function XUiCharacterTowerBattle:InitPanelReward()
    self.ChapterRewardGrids = self.ChapterRewardGrids or {}
    local rewardId = self.ChapterViewModel:GetChapterShowRewardId()
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

function XUiCharacterTowerBattle:UpdateCurrentProgress()
    local finishCount, totalCount = self.ChapterViewModel:GetChapterProgress()
    self.TxtDesc.text = XUiHelper.GetText("CharacterTowerChapterRewardProgressDesc", finishCount, totalCount)
    self.ImgJindu.fillAmount = finishCount / totalCount
    self.ImgLingqu.gameObject:SetActiveEx(finishCount == totalCount)
    self.ImgRedProgress.gameObject:SetActiveEx(self.ChapterViewModel:CheckChapterRewardAchieved())
end

function XUiCharacterTowerBattle:UpdateRelationProgress()
    local relationGroupId = self.ChapterViewModel:GetChapterRelationGroupId()
    local characterId = self.ChapterViewModel:GetChapterCharacterId()
    ---@type XCharacterTowerRelation
    local relationViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerRelation(relationGroupId)
    local finishCount, totalCount = relationViewModel:GetRelationProgress()
    -- 已激活
    self.BtnFetter:SetNameByGroup(0, XUiHelper.GetText("CharacterTowerRelationActivatedDesc", finishCount, totalCount))
    -- 红点
    self.BtnFetter:ShowReddot(relationViewModel:CheckRelationNotActive(characterId))
end

function XUiCharacterTowerBattle:UpdateBtnFightShowRed()
    local relatedChapterId = self.ChapterViewModel:GetChapterRelatedChapterId()
    local hasRedPoint = false
    if XTool.IsNumberValid(relatedChapterId) then
        hasRedPoint = XDataCenter.CharacterTowerManager.CheckRedPointByChapterId(relatedChapterId)
    end
    self.BtnFight:ShowReddot(hasRedPoint)
end

--region 关卡相关

function XUiCharacterTowerBattle:EnterFight(stage)
    if not XDataCenter.FubenManager.CheckPreFight(stage) then
        return
    end
    XLuaUiManager.Open("UiBattleRoleRoom", stage.StageId, nil, {
        GetRoleDetailProxy = function(proxy)
            return require("XUi/XUiCharacterTower/BattleRoleRoom/XUiCharacterTowerBattleRoomRoleDetail")
        end
    })
end

function XUiCharacterTowerBattle:UpdateStageList()
    self.StageList = self.ChapterViewModel:GetChapterStageIds()
    for i = 1, #self.StageList do
        local stageId = self.StageList[i]
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo.IsOpen then
            local grid = self.GridStageList[i]
            if not grid then
                local uiName = "GridFunCharacterTowerBattle"
                uiName = stageCfg.StageGridStyle and string.format("%s%s", uiName, stageCfg.StageGridStyle) or uiName

                local parent = self.GridStageParentList[i]
                local prefabName = XFubenCharacterTowerConfigs.GetCharacterTowerConfigValueByKey(uiName)
                local prefab = parent:LoadPrefab(prefabName)

                grid = XUiGridCharacterTowerBattleStage.New(prefab, self, handler(self, self.ClickStageGrid))
                self.GridStageList[i] = grid
                parent.gameObject:SetActiveEx(true)
            end
            grid:Refresh(stageId)
            self:SetLineActive(i, true)
        end
    end

    local activeStageCount = #self.GridStageList
    for i = activeStageCount + 1, MAX_STAGE_COUNT do
        local parent = self.GridStageParentList[i]
        if parent then
            parent.gameObject:SetActiveEx(false)
        end
        self:SetLineActive(i, false)
    end

    -- 移动至ListView正确的位置
    if self.BoundSizeFitter then
        self.BoundSizeFitter:SetLayoutHorizontal()
    end
end

function XUiCharacterTowerBattle:SetLineActive(index, active)
    local line = self.LineList[index]
    if line then
        line.gameObject:SetActiveEx(active)
    end
end

function XUiCharacterTowerBattle:GotoLastPassStage()
    local index = self:GetUnPassedStageIndex()
    self:GoToStage(index)
end

function XUiCharacterTowerBattle:GetUnPassedStageIndex()
    local count = #self.StageList
    for i = 1, count do
        local stageId = self.StageList[i]
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if not stageInfo.Passed then
            return i
        end
    end
    return count
end

function XUiCharacterTowerBattle:GoToStage(containIndex)
    local gridTf = self.GridStageParentList[containIndex]
    local posX = gridTf.localPosition.x - self.PaneStageList.rect.width / 2
    self.ScrollRect.horizontalNormalizedPosition = 0
    self.ScrollRect.horizontalNormalizedPosition = posX / (1 * self.ScrollRect.content.rect.width - self.PaneStageList.rect.width)
end

-- 选中一个 stage grid
function XUiCharacterTowerBattle:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid.StageId == grid.StageId then
        return
    end

    -- 选中回调
    self:ShowStageDetail(grid.StageId)
    
    -- 取消上一个选择
    if curGrid then
        curGrid:SetStageSelect(false)
    end
    
    -- 选中当前选择
    grid:SetStageSelect(true)
    
    local isContain, containIndex = table.contains(self.StageList, grid.StageId)
    if isContain then
        -- 滚动容器自由移动
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        -- 面板移动
        self:PlayScrollViewMove(containIndex)
    end

    self.CurStageGrid = grid
end

-- 返回滚动容器是否动画回弹
function XUiCharacterTowerBattle:CancelSelect()
    if not self.CurStageGrid then
        return false
    end

    -- 取消当前选择
    self.CurStageGrid:SetStageSelect(false)
    self.CurStageGrid = nil
    
    -- 取消回调
    self:HideStageDetail()
    
    return self:ScrollRectRollBack()
end

function XUiCharacterTowerBattle:PlayScrollViewMove(index)
    -- 动画
    local gridTf = self.GridStageParentList[index]
    local diffX = gridTf.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridTf.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiCharacterTowerBattle:ScrollRectRollBack()
    -- 滚动容器回弹
    local width = self.PaneStageList.rect.width
    local innerWidth = self.PanelStageContent.rect.width
    innerWidth = innerWidth < width and width or innerWidth
    local diff = innerWidth - width
    local tarPosX
    if self.PanelStageContent.localPosition.x < -width / 2 - diff then
        tarPosX = -width / 2 - diff
    elseif self.PanelStageContent.localPosition.x > -width / 2 then
        tarPosX = -width / 2
    else
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        return false
    end

    self:PlayScrollViewMoveBack(tarPosX)
    return true
end

function XUiCharacterTowerBattle:PlayScrollViewMoveBack(tarPosX)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end

function XUiCharacterTowerBattle:ShowStageDetail(stageId)
    self.CurStageId = stageId
    self.AssetPanel.GameObject:SetActiveEx(false)
    if not XLuaUiManager.IsUiShow(ChildUiName) then
        self:OpenOneChildUi(ChildUiName, self, self.ChapterId)
    end
    self:FindChildUiObj(ChildUiName):Refresh(stageId)
end

function XUiCharacterTowerBattle:HideStageDetail()
    if not self.CurStageId then
        return
    end
    
    local childUiObj = self:FindChildUiObj(ChildUiName)
    if childUiObj then
        childUiObj:Hide()
    end
    self.AssetPanel.GameObject:SetActiveEx(true)
end

function XUiCharacterTowerBattle:CloseStageDetail()
    if XLuaUiManager.IsUiShow(ChildUiName) then
        self:CancelSelect()
        return true
    end
    return false
end

--拖拽事件处理
function XUiCharacterTowerBattle:OnDragProxy(dragType)
    if dragType == 0 then
        self:OnScrollRectBeginDrag()
    elseif dragType == 2 then
        self:OnScrollRectEndDrag()
    end
end

function XUiCharacterTowerBattle:OnScrollRectBeginDrag()
    if self:CancelSelect() then
        self.ScrollRect.enabled = false
    end
end

function XUiCharacterTowerBattle:OnScrollRectEndDrag()
    self.ScrollRect.enabled = true
end

--endregion

function XUiCharacterTowerBattle:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFetter, self.OnBtnFetterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTreasure, self.OnBtnTreasureClick)
    self:BindHelpBtn(self.BtnHelp, "CharacterTowerPlot")

    -- ScrollRect的点击和拖拽会触发关闭详细面板
    XUiHelper.RegisterClickEvent(self, self.ScrollRect, self.CancelSelect)
end

function XUiCharacterTowerBattle:OnBtnBackClick()
    if self:CloseStageDetail() then
        return
    end
    self:Close()
end

function XUiCharacterTowerBattle:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 切换到剧情模式
function XUiCharacterTowerBattle:OnBtnFightClick()
    if self:CloseStageDetail() then
        return
    end
    local relatedChapterId = self.ChapterViewModel:GetChapterRelatedChapterId()
    if XTool.IsNumberValid(relatedChapterId) then
        XDataCenter.CharacterTowerManager.OpenChapterUi(relatedChapterId, true)
    end
end

-- 羁绊加成
function XUiCharacterTowerBattle:OnBtnFetterClick()
    if self:CloseStageDetail() then
        return
    end
    local relationGroupId = self.ChapterViewModel:GetChapterRelationGroupId()
    local characterId = self.ChapterViewModel:GetChapterCharacterId()
    XLuaUiManager.Open("UiCharacterTowerFetter", relationGroupId, characterId)
end

-- 打开奖励界面
function XUiCharacterTowerBattle:OnBtnTreasureClick()
    if self:CloseStageDetail() then
        return
    end
    XLuaUiManager.Open("UiCharacterTowerTask", self.ChapterId)
end

return XUiCharacterTowerBattle