---@class XUiRiftFightLayerSelect:XLuaUi 大秘境作战层选择界面（点击区域进入此处）
local XUiRiftFightLayerSelect = XLuaUiManager.Register(XLuaUi, "UiRiftFightLayerSelect")
local XUiGridRiftFightLayer = require("XUi/XUiRift/Grid/XUiGridRiftFightLayer")

local IsPlayEnableAnimTrigger = nil
local ItemIds = {
    XDataCenter.ItemManager.ItemId.RiftGold,
    XDataCenter.ItemManager.ItemId.RiftCoin
}

function XUiRiftFightLayerSelect:OnAwake()
    self.FuncUnlockItemId = nil -- 特权解锁的道具id
    self.GridRewardList = {}
    self.GridPluginList = {}

    self:InitButton()
    self:InitDynamicTable()
    self.BtnAttributeRedEventId = XRedPointManager.AddRedPointEvent(self.BtnAttribute, self.OnCheckAttribute, self, { XRedPointConditions.Types.CONDITION_RIFT_ATTRIBUTE })
end

function XUiRiftFightLayerSelect:OnDestroy()
    XRedPointManager.RemoveRedPointEvent(self.BtnAttributeRedEventId)
end

function XUiRiftFightLayerSelect:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnMapClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "RiftHelp")
    XUiHelper.RegisterClickEvent(self, self.BtnTask, self.OnClickBtnTask)
    XUiHelper.RegisterClickEvent(self, self.BtnTask2, self.OnBtnFuncUnlockClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAttribute, self.OnBtnAttributeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPluginBag, function() XLuaUiManager.Open("UiRiftPluginBag") end)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, function() XDataCenter.RiftManager.OpenUiShop() end)
    XUiHelper.RegisterClickEvent(self, self.BtnCharacter, function() XLuaUiManager.Open("UiRiftCharacter", nil, nil, nil, true) end)
    XUiHelper.RegisterClickEvent(self, self.BtnLuck, self.OnBtnLuckClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStart, self.OnShowDetail)
    XUiHelper.RegisterClickEvent(self, self.BtnStartAgain, self.OnShowDetail)
    XUiHelper.RegisterClickEvent(self, self.BtnContinue, self.OnShowDetail)
    XUiHelper.RegisterClickEvent(self, self.BtnMopup, self.OnBtnMopupClick) -- 派遣(扫荡)
    XUiHelper.RegisterClickEvent(self, self.BtnReward, function() XLuaUiManager.Open("UiRiftPreview", self.CurrSelectXFightLayer) end)
end

function XUiRiftFightLayerSelect:InitDynamicTable()
    -- 选择作战层的滑动列表
    self.DynamicTable = XDynamicTableNormal.New(self.FightLayerList)
    self.DynamicTable:SetProxy(XUiGridRiftFightLayer, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftFightLayerSelect:OnStart(parentUi, panel3D, jumpLayerId)
    self.ParentUi = parentUi
    ---@type XUiPanelRiftMain3D
    self.Panel3D = panel3D
    self.JumpLayerId = jumpLayerId
    parentUi.ChildUi = self
    IsPlayEnableAnimTrigger = true
    self:InitComponent()
end

function XUiRiftFightLayerSelect:RemoveTimer()
    if not self.BubbleTimer then return end
    XScheduleManager.UnSchedule(self.BubbleTimer)
    self.BubbleTimer = nil
end

function XUiRiftFightLayerSelect:OnGetEvents()
    return {
        XEventId.EVENT_RIFT_SEASON,
    }
end

function XUiRiftFightLayerSelect:OnNotify(evt)
    if evt == XEventId.EVENT_RIFT_SEASON then
        self:RefreshDynamicTable()
        self:Refresh()
    end
end

function XUiRiftFightLayerSelect:OnEnable()
    self.ParentUi.ChildUi = self
    if IsPlayEnableAnimTrigger then -- 从riftMain打开时才播动画
        IsPlayEnableAnimTrigger = nil
        self.Transform:Find("Animation/AnimEnable1"):PlayTimelineAnimation()
    end
    -- 切换为区域镜头
    ---@type XRiftChapter
    self.XChapter = XDataCenter.RiftManager.GetEntityChapterById(self.ParentUi.CurrSelectIndex)
    self.Panel3D:SetCameraAngleByChapterId(self.ParentUi.CurrSelectIndex)
    self.Panel3D:SetOtherGameObjectShowByChapterId(self.ParentUi.CurrSelectIndex)
    self.Panel3D:SetDragComponentEnable(false)
    self.BtnCharacter:ShowReddot(XDataCenter.RiftManager:GetCharacterRedPoint())
    
    -- 每次进入检查以下trigger
    -- 1.跨层通关 2.跨层解锁 3.跳转作战层并开始作战 4.是否首通当前区域
    -- 高盖低机制trigger，展示提示界面,关闭后飘字
    local jumpResTrigger = XDataCenter.RiftManager.GetIsTriggerJumpRes()
    -- 【下一层】跳转
    local isLayerIdTrigger = XDataCenter.RiftManager.GetIsNewLayerIdTrigger()
    if jumpResTrigger then
        XLuaUiManager.Open("UiRiftJumpResults", jumpResTrigger, function()
            self.XChapter:CheckFirstPassAndOpenTipFun(function(nextChapter)
                self.ParentUi:AutoPositioningToOpenBubbleByChapterId(nextChapter:GetId())
                self:OnBtnMapClick()
            end)
            self:ShowJumpTip()
        end)
    else
        -- 刷新完数据 最后再弹各种提示
        -- 横幅互斥
        local isJumpOpenTrigger = XDataCenter.RiftManager.GetIsTriggerJumpOpen()
        if isJumpOpenTrigger then
            self:ShowJumpTip()
        elseif isLayerIdTrigger then
            self:ShowNewLayerTip(isLayerIdTrigger)
        end
    end

    if XTool.IsNumberValid(isLayerIdTrigger) then
        self:AutoPositioningByLayerId(isLayerIdTrigger) -- 跳转到跃升层
    else
        self:AutoPositioningByLayerId(self.JumpLayerId)
    end
    self.JumpLayerId = nil
    self:RefreshDynamicTable()
    self:PlayLayerNodeAnim(isLayerIdTrigger)
    self:Refresh()

    -- 检测区域是否全部通关 弹提示，必现要在跃升奖励之后再弹该提示
    if not jumpResTrigger then
        self.XChapter:CheckFirstPassAndOpenTipFun(function (nextChapter)
            self.ParentUi:AutoPositioningToOpenBubbleByChapterId(nextChapter:GetId())
            self:OnBtnMapClick()
        end)
    end
end

function XUiRiftFightLayerSelect:ShowJumpTip()
    self.PanelBeginJump.gameObject:SetActiveEx(true)
    self.PanelBeginJumpEnable:Play()
    self.TxtBeginJump.text = CS.XTextManager.GetText("RiftLayerStartByJump", XDataCenter.RiftManager.GetMaxUnLockFightLayerId())
end

function XUiRiftFightLayerSelect:ShowNewLayerTip(isLayerIdTrigger)
    self.PanelBegin.gameObject:SetActiveEx(true)
    self.PanelBeginEnable:Play()
    self.TxtBegin.text = CS.XTextManager.GetText("RiftLayerStartByAuto", isLayerIdTrigger)
end

function XUiRiftFightLayerSelect:Refresh()
    self:RefreshUiShow() -- 刷新2d界面ui信息
    self:RefreshFightLayerData() -- 刷新3d关卡节点数据
end

function XUiRiftFightLayerSelect:RefreshUiShow()
    self.BtnMopup:SetNameByGroup(1, XDataCenter.RiftManager.GetSweepLeftTimes().."/"..XDataCenter.RiftManager.GetCurrentConfig().DailySweepTimes)
    -- 目标(任务/权限回收)
    self:RefreshUiTask()
    self:RefreshFuncUnlock()

    -- 幸运值信息
    local progress = XDataCenter.RiftManager:GetLuckValueProgress()
    self.ImgLuckProgress.fillAmount = progress
    self.TxtLuckProgress.text = string.format("%s%%", math.floor(progress * 100))
    self.BtnLuck:ShowReddot(progress >= 1)
    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.LuckyStage)
    self.PanelHiddenStage.gameObject:SetActiveEx(isUnlock)

    -- 属性加点按钮
    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.Attribute)
    self.BtnAttribute:SetDisable(not isUnlock)
    -- 商店按钮
    XRedPointManager.Check(self.BtnAttributeRedEventId)
    local isShopRed = XDataCenter.RiftManager.IsShopRed()
    self.BtnShop:ShowReddot(isShopRed)
    -- 插件背包按钮
    local isPluginRed = XDataCenter.RiftManager.IsPluginBagRed()
    self.BtnPluginBag:ShowReddot(isPluginRed)
end

function XUiRiftFightLayerSelect:RefreshDynamicTable()
    local resourceList = self.XChapter:GetAllFightLayersOrderList()
    local res = {}
    local unLockCount = 0
    self.HasPassCount = 0
    for _, xFightLayer in ipairs(resourceList) do
        if not XDataCenter.RiftManager.IsLayerLock(xFightLayer:GetId()) then
            self.HasPassCount = self.HasPassCount + 1
        end
        if xFightLayer:CheckHasLock() then
            unLockCount = unLockCount + 1
            if unLockCount > 5 then
                break
            end
        end
        table.insert(res, xFightLayer)
    end
    self.LayerListData = res
    self.DynamicTable:SetDataSource(self.LayerListData)
    self.DynamicTable:ReloadDataSync(self.CurrSelectLayerListIndex or 1)
    -- 计算进度条
    if self.HasPassCount == #res then
        self.ImgNodeProgress.fillAmount = 1
    else
        self.ImgNodeProgress.fillAmount = self:GetNodePorgress(self.HasPassCount)
    end
end

function XUiRiftFightLayerSelect:GetNodePorgress(hasPassCount)
    local space = self.Btn.rect.height + self.FightLayerList.Spacing.y
    local offset = math.abs(self.BtnSimple.anchoredPosition.y)
    local progress = offset + math.max(0, space * (hasPassCount - 1))
    local totalProgress = math.max(self.FightLayerList.transform.rect.height, self.Btn.rect.height * #self.LayerListData + self.FightLayerList.Spacing.y * (#self.LayerListData - 1))
    return progress / totalProgress
end

function XUiRiftFightLayerSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX or event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local isSelect = self.CurrSelectLayerListIndex == index
        grid:Update(self.LayerListData[index], index)
        grid:SetSelect(isSelect)
        if isSelect then
            self.CurrGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local xFightLayer = self.LayerListData[index]
        if xFightLayer:CheckHasLock() then
            local text = nil
            if xFightLayer.Config.UnlockByPrevLayer then
                text = "RiftLayerLimit2"
            else
                text = "RiftLayerLimit1"
            end
            XUiManager.TipError(CS.XTextManager.GetText(text))
            return
        end
        if self.CurrGrid then
            self.CurrGrid:SetSelect(false)
        end
        grid:SetSelect(true)
        self.CurrGrid = grid
        self.CurrSelectLayerListIndex = index
    end
end

-- 自动定位层级，该函数不包含动态列表刷新，调用完该函数后要再手动调用一遍刷新动态列表
-- 1.如果传入指定序号，则直接定位到该序号
function XUiRiftFightLayerSelect:AutoPositioning(index)
    local curIndex = index or 1
    self.CurrSelectLayerListIndex = curIndex
end

-- 自动定位层级 
-- 如果传了id，定位到该id对应的层
-- 没传的话 则自动定位到当前已经在作战中的层
-- 如果没有在作战中的层，则定位到上一次战斗过的层
-- 如果没有上一次战斗的层级，则定位到上一次进入查看过的层级
-- 如果都不满足则定位到列表的第一个
function XUiRiftFightLayerSelect:AutoPositioningByLayerId(layerId)
    self.LayerListData = self.XChapter:GetAllFightLayersOrderList()
    local curIndex = 1
    local curLayerId = self.LayerListData[1]:GetId() -- 默认选第一个
    if layerId then
        curLayerId = layerId
    else  
        local curPlayingLayer = self.XChapter:GetCurPlayingFightLayer()
        local lastFightStage = XDataCenter.RiftManager.GetLastFightXStage()
        if curPlayingLayer then
            curLayerId = curPlayingLayer:GetId()
        elseif lastFightStage then
            curLayerId = lastFightStage:GetParent():GetParent():GetId()
        else
            local lastFightLayerData = XDataCenter.RiftManager.GetLastRecordFightLayer()
            if not XTool.IsTableEmpty(lastFightLayerData) then
                curLayerId = lastFightLayerData.FightLayerId
            end
        end
    end
    -- 找到这个作战层在列表里的序号index， 如果该作战层不属于该chapter则还是定位到默认index=1的作战层
    ---@type XRiftFightLayer
    self.CurrSelectXFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(curLayerId)
    local xCurFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(curLayerId)
    for k, xFightLayer in pairs(self.LayerListData) do
        if xFightLayer == xCurFightLayer then
            curIndex = k
            break
        end
    end
    self:AutoPositioning(curIndex)
end

function XUiRiftFightLayerSelect:OnGridFightLayerSelected(grid)
    -- 进入战斗层，记录进入打个卡
    XDataCenter.RiftManager.SaveLastFightLayer(grid.XFightLayer)
    grid.XFightLayer:SaveFirstEnter()
    if self.CurrSelectXFightLayer ~= grid.XFightLayer then
        self.CurrSelectXFightLayer = grid.XFightLayer
        self.Transform:Find("Animation/QieHuan"):PlayTimelineAnimation()
        grid:RefreshReddot()
    end
    self:Refresh()
end

---@param fightLayer XRiftFightLayer
function XUiRiftFightLayerSelect:StartLayer(fightLayer, cb)
    -- 已经有数据就不能再请求,否则怪物数据会被刷新掉
    local groups = fightLayer:GetAllStageGroups()
    local chapter, _ = XDataCenter.RiftManager.GetCurrPlayingChapter()
    if XTool.IsTableEmpty(groups) or not chapter then
        XDataCenter.RiftManager.RiftStartLayerRequest(fightLayer:GetId(), function()
            cb()
        end)
    else
        cb()
    end
end

-- 刷新该层的相关数据
function XUiRiftFightLayerSelect:RefreshFightLayerData()
    -- 刷新层名 深度
    local cur, total = self.XChapter:GetChapterProgress()
    self.TxtDepth.text = string.format("%s%%", total ~= 0 and math.round(cur / total * 100) or 0)
    self.TxtTitle.text = self.CurrSelectXFightLayer:GetParent():GetConfig().Name
    
    -- 刷新关卡节点(3D)
    self.Panel3D:SetGridStageGroupData(self.CurrSelectXFightLayer)

    -- 刷新按钮显示状态
    local currLayer = self.CurrSelectXFightLayer:GetId()
    local isCurrPlay = XDataCenter.RiftManager.IsCurrPlayingLayer(currLayer)
    local isPass = XDataCenter.RiftManager.IsLayerPass(currLayer)
    self.BtnStart.gameObject:SetActiveEx(not isCurrPlay and not isPass)     -- 开始挑战
    self.BtnStartAgain.gameObject:SetActiveEx(not isCurrPlay and isPass)    -- 再次挑战
    self.BtnContinue.gameObject:SetActiveEx(isCurrPlay)                     -- 继续挑战
end

function XUiRiftFightLayerSelect:OnShowDetail()
    local newLayerId = self.CurrSelectXFightLayer:GetId()
    if XDataCenter.RiftManager.IsOtherLayerPlaying(newLayerId) then
        -- 弹放弃其他层的弹框
        XUiManager.DialogTip("", XUiHelper.GetText("RiftLayerGiveUp"), XUiManager.DialogType.Normal, nil, function()
            XDataCenter.RiftManager.RiftStopLayerRequest(function()
                self:OnStartNewLayer(newLayerId)
            end)
        end)
        return
    end
    self:OnStartNewLayer(newLayerId)
end

function XUiRiftFightLayerSelect:OnStartNewLayer(newLayerId)
    local newFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(newLayerId)
    self:StartLayer(newFightLayer, function()
        self.Panel3D:AutoOpenDetail(self.CurrSelectXFightLayer)
        self:Refresh()
    end)
end

function XUiRiftFightLayerSelect:OnBtnRefreshClick()
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("RiftRefreshRandomConfirm")
    local sureCallback = function ()
        self:StartLayer(self.CurrSelectXFightLayer, handler(self, self.Refresh))
    end

    if self.CurrSelectXFightLayer:CheckIsOwnFighting() then
        XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
    else
        sureCallback()
    end
end

function XUiRiftFightLayerSelect:OnBtnMopupClick()
    if XDataCenter.RiftManager.GetSweepLeftTimes() <= 0 then
        XUiManager.TipError(XUiHelper.GetText("RiftSweepTimesLimit"))
        return
    end
    local maxPass = XDataCenter.RiftManager.GetMaxPassFightLayerId()
    if not XTool.IsNumberValid(maxPass) then
        XUiManager.TipError(XUiHelper.GetText("RiftSweepForbidTip"))
        return
    end
    if not XDataCenter.RiftManager.IsLayerPass(self.CurrSelectXFightLayer:GetId()) then
        XUiManager.TipError(XUiHelper.GetText("RiftMopupForbid"))
        return
    end
    
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("RiftSweepConfirm")
    local sureCallback = function ()
        XDataCenter.RiftManager.RiftSweepLayerRequest(function ()
            self:Refresh()
        end)
    end
    XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
end

function XUiRiftFightLayerSelect:OnBtnLuckClick()
    local startLucky = function()
        local luckyLayer = XDataCenter.RiftManager:GetLuckLayer()
        self:StartLayer(luckyLayer, function()
            local group = luckyLayer:GetStage()
            XDataCenter.RiftManager.SetCurrSelectRiftStage(group)
            XLuaUiManager.Open("UiRiftLuckStageDetail", group, handler(self, self.Refresh))
        end)
    end

    if XDataCenter.RiftManager.GetCurrPlayingChapter() then
        -- 弹放弃其他层的弹框
        XUiManager.DialogTip("", XUiHelper.GetText("RiftLayerGiveUp"), XUiManager.DialogType.Normal, nil, function()
            XDataCenter.RiftManager.RiftStopLayerRequest(function()
                startLucky()
            end)
        end)
        return
    end

    startLucky()
end

function XUiRiftFightLayerSelect:OnBtnBackClick()
    self:Close()
    self.ParentUi:Close()
end

function XUiRiftFightLayerSelect:OnBtnMapClick()
    self:Close()
    self.ParentUi:OnChildUiClose()
end

-- 点击特权解锁
function XUiRiftFightLayerSelect:OnBtnFuncUnlockClick()
    if self.FuncUnlockItemId then
        local data = {
            Id = self.FuncUnlockItemId,
            Count = "0"
        }
        XLuaUiManager.Open("UiTip", data, nil, nil, nil, nil, nil, XUiHelper.GetText("RiftChapterPrivilegeTarget"), false)

        XDataCenter.RiftManager.CloseFuncUnlockRed()
        self:RefreshFuncUnlock()
    end
end

function XUiRiftFightLayerSelect:OnBtnAttributeClick()
    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.Attribute)
    if isUnlock then
        XLuaUiManager.Open("UiRiftAttribute")
    else
        local funcUnlockCfg = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftFuncUnlock, XRiftConfig.FuncUnlockId.Attribute)
        XUiManager.TipError(funcUnlockCfg.Desc)
    end
end

function XUiRiftFightLayerSelect:OnCheckAttribute(count)
    self.BtnAttribute:ShowReddot(count >= 0)
end

function XUiRiftFightLayerSelect:OnDisable()
    -- 关闭界面隐藏所有关卡节点
    self.Panel3D:ClearAllStageGroup()
    self.Panel3D:SetDragComponentEnable(true)
    self:RemoveTimer()
end

function XUiRiftFightLayerSelect:InitComponent()
    if self.AssetActivityPanel then
        self.AssetActivityPanel:Refresh(ItemIds)
    else
        self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)
    end
end

function XUiRiftFightLayerSelect:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(ItemIds)
end

-- 刷新任务ui
function XUiRiftFightLayerSelect:RefreshUiTask()
    local titleName, desc = XDataCenter.RiftManager.GetBtnShowTask()
    local isShow = titleName ~= nil
    self.PanelTask.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtTaskName.text = titleName
        self.TxtTaskDesc.text = desc
        local isShowRed = XDataCenter.RiftManager.CheckTaskCanReward()
        self.BtnTask:ShowReddot(isShowRed)
    end
end

-- 刷新特权解锁ui
function XUiRiftFightLayerSelect:RefreshFuncUnlock()
    local unlockConfig = XDataCenter.RiftManager.GetNextFuncUnlockConfig()
    local isShow = unlockConfig ~= nil
    self.PanelTask2.gameObject:SetActiveEx(isShow)
    if isShow then
        self.FuncUnlockItemId = unlockConfig.ItemId
        self.TxtTaskDesc2.text = unlockConfig.Desc

        local isRed = XDataCenter.RiftManager.IsFuncUnlockRed()
        self.BtnTask2:ShowReddot(isRed)
    end
end

function XUiRiftFightLayerSelect:OnClickBtnTask()
    self.JumpLayerId = self.CurrSelectXFightLayer:GetId()
    XLuaUiManager.Open("UiRiftTask")
end

function XUiRiftFightLayerSelect:PlayLayerNodeAnim(jumpLayerId)
    if not XTool.IsNumberValid(jumpLayerId) then
        return
    end
    local old = XDataCenter.RiftManager.GetMaxPassFightLayerId()
    ---@type XUiGridRiftFightLayer[]
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        local layerId = grid.XFightLayer:GetId()
        if layerId > old and layerId <= jumpLayerId then
            XScheduleManager.ScheduleOnce(function()
                grid.AnimationBig:Play()
                self.ImgNodeProgress.fillAmount = self:GetNodePorgress(self.HasPassCount - jumpLayerId + layerId)
            end, (layerId - old - 1) * 300)
        end
    end
end

return XUiRiftFightLayerSelect