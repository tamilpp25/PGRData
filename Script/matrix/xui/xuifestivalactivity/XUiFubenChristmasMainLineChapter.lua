local XUiFubenChristmasMainLineChapter = XLuaUiManager.Register(XLuaUi, "UiFubenChristmasMainLineChapter")
local FESTIVAL_FIGHT_DETAIL = "UiFubenChristmasStageDetail"
local FESTIVAL_STORY_DETAIL = "UiStoryChristmasStageDetail"
local XUguiDragProxy = CS.XUguiDragProxy

function XUiFubenChristmasMainLineChapter:Ctor()
    ---@type XUiFestivalActivityProxyDefault
    self._Proxy = false
end

-- 副本小游戏按钮红点条件
local SkipBtnRedPointCondition = {
    [9] = { XRedPointConditions.Types.CONDITION_FUBEN_CLICKCLEARGAME_RED },
    [11] = { XRedPointConditions.Types.CONDITION_FUBEN_DRAGPUZZLEGAME_RED },
    [12] = { XRedPointConditions.Types.CONDITION_FUBEN_DRAGPUZZLEGAME_RED },
    [13] = { XRedPointConditions.Types.CONDITION_CHRISTMAS_TREE },
}

function XUiFubenChristmasMainLineChapter:OnAwake()
    self:InitUiView()
    self.LastOpenStage = nil
    self.StageGroup = {}
    XEventManager.AddEventListener(XEventId.EVENT_ON_FESTIVAL_CHANGED, self.RefreshFestivalNodes, self)
end

function XUiFubenChristmasMainLineChapter:OnEnable()
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
            -- CS.XAudioManager.PlayMusic(festivalConfig.ChapterBgm)
            XSoundManager.PlaySoundDoNotInterrupt(festivalConfig.ChapterBgm)
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
    -- 彩蛋处理
    self:HandleEggStage()
end

function XUiFubenChristmasMainLineChapter:OnDestroy()
    self.IsOpenDetails = nil
    self:StopActivityTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_ON_FESTIVAL_CHANGED, self.RefreshFestivalNodes, self)
end

function XUiFubenChristmasMainLineChapter:InitUiView()
    self.SceneBtnBack.CallBack = function() self:OnBtnBackClick() end
    self.SceneBtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnCloseDetail.CallBack = function() self:OnBtnCloseDetailClick() end
end

function XUiFubenChristmasMainLineChapter:OnBtnBackClick()    
    self:Close()
end

function XUiFubenChristmasMainLineChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenChristmasMainLineChapter:OnStart(chapterId, defaultStageId)
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

function XUiFubenChristmasMainLineChapter:InitProxy()
    if self.ChapterTemplate.Id == XFestivalActivityConfig.ActivityId.NewYearFuben then
        self._Proxy = require("XUi/XUiFestivalActivity/XUiFestivalActivityProxyNewYearFuben").New()
        return
    end
    self._Proxy = require("XUi/XUiFestivalActivity/XUiFestivalActivityProxyDefault").New()
end

function XUiFubenChristmasMainLineChapter:OpenDefaultStage(stageId)
    if self.FestivalStageIds and self.FestivalStages then
        for i = 2, #self.FestivalStageIds do
            if self.FestivalStageIds[i] == stageId and self.FestivalStages[i] then
                self.FestivalStages[i]:OnBtnStageClick()
                break
            end
        end
    end
end

function XUiFubenChristmasMainLineChapter:SetUiData(chapterTemplate)
    -- 初始化prefab组件
    local chapterGameObject = self.PanelChapter:LoadPrefab(chapterTemplate.FubenPrefab)
    local uiObj = chapterGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
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
    -- 彩蛋处理
    self:HandleEggStage()
    -- 界面信息
    self:SwitchFestivalBg(chapterTemplate)
    -- 加载特效
    self:LoadEffect(chapterTemplate.EffectUrl)
    local now = XTime.GetServerNowTimestamp()
    local startTime, endTimeSecond = XFunctionManager.GetTimeByTimeId(self.Chapter:GetTimeId())
    local isShowTime = endTimeSecond and endTimeSecond ~= 0
    self.TxtDay.gameObject:SetActiveEx(isShowTime)
    if isShowTime then
        self.TxtDay.text = XUiHelper.GetTime(endTimeSecond - now, self._Proxy:GetTimeFormatType())
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

function XUiFubenChristmasMainLineChapter:HandleStages()
    self.FestivalStages = {}
    for i = 1, #self.FestivalStageIds do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiFubenChristmasMainLineChapter:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        itemStage.gameObject:SetActiveEx(true)
        self.StageGroup[i] = itemStage
        self.FestivalStages[i] = XUiFestivalStageItem.New(self, itemStage)
        self.FestivalStages[i]:UpdateNode(self.Chapter:GetChapterId(), self.FestivalStageIds[i])
    end
    self:UpdateNodeLines()
    -- 隐藏多余组件
    local indexStage = #self.FestivalStageIds + 1
    local extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    while extraStage do
        extraStage.gameObject:SetActiveEx(false)
        indexStage = indexStage + 1
        extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    end
end

function XUiFubenChristmasMainLineChapter:HandleStageLines()
    self.FestivalStageLine = {}
    for i = 1, #self.FestivalStageIds - 1 do
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

-- 更新刷新
function XUiFubenChristmasMainLineChapter:RefreshFestivalNodes()
    if not self.Chapter or not self.FestivalStageIds then return end
        for i = 1, #self.FestivalStageIds do
        self.FestivalStages[i]:UpdateNode(self.Chapter:GetChapterId(), self.FestivalStageIds[i])
    end
    self:UpdateNodeLines()
    self:HandleEggStage()
    -- 移动至ListView正确的位置
    if self.PanelStageContentSizeFitter then
        self.PanelStageContentSizeFitter:SetLayoutHorizontal()
    end
end

-- 更新节点线条
function XUiFubenChristmasMainLineChapter:UpdateNodeLines()
    if not self.Chapter or not self.FestivalStageIds then return end
    local stageLength = #self.FestivalStageIds
    for i = 2, stageLength do
        local isOpen = self.Chapter:GetStageByStageId(self.FestivalStageIds[i]):GetIsOpen()
        self:SetStageLineActive(i - 1, isOpen)
        if isOpen then
            self.LastOpenStage = i
        end
    end
    self:SetStageLineActive(1, false)
    self:SetStageLineActive(stageLength, false)
end

function XUiFubenChristmasMainLineChapter:SetStageLineActive(index, isActive)
    if self.FestivalStageLine[index] then
        self.FestivalStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

function XUiFubenChristmasMainLineChapter:HandleEggStage()
    local eggStageIndex = 1
    local eggStageId = self.FestivalStageIds[eggStageIndex]
    local eggStage = self.Chapter:GetStageByOrderIndex(eggStageIndex)
    if eggStage and eggStage:GetIsEggStage() then
        -- 彩蛋处理
        local isUnlock = eggStage:GetIsOpen()
        self.FestivalStages[eggStageIndex].GameObject:SetActiveEx(isUnlock)
        if isUnlock then
            local preStageIds = eggStage:GetPreStageId()
            if preStageIds and preStageIds[1] then
                for i = 1, #self.FestivalStageIds do
                    if preStageIds[1] == self.FestivalStageIds[i] then
                        self.FestivalStages[eggStageIndex]:ResetItemPosition(self.FestivalStages[i].Transform.localPosition)
                        break
                    end
                end
            end
        end
    else
        -- 非彩蛋
        self.FestivalStages[eggStageIndex].GameObject:SetActiveEx(false)
    end
    self.FestivalStageLine[eggStageIndex].gameObject:SetActiveEx(false)
end

-- 选中关卡
function XUiFubenChristmasMainLineChapter:UpdateNodesSelect(stageId)
    local stageIds = self.FestivalStageIds
    for i = 1, #stageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
function XUiFubenChristmasMainLineChapter:ClearNodesSelect()
    for i = 1, #self.FestivalStageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

-- 没有彩蛋则增加一个假彩蛋
function XUiFubenChristmasMainLineChapter:GetFakeStages()
    local stageIds = {}
    local stageIdList = self.Chapter:GetStageIdList()
    for i = 1, #stageIdList do
        stageIds[i] = stageIdList[i]
    end
    local firstStage = self.Chapter:GetStageByOrderIndex(1)
    if not firstStage:GetIsEggStage() then
        table.insert(stageIds, 1, stageIds[1])
    end
    return stageIds
end

-- 打开剧情，战斗详情
function XUiFubenChristmasMainLineChapter:OpenStageDetails(stageId, festivalId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then return end
    self.FStage = fStage
    self.IsOpenDetails = true
    self.BtnCloseDetail.gameObject:SetActiveEx(true)
    local detailType = self.FStage:GetStageShowType()
    if detailType == XDataCenter.FubenFestivalActivityManager.StageFuben then
        self:OpenOneChildUi(FESTIVAL_FIGHT_DETAIL, self)
        self:FindChildUiObj(FESTIVAL_FIGHT_DETAIL):SetStageDetail(stageId, festivalId)
        if XLuaUiManager.IsUiShow(FESTIVAL_STORY_DETAIL) then
            self:FindChildUiObj(FESTIVAL_STORY_DETAIL):Close()
        end
    end
    if detailType == XDataCenter.FubenFestivalActivityManager.StageStory then
        self:OpenOneChildUi(FESTIVAL_STORY_DETAIL, self)
        self:FindChildUiObj(FESTIVAL_STORY_DETAIL):SetStageDetail(stageId, festivalId)
        if XLuaUiManager.IsUiShow(FESTIVAL_FIGHT_DETAIL) then
            self:FindChildUiObj(FESTIVAL_FIGHT_DETAIL):Close()
        end
    end
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(false)
    end
    self.PanelStageContentRaycast.raycastTarget = false
end

-- 关闭剧情，战斗详情
function XUiFubenChristmasMainLineChapter:CloseStageDetails()
    self.IsOpenDetails = false
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    if XLuaUiManager.IsUiShow(FESTIVAL_STORY_DETAIL) then
        self:FindChildUiObj(FESTIVAL_STORY_DETAIL):CloseDetailWithAnimation()
    end

    if XLuaUiManager.IsUiShow(FESTIVAL_FIGHT_DETAIL) then
        self:FindChildUiObj(FESTIVAL_FIGHT_DETAIL):CloseDetailWithAnimation()
    end
    self.PanelStageContentRaycast.raycastTarget = true
    self:ClearNodesSelect()
    self:ReopenAssetPanel()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
end

function XUiFubenChristmasMainLineChapter:OnBtnCloseDetailClick()
    self:CloseStageDetails()
end

function XUiFubenChristmasMainLineChapter:OnDragProxy(dragType)
    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

function XUiFubenChristmasMainLineChapter:PlayScrollViewMove(gridTransform)
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
    local gridRect = gridTransform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local left =  self._Proxy:GetScrollOffsetX(self)
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x - left / 2
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiFubenChristmasMainLineChapter:MoveIntoStage(stageIndex)
    local gridRect = self.StageGroup[stageIndex]
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    local left =  self._Proxy:GetScrollOffsetX(self)
    
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

function XUiFubenChristmasMainLineChapter:EndScrollViewMove()
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
    self:ReopenAssetPanel()
end

function XUiFubenChristmasMainLineChapter:ReopenAssetPanel()
    if self.IsOpenDetails then
        return
    end
    if self.AssetPanel and self.AssetPanel.GameObject and self.AssetPanel.GameObject:Exist() then
        self.AssetPanel.GameObject:SetActiveEx(true)
    end
end

-- 背景
function XUiFubenChristmasMainLineChapter:SwitchFestivalBg(festivalTemplate)
    if not festivalTemplate or not festivalTemplate.MainBackgound then
        self.RImgFestivalBg.gameObject:SetActiveEx(false)
        return
    end
    self.RImgFestivalBg:SetRawImage(festivalTemplate.MainBackgound)
end

-- 加载特效
function XUiFubenChristmasMainLineChapter:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

-- 计时器
function XUiFubenChristmasMainLineChapter:CreateActivityTimer(startTime, endTime)
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
            self.TxtDay.text = XUiHelper.GetTime(endTime - time, self._Proxy:GetTimeFormatType())
        end, XScheduleManager.SECOND, 0)
end

function XUiFubenChristmasMainLineChapter:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiFubenChristmasMainLineChapter:SetPanelStageListMovementType(moveMentType)
    if not self.PanelStageList then return end
    self.PanelStageList.movementType = moveMentType
end

function XUiFubenChristmasMainLineChapter:InitSkipBtn()
    local skipIds = self.Chapter:GetSkipId()
    if self.Chapter:GetChapterId() == XFestivalActivityConfig.ActivityId.WhiteValentine then
        if self.BtnGo and XTool.IsNumberValid(skipIds[1]) then
            self.BtnGo.CallBack = function()
                XFunctionManager.SkipInterface(skipIds[1])
            end
        end
        if self.BtnObtain and XTool.IsNumberValid(skipIds[2]) then
            self.BtnObtain.CallBack = function()
                XFunctionManager.SkipInterface(skipIds[2])
            end
        end
    else
        local skipId = skipIds[1]
        if self.BtnSkip and skipId ~= 0 then
            self.BtnSkip.CallBack = function()
                XFunctionManager.SkipInterface(skipId)
            end
            if SkipBtnRedPointCondition[self.Chapter:GetChapterId()] then
                self.RedPointId = XRedPointManager.AddRedPointEvent(self.BtnSkip, self.OnCheckBtnGameRedPoint, self, SkipBtnRedPointCondition[self.Chapter:GetChapterId()], nil, false)
            end
        end
        local skipId2 = skipIds[2]
        if self.BtnSkip2 and XTool.IsNumberValid(skipId2) then
            self.BtnSkip2.CallBack = function()
                XFunctionManager.SkipInterface(skipId2)
            end
            if SkipBtnRedPointCondition[self.Chapter:GetChapterId()] then
                self.RedPointId = XRedPointManager.AddRedPointEvent(self.BtnSkip2, self.OnCheckBtnSkip2RedPoint, self, SkipBtnRedPointCondition[self.Chapter:GetChapterId()], nil, false)
            end
        end
    end
end

function XUiFubenChristmasMainLineChapter:OnCheckBtnGameRedPoint(count)
    self.BtnSkip:ShowReddot(count>=0)
end

function XUiFubenChristmasMainLineChapter:OnCheckBtnSkip2RedPoint(count)
    self.BtnSkip2:ShowReddot(count>=0)
end