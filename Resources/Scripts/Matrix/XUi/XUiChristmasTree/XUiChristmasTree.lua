local XUiChristmasTree = XLuaUiManager.Register(XLuaUi, "UiChristmasTreeMain")

local AttrCount = 0
local LocalStateCount = 0
-- 全局的index设定为局部状态总数+1
local OverallIndex = LocalStateCount + 1
-- 触发拖拽前的延时
local LongClickOffset = 200
-- 计算最近挂点的范围
local MaxDistance = 0.3
local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiChristmasTree:OnAwake()
    self:AddListener()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelGiftList.gameObject)
    self.DynamicTable:SetProxy(XUiOrnamentGrid)
    self.DynamicTable:SetDelegate(self)
    self.Camera = CS.XUiManager.Instance.UiCamera
    self.RectTransform = self.Transform:GetComponent("RectTransform")
end

function XUiChristmasTree:OnEnable()
end

function XUiChristmasTree:OnStart(actId)
    self.ActTemplate = XDataCenter.ChristmasTreeManager.Reset(actId)
    self.ActId = actId

    self.GridTreasureList = {}      -- 任务格子
    self.BtnFilterList = {}         -- 筛选排序页签
    self.AttrViewList = {}          -- 首页评分
    self.BtnChangeList = {}         -- 编辑模式普通状态切换按钮
    self.AttrViewEditList = {}      -- 编辑模式评分
    self.BtnChangeEditList = {}     -- 编辑模式预览状态切换按钮
    self.TreePartList = {}          -- 预制体上的各个挂点  
    self.PlacePoint = {}            -- XUiPlacedOrnamentGrid
    self.CurrentGroup = 0           -- 当前的状态index
    self.LongClick = {}

    self.AutoLayout = self.Transform:Find("SafeAreaContentPane/PanelView/PanelScore/panelScoreDetail")
    
    OverallIndex, LocalStateCount = XChristmasTreeConfig.GetTreePartCount()
    OverallIndex = LocalStateCount + 1
    AttrCount = #self.ActTemplate.AttrName
    MaxDistance = self.ActTemplate.MaxDistance or MaxDistance
    LongClickOffset = self.ActTemplate.LongClickOffset or LongClickOffset
    self:InitUiView()
    self.PanelDress.gameObject:SetActiveEx(false)
    self.PanelView.gameObject:SetActiveEx(true)
    self.InDressMode = false
    self:SwitchView(OverallIndex)
    self:UpdateTaskProgress()
    self:UpdateOrnamentRedPoint()
    self:CheckFirstOpen()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.AutoLayout)
end

function XUiChristmasTree:OnDestroy()
    self.IsOpenDetails = nil
    self:StopActivityTimer()
end

function XUiChristmasTree:CheckFirstOpen()
    local firstOpen, openIndex, storyId = XDataCenter.ChristmasTreeManager.CheckFirstOpen()
    if firstOpen then
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            XDataCenter.ChristmasTreeManager.SetOpen(openIndex)
            -- XSoundManager.PauseMusic()
        end)
    end
end

function XUiChristmasTree:InitUiView()
    local now = XTime.GetServerNowTimestamp()
    local _, endTimeSecond = XFunctionManager.GetTimeByTimeId(self.ActTemplate.TimeId)
    if endTimeSecond then
        self.TxtDay.text = XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.ACTIVITY)
        self:CreateActivityTimer(now, endTimeSecond)
    end
    self.TxtTitle.text = self.ActTemplate.Name

    for i, name in ipairs(self.ActTemplate.AttrName) do
        local scoreDetail = self.PanelScore:Find("panelScoreDetail/Score".. i)
        self.AttrViewList[i] = scoreDetail
        scoreDetail:Find("TxtTitle"):GetComponent("Text").text = name

        scoreDetail = self.PanelScoreEdit:Find("panelScoreDetail/Score".. i)
        self.AttrViewEditList[i] = scoreDetail
        scoreDetail:Find("TxtTitle"):GetComponent("Text").text = name

        local btnFilter = self.PanelFilter.transform:Find("BtnAttr".. i):GetComponent("XUiButton")
        self.BtnFilterList[i] = btnFilter
        btnFilter:SetNameByGroup(0, name)
    end
    self.AttrViewList[#self.AttrViewList + 1] = self.PanelScore:Find("ScoreTotal")
    self.AttrViewEditList[#self.AttrViewEditList + 1] = self.PanelScoreEdit:Find("ScoreTotal")
    self.BtnFilterList[#self.BtnFilterList + 1] = self.PanelFilter.transform:Find("BtnDefault"):GetComponent("XUiButton")
    for i = 1, LocalStateCount do
        local btnChange = self.PanelChangeOver.transform:Find("BtnChange".. i):GetComponent("XUiButton")
        self.BtnChangeList[i] = btnChange
        btnChange = self.PanelChangeOverEdit.transform:Find("BtnChange".. i):GetComponent("XUiButton")
        self.BtnChangeEditList[i] = btnChange
    end

    self.PanelChangeOver:Init(self.BtnChangeList, function(index)
        self:SwitchView(index)
        self.PanelChangeOverEdit:SelectIndex(index, false)
    end, -1)
    self.PanelChangeOverEdit:Init(self.BtnChangeEditList, function(index) self:SwitchView(index) end, -1)
    -- 默认页签的index设为属性总数+1
    self.PanelFilter:Init(self.BtnFilterList, function(index) self:OnBtnFilter(index) end, AttrCount + 1 )
    self.PanelTreasure.gameObject:SetActiveEx(false)
end

function XUiChristmasTree:AddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
    self.BtnDress.CallBack = function() self:OnBtnDressClick() end
    self.BtnSave.CallBack = function() self:OnBtnSaveClick() end
    self.BtnPreview.CallBack = function() self:SwitchView() end
    self.BtnActiveOrnament.CallBack = function() self:OnBtnActiveOrnament() end
    self.BtnClear.CallBack = function() self:OnBtnClear() end
    self.BtnSubItem.CallBack = function() self:OnBtnSubItem() end
    
    self:RegisterClickEvent(self.BtnTreasureBg, self.OnBtnTreasureBgClick)
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    
    self.RedPointActive = XRedPointManager.AddRedPointEvent(self.BtnActiveOrnament, self.OnCheckActive, self, { XRedPointConditions.Types.CONDITION_CHRISTMAS_TREE_ORNAMENT_ACTIVE }, nil, true)
    self.RedPointReward = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_CHRISTMAS_TREE_AWARD }, nil, true)
    self.RedPointUnread = XRedPointManager.AddRedPointEvent(self.BtnDress, self.OnCheckUnread, self, { XRedPointConditions.Types.CONDITION_CHRISTMAS_TREE_ORNAMENT_READ }, nil, true)
end

-- 是否显示红点
function XUiChristmasTree:OnCheckActive(count)
    self.BtnActiveOrnament:ShowReddot(count >= 0)
end

function XUiChristmasTree:OnCheckRewards(count)
    self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
end

function XUiChristmasTree:OnCheckUnread(count)
    self.BtnDress:ShowReddot(count >= 0)
    self:UpdateOrnamentRedPoint()
end

function XUiChristmasTree:UpdateOrnamentRedPoint()
    if not self.DynamicTable then return end
    self.DynamicTable:ReloadDataASync()
    for i = 1, LocalStateCount do
        local isUnread = XDataCenter.ChristmasTreeManager.CheckOrnamentGrpUnread(i)
        self.BtnChangeList[i]:ShowReddot(isUnread)
        self.BtnChangeEditList[i]:ShowReddot(isUnread)
    end
end

function XUiChristmasTree:OnBtnBackClick()
    if self.InDressMode then
        self:OnBtnQuitDressClick()
    else
        self:Close()
    end
end

function XUiChristmasTree:OnBtnMainUiClick()
    if XDataCenter.ChristmasTreeManager.CheckChange() then
        local title = CSXTextManagerGetText("TipTitle")
        local content = CSXTextManagerGetText("ChristmasTreeRestoreHint")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal,nil, XLuaUiManager.RunMain)
        return
    end
    XLuaUiManager.RunMain()
end

-- 搬运function XUiManager.ShowHelpTip(helpDataKey, cb)接口
function XUiChristmasTree:OnBtnHelpClick()
    local config = XHelpCourseConfig.GetHelpCourseTemplateByFunction("ChristmasTree")
    if not config then
        return
    end

    if config.IsShowCourse == 1 then
        XLuaUiManager.Open("UiHelp", config, nil)
    else
        XUiManager.UiFubenDialogTip(config.Name, config.Describe)
    end
end

function XUiChristmasTree:OnBtnTreasureClick()
    self:InitTreasureGrade()
    self.PanelTreasure.gameObject:SetActiveEx(true)
    self:PlayAnimation("TreasureEnable")
end

function XUiChristmasTree:OnBtnTreasureBgClick()
    self:PlayAnimation("TreasureDisable", function()
        self.PanelTreasure.gameObject:SetActiveEx(false)
        self:UpdateTaskProgress()
    end)
end

function XUiChristmasTree:OnBtnQuitDressClick()
    if XDataCenter.ChristmasTreeManager.CheckChange() then
        local title = CSXTextManagerGetText("TipTitle")
        local content = CSXTextManagerGetText("ChristmasTreeRestoreHint")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal,nil, function() self:QuitDressMode() end)
    else
        self:QuitDressMode()
    end
end

function XUiChristmasTree:QuitDressMode()
    XDataCenter.ChristmasTreeManager.ResetChange()
    self.PanelView.gameObject:SetActiveEx(true)
    self:PlayAnimation("QieHuan2", function ()
        self.PanelDress.gameObject:SetActiveEx(false)
    end)
    self.InDressMode = false
    self:SwitchView(OverallIndex)
    self:UpdateTaskProgress()
end

function XUiChristmasTree:OnBtnDressClick()
    self.PanelDress.gameObject:SetActiveEx(true)
    self:PlayAnimation("QieHuan1", function ()
        self.PanelView.gameObject:SetActiveEx(false)
    end)
    self.InDressMode = true
    self.PanelChangeOverEdit:SelectIndex(1)
    self.PanelFilter:SelectIndex(AttrCount + 1)
end

function XUiChristmasTree:OnBtnSaveClick()
    XDataCenter.ChristmasTreeManager.SubmitChange(function()
        XUiManager.TipText("ChristmasTreeSaveAppearanceSuccess")
        self:OnBtnQuitDressClick()
    end)
end

function XUiChristmasTree:UnselectAllItem(exceptIndex)
    for index in pairs(self.TreePartList) do
        local item = self.PlacePoint[index]
        if exceptIndex then
            item:SetSelect(item.Index == exceptIndex and self.CurrentGroup ~= OverallIndex)
        else
            item:SetSelect(false)
            item:SetLight(self.CurrentGroup ~= OverallIndex)
        end
    end
    
    if exceptIndex then
        self.CurSelectGridIndex = exceptIndex
    else
        self.BtnRemove.gameObject:SetActiveEx(false)
    end
    
    if self.CloseBg then
        self.CloseBg.raycastTarget = false
    end
end

function XUiChristmasTree:OnBtnRemove()
    XDataCenter.ChristmasTreeManager.RemoveOrnament(self.CurSelectGridIndex)
    self:RefreshView()
end

function XUiChristmasTree:OnBtnFilter(index)
    self.CurrentFilterIndex = index or self.LastFilterIndex
    self.SRComponent.enabled = true
    if self.InDressMode and self.CurrentGroup == OverallIndex then
        self.GiftList = XDataCenter.ChristmasTreeManager.GetAvailableOrnaments(self.LastGroup, self.CurrentFilterIndex) or {}
    else
        self.GiftList = XDataCenter.ChristmasTreeManager.GetAvailableOrnaments(self.CurrentGroup, self.CurrentFilterIndex)
    end

    if self.LastGroup ~= self.CurrentGroup then
        self:PlayAnimation("PanelGiftListEnable")
    elseif self.LastFilterIndex ~= self.CurrentFilterIndex then
        self:PlayAnimation("PanelGiftListEnable")
    end
    
    self.DynamicTable:SetDataSource(self.GiftList)
    self.DynamicTable:ReloadDataSync()

    self.SRComponent.enabled = false
    self.LastFilterIndex = self.CurrentFilterIndex
end

function XUiChristmasTree:OnBtnClear()
    if XDataCenter.ChristmasTreeManager.CheckPartGrpEmpty(self.CurrentGroup) then return end
    local title = CSXTextManagerGetText("TipTitle")
    local content = CSXTextManagerGetText("ChristmasTreeRemoveOrnamentHint")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal,nil, function ()
        XDataCenter.ChristmasTreeManager.RemoveOrnamentGrp(self.CurrentGroup)
        self:RefreshView()
    end)
end

function XUiChristmasTree:OnBtnActiveOrnament()
    local result, minItemId, minItemCount = XDataCenter.ChristmasTreeManager.CheckCanGetOrnament()
    if not result then
        if minItemCount > 0 then
            XUiManager.TipMsg(CSXTextManagerGetText("ChristmasTreeSubItemInsufficientQuantity", XDataCenter.ItemManager.GetItemName(minItemId)))
        else
            XUiManager.TipMsg(CSXTextManagerGetText("ChristmasTreeOrnamentFull"))
        end
    else
        XDataCenter.ChristmasTreeManager.ActiveOrnament(0, function ()
            self:RefreshView()
            if self.InDressMode then
                self:OnBtnFilter()
            end
        end)
    end
end

function XUiChristmasTree:OnBtnSubItem()
    local _, id = XDataCenter.ChristmasTreeManager.CheckCanGetOrnament()
    XLuaUiManager.Open("UiTip", id)
end

function XUiChristmasTree:OnCancelRemoveBtn()
    self:UnselectAllItem()
    self.CurSelectGridIndex = nil
end

-- 更新左下角的奖励按钮的状态
function XUiChristmasTree:UpdateTaskProgress()
    -- self.TxtDesc.gameObject:SetActiveEx(false)
    self.ImgStarIcon.gameObject:SetActiveEx(false)
    local curStars, totalStars = XDataCenter.ChristmasTreeManager.GetTaskProgress()
    local received = XDataCenter.ChristmasTreeManager.CheckTaskAllFinish()

    XRedPointManager.Check(self.RedPointReward)

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)
    self.TxtStarNum.text = CSXTextManagerGetText("Fract", curStars, totalStars)
    self.ImgLingqu.gameObject:SetActiveEx(received)
end

function XUiChristmasTree:InitTreasureGrade()
    self.GridTreasureGrade.gameObject:SetActiveEx(false)
    -- 先把所有的格子隐藏
    for j = 1, #self.GridTreasureList do
        self.GridTreasureList[j].GameObject:SetActiveEx(false)
    end

    local targetList = self.ActTemplate.TaskId
    if not targetList then
        return
    end

    local offsetValue = 260
    local gridCount = #targetList

    for i = 1, gridCount do
        local offerY = (1 - i) * offsetValue
        local grid = self.GridTreasureList[i]

        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(self.GridTreasureGrade)  -- 复制一个item
            grid = XUiGridTreasureTask.New(self, item)
            grid.Transform:SetParent(self.PanelGradeContent, false)
            grid.Transform.localPosition = CS.UnityEngine.Vector3(item.transform.localPosition.x, item.transform.localPosition.y + offerY, item.transform.localPosition.z)
            self.GridTreasureList[i] = grid
        end

        grid:UpdateGradeGridTask(targetList[i])

        grid:InitTreasureList()
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiChristmasTree:SwitchView(nextView)
    --XLog.Warning("last", self.LastGroup, self.CurrentGroup )
    local lastGroup = self.CurrentGroup or 0
    if nextView then
        self.CurrentGroup = nextView
    elseif self.CurrentGroup == OverallIndex then
        self.PanelChangeOver:SelectIndex(self.LastGroup, false)
        self.CurrentGroup = self.LastGroup
    else
        self.CurrentGroup = OverallIndex
    end
    self:RefreshView(lastGroup)
end

function XUiChristmasTree:RefreshView(lastGroup)
    local AttrValue = XDataCenter.ChristmasTreeManager.GetAttrValue()
    local AttrDelta = XDataCenter.ChristmasTreeManager.GetAttrDeltaValue()
    for i, attrScore in ipairs(self.InDressMode and self.AttrViewEditList or self.AttrViewList) do
        local txtScore = attrScore:Find("TxtScore"):GetComponent("Text")
        txtScore.text = AttrValue[i]
        -- 仅显示子属性差值
        if i < #self.AttrViewList then
            local txtDelta = attrScore:Find("TxtScorePlus"):GetComponent("Text")
            local value = AttrDelta[i]
            if value > 0 then
                txtDelta.text = CSXTextManagerGetText("ChristmasTreeAttrDeltaPlus", value)
            elseif value < 0 then
                txtDelta.text = CSXTextManagerGetText("ChristmasTreeAttrDeltaMinus", value)
            else
                txtDelta.text  = ""
            end
        end
    end
    
    if self.InDressMode then
        local own, count = XDataCenter.ChristmasTreeManager.GetOrnamentCount()
        self.TxtGiftCount.text = string.format("%d/%d", own, count)
        if self.CurrentGroup ~= OverallIndex then
            local isEmpty = XDataCenter.ChristmasTreeManager.CheckPartGrpEmpty(self.CurrentGroup)
            self.BtnClear:SetButtonState(not isEmpty and XUiButtonState.Normal or XUiButtonState.Disable)
        end
    else
        local canGet, minItemId, minItemCount = XDataCenter.ChristmasTreeManager.CheckCanGetOrnament()
        local own = XDataCenter.ItemManager.GetCount(minItemId)
        
        self.TxtConsume.text = string.format("%d/%d", own, minItemCount)
        self.RImgSubItem:SetRawImage(XDataCenter.ItemManager.GetItemIcon(minItemId))
        self.BtnActiveOrnament:SetButtonState(canGet and XUiButtonState.Normal or XUiButtonState.Disable)
    end
    
    self.LastGroup = lastGroup or self.CurrentGroup
    if self.LastGroup ~= self.CurrentGroup then
        local isLoad = self.Tree.gameObject:GetComponent(typeof(CS.XUiLoadPrefab))
        if isLoad then
            self:PlayAnimation("TreeDisable",function ()
                self:RefreshTree(self.CurrentGroup)
                self:PlayAnimation("TreeEnable")
            end)
            return
        end
    end

    self:RefreshTree(self.CurrentGroup)
end

function XUiChristmasTree:ResetLongClicker()
    --for i,v in pairs(self.LongClick) do
    --    if self.PlacePoint[i].IsPointChange then
    --        v:Destroy()
    --        self.LongClick[i] = nil
    --    end
    --end
    
    for i in pairs(self.TreePartList) do
        if self.PlacePoint[i].IsPointChange then
            self.LongClick[i] = XUiButtonLongClick.New(self.TreePartList[i]:GetComponent("XUiPointer") , 15, self, nil, self.OnDrag, function()self:OnEndDrag(true) end, false, self.PlacePoint[i])
            self.LongClick[i]:SetTriggerOffset(LongClickOffset)
        end
    end
end

function XUiChristmasTree:RefreshTree(index)
    local path
    if index == OverallIndex then
        path = self.ActTemplate.OverallPrefab
    else
        path = self.ActTemplate.PartPrefab[index]
    end
    self.TreeGroup = self.Tree.gameObject:LoadPrefab(path).transform
    self:SwitchBtnChange()
    -- 加载挂点
    self.IsPartGroupFull = true
    self.PosInfo = XDataCenter.ChristmasTreeManager.GetCurrentOrnamentPos()
    self.TreePartList = {}
    for i = 1, XChristmasTreeConfig.GetTreePartCount() do
        local part = self.TreeGroup:Find("Point"..i)
        if part then
            local itemInfo
            if self.PosInfo[i] and self.PosInfo[i] ~= 0 then
                itemInfo = XChristmasTreeConfig.GetOrnamentById(self.PosInfo[i])
            else
                self.IsPartGroupFull = false
            end
            if not self.PlacePoint[i] then
                self.PlacePoint[i] = XUiPlacedOrnamentGrid.New(self)
            end
            self.PlacePoint[i]:Refresh(part, itemInfo, i)
            self.TreePartList[i] = self.PlacePoint[i].RImgIcon.transform
        end
    end
    
    self:UnselectAllItem()
    self:SetAllItemLight(true)
    if self.InDressMode then
        self:OnBtnFilter()
    end
    self:ResetLongClicker()
end

function XUiChristmasTree:SelectItem(index)
    if not index or self.CurrentGroup == OverallIndex then return end
    if self.DragItem then
        return
    end
    self.CloseBg = self.TreeGroup:Find("RawImage"):GetComponent("RawImage")
    local item = self.PlacePoint[index]
    if self.CurSelectGridIndex == index then
        self:OnCancelRemoveBtn()
    elseif self.PosInfo[index] then
        self.BtnRemove.gameObject:SetActiveEx(true)
        self.BtnRemove.transform.localPosition = item.Transform.localPosition
        self.BtnRemove.CallBack = function() self:OnBtnRemove() end
        self:UnselectAllItem(index)
        self.CloseBg.raycastTarget = true
        self:RegisterClickEvent(self.CloseBg, function () self:OnCancelRemoveBtn() end)

        self.CurSelectGridIndex = index
    else
        self:UnselectAllItem()
    end
end

function XUiChristmasTree:SetAllItemLight(isLight)
    for index in pairs(self.TreePartList) do
        local item = self.PlacePoint[index]
        item:SetLight(self.CurrentGroup ~= OverallIndex and isLight)
    end
end

-- 切换显示按钮
function XUiChristmasTree:SwitchBtnChange()
    if not self.InDressMode then
        self.PanelChangeOver.gameObject:SetActiveEx(false)
        self.PanelChangeOverEdit.gameObject:SetActiveEx(false)
    elseif self.CurrentGroup == OverallIndex then
        self.PanelChangeOver.gameObject:SetActiveEx(true)
        self.PanelChangeOverEdit.gameObject:SetActiveEx(false)
        for i = 1, AttrCount do
            self.BtnChangeList[i]:SetButtonState(XUiButtonState.Normal)
        end
        self.BtnClear.gameObject:SetActiveEx(false)
    else
        self.PanelChangeOver.gameObject:SetActiveEx(false)
        self.PanelChangeOverEdit.gameObject:SetActiveEx(true)
        self.BtnClear.gameObject:SetActiveEx(true)
    end
    
    for i = 1, LocalStateCount do
        self.BtnChangeList[i].gameObject:SetActiveEx(true)
        self.BtnChangeEditList[i].gameObject:SetActiveEx(true)
    end
end

--动态列表事件
function XUiChristmasTree:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
        local clicker = XUiButtonLongClick.New(grid.GridPointer, 15, self, nil, self.OnDrag, function()self:OnEndDrag(false) end, false, grid)
        clicker:SetTriggerOffset(LongClickOffset)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GiftList[index]
        if not data then
            return
        end
        grid:Refresh(data, index)
        if self.CurrentFilterIndex <= AttrCount then
            grid:ShowAttr(self.CurrentFilterIndex)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        --grid:OpenDetail()
    end
end

-- 计时器
function XUiChristmasTree:CreateActivityTimer(startTime, endTime)
    local time = XTime.GetServerNowTimestamp()
    self:StopActivityTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
            time = XTime.GetServerNowTimestamp()
            if time > endTime then
                self:Close()
                XUiManager.TipError(CSXTextManagerGetText("ActivityMainLineEnd"))
                self:StopActivityTimer()
                return
            end
            self.TxtDay.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end, XScheduleManager.SECOND, 0)
end

function XUiChristmasTree:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)
        self.AnimTimer = nil
    end
end

function XUiChristmasTree:CalculateNearestBlockIndex(ignorePlaced)
    local nearestIndex = nil
    local nearestDistance = 0
    for index, block in pairs(self.TreePartList) do
        local ornamentId = self.PosInfo[index] or 0
        if block and (ignorePlaced or ornamentId == 0) then
            local x1 = self.DragItem.gameObject.transform.position.x
            local y1 = self.DragItem.gameObject.transform.position.y
            local x2 = block.position.x
            local y2 = block.position.y
            local distance = (y2-y1)^2 + (x2-x1)^2
            if nearestDistance == 0 then
                nearestIndex = index
                nearestDistance = distance
            else
                if distance < nearestDistance then
                    nearestIndex = index
                    nearestDistance = distance
                end
            end
        end
    end
    if nearestDistance <= MaxDistance then
        return nearestIndex
    end
end

function XUiChristmasTree:OnDrag(time, caller, item) -- 拖拽
    local data, index, isPlaced, isOwn = item:GetInfo()

    if not self.DragItem then -- 第一次进入拖拽 没有拖拽的碎片
        self.IsDraging = true
        if self.CurrentGroup == OverallIndex then
            caller:Reset()
            if self.InDressMode then
                XUiManager.TipText("ChristmasTreeInPreviewMode")
            end
            return
        end

        if not isOwn then
            caller:Reset()
            XUiManager.TipText("ChristmasTreeOrnamentNotOwn")
            return
        end
        if self.IsPartGroupFull and not isPlaced then
            caller:Reset()
            XUiManager.TipText("ChristmasTreePartGroupFull")
            return
        end
        -- 锁定中 退出
        if self.ClickLock then
            caller:Reset()
            return
        end

        if data then
            self.CurDragItemId = data.Id
            self.NearestIndex = nil
            self.DragItem = self.OrnamentDragItem
            self.DragItem.gameObject:SetActiveEx(true)
            self.DragItem:SetRawImage(data.ResPath)
            self.DragItem.rectTransform.sizeDelta = CS.UnityEngine.Vector2(data.Width, data.Height)
            self.DragItem.rectTransform.localPosition = self:GetPoint()
        end
        if isPlaced then
            item.RImgIcon:CrossFadeAlpha(0.2, 0.2, false);
        end
        self.LastClickIndex = index
        self:UnselectAllItem()
    elseif self.IsDraging then-- 持续更新拖拽的碎片位置
        self.DragItem.gameObject.transform.localPosition = self:GetPoint()
        local nearestIndex = self:CalculateNearestBlockIndex(isPlaced)
        -- XLog.Warning(nearestIndex, nearestDistance)
        if nearestIndex then
            if not self.NearestIndex then
                self.NearestIndex = nearestIndex
                self.PlacePoint[nearestIndex]:SetSelect(true)
            elseif self.NearestIndex ~= nearestIndex then
                self.PlacePoint[self.NearestIndex]:SetSelect(false)
                self.NearestIndex = nearestIndex
                self.PlacePoint[nearestIndex]:SetSelect(true)
            end
        elseif self.NearestIndex then
            self.PlacePoint[self.NearestIndex]:SetSelect(false)
            self.NearestIndex = nil
        end
    end
end

function XUiChristmasTree:OnEndDrag(isChangePiece) -- 抬起
    if not self.IsDraging then return end
    if not self.NearestIndex then -- 点击抬起过快可能导致NearestIndex为空 或者 周围无可用挂点
        if self.DragItem then
            if isChangePiece then
                self.PlacePoint[self.LastClickIndex].RImgIcon:CrossFadeAlpha(1, 0.2, false);
            end
            self.DragItem.gameObject:SetActiveEx(false)
            self.DragItem = nil
            self.LastClickIndex = nil
        end
        self:UnselectAllItem()
    elseif self.DragItem then
        self.DragItem.gameObject:SetActiveEx(false)
        self.DragItem = nil
        self.PlacePoint[self.NearestIndex]:SetSelect(false)
        if isChangePiece then
            XDataCenter.ChristmasTreeManager.SwapOrnamentPos(self.NearestIndex ,self.LastClickIndex)
            self.CurDragItemId = nil
            -- self:SelectItem(self.LastClickIndex, ture)
            self.PlacePoint[self.LastClickIndex].RImgIcon:CrossFadeAlpha(1, 0.2, false);
        else
            XDataCenter.ChristmasTreeManager.PutOrnament(self.NearestIndex ,self.CurDragItemId)
        end
        self.LastClickIndex = nil
        self.NearestIndex = nil
        self:RefreshView()
    end
    self.CurSelectGridIndex = nil
    self.IsDraging = false
    self.ClickLock = true
    XScheduleManager.ScheduleOnce(function()
        self.ClickLock = false
    end, 100)
end

function XUiChristmasTree:GetPoint()
    local screenPoint
    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
        screenPoint = CS.UnityEngine.Vector2(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)
    else
        screenPoint = CS.UnityEngine.Input.GetTouch(0).position
    end

    -- 设置拖拽
    local hasValue, v2 = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.RectTransform, screenPoint, self.Camera)
    if hasValue then
        local x = v2.x
        local y = v2.y
        --if x < -self.PieceMoveLimitX then x = -self.PieceMoveLimitX elseif x > self.PieceMoveLimitX then x = self.PieceMoveLimitX end
        --if y < -self.PieceMoveLimitY then y = -self.PieceMoveLimitY elseif y > self.PieceMoveLimitY then y = self.PieceMoveLimitY end
        return CS.UnityEngine.Vector3(x, y, 0)
    else
        return CS.UnityEngine.Vector3.zero
    end
end