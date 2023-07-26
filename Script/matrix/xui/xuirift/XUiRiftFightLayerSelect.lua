--大秘境作战层选择界面（点击区域进入此处）
local XUiRiftFightLayerSelect = XLuaUiManager.Register(XLuaUi, "UiRiftFightLayerSelect")
local XUiGridRiftFightLayer = require("XUi/XUiRift/Grid/XUiGridRiftFightLayer")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

local IsPlayEnableAnimTrigger = nil
local BubbleChangeTime = 3 -- 插件和奖励列表切换的时间
local BubbleDuration = 10 -- 启用切换气泡

function XUiRiftFightLayerSelect:OnAwake()
    self.FuncUnlockItemId = nil -- 特权解锁的道具id
    self.GridRewardList = {}
    self.GridPluginList = {}

    self:InitButton()
    self:InitDynamicTable()
    self:InitAssetPanel()
    self.BtnAttributeRedEventId = XRedPointManager.AddRedPointEvent(self.BtnAttribute, self.OnCheckAttribute, self, { XRedPointConditions.Types.CONDITION_RIFT_ATTRIBUTE })
end

function XUiRiftFightLayerSelect:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnMapClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "RiftHelp")
    self:BindHelpBtn(self.BtnLuckHelp, "RiftLuckyHelp")
    XUiHelper.RegisterClickEvent(self, self.BtnTask, function() XLuaUiManager.Open("UiRiftTask") end)
    XUiHelper.RegisterClickEvent(self, self.BtnTask2, self.OnBtnFuncUnlockClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAttribute, self.OnBtnAttributeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPluginBag, function() XLuaUiManager.Open("UiRiftPluginBag") end)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, function() XDataCenter.RiftManager.OpenUiShop() end)
    XUiHelper.RegisterClickEvent(self, self.BtnCharacter, function() XLuaUiManager.Open("UiRiftCharacter", nil, nil, nil, true) end)
    -- XUiHelper.RegisterClickEvent(self, self.BtnMap, self.OnBtnMapClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLuck, self.OnBtnLuckClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStart, self.OnBtnStartClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStartAgain, self.OnBtnStartClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGiveup, self.OnBtnGiveupClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRefresh, self.OnBtnRefreshClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMopup, self.OnBtnMopupClick) -- 派遣(扫荡)
    XUiHelper.RegisterClickEvent(self, self.BtnReward, function() XLuaUiManager.Open("UiRiftPreview", self.CurrSelectXFightLayer) end)
end

function XUiRiftFightLayerSelect:InitDynamicTable()
    -- 选择作战层的滑动列表
    self.DynamicTable = XDynamicTableNormal.New(self.FightLayerList)
    self.DynamicTable:SetProxy(XUiGridRiftFightLayer, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftFightLayerSelect:OnStart(parentUi, panel3D)
    self.ParentUi = parentUi
    self.Panel3D = panel3D
    parentUi.ChildUi = self
    IsPlayEnableAnimTrigger = true
end

function XUiRiftFightLayerSelect:InitBubbleChange()
    if self.BubbleTimer then
        return
    end
    local duration = BubbleDuration
    local changeCD = BubbleChangeTime -- 插件和奖励列表切换的时间
    local flag = true
    self.PanelRewardList.gameObject:SetActiveEx(flag)
    self.PanelPluginList.gameObject:SetActiveEx(not flag)
    self.Transform:Find("Animation/RewardEnable"):PlayTimelineAnimation()

    self.BubbleTimer = XScheduleManager.ScheduleForever(function()
        changeCD = changeCD - 1
        duration = duration - 1
        if changeCD < 0 then -- 切换气泡显示
            changeCD = BubbleChangeTime
            flag = not flag
            self.PanelRewardList.gameObject:SetActiveEx(flag)
            self.PanelPluginList.gameObject:SetActiveEx(not flag)
        end

        if duration < 0 then -- 气泡消失
            self.Transform:Find("Animation/RewardDisable"):PlayTimelineAnimation(function ()
                self.PanelRewardList.gameObject:SetActiveEx(false)
                self.PanelPluginList.gameObject:SetActiveEx(false)
            end)
            self:RemoveTimer()
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiRiftFightLayerSelect:RemoveTimer()
    if not self.BubbleTimer then return end
    XScheduleManager.UnSchedule(self.BubbleTimer)
    self.BubbleTimer = nil
end

function XUiRiftFightLayerSelect:OnEnable()
    self.ParentUi.ChildUi = self
    if IsPlayEnableAnimTrigger then -- 从riftMain打开时才播动画
        IsPlayEnableAnimTrigger = nil
        self.Transform:Find("Animation/AnimEnable1"):PlayTimelineAnimation()
    end
    -- 切换为区域镜头
    self.XChapter = XDataCenter.RiftManager.GetEntityChapterById(self.ParentUi.CurrSelectIndex)
    self.Panel3D:SetCameraAngleByChapterId(self.ParentUi.CurrSelectIndex)
    self.Panel3D:SetOtherGameObjectShowByChapterId(self.ParentUi.CurrSelectIndex)
    self.Panel3D:SetDragComponentEnable(false)
    
    -- 每次进入检查以下trigger
    -- 1.跨层通关 2.跨层解锁 3.跳转作战层并开始作战 4.是否首通当前区域
    -- 高盖低机制trigger，展示提示界面
    local jumpResTrigger = XDataCenter.RiftManager.GetIsTriggerJumpRes()
    if jumpResTrigger then 
        XLuaUiManager.Open("UiRiftJumpResults", jumpResTrigger, function ()
            self.XChapter:CheckFirstPassAndOpenTipFun(function (nextChapter)
                self.ParentUi:AutoPositioningToOpenBubbleByChapterId(nextChapter:GetId())
                self:OnBtnMapClick()
            end)
        end)
    end
    -- 每次进入界面检测【跃升跨层解锁】Trigger和【下一层】跳转Trigger，跃升trigger优先
    local isJumpOpenTrigger = XDataCenter.RiftManager.GetIsTriggerJumpOpen()
    local isLayerIdTrigger = XDataCenter.RiftManager.GetIsNewLayerIdTrigger()
    self.PanelBegin.gameObject:SetActiveEx(false) -- 弹横幅
    self.PanelBeginJump.gameObject:SetActiveEx(false)
    self:AutoPositioningByLayerId(isLayerIdTrigger)
    self:RefreshDynamicTable()
    self:Refresh()
    self:InitBubbleChange()
    
    -- 刷新完数据 最后再弹各种提示
    -- 横幅互斥
    if isJumpOpenTrigger then
        self.PanelBeginJump.gameObject:SetActiveEx(true)
        self.TxtBeginJump.text = CS.XTextManager.GetText("RiftLayerStartByJump", XDataCenter.RiftManager.GetMaxUnLockFightLayerId())
    elseif isLayerIdTrigger then
        self.PanelBegin.gameObject:SetActiveEx(true)
        self.TxtBegin.text = CS.XTextManager.GetText("RiftLayerStartByAuto", isLayerIdTrigger)
    end
    -- 跳转Trigger必开始作战
    if isLayerIdTrigger then
        XDataCenter.RiftManager.RiftStartLayerRequest(isLayerIdTrigger, function ()
            self:Refresh()
        end)
    end
    -- 检测区域是否全部通关 弹提示，必现要在跃升奖励之后再弹该提示
    if not jumpResTrigger then
        self.XChapter:CheckFirstPassAndOpenTipFun(function (nextChapter)
            self.ParentUi:AutoPositioningToOpenBubbleByChapterId(nextChapter:GetId())
            self:OnBtnMapClick()
        end)
    end
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
    local value = math.floor((self.XChapter:GetLuckValueProgress() * 100))
    self.TxtLuckProgress.text =  value.. "%"
    self.ImgLuckProgress.fillAmount = self.XChapter:GetLuckValueProgress()
    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.LuckyStage)
    self.PanelHiddenStage.gameObject:SetActiveEx(isUnlock)

    -- 资源栏
    self:UpdateAssetPanel()

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
    for i, xFightLayer in ipairs(resourceList) do
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
end

function XUiRiftFightLayerSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
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

        self.CurrGrid:SetSelect(false)
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
    if self.CurrSelectXFightLayer == grid.XFightLayer then
        return
    end
    
    self.CurrSelectXFightLayer = grid.XFightLayer
    self.Transform:Find("Animation/QieHuan"):PlayTimelineAnimation()
    grid:RefreshReddot()
    self:Refresh()
    self:InitBubbleChange() -- 打开气泡
end

-- 刷新该层的相关数据
function XUiRiftFightLayerSelect:RefreshFightLayerData()
    -- 刷新层名 深度
    self.TxtDepth.text = self.CurrSelectXFightLayer:GetId()
    self.TxtTitle.text = self.CurrSelectXFightLayer:GetTypeDesc()
    -- 刷新奖励信息
    local rewards = {}
    local rewardId = self.CurrSelectXFightLayer:GetConfig().RewardId
    if rewardId > 0 then
        rewards = XRewardManager.GetRewardList(rewardId) 
    end
    for i, grid in ipairs(self.GridRewardList) do
        grid.GameObject:SetActiveEx(false)
    end
    for i, item in ipairs(rewards) do
        local grid =  self.GridRewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward, self.GridReward.parent)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewardList[i] = grid
        end
        grid:Refresh(item)
        grid:SetReceived(self.CurrSelectXFightLayer:CheckHasPassed())
        grid.GameObject:SetActive(true)
    end
    self.GridReward.gameObject:SetActiveEx(false)
    
    -- 刷新插件信息
    for i, grid in ipairs(self.GridPluginList) do
        grid.GameObject:SetActiveEx(false)
    end
    local pluginIds = self.CurrSelectXFightLayer.ClientConfig.PluginList
    for i, pluginId in ipairs(pluginIds) do
        local grid =  self.GridPluginList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridRiftPlugin, self.GridRiftPlugin.parent)
            grid = XUiRiftPluginGrid.New(ui)
            self.GridPluginList[i] = grid
        end
        local xPlugin = XDataCenter.RiftManager.GetPlugin(pluginId)
        grid:Refresh(xPlugin)
        grid:Init(function ()
            XLuaUiManager.Open("UiRiftPluginShopTips", {PluginId = xPlugin:GetId()})
        end)
        grid.GameObject:SetActive(true)
    end
    self.GridRiftPlugin.gameObject:SetActiveEx(false)
    
    -- 刷新关卡节点(3D)
    self.Panel3D:SetGridStageGroupData(self.CurrSelectXFightLayer)

    -- 作战层动态列表和地图按钮互斥显示
    local isFightBtn = self.CurrSelectXFightLayer:CheckHasStarted()
    self.PanelLayerList.gameObject:SetActiveEx(not isFightBtn)
    self.PanelFightBtn.gameObject:SetActiveEx(isFightBtn)

    -- 刷新按钮显示状态
    local isShow = self.CurrSelectXFightLayer:CheckHasPassed() -- 已通关用再次挑战按钮
    self.BtnStartAgain.gameObject:SetActiveEx(isShow)
    self.BtnStart.gameObject:SetActiveEx(not isShow)
    local currBtnStart = isShow and self.BtnStartAgain or self.BtnStart
    
    currBtnStart.gameObject:SetActiveEx(true)
    self.BtnRefresh.gameObject:SetActiveEx(false)
    self.BtnGiveup:SetDisable(false)
    self.BtnRefresh:SetDisable(false)

    if self.CurrSelectXFightLayer:CheckHasStarted() then    -- 作战开始
        currBtnStart.gameObject:SetActiveEx(false)
        -- 作战开始，但是进度为0
        if self.CurrSelectXFightLayer:GetProgress() <= 0 then
            self.BtnRefresh.gameObject:SetActiveEx(true)
        else
            self.BtnRefresh.gameObject:SetActiveEx(false)
        end
    elseif self.CurrSelectXFightLayer:CheckNoneData() then  -- 没有任何数据
        self.BtnGiveup:SetDisable(true)
        self.BtnRefresh:SetDisable(true)
    end

    local isZoom = self.CurrSelectXFightLayer:GetType() == XRiftConfig.LayerType.Zoom
    self.BtnMopup.gameObject:SetActiveEx(not isZoom) -- 跃升层隐藏扫荡按钮
    self.BtnMopup:SetDisable(self.CurrSelectXFightLayer:CheckMopupDisable()) -- 跃升层隐藏扫荡按钮
end

function XUiRiftFightLayerSelect:OnBtnStartClick()
    XDataCenter.RiftManager.RiftStartLayerRequest(self.CurrSelectXFightLayer:GetId(), function ()
        self:Refresh()
    end)
end

function XUiRiftFightLayerSelect:OnBtnGiveupClick()
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("RiftGiveUpConfirm")
    local sureCallback = function ()
        XDataCenter.RiftManager.RiftStopLayerRequest(function ()
            self:Refresh()
            local playTrans = self.Transform:Find("Animation/LayerListEnable")
            if playTrans.gameObject.activeInHierarchy then
                playTrans:PlayTimelineAnimation()
            end
        end)
    end
    XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
end

function XUiRiftFightLayerSelect:OnBtnRefreshClick()
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("RiftRefreshRandomConfirm")
    local sureCallback = function ()
        XDataCenter.RiftManager.RiftStartLayerRequestWithCD(self.CurrSelectXFightLayer:GetId(), function ()
            self:Refresh()
        end)
    end

    if self.CurrSelectXFightLayer:CheckIsOwnFighting() then
        XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
    else
        sureCallback()
    end
end

function XUiRiftFightLayerSelect:OnBtnMopupClick()
    if XDataCenter.RiftManager.GetSweepLeftTimes() <= 0 then
        XUiManager.TipError(CS.XTextManager.GetText("RiftSweepTimesLimit"))
        return
    end
    if not self.CurrSelectXFightLayer:CheckHasPassed() then
        XUiManager.TipError(CS.XTextManager.GetText("RiftSweepFirstPassLimit"))
        return
    end
    if self.CurrSelectXFightLayer:CheckIsOwnFighting() then
        XUiManager.TipError(CS.XTextManager.GetText("RiftSweepDataLimit"))
        return
    end
    
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("RiftSweepConfirm")
    local sureCallback = function ()
        XDataCenter.RiftManager.RiftSweepLayerRequest(self.CurrSelectXFightLayer:GetId(), function ()
            self:Refresh()
        end)
    end
    XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
end

function XUiRiftFightLayerSelect:OnBtnLuckClick()
    -- 区域唯一幸运节点检测
    local luckFightLayer = self.XChapter:GetCurrLuckFightLayer()
    if luckFightLayer and luckFightLayer:GetLuckStageGroup() and not luckFightLayer:GetLuckStageGroup():CheckHasPassed() then
        local title = CS.XTextManager.GetText("TipTitle")
        local content = CS.XTextManager.GetText("RiftLuckOnlyLimit")
        local sureCallback = function ()
            -- 检测跳转限制，目标作战层不是该层
            if self.CurrSelectXFightLayer:CheckIsOwnFighting() and luckFightLayer ~= self.CurrSelectXFightLayer then 
                XUiManager.TipError(CS.XTextManager.GetText("RiftFightLimit"))
                return
            end
            -- 跳转到指定层
            self:AutoPositioningByLayerId(luckFightLayer:GetId())
            self:RefreshDynamicTable()
            self:Refresh()
        end
        XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
        return
    end

    -- 开始作战状态检测
    if not self.CurrSelectXFightLayer:CheckHasStarted() then
        XUiManager.TipError(CS.XTextManager.GetText("RiftLuckNotFightLimit"))
        return
    end

    -- 幸运值检测
    if self.XChapter:GetLuckValueProgress() < 1 then
        XUiManager.TipError(CS.XTextManager.GetText("RiftLuckValueLimit"))
        return
    end

    XDataCenter.RiftManager.RiftStartLuckyNodeRequest(function ()
        self:Refresh()
    end)  
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
        XLuaUiManager.Open("UiTip", data)

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

function XUiRiftFightLayerSelect:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.RiftGold,
            XDataCenter.ItemManager.ItemId.RiftCoin
        },
        handler(self, self.UpdateAssetPanel),
        self.AssetActivityPanel
    )
end

function XUiRiftFightLayerSelect:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.RiftGold,
            XDataCenter.ItemManager.ItemId.RiftCoin
        }
    )
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

return XUiRiftFightLayerSelect