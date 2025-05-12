---@class XUiGridGachaLiverDrawButton: XUiNode
---@field _Control XGachaCanLiverControl
local XUiGridGachaLiverDrawButton = XClass(XUiNode, 'XUiGridGachaLiverDrawButton')

function XUiGridGachaLiverDrawButton:OnStart(type)
    self.Type = type
    self.GridBtn.CallBack = handler(self, self.OnBtnClick)
end

--region 界面刷新
function XUiGridGachaLiverDrawButton:Refresh()
    self:_RefreshEnableState()
    self:_RefreshFreeShow() 
    self:_RefreshConsumeShow()
end

function XUiGridGachaLiverDrawButton:_RefreshFreeShow()
    local freeItemCount = self._Control:GetCurActivityFreeItemCount()
    self._IsShowFreePanel = freeItemCount > 0 and self._IsEnable

    self.PanelFree.gameObject:SetActiveEx(self._IsShowFreePanel)

    if self._IsShowFreePanel then
        -- 显示免费次数和免费道具
        self.TxtFreeNum.text = XUiHelper.FormatText(XGachaConfigs.GetClientConfig('FreeItemLabel'), freeItemCount)
        
        local freeItemId = self._Control:GetCurActivityFreeItemId()

        if XTool.IsNumberValid(freeItemId) then
            local icon = XItemConfigs.GetItemIconById(freeItemId)

            if string.IsNilOrEmpty(icon) then
                XLog.Error('免费道具的图标路径无效:'..tostring(icon)..' Id:'..tostring(freeItemId))
            else
                self.ImgFreeItemIcon:SetRawImage(icon)
            end
        else
            XLog.Error('免费道具Id配置无效：'..tostring(freeItemId))
        end
    end
end

function XUiGridGachaLiverDrawButton:_RefreshConsumeShow()
    self._IsShowConsumePanel = true
    self.PanelCount.gameObject:SetActiveEx(true)
    -- 如果按钮禁用了，则不用显示了
    if not self._IsEnable then
        self.PanelCount.gameObject:SetActiveEx(false)
        return
    end
    
    
    if self.Type == XEnumConst.GachaCanLiver.DrawButtonType.One then
        self._DrawTurns = 1
        -- 单抽如果有免费的就不用显示付费的了
        if self._IsShowFreePanel then
            self._IsShowConsumePanel = false
            self.PanelCount.gameObject:SetActiveEx(false)
            return
        end
    else
        self._DrawTurns = 10
        -- 对于十抽，如果有免费的且足够10抽，则不显示
        local freeItemCount = self._Control:GetCurActivityFreeItemCount()

        if freeItemCount >= self._DrawTurns then
            self._IsShowConsumePanel = false
            self.PanelCount.gameObject:SetActiveEx(false)
            return
        end
    end

    local gachaId = self._Control:GetCurShowGachaId()

    if XTool.IsNumberValid(gachaId) then
        -- 显示抽卡道具消耗和图标
        local costCount = self._Control:GetConsumeCount(gachaId)
        local costTurns = self._DrawTurns - self._Control:GetCurActivityFreeItemCount()
        local totalCost = costTurns * costCount
        
        self.TxtNum.text = totalCost
        
        local consumeItemId = self._Control:GetConsumeItemId(gachaId)

        if XTool.IsNumberValid(consumeItemId) then
            local icon = XItemConfigs.GetItemIconById(consumeItemId)

            if string.IsNilOrEmpty(icon) then
                XLog.Error('抽卡道具的图标路径无效:'..tostring(icon)..' Id:'..tostring(consumeItemId))
            else
                self.ImgUseItemIcon:SetRawImage(icon)
            end
            
            -- 如果普通道具不足，需要额外显示标签
            local currentCount = XDataCenter.ItemManager.GetCount(consumeItemId)
            self.TagExchange.gameObject:SetActiveEx(currentCount < totalCost)
        else
            XLog.Error('抽卡道具Id配置无效：'..tostring(consumeItemId))
        end

    else
        XLog.Error('抽卡界面内抽卡按钮读取gachaId无效：'..tostring(gachaId))
    end
end

function XUiGridGachaLiverDrawButton:_RefreshEnableState()
    self._IsEnable = true
    self.GridBtn:SetButtonState(CS.UiButtonState.Normal)
    if self.Type == XEnumConst.GachaCanLiver.DrawButtonType.Ten then
        -- 十抽，如果卡池剩余次数不足需要禁用
        local gachaId = self._Control:GetCurShowGachaId()
        local gachaCfg = XGachaConfigs.GetGachaCfgById(gachaId)
        local gachaItemExchangeCfg = XGachaConfigs.GetGachaItemExchangeCfgById(gachaCfg.ExchangeId)
        if XTool.IsNumberValid(gachaId) then
            -- 只有卡池是有限次的，才能根据抽取次数进行控制
            if not XDataCenter.GachaManager.GetIsInfinite(gachaId) then
                --- 当前抽取的次数
                local curCount = XDataCenter.GachaManager.GetCurCountOfAll(gachaId)
                --- 可抽取的最大次数
                local maxCount = XDataCenter.GachaManager.GetMaxCountOfAll(gachaId)

                --- 剩余次数
                local leftCount = maxCount - curCount

                if leftCount < 10 then
                    self._IsEnable = false
                    self.GridBtn:SetButtonState(CS.UiButtonState.Disable)
                end
            else
                -- 卡池无限时，则只根据道具兑换剩余次数来判断
                local totalLeftCanBuy = gachaItemExchangeCfg.TotalBuyCountMax - XDataCenter.GachaManager.GetTotalGachaTimes(gachaCfg.Id)
                if totalLeftCanBuy < 10 then
                    self._IsEnable = false
                    self.GridBtn:SetButtonState(CS.UiButtonState.Disable)
                end
            end
        else
            XLog.Error('抽卡界面内抽卡按钮读取gachaId无效：'..tostring(gachaId))
        end
    end
end

--endregion

function XUiGridGachaLiverDrawButton:OnBtnClick()
    if self._IsEnable then
        self.Parent:RequestDoGacha(self._DrawTurns)
    else
        
    end
end



return XUiGridGachaLiverDrawButton