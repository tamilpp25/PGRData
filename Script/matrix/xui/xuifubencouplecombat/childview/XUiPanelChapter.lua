local XUiPanelChapter = XClass(nil, "XUiPanelChapter")
local XUiStageItem = require("XUi/XUiFubenCoupleCombat/ChildItem/XUiStageItem")

local FUBEN_FIGHT_DETAIL = "UiFubenCoupleCombatDetail"
local XUguiDragProxy = CS.XUguiDragProxy

function XUiPanelChapter:Ctor(ui, rootUi, chapterIndex)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL, self.CloseStageDetails, self)

    self.StageGroup = {}
    self.NeedReset = false
    self.ChapterIndex = chapterIndex

    self:InitPaneStageListActive()
end

function XUiPanelChapter:InitPaneStageListActive()
    for i = XFubenCoupleCombatConfig.ChapterType.Normal, XFubenCoupleCombatConfig.ChapterType.Hard do
        self["PaneStageList" .. i].gameObject:SetActiveEx(false)
    end
end
 
function XUiPanelChapter:OnEnable()
    if self.NeedReset then
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        self:ReopenAssetPanel()
    else
        self.NeedReset = true
    end

    self:DrawStagePanel()
end

function XUiPanelChapter:OnDestroy()
    self.IsOpenDetails = nil
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL, self.CloseStageDetails, self)
end

function XUiPanelChapter:SetUiData(chapterId, isAutoMove)
    self.LastUnlockStage = 1
    self.ChapterId = chapterId
    self.StageIdList = XFubenCoupleCombatConfig.GetChapterStageIds(chapterId)
    self.AssetPanel = self.RootUi.AssetPanel

    local chapterType = XFubenCoupleCombatConfig.GetChapterType(chapterId)
    self.ChapterType = chapterType
    self.PaneStageList = self["PaneStageList" .. chapterType]
    if not self.PaneStageList then
        XLog.Error(string.format("未在配置中找到ChapterType = %s，检查CoupleCombatChapter配置中的ChapterType字段，Id为：%s", chapterType, chapterId))
        return
    end

    self.PaneStageList.gameObject:SetActiveEx(true)
    self.PanelStageContent = self["PanelStageContent" .. chapterType]
    self.PanelStageContentRaycast = self["PanelStageContentRaycast" .. chapterType]
    self.PanelStageContentSizeFitter = self["PanelStageContentSizeFitter" .. chapterType]
    
    local dragProxy = self.PaneStageList:GetComponent(typeof(XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.PaneStageList.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))

    -- 关卡绘制
    self:DrawStagePanel()

    -- 移动至ListView正确的位置
    if self.PanelStageContentSizeFitter then
        self.PanelStageContentSizeFitter:SetLayoutHorizontal()
    end

    if isAutoMove then
        self:MoveIntoStage(self.LastUnlockStage)
    end
end

-- 关卡Panel绘制
function XUiPanelChapter:DrawStagePanel()
    if not self.PaneStageList or not XTool.IsNumberValid(self.ChapterType) then
        return 
    end

    self:HandleStages()
    
    -- 4期不连线
    -- if self.ChapterType == XFubenCoupleCombatConfig.ChapterType.Hard then
    --     -- 困难模式10个关卡9条线计算
    --     self:HandleStageLines(#self.StageIdList - 1)
    --     self:UpdateHardNodeLines()
    -- else
    --     -- 普通模式6个关卡6条线计算
    --     self:HandleStageLines(#self.StageIdList)
    --     self:UpdateNorNodeLines()
    -- end
end

-- 关卡处理
function XUiPanelChapter:HandleStages()
    self.ChapterStages = {}
    local stageCount = #self.StageIdList
    for i = 1, stageCount do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiPanelChapter:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        itemStage.gameObject:SetActiveEx(true)
        self.StageGroup[i] = itemStage
        self.ChapterStages[i] = XUiStageItem.New(self, itemStage, self.ChapterIndex)
        self.ChapterStages[i]:UpdateNode(self.StageIdList[i], i, self.ChapterId)
    end

    --隐藏多余组件
    local index = stageCount + 1
    local itemStage = self.PanelStageContent:Find(string.format("Stage%d", index))
    while itemStage do
        itemStage.gameObject:SetActiveEx(false)
        index = index + 1
        itemStage = self.PanelStageContent:Find(string.format("Stage%d", index))
    end
end

-- 线条处理
function XUiPanelChapter:HandleStageLines(stageListLength)
    self.ChapterStageLine = {}
    for i = 1, stageListLength do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiPanelChapter:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            return
        end
        itemLine.gameObject:SetActiveEx(false)
        self.ChapterStageLine[i] = itemLine
    end

    -- 隐藏多余组件
    local indexLine = #self.ChapterStageLine
    local extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    while extraLine do
        extraLine.gameObject:SetActiveEx(false)
        indexLine = indexLine + 1
        extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    end
end

-- 更新普通节点线条
function XUiPanelChapter:UpdateNorNodeLines()
    if not self.StageIdList then return end
    local stageLength = #self.StageIdList
    
    for i = 1, stageLength - 1 do
        local isHavenextStage = XDataCenter.FubenCoupleCombatManager.IsHaveNextStageIdByStageId(self.StageIdList[i])
        local isUnlock = (isHavenextStage and XDataCenter.FubenManager.CheckStageIsPass(self.StageIdList[i])) or 
            (not isHavenextStage and XDataCenter.FubenManager.CheckStageIsUnlock(self.StageIdList[i]))
        self:SetStageLineActive(i, isUnlock)
    end
    -- 处理最后合并线段
    local isLastLineActive = XDataCenter.FubenManager.CheckStageIsPass(self.StageIdList[#self.ChapterStageLine - 1]) or 
                             XDataCenter.FubenManager.CheckStageIsPass(self.StageIdList[#self.ChapterStageLine - 2])
    self:SetStageLineActive(#self.ChapterStageLine, isLastLineActive)

    for i = 1, stageLength do
        local isUnlock = XDataCenter.FubenManager.CheckStageIsUnlock(self.StageIdList[i])
        if isUnlock then
            self.LastUnlockStage = i
        end
    end
end

-- 更新困难节点线条
function XUiPanelChapter:UpdateHardNodeLines()
    if not self.StageIdList then return end
    local stageLength = #self.StageIdList
    
    for i = 1, stageLength - 1 do
        local isOpen = XDataCenter.FubenManager.CheckStageOpen(self.StageIdList[i + 1])
        self:SetStageLineActive(i, isOpen)
    end

    for i = 1, stageLength do
        local isUnlock = XDataCenter.FubenManager.CheckStageIsUnlock(self.StageIdList[i])
        if isUnlock then
            self.LastUnlockStage = i
        end
    end
end

function XUiPanelChapter:SetStageLineActive(index, isActive)
    if self.ChapterStageLine[index] then
        self.ChapterStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

-- 选中关卡
function XUiPanelChapter:UpdateNodesSelect(stageId)
    for i = 1, #self.StageIdList do
        if self.ChapterStages[i] then
            self.ChapterStages[i]:SetNodeSelect(self.StageIdList[i] == stageId)
        end
    end
end

-- 取消选中
function XUiPanelChapter:ClearNodesSelect()
    for i = 1, #self.StageIdList do
        if self.ChapterStages[i] then
            self.ChapterStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

-- 打开剧情，战斗详情
function XUiPanelChapter:OpenStageDetails(stageId)
    self.IsOpenDetails = true
    --self.BtnCloseDetail.gameObject:SetActiveEx(true)
    self.RootUi:OpenOneChildUi(FUBEN_FIGHT_DETAIL, self)
    self.RootUi:FindChildUiObj(FUBEN_FIGHT_DETAIL):SetStageDetail(stageId)
    
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(false)
    end
    self.PanelStageContentRaycast.raycastTarget = false
end

-- 关闭剧情，战斗详情
function XUiPanelChapter:CloseStageDetails()
    self.IsOpenDetails = false
    --self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self.PanelStageContentRaycast.raycastTarget = true
    self:ClearNodesSelect()
    self:ReopenAssetPanel()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
end

function XUiPanelChapter:OnBtnCloseDetailClick()
    self:CloseStageDetails()
end

function XUiPanelChapter:OnDragProxy(dragType)

    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

function XUiPanelChapter:PlayScrollViewMove(gridTransform)
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
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

function XUiPanelChapter:MoveIntoStage(stageIndex)
    local gridRect = self.StageGroup[stageIndex]
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX > CS.XResolutionManager.OriginWidth / 2 then
        local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x
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

function XUiPanelChapter:EndScrollViewMove()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
    self:ReopenAssetPanel()
end

function XUiPanelChapter:ReopenAssetPanel()
    if self.IsOpenDetails then
        return
    end
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(true)
    end
end

-- 背景
function XUiPanelChapter:SwitchFestivalBg(festivalTemplate)
    if not festivalTemplate or not festivalTemplate.MainBackgound then
        self.RImgFestivalBg.gameObject:SetActiveEx(false)
        return
    end
    self.RImgFestivalBg:SetRawImage(festivalTemplate.MainBackgound)
end

-- 加载特效
function XUiPanelChapter:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiPanelChapter:SetPanelStageListMovementType(movementType)
    if not self.PaneStageList then return end
    self.PaneStageList.movementType = movementType
end

return XUiPanelChapter