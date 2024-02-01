local XUiGridChapter = require("XUi/XUiFubenMainLineChapter/XUiGridChapter")
local XUiMultiDimSingleCopy = XLuaUiManager.Register(XLuaUi, "UiMultiDimSingleCopy")
local XUguiDragProxy = CS.XUguiDragProxy

function XUiMultiDimSingleCopy:OnAwake()
    self.LastOpenStage = nil
    self.StageGroup = {}
    self:InitUiView()
    XEventManager.AddEventListener(XEventId.EVENT_ON_MULTIDIM_SINGLE_CHANGED, self.RefreshNodes, self) --通关刷新数据
end

function XUiMultiDimSingleCopy:OnEnable()
    if self.LastOpenStage then
        self:MoveIntoStage(self.LastOpenStage)
    end
    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
    -- -- 彩蛋处理
    -- self:HandleEggStage()
end

function XUiMultiDimSingleCopy:InitUiView()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnCloseDetail.CallBack = function() self:OnBtnCloseDetailClick() end
    self:BindHelpBtn(self.BtnHelp, "MultiDimMain")
end

function XUiMultiDimSingleCopy:OnStart(themeId)
    self.ThemeId = themeId
    self.ThemeDataCfg = XDataCenter.MultiDimManager.GetMultiDimThemeData(themeId)

    self:SetUiData(self.ThemeDataCfg)
end

function XUiMultiDimSingleCopy:SetUiData(themeDataCfg)
    -- 先检测时间
    local now = XTime.GetServerNowTimestamp()
    local endTimeSecond = XFunctionManager.GetEndTimeByTimeId(themeDataCfg.TimeId)
    if endTimeSecond then
        -- self.TxtDay.text = XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.ACTIVITY)
        self:CreateActivityTimer(endTimeSecond)
    end

    -- 初始化prefab组件
    local chapterGameObject = self.PanelChapter:LoadPrefab(themeDataCfg.FubenSinglePrefab)
    local uiObj = chapterGameObject.transform:GetComponent("UiObject") --把加载出的副本prefab的UiObject添加到self
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

    self.StageIdList = self:GetFakeStages()
    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
    -- -- 彩蛋处理
    -- self:HandleEggStage()
    -- 背景图片
    self:SwitchBg(themeDataCfg)
    -- 加载特效
    self:LoadEffect(themeDataCfg.EffectUrl)
   
    self.TxtChapterName.text = self.ThemeDataCfg.Name
    
    local itemId = XDataCenter.MultiDimManager.GetActivityItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
end

function XUiMultiDimSingleCopy:CreateActivityTimer(endTime)
    self:StopActivityTimer()
    self:UpdateTime(endTime)
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime(endTime)
    end, XScheduleManager.SECOND)
end

function XUiMultiDimSingleCopy:UpdateTime(endTime)
    local now = XTime.GetServerNowTimestamp()
    if now >= endTime then
        XUiManager.TipText("MultiDimActivityEnd")
        self:StopActivityTimer()
        self:Close()
        return
    end
    self.TxtDay.text = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiMultiDimSingleCopy:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiMultiDimSingleCopy:HandleStages()
    self.Stages = {}
    for i = 1, #self.StageIdList do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiMultiDimSingleCopy:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        itemStage.gameObject:SetActiveEx(true)
        self.StageGroup[i] = itemStage
        self.Stages[i] = XUiMultiDimSingleStageItem.New(self, itemStage)
        self.Stages[i]:UpdateNode(self.ThemeId, self.StageIdList[i], i)
    end
    self:UpdateNodeLines()
    -- 隐藏多余组件
    local indexStage = #self.StageIdList + 1
    local extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    while extraStage do
        extraStage.gameObject:SetActiveEx(false)
        indexStage = indexStage + 1
        extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    end
end

function XUiMultiDimSingleCopy:HandleStageLines()
    self.StageLine = {}
    for i = 1, #self.StageIdList - 1 do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiMultiDimSingleCopy:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            return
        end
        itemLine.gameObject:SetActiveEx(false)
        self.StageLine[i] = itemLine
    end

    -- 隐藏多余组件
    local indexLine = #self.StageLine
    local extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    while extraLine do
        extraLine.gameObject:SetActiveEx(false)
        indexLine = indexLine + 1
        extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    end
end

-- 更新刷新
function XUiMultiDimSingleCopy:RefreshNodes()
    if not self.ThemeDataCfg or not self.StageIdList then return end
    for i = 1, #self.StageIdList do
        self.Stages[i]:UpdateNode(self.ThemeDataCfg.Id, self.StageIdList[i], i)
    end
    self:UpdateNodeLines()
    -- self:HandleEggStage()
end

-- 更新节点线条
function XUiMultiDimSingleCopy:UpdateNodeLines()
    if not self.ThemeDataCfg or not self.StageIdList then return end
    local stageLength = #self.StageIdList
    for i = 2, stageLength do
        local isOpen = XDataCenter.FubenManager.GetStageInfo(self.StageIdList[i]).IsOpen
        self:SetStageLineActive(i - 1, isOpen)
        if isOpen then
            self.LastOpenStage = i
        end
    end
    -- self:SetStageLineActive(1, false)
    self:SetStageLineActive(stageLength, false)
end

function XUiMultiDimSingleCopy:SetStageLineActive(index, isActive)
    if self.StageLine[index] then
        self.StageLine[index].gameObject:SetActiveEx(isActive)
    end
end

function XUiMultiDimSingleCopy:HandleEggStage()
    local eggStageIndex = 1
    local eggStageId = self.StageIdList[eggStageIndex]
    local eggStageCfg = XDataCenter.FubenManager.GetStageCfg(eggStageId)
    local eggStageInfo = XDataCenter.FubenManager.GetStageInfo(eggStageId)
    local stageType = eggStageCfg.stageType
    if eggStageCfg and stageType and ((stageType == XFubenConfigs.STAGETYPE_STORYEGG) or (stageType == XFubenConfigs.STAGETYPE_FIGHTEGG)) then
        -- 彩蛋处理
        local isUnlock = eggStageInfo.IsOpen
        self.Stages[eggStageIndex].GameObject:SetActiveEx(isUnlock)
        if isUnlock then
            local preStageIds = eggStageCfg.PreStageId
            if preStageIds and preStageIds[1] then
                for i = 1, #self.StageIdList do
                    if preStageIds[1] == self.StageIdList[i] then
                        self.Stages[eggStageIndex]:ResetItemPosition(self.Stages[i].Transform.localPosition)
                        break
                    end
                end
            end
        end
    else
        -- 非彩蛋
        self.Stages[eggStageIndex].GameObject:SetActiveEx(false)
    end
    self.StageLine[eggStageIndex].gameObject:SetActiveEx(false)
end

-- 点击:选中关卡
function XUiMultiDimSingleCopy:UpdateNodesSelect(stageId)
    local stageIds = self.StageIdList
    for i = 1, #stageIds do
        if self.Stages[i] then
            self.Stages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
function XUiMultiDimSingleCopy:ClearNodesSelect()
    for i = 1, #self.StageIdList do
        if self.Stages[i] then
            self.Stages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

function XUiMultiDimSingleCopy:GetFakeStages()
    local stageIds = {}
    local stageIdList = XMultiDimConfig.GetMultiSingleStageListByThemeId(self.ThemeId)
    if stageIdList and next(stageIdList) then
        for i = 1, #stageIdList do
            stageIds[i] = stageIdList[i]
        end
        -- local firstStage = self.ThemeDataCfg:GetStageByOrderIndex(1)
        -- if not firstStage:GetIsEggStage() then
        --     table.insert(stageIds, 1, stageIds[1])
        -- end
    end
    return stageIds
end

-- 点击:打开战斗详情
function XUiMultiDimSingleCopy:OpenStageDetails(stageId, themeId)
    local mStage = XMultiDimConfig.GetMultiSingleStageDataById(stageId)
    if not mStage then return end
    self.MStage = mStage
    self.IsOpenDetails = true
    self.BtnCloseDetail.gameObject:SetActiveEx(true)
    self:OpenOneChildUi("UiMultiDimSingleCopyTips", self)
    self:FindChildUiObj("UiMultiDimSingleCopyTips"):SetStageDetail(stageId, themeId)
    self.PanelStageContentRaycast.raycastTarget = false
end

-- 关闭战斗详情
function XUiMultiDimSingleCopy:CloseStageDetails()
    self.IsOpenDetails = false
    self.BtnCloseDetail.gameObject:SetActiveEx(false)

    if XLuaUiManager.IsUiShow("UiMultiDimSingleCopyTips") then
        self:FindChildUiObj("UiMultiDimSingleCopyTips"):CloseDetailWithAnimation()
    end
    self.PanelStageContentRaycast.raycastTarget = true
    self:ClearNodesSelect()
    self:ReopenAssetPanel()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
end

function XUiMultiDimSingleCopy:OnBtnCloseDetailClick()
    self:CloseStageDetails()
end

function XUiMultiDimSingleCopy:OnDragProxy(dragType)
    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

function XUiMultiDimSingleCopy:PlayScrollViewMove(gridTransform)
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

function XUiMultiDimSingleCopy:MoveIntoStage(stageIndex)
    local gridRect = self.StageGroup[stageIndex]
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    local left =  0
    
    if diffX > CS.XResolutionManager.OriginWidth / 2 - left then
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

function XUiMultiDimSingleCopy:EndScrollViewMove()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
    self:ReopenAssetPanel()
end

function XUiMultiDimSingleCopy:ReopenAssetPanel()
    if self.IsOpenDetails then
        return
    end
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(true)
    end
end

-- 背景
function XUiMultiDimSingleCopy:SwitchBg(themeDataCfg)
    if not themeDataCfg or not themeDataCfg.FubenSingleMainBg then
        self.RImgFestivalBg.gameObject:SetActiveEx(false)
        return
    end
    self.RImgFestivalBg:SetRawImage(themeDataCfg.FubenSingleMainBg)
end

-- 加载特效
function XUiMultiDimSingleCopy:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiMultiDimSingleCopy:SetPanelStageListMovementType(moveMentType)
    if not self.PaneStageList then return end
    self.PaneStageList.movementType = moveMentType
end

function XUiMultiDimSingleCopy:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMultiDimSingleCopy:OnBtnBackClick()
    self:Close()
end

function XUiMultiDimSingleCopy:OnDestroy()
    self.IsOpenDetails = nil
    self:StopActivityTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_ON_MULTIDIM_SINGLE_CHANGED, self.RefreshNodes, self)
end