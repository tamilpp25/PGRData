local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelGachaLiverDrawBase: XUiNode
---@field _Control XGachaCanLiverControl
---@field GachaCfg XTableGacha
---@field RootUi XLuaUi
local XUiPanelGachaLiverDrawBase = XClass(XUiNode, 'XUiPanelGachaLiverDrawBase')

local XUiGridGachaLiverDrawButton = require('XUi/XUiGachaCanLiver/XUiGachaCanLiverMain/XUiGridGachaLiverDrawButton')

local DrawState = {
    Show = 1,
    Result = 2
}

--region 生命周期
function XUiPanelGachaLiverDrawBase:OnStart(gachaId, isTimelimit, rootUi, isHideTimelimit)
    self.BtnCharater.CallBack = handler(self, self.OnBtnCharacterClick)
    self.BtnChange.CallBack = handler(self, self.OnBtnChangeClick)
    self.BtnShop.CallBack = handler(self ,self.OnBtnShopClick)
    self.BtnTask.CallBack = handler(self, self.OnBtnTaskClick)
    self.BtnMore.CallBack = handler(self, self.OnBtnMoreClick)
    self.RootUi = rootUi
    self.IsHideTimeLimit = isHideTimelimit
    self:InitDrawData(gachaId, isTimelimit)
    self:InitPanelAssets()
    self:InitShopRewardShow()
    self:InitDrawButtons()
    self:InitReddot()

    if self.IsHideTimeLimit then
        self.BtnChange.gameObject:SetActiveEx(false)
    end

    if not self.IsHideTimeLimit then
        -- 开启踢出检查
        self._Control:StartTimelimitDrawLeftTimer()
    end
    
    self._IsStartRun = true
end

function XUiPanelGachaLiverDrawBase:OnEnable()
    self:RefreshAll()

    if self._IsStartRun then
        self._IsStartRun = false
        return
    end

    if self.RootUi.Name == 'UiGachaCanLiverMain' then
        self.RootUi:PlayAnimationWithMask('Enable')
    end
end

function XUiPanelGachaLiverDrawBase:OnDisable()
    self:StopTimelimitDrawLeftTimer()
end
--endregion

--region 初始化
function XUiPanelGachaLiverDrawBase:InitDrawData(gachaId, isTimelimit)
    self.GachaId = gachaId
    self.GachaCfg = XGachaConfigs.GetGachaCfgById(self.GachaId)
    self._Control:SetCurShowGachaId(self.GachaId)
    self.IsTimeLimit = isTimelimit
    self._Control:SetCurShowGachaIsTimelimit(isTimelimit)

    if self.IsTimeLimit then
        self.IsOpen, self.LockDesc = XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsUnlock(self.GachaId)
    else
        self.IsOpen = true
    end
end

function XUiPanelGachaLiverDrawBase:InitPanelAssets()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(self._Control:GetConfigPanelAssetItemIds(XMVCA.XGachaCanLiver:GetCurActivityId()), self.PanelSpecialTool, self)
end

function XUiPanelGachaLiverDrawBase:InitShopRewardShow()
    local shopRewardShowId = self._Control:GetCurActivityShopShowRewardId()

    if XTool.IsNumberValid(shopRewardShowId) then
        local rewardGoodsList = XRewardManager.GetRewardListNotCount(shopRewardShowId)
        
        XUiHelper.RefreshCustomizedList(self.GridReward.transform.parent, self.GridReward, rewardGoodsList and #rewardGoodsList or 0, function(index, go)
            local grid = XUiGridCommon.New(self.RootUi, go)
            grid:Refresh(rewardGoodsList[index])
        end)
    else
        XLog.Error('商品预览奖励Id配置无效：'..tostring(shopRewardShowId)..' 当前活动Id：'..tostring(XMVCA.XGachaCanLiver:GetCurActivityId()))
    end
end

function XUiPanelGachaLiverDrawBase:InitDrawButtons()
    self._OneDrawBtn = XUiGridGachaLiverDrawButton.New(self.BtnDraw1, self, XEnumConst.GachaCanLiver.DrawButtonType.One)
    self._OneDrawBtn:Open()
    
    self._TenDrawBtn = XUiGridGachaLiverDrawButton.New(self.BtnDraw2, self, XEnumConst.GachaCanLiver.DrawButtonType.Ten)
    self._TenDrawBtn:Open()
end

function XUiPanelGachaLiverDrawBase:InitReddot()
    self._ShopReddotId = self:AddRedPointEvent(self.BtnShop, self.OnShopReddotEvent, self, { XRedPointConditions.Types.CONDITION_GACHACANLIVER_SHOP })
    self._TaskReddotId = self:AddRedPointEvent(self.BtnTask, self.OnTaskReddotEvent, self, { XRedPointConditions.Types.CONDITION_GACHACANLIVER_TASK })
    self._TimelimitDrawReddotId = self:AddRedPointEvent(self.BtnChange, self.OnTimelimitReddotEvent, self, { XRedPointConditions.Types.CONDITION_GACHACANLIVER_TIMELIMITDRAW })
end
--endregion

--region 界面刷新

--- 检查卡池是否抽完，并刷新
function XUiPanelGachaLiverDrawBase:RefreshAllWhithCheckDone()
    if self.IsTimeLimit then
        local isSellOutAllRare = XDataCenter.GachaManager.GetGachaIsSoldOutRare(self.GachaId)

        if isSellOutAllRare then
            XLuaUiManager.Open('UiGachaCanLiverPopupDrawOver', self.GachaId)
            self:InitDrawData(self._Control:GetCurActivityLatestTimelimitGachaId(), true)
        end
    end
    
    self:RefreshAll()
end

function XUiPanelGachaLiverDrawBase:RefreshAll()
    self:RefreshDrawSpecialRewardsShow()
    self:RefreshDrawButtonsState()
    self:RefreshDifferUiShow()
    self:RefreshHadDoneDrawTimes()
    self:RefreshReddot()
    self:RefreshTaskButtonState()
end

function XUiPanelGachaLiverDrawBase:RefreshDifferUiShow()
    self.PanelTitleNormal.gameObject:SetActiveEx(not self.IsTimeLimit)
    self.PanelTitleTimeLimited.gameObject:SetActiveEx(self.IsTimeLimit)
    
    self.PanelUnlockCountShow.gameObject:SetActiveEx(self.IsTimeLimit)
    self.PanelLock.gameObject:SetActiveEx(not self.IsOpen)

    if not self.IsOpen then
        self.TxtLockTips.text = self.LockDesc
    end

    if self.IsTimeLimit then
        self:_RefreshTimelimitDrawShow()
    else
        self:_RefreshResistentDrawShow()
    end
end

--- 刷新常驻卡池的显示
function XUiPanelGachaLiverDrawBase:_RefreshResistentDrawShow()
    self:StartTimelimitDrawLeftTimer()
    local timelimitGachaIndex = self._Control:GetCurActivityLatestTimelimitGachaIndex()
    local drawNamFormat = XGachaConfigs.GetClientConfig('CanLiverDrawName', 2)
    self.BtnChange:SetNameByGroup(1, XUiHelper.FormatText(drawNamFormat, string.format('%02d', timelimitGachaIndex)))
    
    local timelimitGachaId = self._Control:GetCurActivityLatestTimelimitGachaId()
    local hasAnyTimelimitGachaUnlock = XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsUnlock(timelimitGachaId)

    self.BtnChange:SetButtonState(hasAnyTimelimitGachaUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnShop:ShowTag(false)
    -- 如果入口转移了，需要点掉蓝点
    if XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsOutTime() then
        XMVCA.XGachaCanLiver:SetReddotHideByKey(XEnumConst.GachaCanLiver.ReddotKey.ResistenceDrawNoEnterAfterTLClsoed)
    end
    
    if self.BtnChangeStateCtrl then
        self.BtnChangeStateCtrl:ChangeState('TimeLimit')
    end
    
    -- 设置背景图
    local bgPath = XGachaConfigs.GetClientConfig('LilithDrawMainFullBgs', 1)
    if self.RImgBg and not string.IsNilOrEmpty(bgPath) then
        self.RImgBg:SetRawImage(bgPath)
    end
end

--- 刷新限时卡池的显示
function XUiPanelGachaLiverDrawBase:_RefreshTimelimitDrawShow()
    self.TxtUnLockNum.text = self._Control:GetCurActivityTimelimitGachaUnlockCount()
    self.BtnChange:SetNameByGroup(0, '')
    self.BtnChange:SetNameByGroup(1, XGachaConfigs.GetClientConfig('CanLiverDrawName', 1))
    self.BtnChange:SetButtonState(CS.UiButtonState.Normal)
    self.PanelTime.gameObject:SetActiveEx(true)
    self.BtnShop:ShowTag(true)
    
    -- 显示索引图标
    if self.RawImgTitleNum then
        local timelimitGachaIndex = self._Control:GetCurActivityLatestTimelimitGachaIndex()
        local iconAddress = XGachaConfigs.GetClientConfig('LilithTimeLimitDrawTitleIcons', timelimitGachaIndex)

        if not string.IsNilOrEmpty(iconAddress) then
            self.RawImgTitleNum:SetRawImage(iconAddress)
        end
        
        -- 判断是否是最后一个限时卡池
        self.ImgMax.gameObject:SetActiveEx(self._Control:GetCurActivityTimelimitGachaLockCount() <= 0)
    end

    if self.IsOpen then
        XMVCA.XGachaCanLiver:SetReddotHideByKey(XEnumConst.GachaCanLiver.ReddotKey.TimelimitDrawNoEnterAfterUnLock)
    end
    self:StartTimelimitDrawLeftTimer()

    XMVCA.XGachaCanLiver:SetReddotHideByKey(XEnumConst.GachaCanLiver.ReddotKey.TimelimitDrawNoEnter)

    if self.BtnChangeStateCtrl then
        self.BtnChangeStateCtrl:ChangeState('Normal')
    end

    -- 设置背景图
    local bgPath = XGachaConfigs.GetClientConfig('LilithDrawMainFullBgs', 2)
    if self.RImgBg and not string.IsNilOrEmpty(bgPath) then
        self.RImgBg:SetRawImage(bgPath)
    end
end

--- 刷新卡池特殊奖励显示
function XUiPanelGachaLiverDrawBase:RefreshDrawSpecialRewardsShow(gachaId)
    if XTool.IsNumberValid(gachaId) then
        self.GachaId = gachaId
    end

    if not XTool.IsTableEmpty(self._SpecialRewardGrids) then
        for i, v in pairs(self._SpecialRewardGrids) do
            v.GameObject:SetActiveEx(false)
        end
    end

    if XTool.IsNumberValid(self.GachaId) then
        local dataList = self._Control:GetGachaSpecialRewardInfoList(self.GachaId)

        if self._SpecialRewardGrids == nil then
            self._SpecialRewardGrids = {}
        end
        
        --- 处理显示数目，如果有特殊奖励，且限制数目的话，取两者数目最小的值
        local count = dataList and #dataList or 0

        if count > 0 then
            local limitCount = self._Control:GetCurActivitySpecialRewardLimitCount()
            if XTool.IsNumberValid(limitCount) then
                count = math.min(count, limitCount)
            end
        end
        
        XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, count, function(index, go)
            local item = self._SpecialRewardGrids[go]

            if not item then
                item = XUiGridCommon.New(self.RootUi, go)
                self._SpecialRewardGrids[go] = item
            end
            
            local tmpData = {}
            local rewardInfo = dataList[index]
            
            tmpData.TemplateId = rewardInfo.TemplateId
            tmpData.Count = rewardInfo.Count
            local curCount = nil
            if rewardInfo.RewardType == XGachaConfigs.RewardType.Count then
                curCount = rewardInfo.CurCount
            end
            item:Refresh(tmpData, nil, nil, nil, curCount)

            if item.PanelLack then
                item.PanelLack.gameObject:SetActiveEx(curCount <= 0)
            end
        end)
    else
        XLog.Error('尝试刷新卡池特殊奖励展示，但卡池Id无效:'..tostring(self.GachaId))
    end
end

function XUiPanelGachaLiverDrawBase:RefreshDrawButtonsState()
    self._OneDrawBtn:Refresh()
    self._TenDrawBtn:Refresh()

    local isSellOutAllRare = XDataCenter.GachaManager.GetGachaIsSoldOutRare(self.GachaId)

    self.PanelDrawButtons.gameObject:SetActiveEx(not isSellOutAllRare)
    self.PanelOver.gameObject:SetActiveEx(isSellOutAllRare)
    
    if isSellOutAllRare then
        self._OneDrawBtn:Close()
        self._TenDrawBtn:Close()
    else
        self._OneDrawBtn:Open()
        self._TenDrawBtn:Open()
    end
    
end

function XUiPanelGachaLiverDrawBase:RefreshHadDoneDrawTimes()
    local isSellOutAllRare = XDataCenter.GachaManager.GetGachaIsSoldOutRare(self.GachaId)

    self.TxtTotalDrawCount.transform.parent.gameObject:SetActiveEx(not isSellOutAllRare)
    if isSellOutAllRare then
        self.TxtTotalDrawCount.text = ''
    else
        self.TxtTotalDrawCount.text = XUiHelper.FormatText(XGachaConfigs.GetClientConfig('HadDoneDrawTimesLabel'), XDataCenter.GachaManager.GetMissTimes(self.GachaId), self.GachaCfg.PropStartTimes)
    end
end

function XUiPanelGachaLiverDrawBase:RefreshReddot()
    XRedPointManager.Check(self._ShopReddotId)
    XRedPointManager.Check(self._TaskReddotId)
    XRedPointManager.Check(self._TimelimitDrawReddotId)
end

function XUiPanelGachaLiverDrawBase:RefreshTaskButtonState()
    local leftFreeItemCount = self._Control:GetLeftCanGetFreeItemCount()
    
    self.BtnTask:ShowTag(leftFreeItemCount <= 0)
    
    self._TaskIsOpen = leftFreeItemCount > 0
end
--endregion

--region 事件回调
function XUiPanelGachaLiverDrawBase:OnBtnShopClick()
    local shopIds = self._Control:GetCurActivityShopIds(true)
    
    XShopManager.GetShopInfoList(shopIds, function()
        XLuaUiManager.Open("UiGachaCanLiverShop", shopIds)
    end, XShopManager.ShopType.Activity)
end

function XUiPanelGachaLiverDrawBase:OnBtnTaskClick()
    if not self._TaskIsOpen then
        XUiManager.TipMsg(XGachaConfigs.GetClientConfig('NoFreeItemCanGetTips'))
        return
    end
    
    XLuaUiManager.OpenWithCloseCallback("UiGachaCanLiverTask", function() 
        self:RefreshReddot()
    end)
end

function XUiPanelGachaLiverDrawBase:OnBtnChangeClick()
    local gachaId = nil
    local isTimeLimit = false
    
    if self.IsTimeLimit then
        gachaId = self._Control:GetCurActivityResidentGachaId()
    else
        if self.IsHideTimeLimit then
           return     
        end
        
        local timelimitGachaId = self._Control:GetCurActivityLatestTimelimitGachaId()
        gachaId = timelimitGachaId
        isTimeLimit = true
    end

    if XTool.IsNumberValid(gachaId) then
        XDataCenter.GachaManager.GetGachaRewardInfoRequest(gachaId, function()
            self:InitDrawData(gachaId, isTimeLimit)
            self:RefreshAll()

            -- 根据原来的类型设置动画背景
            if self.BtnSwitch and self.RImgBgAnim then
                if isTimeLimit then
                    local bg = XGachaConfigs.GetClientConfig('LilithDrawMainFullBgs', 1)
                    if not string.IsNilOrEmpty(bg) then
                        self.RImgBgAnim:SetRawImage(bg)
                        self.RootUi:PlayAnimationWithMask('BtnSwitch')
                    end
                else
                    local bg = XGachaConfigs.GetClientConfig('LilithDrawMainFullBgs', 2)
                    if not string.IsNilOrEmpty(bg) then
                        self.RImgBgAnim:SetRawImage(bg)
                        self.RootUi:PlayAnimationWithMask('BtnSwitch')
                    end
                end
            end
        end)
    end
end

function XUiPanelGachaLiverDrawBase:OnBtnCharacterClick()
    local characterId = self._Control:GetCurActivityCharacterId()

    if XTool.IsNumberValid(characterId) then
        XLuaUiManager.Open("UiCharacterDetail", characterId)
    else
        XLog.Error('角色Id配置无效：'..tostring(characterId)..' 当前活动Id：'..tostring(XMVCA.XGachaCanLiver:GetCurActivityId()))
    end
end

function XUiPanelGachaLiverDrawBase:OnBtnMoreClick()
    XLuaUiManager.Open('UiGachaCanLiverLog', self.GachaCfg, 1)
end
--endregion

--region 红点
function XUiPanelGachaLiverDrawBase:OnShopReddotEvent(count)
    self.BtnShop:ShowReddot(count >= 0)
end

function XUiPanelGachaLiverDrawBase:OnTaskReddotEvent(count)
    self.BtnTask:ShowReddot(count >= 0)
end

function XUiPanelGachaLiverDrawBase:OnTimelimitReddotEvent(count)
    if self.IsTimeLimit then
        self.BtnChange:ShowReddot(false)
    else
        self.BtnChange:ShowReddot(count >= 0)
    end
end
--endregion

--region 抽卡流程
function XUiPanelGachaLiverDrawBase:RequestDoGacha(gachaCount)
    if not self.IsOpen then
        return
    end
    
    if not self:CheckIsCanGacha(gachaCount) then
        return
    end
    XDataCenter.KickOutManager.Lock(XEnumConst.KICK_OUT.LOCK.GACHA)
    self:DoGacha(gachaCount)
end

function XUiPanelGachaLiverDrawBase:CheckIsCanGacha(gachaCount)
    if not XDataCenter.GachaManager.CheckGachaIsOpenById(self.GachaCfg.Id, true) then
        return false
    end

    -- 抽卡前检测物品是否满了
    if XMVCA.XEquip:CheckBoxOverLimitOfDraw() then
        return false
    end

    -- 检查货币是否足够
    local gachaId = self._Control:GetCurShowGachaId()
    local consumeId = self._Control:GetConsumeItemId(gachaId)
    -- 需要的道具总数
    local consumeCount = self._Control:GetConsumeCount(gachaId)
    local needConsumeCount = consumeCount * gachaCount
    -- 付费道具数
    local ownItemCount = XDataCenter.ItemManager.GetItem(consumeId).Count
    -- 免费道具数
    local ownFreeItemCount = self._Control:GetCurActivityFreeItemCount()
    -- 缺少的道具数
    local lackItemCount = needConsumeCount - ownItemCount - ownFreeItemCount
    if lackItemCount > 0 then
        -- 打开购买界面
        self:OpenGachaItemShop(function()
            XUiManager.TipError(CS.XTextManager.GetText("DrawNotEnoughError"))
        end, gachaCount)
        return false
    end

    return true
end

-- 打开gacha道具购买界面
function XUiPanelGachaLiverDrawBase:OpenGachaItemShop(openCb, gachaCount)
    -- 购买上限检测
    local gachaCfg = XGachaConfigs.GetGachaCfgById(self.GachaId)
    local gachaBuyTicketRuleConfig = XGachaConfigs.GetGachaItemExchangeCfgById(gachaCfg.ExchangeId)
    if XDataCenter.GachaManager.GetTotalGachaTimes(self.GachaId) >= gachaBuyTicketRuleConfig.TotalBuyCountMax then
        XUiManager.TipError(CS.XTextManager.GetText("BuyItemCountLimit", XDataCenter.ItemManager.GetItemName(gachaCfg.ConsumeId)))
        return
    end

    local createItemData = function(config, index)
        return
        {
            ItemId = config.UseItemIds[index],
            Sale = config.Sales[index], -- 折扣
            CostNum = config.UseItemCounts[index], -- 价格
            ItemImg = config.UseItemImgs[index],
        }
    end
    local itemData = createItemData(gachaBuyTicketRuleConfig, 1)
    
    local targetData = { ItemId = gachaCfg.ConsumeId, ItemImg = gachaBuyTicketRuleConfig.TargetItemImg }

    XLuaUiManager.Open("UiGachaCanLiverPopupBuyAsset", gachaCfg, itemData, targetData, gachaCount, function()
        self:RefreshAll()
    end)
    if openCb then
        openCb()
    end
end

-- 抽卡流程
function XUiPanelGachaLiverDrawBase:DoGacha(gachaCount)
    self._Control:SetLockTickout(true)
    XDataCenter.GachaManager.DoGacha(self.GachaCfg.Id, gachaCount, handler(self, self.OnGachaDoSuccess), function(res)
        self._Control:SetLockTickout(false)
    end)
end

function XUiPanelGachaLiverDrawBase:OnGachaDoSuccess(rewardList, newUnlockGachaId, res)
    local isMultyReward = XTool.GetTableCount(rewardList) > 1
    
    local cb = function(isSkip)
        if XTool.IsNumberValid(self.GachaCfg.GachaShowGroupId) then
            XLuaUiManager.PopThenOpen("UiEpicFashionGachaShow", self.GachaId, rewardList, function()
                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.GACHA, false)
                -- 刷新
                self:RefreshAllWhithCheckDone()
                self._Control:SetLockTickout(false)
            end, (isSkip and isMultyReward) and DrawState.Result or DrawState.Show)
        else
            XLuaUiManager.PopThenOpen("UiDrawShowNew",  nil, rewardList, nil, (isSkip and isMultyReward) and DrawState.Result or DrawState.Show, function()
                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.GACHA, false)
                -- 刷新
                self:RefreshAllWhithCheckDone()
                self._Control:SetLockTickout(false)
            end)
        end
    end

    --- 自定义展示品质
    if not XTool.IsTableEmpty(res.GachaRewardIdList) then
        for i, rewardInfo in pairs(rewardList) do
            local gachaRewardCfgId = res.GachaRewardIdList[i]

            if XTool.IsNumberValid(gachaRewardCfgId) then
                local cfg = XGachaConfigs.GetGachaReward()[gachaRewardCfgId]

                if cfg and not string.IsNilOrEmpty(cfg.Note) then
                    rewardInfo.ShowQuality = string.IsNumeric(cfg.Note) and tonumber(cfg.Note) or nil
                end
            end
        end
    end
    
    XLuaUiManager.Open('UiLilithGachaShow', self.GachaId, rewardList, cb)
end
--endregion

--region 定时器
function XUiPanelGachaLiverDrawBase:StopTimelimitDrawLeftTimer()
    if self._DrawLeftTimerId then
        XScheduleManager.UnSchedule(self._DrawLeftTimerId)
        self._DrawLeftTimerId = nil
    end
end

function XUiPanelGachaLiverDrawBase:StartTimelimitDrawLeftTimer()
    if self._TimeLimitDrawIsOver or self.IsHideTimeLimit then
        return
    end
    
    self:StopTimelimitDrawLeftTimer()
    self._DrawLeftTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateTimelimitDrawTimeShow), XScheduleManager.SECOND)
    self:UpdateTimelimitDrawTimeShow()
end

function XUiPanelGachaLiverDrawBase:UpdateTimelimitDrawTimeShow()
    local now = XTime.GetServerNowTimestamp()
    
    --- 限时卡池时间统一
    local gachaId = self.IsTimeLimit and self.GachaId or self._Control:GetCurActivityTimelimitGachaIdByIndex(1)
    
    ---@type XTableGacha
    local gachaCfg = XGachaConfigs.GetGachaCfgById(gachaId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(gachaCfg.TimeId)
    
    local leftTime = endTime - now

    if leftTime < 0 then
        leftTime = 0
    end

    if self.IsTimeLimit then
        self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    else
        self.BtnChange:SetNameByGroup(0, XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    end

    if leftTime <= 0 then
        self:StopTimelimitDrawLeftTimer()
        self._TimeLimitDrawIsOver = true
        
        -- 如果处于常驻，则关闭入口
        if not self.IsTimeLimit then
            self.IsHideTimeLimit = true
            self.BtnChange.gameObject:SetActiveEx(false)
        end
    end
end
--endregion

return XUiPanelGachaLiverDrawBase