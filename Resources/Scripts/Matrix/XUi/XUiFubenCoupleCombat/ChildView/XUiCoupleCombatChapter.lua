local XUiCoupleCombatChapter = XClass(nil, "XUiCoupleCombatChapter")
local XUiStageItem = require("XUi/XUiFubenCoupleCombat/ChildItem/XUiStageItem")

local FUBEN_FIGHT_DETAIL = "UiFubenCoupleCombatDetail"
local XUguiDragProxy = CS.XUguiDragProxy

function XUiCoupleCombatChapter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL, self.CloseStageDetails, self)

    self.StageGroup = {}
    self.NeedReset = false
end
 
function XUiCoupleCombatChapter:OnEnable()
    if self.NeedReset then
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        self:ReopenAssetPanel()
    else
        self.NeedReset = true
    end

    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
end

function XUiCoupleCombatChapter:OnDestroy()
    self.IsOpenDetails = nil
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL, self.CloseStageDetails, self)
end

function XUiCoupleCombatChapter:SetUiData(chapterType, isAutoMove)
    self.LastUnlockStage = 1
    self.ChapterType = chapterType
    self.StageIdList = XDataCenter.FubenCoupleCombatManager.GetChapterTemplate(chapterType).StageIds
    -- 初始化prefab组件
    --local chapterGameObject = self.Transform:LoadPrefab(self.ChapterTemplate.ChapterPrefab[chapterType])
    --XTool.InitUiObjectByUi(self, chapterGameObject)

    --local uiObj = chapterGameObject.transform:GetComponent("UiObject")
    --for i = 0, uiObj.NameList.Count - 1 do
    --    self[uiObj.NameList[i]] = uiObj.ObjList[i]
    --end
    self.AssetPanel = self.RootUi.AssetPanel
    
    if self.PaneStageList then
        local dragProxy = self.PaneStageList:GetComponent(typeof(XUguiDragProxy))
        if not dragProxy then
            dragProxy = self.PaneStageList.gameObject:AddComponent(typeof(XUguiDragProxy))
        end
        dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
    end
    -- 线条处理
    self:HandleStageLines()

    self:UpdateNodeLines()
    -- 关卡处理
    self:HandleStages()

    -- 移动至ListView正确的位置
    if self.PanelStageContentSizeFitter then
        self.PanelStageContentSizeFitter:SetLayoutHorizontal()
    end

    if isAutoMove then
        self:MoveIntoStage(self.LastUnlockStage)
    end
end

function XUiCoupleCombatChapter:HandleStages()
    self.ChapterStages = {}
    for i = 1, #self.StageIdList do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiCoupleCombatChapter:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        itemStage.gameObject:SetActiveEx(true)
        self.StageGroup[i] = itemStage
        self.ChapterStages[i] = XUiStageItem.New(self, itemStage)
        self.ChapterStages[i]:UpdateNode(self.StageIdList[i], i, self.ChapterType)
        --self.ChapterStages[i]:SetChallengingStage(i == self.LastUnlockStage)
    end
end

function XUiCoupleCombatChapter:HandleStageLines()
    self.ChapterStageLine = {}
    for i = 1, #self.StageIdList-1 do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiCoupleCombatChapter:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
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

-- 更新节点线条
function XUiCoupleCombatChapter:UpdateNodeLines()
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

    --self:SetStageLineActive(1, false)
    --self:SetStageLineActive(stageLength + 1, true)
end

function XUiCoupleCombatChapter:SetStageLineActive(index, isActive)
    if self.ChapterStageLine[index] then
        self.ChapterStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

-- 选中关卡
function XUiCoupleCombatChapter:UpdateNodesSelect(stageId)
    for i = 1, #self.StageIdList do
        if self.ChapterStages[i] then
            self.ChapterStages[i]:SetNodeSelect(self.StageIdList[i] == stageId)
        end
    end
end

-- 取消选中
function XUiCoupleCombatChapter:ClearNodesSelect()
    for i = 1, #self.StageIdList do
        if self.ChapterStages[i] then
            self.ChapterStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

-- 打开剧情，战斗详情
function XUiCoupleCombatChapter:OpenStageDetails(stageId)
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
function XUiCoupleCombatChapter:CloseStageDetails()
    self.IsOpenDetails = false
    --self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self.PanelStageContentRaycast.raycastTarget = true
    self:ClearNodesSelect()
    self:ReopenAssetPanel()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
end

function XUiCoupleCombatChapter:OnBtnCloseDetailClick()
    self:CloseStageDetails()
end

function XUiCoupleCombatChapter:OnDragProxy(dragType)
    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

function XUiCoupleCombatChapter:PlayScrollViewMove(gridTransform)
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

function XUiCoupleCombatChapter:MoveIntoStage(stageIndex)
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

function XUiCoupleCombatChapter:EndScrollViewMove()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
    self:ReopenAssetPanel()
end

function XUiCoupleCombatChapter:ReopenAssetPanel()
    if self.IsOpenDetails then
        return
    end
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(true)
    end
end

-- 背景
function XUiCoupleCombatChapter:SwitchFestivalBg(festivalTemplate)
    if not festivalTemplate or not festivalTemplate.MainBackgound then
        self.RImgFestivalBg.gameObject:SetActiveEx(false)
        return
    end
    self.RImgFestivalBg:SetRawImage(festivalTemplate.MainBackgound)
end

-- 加载特效
function XUiCoupleCombatChapter:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiCoupleCombatChapter:SetPanelStageListMovementType(movementType)
    if not self.PaneStageList then return end
    self.PaneStageList.movementType = movementType
end

return XUiCoupleCombatChapter