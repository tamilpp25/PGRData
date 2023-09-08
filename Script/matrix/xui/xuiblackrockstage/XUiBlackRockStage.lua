local XUiBlackRockStageItem = require("XUi/XUiBlackRockStage/XUiBlackRockStageItem")

---@field private _Control XBlackRockStageControl
---@class XUiBlackRockStage:XLuaUi
local XUiBlackRockStage = XLuaUiManager.Register(XLuaUi, "UiBlackRockStage")

function XUiBlackRockStage:Ctor()
    self.IsOpenDetails = false
    ---@type XUiFestivalStageItem[]
    self.FestivalStages = nil
    self.FestivalStageLine = nil
    self.LastOpenStage = nil
    self.StageGroup = {}
    self._UiDetailName = "UiEpicFashionGachaStageDetail"
end

function XUiBlackRockStage:OnAwake()
    self:BindExitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDetail, self.OnClickCloseDetail)
    self:RegisterClickEvent(self.ToggleSkipMovie, self.OnClickSkipMovie)
end

function XUiBlackRockStage:OnStart()
    -- 保存点击
    XDataCenter.FubenFestivalActivityManager.SaveFestivalActivityIsOpen(XEnumConst.BLACK_ROCK.STAGE.FESTIVAL_ACTIVITY_ID)
end

function XUiBlackRockStage:OnEnable()
    self._Control:UpdateUiData()

    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()

    self:Update()

    self:PlayVideo()

    if self.LastOpenStage then
        self:MoveIntoStage(self.LastOpenStage)
    end
end

function XUiBlackRockStage:OnGetEvents()
    return {
        CS.XEventId.EVENT_UI_DISABLE,
    }
end

function XUiBlackRockStage:OnNotify(evt, uiObject)
    local uiName = uiObject.UiData.UiName
    if uiName ~= self._UiDetailName then
        return
    end
    self:EndScrollViewMove()
end

function XUiBlackRockStage:Update()
    local uiData = self._Control:GetUiData()
    self.ToggleSkipMovie.isOn = uiData.IsSkipMovie
end

function XUiBlackRockStage:OnClickCloseDetail()
    self.IsOpenDetails = false
    XLuaUiManager.Close(self._UiDetailName)
end

function XUiBlackRockStage:OnClickSkipMovie()
    local isOn = self.ToggleSkipMovie.isOn
    self._Control:SetSkipMovie(isOn)
end

--region scroll
function XUiBlackRockStage:SetPanelStageListMovementType(moveMentType)
    self.PanelStageList.movementType = moveMentType
end

function XUiBlackRockStage:MoveIntoStage(stageIndex)
    ---@type UnityEngine.RectTransform
    local gridRect = self.StageGroup[stageIndex]
    local gridWidth = gridRect.rect.width

    -- ui设置的宽度与子ui宽度大小不一
    if gridRect.childCount > 0 then
        local child = gridRect:GetChild(0)
        local childTransform = XUiHelper.TryGetComponent(child, "", "RectTransform")
        if childTransform then
            local childWidth = childTransform.rect.width
            if childWidth > gridWidth then
                gridWidth = childWidth
            end
        end
    end

    local diffX = gridRect.anchoredPosition.x + self.PanelStageContent.anchoredPosition.x + gridWidth
    local left = self:GetScrollOffsetX()

    if diffX > CS.XResolutionManager.OriginWidth - left then
        local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x - left
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
            self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        end)
    end
end

function XUiBlackRockStage:HandleStages()
    self.FestivalStages = {}
    local uiData = self._Control:GetUiData()
    local stageList = uiData.StageList
    local chapterId = uiData.ChapterId
    for i = 1, #stageList do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiFubenChristmasMainLineChapter:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        itemStage.gameObject:SetActiveEx(true)
        self.StageGroup[i] = itemStage
        self.FestivalStages[i] = XUiBlackRockStageItem.New(self, itemStage)
        self.FestivalStages[i]:UpdateNode(chapterId, stageList[i].StageId)
    end
    self:UpdateNodeLines()
    -- 隐藏多余组件
    local indexStage = #stageList + 1
    local extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    while extraStage do
        extraStage.gameObject:SetActiveEx(false)
        indexStage = indexStage + 1
        extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    end
end

function XUiBlackRockStage:HandleStageLines()
    self.FestivalStageLine = {}
    local uiData = self._Control:GetUiData()
    local stageList = uiData.StageList
    for i = 1, #stageList do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiFubenChristmasMainLineChapter:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            return
        end
        itemLine.gameObject:SetActiveEx(false)
        self.FestivalStageLine[i] = itemLine
    end

    -- 隐藏多余组件
    local indexLine = #self.FestivalStageLine
    local extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    while extraLine do
        extraLine.gameObject:SetActiveEx(false)
        indexLine = indexLine + 1
        extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    end
end

-- 更新节点线条
function XUiBlackRockStage:UpdateNodeLines()
    local uiData = self._Control:GetUiData()
    local stageList = uiData.StageList
    local stageLength = #stageList
    for i = 2, stageLength do
        local isOpen = stageList[i].IsOpen
        self:SetStageLineActive(i, isOpen)
        if isOpen then
            self.LastOpenStage = i
        end
    end
    self:SetStageLineActive(1, false)
    --self:SetStageLineActive(stageLength, false)
end

function XUiBlackRockStage:SetStageLineActive(index, isActive)
    if self.FestivalStageLine[index] then
        self.FestivalStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

-- 选中关卡
function XUiBlackRockStage:UpdateNodesSelect(stageId)
    local stageList = self._Control:GetUiData().StageList
    for i = 1, #stageList do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(stageList[i].StageId == stageId)
        end
    end
end

function XUiBlackRockStage:OpenStageDetails(stageId)
    XLuaUiManager.Open(self._UiDetailName, stageId)
end

function XUiBlackRockStage:PlayScrollViewMove(gridTransform)
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
    local gridRect = gridTransform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local left = self:GetScrollOffsetX()
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x - left / 2
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiBlackRockStage:GetScrollOffsetX()
    local viewPortRectTransform = XUiHelper.TryGetComponent(self.PanelStageContent.parent, "", "RectTransform")
    local left = viewPortRectTransform.offsetMin.x
    return left
end

function XUiBlackRockStage:OnUiDetailDisable(ui)
    print(ui)
end

function XUiBlackRockStage:EndScrollViewMove()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
end

--endregion

function XUiBlackRockStage:PlayVideo()
    local videoId = 10104
    local url = XVideoConfig.GetMovieUrlById(videoId)
    self.VideoPlayer:SetVideoFromRelateUrl(url)
    self.VideoPlayer:Prepare()
end

return XUiBlackRockStage
