local XUiPanelFubenSpringFestivalStage = XClass(nil, "XUiPanelFubenSpringFestivalStage")
local XUiSpringFestivalStageItem = require("XUi/XUiSpringFestival/XUiSpringFestivalStageItem")
local XUguiDragProxy = CS.XUguiDragProxy

local FESTIVAL_FIGHT_DETAIL = "UiFubenSpringFestivalStageDetail"
local FESTIVAL_STORY_DETAIL = "UiStorySpringFestivalStageDetail"
function XUiPanelFubenSpringFestivalStage:Ctor(rootUi, transform, chapter)
    self.RootUi = rootUi
    self.GameObject = transform.gameObject
    self.Transform = transform
    self.Chapter = chapter
    self.StageCount = self.Chapter:GetStageTotalCount()
    self.LineCount = self.StageCount - 1
    XTool.InitUiObject(self)
    self:InitUi()
end

function XUiPanelFubenSpringFestivalStage:InitUi()
    self.Stages = {}
    self.Lines = {}
    local stageIds = self.Chapter:GetStageIdList()
    for i = 1, self.StageCount do
        local itemStage = self.PanelStageContent:Find("Stage" .. i)
        self.Stages[i] = XUiSpringFestivalStageItem.New(self, itemStage)
        self.Stages[i]:UpdateNode(self.Chapter:GetChapterId(), stageIds[i])
    end

    for i = 1, self.LineCount do
        self.Lines[i] = self.PanelStageContent:Find("Line" .. i)
    end

    self.BtnCloseDetail.CallBack = function() self:OnBtnCloseDetailClick() end
    self:Refresh()
end

function XUiPanelFubenSpringFestivalStage:Refresh()
    local dragProxy = self.PaneStageList:GetComponent(typeof(XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.PaneStageList.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
    self.Chapter:RefreshChapterStageInfos()
    self:RefreshStages()
end

function XUiPanelFubenSpringFestivalStage:RefreshStages()
    local stageIds = self.Chapter:GetStageIdList()
    for i = 1, self.StageCount do
        if self.Stages[i] then
            self.Stages[i]:UpdateNode(self.Chapter:GetChapterId(), stageIds[i])
        end
    end
    self:RefreshLines()
end

function XUiPanelFubenSpringFestivalStage:RefreshLines()
    local passCount = self.Chapter:GetStagePassCount()
    for i = 1, self.LineCount do
        self.Lines[i].gameObject:SetActiveEx(i <= passCount)
    end
end

-- 选中关卡
function XUiPanelFubenSpringFestivalStage:UpdateNodesSelect(stageId)
    local stageIds = self.Chapter:GetStageIdList()
    for i = 1, #stageIds do
        if self.Stages[i] then
            self.Stages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
function XUiPanelFubenSpringFestivalStage:ClearNodesSelect()
    local stageIds = self.Chapter:GetStageIdList()
    for i = 1, #stageIds do
        if self.Stages[i] then
            self.Stages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

-- 打开剧情，战斗详情
function XUiPanelFubenSpringFestivalStage:OpenStageDetails(stageId, festivalId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    local detailType = XDataCenter.FubenFestivalActivityManager.StageFuben
    self.BtnCloseDetail.gameObject:SetActiveEx(true)
    if not fStage then
        self.IsOpenDetails = true
        self.StageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageType = self.StageCfg.StageType
        if stageType == XFubenConfigs.STAGETYPE_FIGHT or stageType == XFubenConfigs.STAGETYPE_FIGHTEGG then
            detailType = XDataCenter.FubenFestivalActivityManager.StageFuben
        elseif stageType == XFubenConfigs.STAGETYPE_STORY or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
            detailType = XDataCenter.FubenFestivalActivityManager.StageStory
        end
    else
        self.FStage = fStage
        self.IsOpenDetails = true
        detailType = self.FStage:GetStageShowType()
    end

    if detailType == XDataCenter.FubenFestivalActivityManager.StageFuben then
        self.RootUi:OpenOneChildUi(FESTIVAL_FIGHT_DETAIL, self)
        self.RootUi:FindChildUiObj(FESTIVAL_FIGHT_DETAIL):SetStageDetail(stageId, festivalId)
        if XLuaUiManager.IsUiShow(FESTIVAL_STORY_DETAIL) then
            self.RootUi:FindChildUiObj(FESTIVAL_STORY_DETAIL):Close()
        end
    elseif detailType == XDataCenter.FubenFestivalActivityManager.StageStory then
        self.RootUi:OpenOneChildUi(FESTIVAL_STORY_DETAIL, self)
        self.RootUi:FindChildUiObj(FESTIVAL_STORY_DETAIL):SetStageDetail(stageId, festivalId)
        if XLuaUiManager.IsUiShow(FESTIVAL_FIGHT_DETAIL) then
            self.RootUi:FindChildUiObj(FESTIVAL_FIGHT_DETAIL):Close()
        end
    end
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(false)
    end
    self.PanelStageContentRaycast.raycastTarget = false
    self.RootUi:PlayAnimation("PanelTitleDisable")
end

-- 关闭剧情，战斗详情
function XUiPanelFubenSpringFestivalStage:CloseStageDetails()
    self.IsOpenDetails = false
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self.PanelStageContentRaycast.raycastTarget = true
    if XLuaUiManager.IsUiShow(FESTIVAL_STORY_DETAIL) then
        self.RootUi:FindChildUiObj(FESTIVAL_STORY_DETAIL):CloseDetailWithAnimation()
    end

    if XLuaUiManager.IsUiShow(FESTIVAL_FIGHT_DETAIL) then
        self.RootUi:FindChildUiObj(FESTIVAL_FIGHT_DETAIL):CloseDetailWithAnimation()
    end
    self:ClearNodesSelect()
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    self.RootUi:PlayAnimation("PanelTitleEnable")
end

function XUiPanelFubenSpringFestivalStage:OnBtnCloseDetailClick()
    self:CloseStageDetails()
end

function XUiPanelFubenSpringFestivalStage:PlayScrollViewMove(gridTransform)
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    local gridRect = gridTransform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiPanelFubenSpringFestivalStage:MoveIntoStage(stageIndex)
    local gridRect = self.StageGroup[stageIndex]
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX > CS.XResolutionManager.OriginWidth / 2 then
        local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
            self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        end)
    end
end

function XUiPanelFubenSpringFestivalStage:EndScrollViewMove()
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

function XUiPanelFubenSpringFestivalStage:OnDragProxy(dragType)
    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

function XUiPanelFubenSpringFestivalStage:ShowPanel(isShow)
    self.GameObject:SetActiveEx(isShow)
end

return XUiPanelFubenSpringFestivalStage