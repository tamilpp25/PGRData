--- 鬼泣联动剧情关，使用了FestivalActivity的配置
---@class XUiDMCFestivalActivityMain: XLuaUi
local XUiDMCFestivalActivityMain = XLuaUiManager.Register(XLuaUi, 'UiDMCFestivalActivityMain')

local XUiGridDMCFestivalActivityStage = require("XUi/XUiDMCFestivalActivity/XUiGridDMCFestivalActivityStage")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")

local STAGE_DETAIL_UINAME = 'UiDMCFestivalActivityStageDetail'
local XUguiDragProxy = CS.XUguiDragProxy

local UiGridDMCFestivalChapterMoveTargetX = nil
local UiGridDMCFestivalChapterMoveMaxX = nil
local UiGridDMCFestivalChapterMoveMinX = nil

--region --------- 生命周期 ---------->>>
function XUiDMCFestivalActivityMain:OnAwake()
    UiGridDMCFestivalChapterMoveTargetX = CS.XGame.ClientConfig:GetFloat('UiGridDMCFestivalChapterMoveTargetX')
    UiGridDMCFestivalChapterMoveMaxX = CS.XGame.ClientConfig:GetInt('UiGridDMCFestivalChapterMoveMaxX')
    UiGridDMCFestivalChapterMoveMinX = CS.XGame.ClientConfig:GetInt('UiGridDMCFestivalChapterMoveMinX')

    self:InitUiView()
    self.LastOpenStage = nil
    self.StageGroup = {}
    XEventManager.AddEventListener(XEventId.EVENT_ON_FESTIVAL_CHANGED, self.RefreshFestivalNodes, self)
end

function XUiDMCFestivalActivityMain:OnStart(chapterId, defaultStageId)
    self.ChapterId = chapterId
    self.Chapter = XDataCenter.FubenFestivalActivityManager.GetFestivalChapterById(chapterId)
    self.ChapterTemplate = XFestivalActivityConfig.GetFestivalById(self.ChapterId)
    self:InitProxy()
    self:SetUiData(self.ChapterTemplate)
    self.NeedReset = false

    if defaultStageId then
        self:OpenDefaultStage(defaultStageId)
    end
    -- 保存点击
    XDataCenter.FubenFestivalActivityManager.SaveFestivalActivityIsOpen(chapterId)
end

function XUiDMCFestivalActivityMain:OnEnable()
    -- 对之前的预制体拼写错误变量做兼容
    self.PanelStageList = self.PanelStageList or self.PaneStageList
    if self.PanelStageList and self.NeedReset then
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        self:ReopenAssetPanel()
    else
        self.NeedReset = true
    end

    if not XDataCenter.MovieManager.IsPlayingMovie() then
        local festivalConfig = XFestivalActivityConfig.GetFestivalById(self.ChapterId)
        if festivalConfig and festivalConfig.ChapterBgm > 0 then
            XLuaAudioManager.PlaySoundDoNotInterrupt(festivalConfig.ChapterBgm)
        end
    end

    if self.LastOpenStage then
        self:MoveIntoStage(self.LastOpenStage)
    end

    if self.RedPointId then
        XRedPointManager.Check(self.RedPointId)
    end

    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
end

function XUiDMCFestivalActivityMain:OnDestroy()
    self.IsOpenDetails = nil
    self:StopActivityTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_ON_FESTIVAL_CHANGED, self.RefreshFestivalNodes, self)
end

--endregion <<<--------------------

--region ---------- 初始化 ---------->>>
function XUiDMCFestivalActivityMain:InitUiView()
    self.SceneBtnBack.CallBack = function() self:OnBtnBackClick() end
    self.SceneBtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnCloseDetail.CallBack = function() self:OnBtnCloseDetailClick() end
end

function XUiDMCFestivalActivityMain:InitProxy()
    self._Proxy = require("XUi/XUiFestivalActivity/XUiFestivalActivityProxyDefault").New()
end

function XUiDMCFestivalActivityMain:SetUiData(chapterTemplate)
    -- 初始化prefab组件
    local chapterGameObject = self.PanelChapter:LoadPrefab(chapterTemplate.FubenPrefab)
    local uiObj = chapterGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    -- 初始化动态生成节点的层级
    XUiHelper.SetCanvasesSortingOrder(self.PanelChapter.transform)

    self.PanelStageList.onValueChanged:AddListener(function(vec2)
        -- 只有打开详情了才执行
        if not self.IsOpenDetails then
            return
        end
        
        if self._ScrollLastPosX == nil then
            self._ScrollLastPosX = vec2.x
        end
        -- 控制触发的滑动距离
        if math.abs(vec2.x - self._ScrollLastPosX) < 0.02 then
            return
        else
            self._ScrollLastPosX = vec2.x
        end
        -- 控制仅在PC滚轮操作下才额外执行取消选择
        if not self._FocusScrollMoving then
            self:CloseStageDetails()
            self._ScrollLastPosX = nil
        end
    end)

    -- 设置顶部控制按钮 返回 和 主界面
    if self.TopControl then
        self.SceneTopControl.gameObject:SetActiveEx(false)
        self.BtnBack.CallBack = function() self:OnBtnBackClick() end
        self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
        self.TopControl.gameObject:SetActiveEx(true)
    else
        self.SceneTopControl.gameObject:SetActiveEx(true)
    end
    self:InitSkipBtn()
    if self.PaneStageList then
        local listCanvas = self.PaneStageList.gameObject:GetComponent(typeof(CS.UnityEngine.Canvas))
        local rootCanvas = self.GameObject:GetComponent(typeof(CS.UnityEngine.Canvas))
        if not XTool.UObjIsNil(listCanvas) and not XTool.UObjIsNil(rootCanvas) then
            listCanvas.sortingOrder = rootCanvas.sortingOrder + listCanvas.sortingOrder
        end
        local dragProxy = self.PaneStageList:GetComponent(typeof(XUguiDragProxy))
        if not dragProxy then
            dragProxy = self.PaneStageList.gameObject:AddComponent(typeof(XUguiDragProxy))
        end
        dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
    end
    self.FestivalStageIds = self:GetFakeStages(chapterTemplate)
    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
    -- 界面信息
    self:SwitchFestivalBg(chapterTemplate)
    -- 加载特效
    self:LoadEffect(chapterTemplate.EffectUrl)
    local now = XTime.GetServerNowTimestamp()
    local startTime, endTimeSecond = XFunctionManager.GetTimeByTimeId(self.Chapter:GetTimeId())
    local isShowTime = endTimeSecond and endTimeSecond ~= 0
    self.TxtTime.gameObject:SetActiveEx(isShowTime)
    if isShowTime then
        self.TxtTime.text = XUiHelper.GetTime(endTimeSecond - now, self._Proxy:GetTimeFormatType())
        self:CreateActivityTimer(now, endTimeSecond)
    end
    self.TxtChapterName.text = self.Chapter:GetName()
    self.TxtChapter.text = (self.ChapterId >= 10) and self.ChapterId or string.format("0%d", self.ChapterId)
    local itemId = XDataCenter.ItemManager.ItemId
    if self.PanelAsset then
        if not self.AssetPanel then
            self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, itemId.FreeGem, itemId.ActionPoint, itemId.Coin)
        end
    end
end

-- 背景
function XUiDMCFestivalActivityMain:SwitchFestivalBg(festivalTemplate)
    if not festivalTemplate or not festivalTemplate.MainBackgound then
        self.RImgFestivalBg.gameObject:SetActiveEx(false)
        return
    end
    self.RImgFestivalBg:SetRawImage(festivalTemplate.MainBackgound)
end

-- 加载特效
function XUiDMCFestivalActivityMain:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiDMCFestivalActivityMain:InitSkipBtn()
    -- todo
end

--endregion <<<----------------------

--region ---------- 事件回调 ---------->>>

function XUiDMCFestivalActivityMain:OnBtnBackClick()
    self:Close()
end

function XUiDMCFestivalActivityMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDMCFestivalActivityMain:OnBtnCloseDetailClick()
    self:CloseStageDetails()
end

function XUiDMCFestivalActivityMain:Close()
    if self.IsOpenDetails then
        self:CloseStageDetails()
    else
        self.Super.Close(self)
    end
end

--endregion <<<----------------------

--region ---------- 界面刷新 ---------->>>


function XUiDMCFestivalActivityMain:HandleStages()
    if self.FestivalStages == nil then
        self.FestivalStages = {}
    end
    
    for i = 1, #self.FestivalStageIds do
        local grid = self.FestivalStages[i]

        if not grid then
            local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
            if not itemStage then
                XLog.Error("XUiDMCFestivalActivityMain:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
                break
            end
            -- 组件初始化
            self.StageGroup[i] = itemStage
            self.FestivalStages[i] = XUiGridDMCFestivalActivityStage.New(itemStage, self)
            grid = self.FestivalStages[i]
        end
        
        grid:Open()
        grid:UpdateNode(self.Chapter:GetChapterId(), self.FestivalStageIds[i])
    end
    self:UpdateNodeLines()
    -- 隐藏多余组件
    local indexStage = #self.FestivalStageIds + 1
    local extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    while extraStage do
        if self.FestivalStages[indexStage] then
            self.FestivalStages[indexStage]:Close()
        else
            extraStage.gameObject:SetActiveEx(false)
            indexStage = indexStage + 1
        end

        extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    end
end

function XUiDMCFestivalActivityMain:HandleStageLines()
    self.FestivalStageLine = {}
    for i = 1, #self.FestivalStageIds - 1 do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiDMCFestivalActivityMain:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            break
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

-- 更新刷新
function XUiDMCFestivalActivityMain:RefreshFestivalNodes()
    if not self.Chapter or not self.FestivalStageIds then return end
    for i = 1, #self.FestivalStageIds do
        self.FestivalStages[i]:UpdateNode(self.Chapter:GetChapterId(), self.FestivalStageIds[i])
    end
    self:UpdateNodeLines()
    -- 移动至ListView正确的位置
    if self.PanelStageContentSizeFitter then
        self.PanelStageContentSizeFitter:SetLayoutHorizontal()
    end
end

-- 更新节点线条
function XUiDMCFestivalActivityMain:UpdateNodeLines()
    if not self.Chapter or not self.FestivalStageIds then return end
    local stageLength = #self.FestivalStageIds
    for i = 2, stageLength do
        local isOpen = self.Chapter:GetStageByStageId(self.FestivalStageIds[i]):GetIsShow()
        self:SetStageLineActive(i - 1, isOpen)
        if isOpen then
            self.LastOpenStage = i
        end
    end
    self:SetStageLineActive(stageLength, false)
end

function XUiDMCFestivalActivityMain:SetStageLineActive(index, isActive)
    if self.FestivalStageLine[index] then
        self.FestivalStageLine[index].gameObject:SetActiveEx(isActive)
    end
end
--endregion <<<-----------------------

function XUiDMCFestivalActivityMain:OpenDefaultStage(stageId)
    if self.FestivalStageIds and self.FestivalStages then
        for i = 2, #self.FestivalStageIds do
            if self.FestivalStageIds[i] == stageId and self.FestivalStages[i] then
                self.FestivalStages[i]:OnBtnStageClick()
                break
            end
        end
    end
end

-- 选中关卡
function XUiDMCFestivalActivityMain:UpdateNodesSelect(stageId)
    local stageIds = self.FestivalStageIds
    for i = 1, #stageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
function XUiDMCFestivalActivityMain:ClearNodesSelect()
    for i = 1, #self.FestivalStageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

function XUiDMCFestivalActivityMain:GetFakeStages()
    local stageIds = {}
    local stageIdList = self.Chapter:GetStageIdList()
    for i = 1, #stageIdList do
        stageIds[i] = stageIdList[i]
    end
    
    return stageIds
end

-- 打开剧情，战斗详情
function XUiDMCFestivalActivityMain:OpenStageDetails(stageId, festivalId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then return end
    self.FStage = fStage
    self.IsOpenDetails = true
    self.BtnCloseDetail.gameObject:SetActiveEx(true)
    
    self:OpenOneChildUi(STAGE_DETAIL_UINAME, self)
    self:FindChildUiObj(STAGE_DETAIL_UINAME):SetStageDetail(stageId, festivalId)
    
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(false)
    end
    self.PanelStageContentRaycast.raycastTarget = false
end

-- 关闭剧情，战斗详情
function XUiDMCFestivalActivityMain:CloseStageDetails()
    self.IsOpenDetails = false
    self.BtnCloseDetail.gameObject:SetActiveEx(false)

    if XLuaUiManager.IsUiShow(STAGE_DETAIL_UINAME) then
        self:FindChildUiObj(STAGE_DETAIL_UINAME):CloseDetailWithAnimation()
    end
    
    self.PanelStageContentRaycast.raycastTarget = true
    self:ClearNodesSelect()
    self:ReopenAssetPanel()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
end


--region ---------- 关卡滑动 ---------->>>
function XUiDMCFestivalActivityMain:OnDragProxy(dragType)
    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

function XUiDMCFestivalActivityMain:PlayScrollViewMove(gridTransform)
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
    local gridRect = gridTransform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < UiGridDMCFestivalChapterMoveMinX or diffX > UiGridDMCFestivalChapterMoveMaxX then
        local left =  self._Proxy:GetScrollOffsetX(self)
        local tarPosX = UiGridDMCFestivalChapterMoveTargetX - gridRect.localPosition.x - left / 2
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        self._FocusScrollMoving = true
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
            self._FocusScrollMoving = false
        end)
    end
end

function XUiDMCFestivalActivityMain:MoveIntoStage(stageIndex)
    local gridRect = self.StageGroup[stageIndex]
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    local left =  self._Proxy:GetScrollOffsetX(self)

    if diffX > CS.XResolutionManager.OriginWidth / 2 - left then
        local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x - left
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
        self._FocusScrollMoving = true
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
            self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
            self._FocusScrollMoving = false
        end)
    end
end

function XUiDMCFestivalActivityMain:EndScrollViewMove()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
    self:ReopenAssetPanel()
end

function XUiDMCFestivalActivityMain:SetPanelStageListMovementType(moveMentType)
    if not self.PanelStageList then return end
    self.PanelStageList.movementType = moveMentType
end

--endregion <<<-----------------------

function XUiDMCFestivalActivityMain:ReopenAssetPanel()
    if self.IsOpenDetails then
        return
    end
    if self.AssetPanel and self.AssetPanel.GameObject and self.AssetPanel.GameObject:Exist() then
        self.AssetPanel.GameObject:SetActiveEx(true)
    end
end

--region 定时器 - 踢出检查
function XUiDMCFestivalActivityMain:CreateActivityTimer(startTime, endTime)
    local time = XTime.GetServerNowTimestamp()
    self:StopActivityTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
        time = XTime.GetServerNowTimestamp()
        if time > endTime then
            self:Close()
            XUiManager.TipError(CS.XTextManager.GetText("ActivityMainLineEnd"))
            self:StopActivityTimer()
            return
        end
        self.TxtTime.text = XUiHelper.GetTime(endTime - time, self._Proxy:GetTimeFormatType())
    end, XScheduleManager.SECOND, 0)
end

function XUiDMCFestivalActivityMain:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end
--endregion

return XUiDMCFestivalActivityMain