local XUiSimulatedCombatChapter = XClass(nil, "XUiSimulatedCombatChapter")
local XUiStageItem = require("XUi/XUiFubenSimulatedCombat/ChildItem/XUiStageItem")

local FUBEN_FIGHT_DETAIL = "UiSimulatedCombatStageDetail"
local XUguiDragProxy = CS.XUguiDragProxy

function XUiSimulatedCombatChapter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.StageGroup = {}
    self.NeedReset = false
end
 
function XUiSimulatedCombatChapter:OnEnable()
    if self.PanelStageList and self.NeedReset then
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        self:ReopenAssetPanel()
    else
        self.NeedReset = true
    end

    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
    -- 彩蛋处理
    --self:HandleEggStage()
end

function XUiSimulatedCombatChapter:OnDestroy()
    self.IsOpenDetails = nil
    self:StopActivityTimer()
end

function XUiSimulatedCombatChapter:OpenDefaultStage(stageId)
    if self.StageInterDatas and self.ChapterStages then
        for i = 2, #self.StageInterDatas do
            if self.StageInterDatas[i].StageId == stageId and self.ChapterStages[i] then
                self.ChapterStages[i]:OnBtnStageClick()
                break
            end
        end
    end
end

function XUiSimulatedCombatChapter:SetUiData(chapterType)
    self.LastUnlockStage = 1
    self.ChapterType = chapterType
    self.ChapterTemplate = XDataCenter.FubenSimulatedCombatManager.GetCurrentActTemplate()
    if not self.ChapterTemplate then return end
    self.StageInterDatas = XFubenSimulatedCombatConfig.GetStageInterDataByType(chapterType)
    -- 初始化prefab组件
    local chapterGameObject = self.Transform:LoadPrefab(self.ChapterTemplate.ChapterPrefab[chapterType])
    --XTool.InitUiObjectByUi(self, chapterGameObject)

    local uiObj = chapterGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    
    if self.PaneStageList then
        local dragProxy = self.PaneStageList:GetComponent(typeof(XUguiDragProxy))
        if not dragProxy then
            dragProxy = self.PaneStageList.gameObject:AddComponent(typeof(XUguiDragProxy))
        end
        dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
    end
    --self.StageInterDatas = self:GetFakeStages()
    -- 线条处理
    self:HandleStageLines()

    self:UpdateNodeLines()
    -- 关卡处理
    self:HandleStages()
    -- 彩蛋处理
    --self:HandleEggStage()
    -- 界面信息
    --self:SwitchFestivalBg(chapterTemplate)
    -- 加载特效
    --self:LoadEffect(chapterTemplate.EffectUrl)
    
    self:MoveIntoStage(self.LastUnlockStage)
end

function XUiSimulatedCombatChapter:HandleStages()
    self.ChapterStages = {}
    for i = 1, #self.StageInterDatas do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i+1))
        if not itemStage then
            XLog.Error("XUiSimulatedCombatChapter:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        else
            --XLog.Warning("itemStage",itemStage, i)
        end
        -- 组件初始化
        itemStage.gameObject:SetActiveEx(true)
        self.StageGroup[i] = itemStage
        self.ChapterStages[i] = XUiStageItem.New(self, itemStage)
        self.ChapterStages[i]:UpdateNode(self.StageInterDatas[i])
        self.ChapterStages[i]:SetChallengingStage(i == self.LastUnlockStage)
    end
    
    -- 隐藏多余组件
    --local indexStage = #self.StageInterDatas + 2
    --local extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    --while extraStage do
    --    extraStage.gameObject:SetActiveEx(false)
    --    indexStage = indexStage + 1
    --    extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    --end
end

function XUiSimulatedCombatChapter:HandleStageLines()
    self.ChapterStageLine = {}
    for i = 1, #self.StageInterDatas do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiSimulatedCombatChapter:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
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
function XUiSimulatedCombatChapter:UpdateNodeLines()
    if not self.StageInterDatas then return end
    local stageLength = #self.StageInterDatas
    
    for i = 2, stageLength do
        local isOpen = XDataCenter.FubenManager.CheckStageOpen(self.StageInterDatas[i].StageId)
        self:SetStageLineActive(i, isOpen)
        local isUnlock = XDataCenter.FubenManager.CheckStageIsUnlock(self.StageInterDatas[i].StageId)
        if isUnlock then
            self.LastUnlockStage = i
        end
    end
    self:SetStageLineActive(1, false)
    self:SetStageLineActive(stageLength + 1, true)
end

function XUiSimulatedCombatChapter:SetStageLineActive(index, isActive)
    if self.ChapterStageLine[index] then
        self.ChapterStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

--function XUiSimulatedCombatChapter:HandleEggStage()
--    self.ChapterStageLine[1].gameObject:SetActiveEx(false)
--    local eggStageIndex = 1
--    local eggStageId = self.FestivalStageIds[eggStageIndex]
--    if XDataCenter.FubenFestivalActivityManager.IsEgg(eggStageId) then
--        -- 彩蛋处理
--        local isUnlock = XDataCenter.FubenFestivalActivityManager.CheckFestivalStageOpen(eggStageId)
--        self.FestivalStages[eggStageIndex].GameObject:SetActiveEx(isUnlock)
--        local stageCfg = XDataCenter.FubenManager.GetStageCfg(eggStageId)
--        if isUnlock and stageCfg then
--            if stageCfg.PreStageId and stageCfg.PreStageId[1] then
--                for i = 1, #self.FestivalStageIds do
--                    if stageCfg.PreStageId[1] == self.FestivalStageIds[i] then
--                        self.FestivalStages[eggStageIndex]:ResetItemPosition(self.FestivalStages[i].Transform.localPosition)
--                        break
--                    end
--                end
--            end
--        end
--    else
--        -- 非彩蛋
--        self.FestivalStages[eggStageIndex].GameObject:SetActiveEx(false)
--    end
--    self.FestivalStageLine[eggStageIndex].gameObject:SetActiveEx(false)
--end

-- 选中关卡
function XUiSimulatedCombatChapter:UpdateNodesSelect(stageId)
    for i = 1, #self.StageInterDatas do
        if self.ChapterStages[i] then
            self.ChapterStages[i]:SetNodeSelect(self.StageInterDatas[i].StageId == stageId)
        end
    end
end

-- 取消选中
function XUiSimulatedCombatChapter:ClearNodesSelect()
    for i = 1, #self.StageInterDatas do
        if self.ChapterStages[i] then
            self.ChapterStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

-- 没有彩蛋则增加一个假彩蛋
function XUiSimulatedCombatChapter:GetFakeStages()
    local stageIds = {}
    for i = 1, #self.ChapterStages do
        stageIds[i] = self.ChapterStages[i]
    end
    table.insert(stageIds, 1, stageIds[1])
    return stageIds
end

-- 打开剧情，战斗详情
function XUiSimulatedCombatChapter:OpenStageDetails(stageInterId)
    self.IsOpenDetails = true
    self.BtnCloseDetail.gameObject:SetActiveEx(true)
    self.RootUi:OpenOneChildUi(FUBEN_FIGHT_DETAIL, self)
    self.RootUi:FindChildUiObj(FUBEN_FIGHT_DETAIL):SetStageDetail(stageInterId)
    
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(false)
    end
    self.PanelStageContentRaycast.raycastTarget = false
end

-- 关闭剧情，战斗详情
function XUiSimulatedCombatChapter:CloseStageDetails()
    self.IsOpenDetails = false
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self.PanelStageContentRaycast.raycastTarget = true
    self:ClearNodesSelect()
    self:ReopenAssetPanel()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
end

function XUiSimulatedCombatChapter:OnBtnCloseDetailClick()
    self:CloseStageDetails()
end

function XUiSimulatedCombatChapter:OnDragProxy(dragType)
    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

function XUiSimulatedCombatChapter:PlayScrollViewMove(gridTransform)
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

function XUiSimulatedCombatChapter:MoveIntoStage(stageIndex)
    local gridRect = self.StageGroup[stageIndex]
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    --XLog.Warning("diffX", diffX, CS.XResolutionManager.OriginWidth / 2)
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

function XUiSimulatedCombatChapter:EndScrollViewMove()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
    self:ReopenAssetPanel()
end

function XUiSimulatedCombatChapter:ReopenAssetPanel()
    if self.IsOpenDetails then
        return
    end
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(true)
    end
end

-- 背景
function XUiSimulatedCombatChapter:SwitchFestivalBg(festivalTemplate)
    if not festivalTemplate or not festivalTemplate.MainBackgound then
        self.RImgFestivalBg.gameObject:SetActiveEx(false)
        return
    end
    self.RImgFestivalBg:SetRawImage(festivalTemplate.MainBackgound)
end

-- 加载特效
function XUiSimulatedCombatChapter:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiSimulatedCombatChapter:SetPanelStageListMovementType(movementType)
    if not self.PanelStageList then return end
    self.PanelStageList.movementType = movementType
end

return XUiSimulatedCombatChapter