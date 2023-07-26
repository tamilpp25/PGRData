--大秘境层结算界面
local XUiRiftSettleWin = XLuaUiManager.Register(XLuaUi, "UiRiftSettleWin")
local XUiGridRiftSettlePlugin = require("XUi/XUiRift/Grid/XUiGridRiftSettlePlugin")

function XUiRiftSettleWin:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
    self.GridRewardList = {}
end

function XUiRiftSettleWin:InitButton()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnAgain, self.OnBtnAgainClick)
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNextClick)
    self:RegisterClickEvent(self.BtnJump, self.OnBtnJumpClick)
    self:RegisterClickEvent(self.BtnMopup, self.OnBtnMopupClick) -- 派遣(扫荡)

end

function XUiRiftSettleWin:InitDynamicTable()
    -- 选择作战层的滑动列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelPluginScrollView)
    self.DynamicTable:SetProxy(XUiGridRiftSettlePlugin, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftSettleWin:OnStart(layerId, riftSettleResult, ignoreNextBtn, isMopUp)
    -- 只有正常战斗流程打完作战层才会有settleData
    self.Data = riftSettleResult
    self.LayerId = layerId
    self.IgnoreNextBtn = ignoreNextBtn
    self.IsMopUp = isMopUp
end

function XUiRiftSettleWin:OnEnable()
    self:Refresh()
    -- 打开层结算界面，说明层作战结束，清除关卡数据, 在刷新ui之后清除，因为清除数据要在数据展示之后
    XDataCenter.RiftManager.ClearStageGroupRelationshipChain()
end

function XUiRiftSettleWin:Refresh()
    local riftSettleResult = self.Data
    local currXFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(self.LayerId)
    self.CurrXFightLayer = currXFightLayer
    self.TxtName.text = CS.XTextManager.GetText("RiftDepthSettle", currXFightLayer:GetId())
    self.TxtStageTime.text = XUiHelper.GetTime(math.floor(currXFightLayer:GetTotalStagePassTime()))
    
    local isFirst = nil
    if riftSettleResult then
        -- 跃升相关
        local isZoom = currXFightLayer:GetType() == XRiftConfig.LayerType.Zoom
        self.PanelPointHistory.gameObject:SetActiveEx(isZoom)
        self.PanelPointNow.gameObject:SetActiveEx(isZoom)
        if isZoom then
            self.TxtPointHistory.text = currXFightLayer:GetId()
            local jumpToLayerId = currXFightLayer:GetId() + riftSettleResult.JumpLayerRecord.AddOrderMax
            self.TxtPointNow.text = jumpToLayerId
            self.JumpToLayerId = jumpToLayerId 
        end
        
        -- 首通奖励
        isFirst = riftSettleResult.RewardedLayerIds and riftSettleResult.RewardedLayerIds[1]
        if isFirst then
            local rewardId = currXFightLayer:GetConfig().RewardId
            local rewards = {}
            if rewardId > 0 then
                rewards = XRewardManager.GetRewardList(rewardId) 
            end
            if rewards then
                for i, item in ipairs(rewards) do
                    local grid
                    if self.GridRewardList[i] then
                        grid = self.GridRewardList[i]
                    else
                        local ui = CS.UnityEngine.Object.Instantiate(self.GridCommonFirst, self.GridCommonFirst.parent)
                        grid = XUiGridCommon.New(self, ui)
                        self.GridRewardList[i] = grid
                    end
                    grid:Refresh(item)
                    grid.GameObject:SetActive(true)
                end
            end
            self.GridCommonFirst.gameObject:SetActive(false)
        end
    end
    self.PanelFirstPass.gameObject:SetActive(isFirst)
    if isFirst then -- 设置首通提示Trigger
        XDataCenter.RiftManager.SetFirstPassChapterTrigger(currXFightLayer:GetId())
    end
    
    -- 金币
    self.GridCommonPass:Find("PanelTxt/TxtCount"):GetComponent("Text").text = currXFightLayer:GetConfig().CoinCount
    local gridCommonPass = XUiGridCommon.New(self, self.GridCommonPass)
    local data = 
    {
        Count = currXFightLayer:GetConfig().CoinCount,
        TemplateId = XDataCenter.ItemManager.ItemId.RiftGold,
        RewardType = 1
    }
    gridCommonPass:Refresh(data)
    
    -- 分解插件
    self:RefreshDynamicTable(currXFightLayer)
    
    self:ShowFuncUnlockPanel()
    
    -- 底部按钮状态
    local nextLayerId = self.CurrXFightLayer:GetId() + 1 
    local nextFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(nextLayerId)
    self.NextXFightLayer = nextFightLayer
    local isShowBtnNext = nextFightLayer and not nextFightLayer:CheckHasLock() and not self.CurrXFightLayer:CheckIsLastLayerInChapter()
    self.BtnNext.gameObject:SetActiveEx(isShowBtnNext and not self.JumpToLayerId and not self.IgnoreNextBtn)
    self.BtnJump.gameObject:SetActiveEx(self.JumpToLayerId and not self.IgnoreNextBtn)
    self.BtnAgain.gameObject:SetActiveEx(not self.IsMopUp)
    self.BtnMopup.gameObject:SetActiveEx(self.IsMopUp)
    self.BtnMopup:SetNameByGroup(0, CS.XTextManager.GetText("RiftMopup", XDataCenter.RiftManager.GetSweepLeftTimes(), XDataCenter.RiftManager.GetCurrentConfig().DailySweepTimes))
end

function XUiRiftSettleWin:RefreshDynamicTable(currXFightLayer)
    self.RecordDropPluginList = currXFightLayer:GetRecordPluginDrop()
    self.DynamicTable:SetDataSource(self.RecordDropPluginList)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiRiftSettleWin:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RecordDropPluginList[index], index)
    end
end

-- 显示功能解锁界面
function XUiRiftSettleWin:ShowFuncUnlockPanel()
    if self.Data == nil or self.Data.RewardedLayerIds == nil or #self.Data.RewardedLayerIds == 0 then
        return
    end

    local showItemDic = {}

    -- 通关层解锁
    local funcUnlockCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftFuncUnlock)
    for _, unlockCfg in ipairs(funcUnlockCfgs) do
        local isUnlock = XConditionManager.CheckCondition(unlockCfg.Condition)
        if isUnlock then
            local conditionCfg = XConditionManager.GetConditionTemplate(unlockCfg.Condition)
            local layerId = conditionCfg.Params[2]
            for _, passLayerId in ipairs(self.Data.RewardedLayerIds) do
                if passLayerId == layerId then
                    local itemId = unlockCfg.ItemId
                    if showItemDic[itemId] then 
                        showItemDic[itemId].Count = showItemDic[itemId].Count + 1
                    else
                        showItemDic[itemId] = { TemplateId = itemId, Count = 1 }
                    end
                end
            end
        end
    end

    -- 服务器下发奖励道具
    for _, layerId in pairs(self.Data.RewardedLayerIds) do
        local xFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(layerId)
        local rewardId = xFightLayer:GetConfig().RewardId
        local rewards = XRewardManager.GetRewardList(rewardId)
        if rewards then
            for _, item in ipairs(rewards) do
                if item.TemplateId == XDataCenter.ItemManager.ItemId.RiftLoadLimit or item.TemplateId == XDataCenter.ItemManager.ItemId.RiftAttributeLimit then
                    local itemId = item.TemplateId
                    if showItemDic[itemId] then 
                        showItemDic[itemId].Count = showItemDic[itemId].Count + item.Count
                    else
                        showItemDic[itemId] = { TemplateId = itemId, Count = item.Count }
                    end
                end
            end
        end
    end

    if next(showItemDic) then
        local showItemList = {}
        for _, item in pairs(showItemDic) do
            table.insert(showItemList, item)
        end
        XLuaUiManager.Open("UiRiftFuncUnlockTips", showItemList)
    end
end

function XUiRiftSettleWin:OnBtnAgainClick()
    local doFun = function ()
        if self.CurrXFightLayer:CheckIsOwnFighting() then
            XLog.Error("数据错误，没有层结算完毕就再次请求刷新作战层数据 ")
            return
        end
        CS.XFight.ExitForClient(true)
        -- 直接再进入战斗，关闭界面会在退出战斗前通过remove移除
        XDataCenter.RiftManager.RiftStartLayerRequest(self.CurrXFightLayer:GetId(), function ()
            local firstStageGroup = self.CurrXFightLayer:GetAllStageGroups()[1]
            XDataCenter.RiftManager.SetCurrSelectRiftStage(firstStageGroup)
            XDataCenter.RiftManager.EnterFight()
        end)
    end

    local xChapter = self.CurrXFightLayer:GetParent()
    XDataCenter.RiftManager.CheckDayTipAndDoFun(xChapter, doFun)
end

function XUiRiftSettleWin:OnBtnNextClick()
    if self.NextXFightLayer and not self.NextXFightLayer:CheckHasLock() then
        XDataCenter.RiftManager.SetNewLayerTrigger(self.NextXFightLayer:GetId()) -- 设置自动定位层级的trigger
    end
    self:Close()
end

function XUiRiftSettleWin:OnBtnJumpClick()
    if self.JumpToLayerId then
        XDataCenter.RiftManager.SetNewLayerTrigger(self.JumpToLayerId) -- 设置自动定位层级的trigger
    end
    self:Close()
end

function XUiRiftSettleWin:OnBtnCloseClick()
    self:Close()
end

function XUiRiftSettleWin:OnBtnMopupClick()
    if XDataCenter.RiftManager.GetSweepLeftTimes() <= 0 then
        XUiManager.TipError(CS.XTextManager.GetText("RiftSweepTimesLimit"))
        return
    end
    if not self.CurrXFightLayer:CheckHasPassed() then
        XUiManager.TipError(CS.XTextManager.GetText("RiftSweepFirstPassLimit"))
        return
    end
    if self.CurrXFightLayer:CheckIsOwnFighting() then
        XUiManager.TipError(CS.XTextManager.GetText("RiftSweepDataLimit"))
        return
    end
    
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("RiftSweepConfirm")
    local sureCallback = function ()
        self:Close()
        -- 必须要先进入战斗才能再次扫荡
        XDataCenter.RiftManager.RiftStartLayerRequest(self.CurrXFightLayer:GetId(), function ()
            XDataCenter.RiftManager.RiftSweepLayerRequest(self.CurrXFightLayer:GetId())
        end)
    end
    XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
end

function XUiRiftSettleWin:OnDestroy()
    CS.XFight.ExitForClient(true)
end

return XUiRiftSettleWin