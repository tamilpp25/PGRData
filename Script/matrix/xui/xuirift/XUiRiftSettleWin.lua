local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiRiftSettleWin:XLuaUi 大秘境层结算界面
---@field _Control XRiftControl
local XUiRiftSettleWin = XLuaUiManager.Register(XLuaUi, "UiRiftSettleWin")
local XUiGridRiftSettlePlugin = require("XUi/XUiRift/Grid/XUiGridRiftSettlePlugin")

function XUiRiftSettleWin:OnAwake()
    self:InitButton()
    self.GridRewardList = {}
end

function XUiRiftSettleWin:InitButton()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnAgain, self.OnBtnAgainClick)
    self:RegisterClickEvent(self.PanelPluginTip, self.OnHidePluginTip)
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
end

function XUiRiftSettleWin:InitPluginShow()
    self._NeedPlayAnimation = true
    self._PluginShowMap = {}
    self.PanelShow.gameObject:SetActiveEx(true)
    self.PanelWin.gameObject:SetActiveEx(false)
    local datas = self.Data and self.Data.PluginDropRecords or self.CurrXFightLayer:GetRecordPluginDrop()
    table.sort(datas, handler(self._Control, self._Control.SortDropPluginBase))
    self:RefreshTemplateGrids(self.GridShow, datas, self.GridShow.parent, nil, "UiRiftSettleWinPluginShow", function(grid, data)
        local pluginTip = require("XUi/XUiRift/Grid/XUiGridRiftPluginDrop").New(grid.GridRiftPluginTips, self)
        pluginTip:Refresh(data)
        pluginTip:RefreshBg()
        pluginTip:SetClickCallBack(handler(self, self.OnBtnContinueClick))
        table.insert(self._PluginShowMap, pluginTip)
    end)
end

function XUiRiftSettleWin:Refresh()
    local riftSettleResult = self.Data
    local currXFightLayer = self._Control:GetEntityFightLayerById(self.LayerId)
    self.CurrXFightLayer = currXFightLayer
    self.TxtName.text = currXFightLayer:GetConfig().Name
    local passTime = 0
    if self.IsLuckyStage then
        passTime = self._Control:GetLuckPassTime()
    else
        passTime = currXFightLayer:GetTotalStagePassTime()
    end
    self.TxtStageTime.text = XUiHelper.GetTime(math.floor(passTime))

    local datas = {}
    local isFirst = nil
    if riftSettleResult then
        if not self.IsLuckyStage then
            self.PanelPointHistory.gameObject:SetActiveEx(false)
            self.PanelPointNow.gameObject:SetActiveEx(false)
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
        self._Control:SetFirstPassChapterTrigger(currXFightLayer:GetFightLayerId())
    end
    
    -- 金币
    datas = {}
    if not self.IsLuckyStage then
        table.insert(datas, self:CreateReward(currXFightLayer:GetConfig().CoinCount))
    end
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
    local pluginDrops = currXFightLayer:GetRecordPluginDrop()
    table.sort(pluginDrops, handler(self._Control, self._Control.SortDropPlugin))
    self:RefreshTemplateGrids(self.GridPlugin, pluginDrops, self.GridPlugin.parent, nil, "UiRiftSettleWinPlugin", function(grid, data)
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
    local nextLayerId = self.CurrXFightLayer:GetFightLayerId() + 1
    local nextFightLayer = self._Control:GetEntityFightLayerById(nextLayerId)
    self.NextXFightLayer = nextFightLayer
    self.BtnJump.gameObject:SetActiveEx(false)
    self.BtnAgain.gameObject:SetActiveEx(not self.IsMopUp and not self.IsLuckyStage)
    self.BtnMopup.gameObject:SetActiveEx(false)
    --self.BtnMopup:SetNameByGroup(0, CS.XTextManager.GetText("RiftMopup", self._Control:GetSweepLeftTimes(), self._Control:GetCurrentConfig().DailySweepTimes))
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
    local funcUnlockCfgs = self._Control:GetFuncUnlockConfigs()
    for _, unlockCfg in ipairs(funcUnlockCfgs) do
        if XTool.IsNumberValid(unlockCfg.Condition) then
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
    end

    -- 服务器下发奖励道具
    for _, layerId in pairs(self.Data.RewardedLayerIds) do
        local xFightLayer = self._Control:GetEntityFightLayerById(layerId)
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
        -- 直接再进入战斗，关闭界面会在退出战斗前通过remove移除
        local firstStageGroup = self.CurrXFightLayer:GetStageGroup()
        self._Control:SetCurrSelectRiftStage(firstStageGroup)

        local xTeam = self._Control:GetSingleTeamData(self.IsLuckyStage)
        self._Control:EnterFight(xTeam)
    end

    local xChapter = self.CurrXFightLayer:GetParent()
    self._Control:CheckDayTipAndDoFun(xChapter, doFun)
end

function XUiRiftSettleWin:OnBtnCloseClick()
    self:Close()
end

function XUiRiftSettleWin:OnBtnContinueClick()
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
    CS.UnityEngine.Cursor.lockState = CS.UnityEngine.CursorLockMode.None
    CS.UnityEngine.Cursor.visible = true
end

return XUiRiftSettleWin