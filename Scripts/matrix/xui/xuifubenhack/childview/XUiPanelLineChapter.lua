local XUiPanelLineChapter = XClass(nil, "XUiPanelLineChapter")
local XUguiDragProxy = CS.XUguiDragProxy

local XUiGridStageItem = require("XUi/XUiFubenHack/ChildItem/XUiGridStageItem")

function XUiPanelLineChapter:Ctor(uiRoot, ui, chapterTemplate)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.ChapterTemplate = chapterTemplate
    self.StageGroup = {}
    self.GridTreasureList = {}

    XTool.InitUiObject(self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL, self.CloseStageDetails, self)
end

function XUiPanelLineChapter:OnShow(delay)
    --self.GameObject:SetActiveEx(false)
    self:Refresh()
    --self.AnimTimer = XScheduleManager.ScheduleOnce(function()
    --    self.GameObject:SetActiveEx(true)
    --    --self.AnimEnable:PlayTimelineAnimation()
    --    self.LineEnable:PlayTimelineAnimation()
    --    for _, v in ipairs(self.ActStages) do
    --        v.IconEnable:PlayTimelineAnimation()
    --    end
    --end, delay or 1000)

    if self.PaneStageList and self.NeedReset then
        self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    else
        self.NeedReset = true
    end

    if self.LastOpenStage then
        self:MoveIntoStage(self.LastOpenStage)
    end
end

function XUiPanelLineChapter:OnHide()
    self.GameObject:SetActiveEx(true)
    self.LineDisable:PlayTimelineAnimation()
    for _, v in ipairs(self.ActStages) do
        v.IconDisable:PlayTimelineAnimation()
    end
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)
        self.AnimTimer = nil
    end
end

-- 更新刷新
function XUiPanelLineChapter:Refresh()
    local dragProxy = self.PaneStageList:GetComponent(typeof(XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.PaneStageList.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))

    self.ActStageIds = self.ChapterTemplate.StageId
    --XDataCenter.FubenNewCharActivityManager.GetAvailableStageIds(self.ChapterTemplate.Id)
    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
    -- 界面信息
    -- self:SwitchFestivalBg(chapterTemplate)
end

function XUiPanelLineChapter:HandleStages()
    self.ActStages = {}
    for i = 1, #self.ActStageIds do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiPanelLineChapter:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        -- XLog.Warning(self.ActStageIds[i], isOpen, itemStage)
        self.StageGroup[i] = itemStage
        self.ActStages[i] = XUiGridStageItem.New(self, itemStage)
        itemStage.gameObject:SetActiveEx(true)
        self.ActStages[i]:UpdateNode(self.ChapterTemplate.Id, self.ActStageIds[i], i)
    end
    self:UpdateNodeLines()
end

function XUiPanelLineChapter:HandleStageLines()
    self.ActStageLine = {}
    for i = 2, #self.ActStageIds do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i-1))
        if not itemLine then
            XLog.Error("XUiPanelLineChapter:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            return
        end
        itemLine.gameObject:SetActiveEx(false)
        self.ActStageLine[i] = itemLine
    end
end

-- 更新节点线条
function XUiPanelLineChapter:UpdateNodeLines()
    if not self.ChapterTemplate or not self.ActStageIds then return end
    local stageLength = #self.ActStageIds
    for i = 2, stageLength do
        local isOpen = XDataCenter.FubenManager.CheckStageOpen(self.ActStageIds[i])
        self:SetStageLineActive(i, isOpen)
        if isOpen then
            self.LastOpenStage = i
        end
    end
    self:SetStageLineActive(1, true)
end

function XUiPanelLineChapter:SetStageLineActive(index, isActive)
    if self.ActStageLine[index] then
        self.ActStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

-- 选中关卡
function XUiPanelLineChapter:UpdateNodesSelect(stageId)
    local stageIds = self.ActStageIds
    for i = 1, #stageIds do
        if self.ActStages[i] then
            self.ActStages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
function XUiPanelLineChapter:ClearNodesSelect()
    for i = 1, #self.ActStageIds do
        if self.ActStages[i] then
            self.ActStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

function XUiPanelLineChapter:GetStages()
    local stageIds = {}
    for i = 1, #self.ChapterTemplate.StageId do
        stageIds[i] = self.ChapterTemplate.StageId[i]
    end
    return stageIds
end

-- 打开剧情，战斗详情
function XUiPanelLineChapter:OpenStageDetails(stageId)
    --self:CloseStageDetails()

    self.UiRoot:OpenChildUi("UiFubenHackSection", self.UiRoot)
    local childUiObj = self.UiRoot:FindChildUiObj("UiFubenHackSection")
    if childUiObj then
        childUiObj:SetStageDetail(stageId)
    end

    self.PanelStageContentRaycast.raycastTarget = false
end

-- 关闭剧情，战斗详情
function XUiPanelLineChapter:CloseStageDetails()
    self.IsOpenDetails = false
    self.PanelStageContentRaycast.raycastTarget = true
    self:ClearNodesSelect()
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

function XUiPanelLineChapter:OnDragProxy(dragType)
    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

function XUiPanelLineChapter:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL, self.CloseStageDetails, self)
end

function XUiPanelLineChapter:PlayScrollViewMove(gridTransform)
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

function XUiPanelLineChapter:MoveIntoStage(stageIndex)
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

function XUiPanelLineChapter:EndScrollViewMove()
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

-- 背景
function XUiPanelLineChapter:SwitchFestivalBg(festivalTemplate)
    if not festivalTemplate or not festivalTemplate.MainBackgound then return end
    self.RImgFestivalBg:SetRawImage(festivalTemplate.MainBackgound)
end

return XUiPanelLineChapter