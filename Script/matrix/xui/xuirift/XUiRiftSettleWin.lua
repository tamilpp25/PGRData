--大秘境层结算界面
local XUiRiftSettleWin = XLuaUiManager.Register(XLuaUi, "UiRiftSettleWin")
local XUiGridRiftSettlePlugin = require("XUi/XUiRift/Grid/XUiGridRiftSettlePlugin")

function XUiRiftSettleWin:OnAwake()
    self:InitButton()
    self.GridRewardList = {}
end

function XUiRiftSettleWin:InitButton()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnAgain, self.OnBtnAgainClick)
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNextClick)
    self:RegisterClickEvent(self.BtnJump, self.OnBtnJumpClick)
    self:RegisterClickEvent(self.PanelPluginTip, self.OnHidePluginTip)
    self:RegisterClickEvent(self.BtnMopup, self.OnBtnMopupClick) -- 派遣(扫荡)
    self:RegisterClickEvent(self.BtnContinue, self.OnBtnContinueClick)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)

end

function XUiRiftSettleWin:OnStart(layerId, riftSettleResult, ignoreNextBtn, isMopUp, sweepData, callBack)
    self._CallBack = callBack
    -- 只有正常战斗流程打完作战层才会有settleData
    self.Data = riftSettleResult
    self.LayerId = layerId
    self.IgnoreNextBtn = ignoreNextBtn
    self.IsMopUp = isMopUp
    self.SweepData = sweepData
    self.IsLuckyStage = self.Data and self.Data.IsLuckyNode
end

function XUiRiftSettleWin:OnEnable()
    self:Refresh()
    self:InitPluginShow()
    self:OnHidePluginTip()
    self:SetMouseVisible()
    -- 打开层结算界面，说明层作战结束，清除关卡数据, 在刷新ui之后清除，因为清除数据要在数据展示之后
    XDataCenter.RiftManager.ClearStageGroupRelationshipChain(self.LayerId)
end

function XUiRiftSettleWin:InitPluginShow()
    self._NeedPlayAnimation = true
    self._PluginShowMap = {}
    self.PanelShow.gameObject:SetActiveEx(true)
    self.PanelWin.gameObject:SetActiveEx(false)
    local datas = self.Data and self.Data.PluginDropRecords or self.CurrXFightLayer:GetRecordPluginDrop()
    self:RefreshTemplateGrids(self.GridShow, datas, self.GridShow.parent, nil, "UiRiftSettleWinPluginShow", function(grid, data)
        local pluginTip = require("XUi/XUiRift/Grid/XUiGridRiftPluginDrop").New(grid.GridRiftPluginTips, self)
        pluginTip:Refresh(data)
        pluginTip:RefreshBg()
        table.insert(self._PluginShowMap, pluginTip)
    end)
end

function XUiRiftSettleWin:Refresh()
    local riftSettleResult = self.Data
    local currXFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(self.LayerId)
    self.CurrXFightLayer = currXFightLayer
    self.TxtName.text = CS.XTextManager.GetText("RiftDepthSettle", currXFightLayer:GetId())
    self.TxtStageTime.text = XUiHelper.GetTime(math.floor(currXFightLayer:GetTotalStagePassTime()))

    local datas = {}
    local isFirst = nil
    if riftSettleResult then
        if not self.IsLuckyStage then
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
        end
        
        -- 首通奖励
        isFirst = riftSettleResult.RewardedLayerIds and riftSettleResult.RewardedLayerIds[1]
        if isFirst then
            local rewardId = currXFightLayer:GetConfig().RewardId
            if rewardId > 0 then
                local rewards = XRewardManager.GetRewardList(rewardId)
                for _, v in pairs(rewards) do
                    table.insert(datas, { Reward = v })
                end
            end
            if riftSettleResult.FirstPassPluginDropRecords then
                for _, v in pairs(riftSettleResult.FirstPassPluginDropRecords) do
                    table.insert(datas, { Plugin = v })
                end
            end
            self:RefreshTemplateGrids(self.GridFirst, datas, self.GridFirst.parent, nil, "UiRiftSettleWinFirstReward", function(grid, data)
                if data.Reward then
                    local reward = XUiGridCommon.New(self, grid.Grid256New)
                    reward:Refresh(data.Reward)
                    grid.TxtOther.gameObject:SetActiveEx(false)
                    grid.PanelReward.gameObject:SetActiveEx(true)
                    grid.PanelPlugin.gameObject:SetActiveEx(false)
                else
                    local plugin = XUiGridRiftSettlePlugin.New(grid.Transform, self)
                    plugin:Refresh(data.Plugin)
                    self:RegisterClickEvent(grid.Transform, function()
                        self:OnShowPluginTip(data.Plugin, grid.BtnTip)
                    end)
                    grid.PanelReward.gameObject:SetActiveEx(false)
                    grid.PanelPlugin.gameObject:SetActiveEx(true)
                end
            end)
        end
    end
    self.PanelFirstPass.gameObject:SetActive(isFirst)
    if isFirst then -- 设置首通提示Trigger
        XDataCenter.RiftManager.SetFirstPassChapterTrigger(currXFightLayer:GetId())
    end
    
    -- 金币
    datas = {}
    table.insert(datas, self:CreateReward(currXFightLayer:GetConfig().CoinCount))
    local coinRaise = 0
    if riftSettleResult then
        coinRaise = riftSettleResult.CoinRaise
    elseif self.SweepData then
        coinRaise = self.SweepData.CoinRaise
    end
    if XTool.IsNumberValid(coinRaise) then
        table.insert(datas, self:CreateReward(coinRaise, true))
    end
    self:RefreshTemplateGrids(self.GridPass, datas, self.GridPass.parent, nil, "UiRiftSettleWinPassReward", function(grid, data)
        local reward = XUiGridCommon.New(self, grid.GridCommonPass)
        reward:Refresh(data)
        if data.isAddition then
            grid.TxtOrigin.gameObject:SetActiveEx(true)
            grid.TxtOrigin.text = XUiHelper.GetText("RiftDropAddition")
        else
            grid.TxtOrigin.gameObject:SetActiveEx(false)
        end
    end)

    -- 分解插件
    self:RefreshTemplateGrids(self.GridPlugin, currXFightLayer:GetRecordPluginDrop(), self.GridPlugin.parent, nil, "UiRiftSettleWinPlugin", function(grid, data)
        local plugin = XUiGridRiftSettlePlugin.New(grid.Transform, self)
        plugin:Refresh(data)
        self:RegisterClickEvent(grid.Transform, function()
            self:OnShowPluginTip(data, grid.BtnTip)
        end)
    end)

    datas = {}
    local changeCount, additionCount = currXFightLayer:GetRecordPluginDropChangeCount()
    if changeCount > 0 then
        table.insert(datas, self:CreateReward(changeCount))
    end
    if additionCount > 0 then
        table.insert(datas, self:CreateReward(additionCount, true))
    end
    local hasChanged = #datas > 0
    self.TxtTransformTitle.gameObject:SetActiveEx(hasChanged)
    self.PanelPointList.gameObject:SetActiveEx(hasChanged)
    if hasChanged then
        self:RefreshTemplateGrids(self.GridChange, datas, self.GridChange.parent, nil, "", function(grid, data)
            local reward = XUiGridCommon.New(self, grid.GridCommonPass)
            reward:Refresh(data)
            if data.isAddition then
                grid.TxtOrigin.gameObject:SetActiveEx(true)
                grid.TxtOrigin.text = XUiHelper.GetText("RiftChangeAddition")
            else
                grid.TxtOrigin.gameObject:SetActiveEx(false)
            end
        end)
    end
    
    self:ShowFuncUnlockPanel()
    
    -- 底部按钮状态
    local nextLayerId = self.CurrXFightLayer:GetId() + 1 
    local nextFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(nextLayerId)
    self.NextXFightLayer = nextFightLayer
    local isShowBtnNext = nextFightLayer and not nextFightLayer:CheckHasLock() and not self.CurrXFightLayer:CheckIsLastLayerInChapter()
    self.BtnNext.gameObject:SetActiveEx(isShowBtnNext and not self.JumpToLayerId and not self.IgnoreNextBtn and not self.IsLuckyStage)
    self.BtnJump.gameObject:SetActiveEx(self.JumpToLayerId and not self.IgnoreNextBtn and not self.IsLuckyStage)
    self.BtnAgain.gameObject:SetActiveEx(not self.IsMopUp and not self.IsLuckyStage)
    self.BtnMopup.gameObject:SetActiveEx(self.IsMopUp and not self.IsLuckyStage)
    self.BtnMopup:SetNameByGroup(0, CS.XTextManager.GetText("RiftMopup", XDataCenter.RiftManager.GetSweepLeftTimes(), XDataCenter.RiftManager.GetCurrentConfig().DailySweepTimes))
end

function XUiRiftSettleWin:CreateReward(coinCount, isAddition)
    return
    {
        Count = coinCount,
        TemplateId = XDataCenter.ItemManager.ItemId.RiftGold,
        RewardType = 1,
        isAddition = isAddition
    }
end

function XUiRiftSettleWin:OnShowPluginTip(dropData, dimObj)
    self.PanelPluginTip.gameObject:SetActiveEx(true)
    if not self._PluginTip then
        ---@type XUiGridRiftPluginDrop
        self._PluginTip = require("XUi/XUiRift/Grid/XUiGridRiftPluginDrop").New(self.GridRiftPluginTips, self)
    end
    self._PluginTip:Refresh(dropData)

    local pos = self.GridRiftPluginTips.parent:InverseTransformPoint(dimObj.transform.position)
    local posX = pos.x - dimObj.rect.width * dimObj.localScale.x * dimObj.pivot.x
    local posY = pos.y + dimObj.rect.height * dimObj.localScale.y * (1 - dimObj.pivot.y)
    self.GridRiftPluginTips.localPosition = Vector3(posX, posY, 0)
end

function XUiRiftSettleWin:OnHidePluginTip()
    self.PanelPluginTip.gameObject:SetActiveEx(false)
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

            local xTeam
            local currSelectRiftStageGroup = XDataCenter.RiftManager.GetCurrSelectRiftStageGroup()
            if currSelectRiftStageGroup:GetType() == XRiftConfig.StageGroupType.Multi then
                xTeam = XDataCenter.RiftManager.GetMultiTeamData()[1]
            else
                xTeam = XDataCenter.RiftManager.GetSingleTeamData(self.IsLuckyStage)
            end
            XDataCenter.RiftManager.EnterFight(xTeam)
        end)
    end

    local xChapter = self.CurrXFightLayer:GetParent()
    XDataCenter.RiftManager.CheckDayTipAndDoFun(xChapter, doFun)
end

function XUiRiftSettleWin:OnBtnNextClick()
    if self.NextXFightLayer and not self.NextXFightLayer:CheckHasLock() then
        local nextId = self.NextXFightLayer:GetId()
        XDataCenter.RiftManager.SetNewLayerTrigger(nextId) -- 设置自动定位层级的trigger
        XDataCenter.RiftManager.SetOpenLayerSelectTrigger(nextId)
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
    XDataCenter.RiftManager.SetOpenLayerSelectTrigger(self.CurrXFightLayer:GetId())
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
            XDataCenter.RiftManager.RiftSweepLayerRequest()
        end)
    end
    XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
end

function XUiRiftSettleWin:OnBtnContinueClick()
    -- 待接：翻卡动画
    if self._NeedPlayAnimation then
        self._NeedPlayAnimation = false
        for _, v in pairs(self._PluginShowMap) do
            v:DoOverturn()
        end
        return
    end
    self:OnBtnSkipClick()
end

function XUiRiftSettleWin:OnBtnSkipClick()
    -- 待接：等动画播放完才可以点击
    self.PanelShow.gameObject:SetActiveEx(false)
    self.PanelWin.gameObject:SetActiveEx(true)
end

function XUiRiftSettleWin:OnDestroy()
    CS.XFight.ExitForClient(true)
end

function XUiRiftSettleWin:Close()
    self.Super.Close(self)
    if self._CallBack then
        self._CallBack()
    end
end

function XUiRiftSettleWin:SetMouseVisible()
    -- 这里只有PC端开启了键鼠以后才能获取到设备
    if CS.XFight.Instance and CS.XFight.Instance.InputSystem then
        local inputKeyboard = CS.XFight.Instance.InputSystem:GetDevice(typeof(CS.XInputKeyboard))
        inputKeyboard.HideMouseEvenByDrag = false
    end
end

return XUiRiftSettleWin