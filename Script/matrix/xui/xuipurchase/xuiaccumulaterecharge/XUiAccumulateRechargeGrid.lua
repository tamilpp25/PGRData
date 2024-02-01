---@class XUiAccumulateRechargeGrid : XUiNode
---@field TxtRewareTitle UnityEngine.UI.Text
---@field BtnReceiveHave UnityEngine.RectTransform
---@field BtnTcanchaungBlue XUiComponent.XUiButton
---@field RewardOldContent UnityEngine.RectTransform
---@field BigOldRewardGrid UnityEngine.RectTransform
---@field SmallOldRewardGrid UnityEngine.RectTransform
---@field BigNewRewardGrid UnityEngine.RectTransform
---@field RewardNewContent UnityEngine.RectTransform
---@field SmallNewRewardGrid UnityEngine.RectTransform
local XUiAccumulateRechargeGrid = XClass(XUiNode, "XUiAccumulateRechargeGrid")

function XUiAccumulateRechargeGrid:Ctor()
    self._RewardGridList = self._RewardGridList or {}
    self._RewardExtraGridList = self._RewardExtraGridList or {}
    self._NormalBigGrid = self._NormalBigGrid
    self._ExtraBigGrid = self._ExtraBigGrid
    self._Data = self._Data
end

--region 生命周期
function XUiAccumulateRechargeGrid:OnStart()
    self:_RegisterButtonClicks()
    self.SmallOldRewardGrid.gameObject:SetActiveEx(false)
    self.SmallNewRewardGrid.gameObject:SetActiveEx(false)
end

--endregion

--region 按钮事件
function XUiAccumulateRechargeGrid:OnBtnTcanchaungBlueClick()
    if not self._Data or (XDataCenter.PurchaseManager.AccumulateRewardGeted(self._Data.Id) and
        XDataCenter.PurchaseManager.AccumulateExtraRewardGeted(self._Data.ExtraId)) then
        return
    end

    local payId = XDataCenter.PurchaseManager.GetAccumulatePayId()

    XDataCenter.PurchaseManager.GetAccumulatePayReq(payId, self._Data.Id)
end

--endregion
---@param data { Id : number, State : number, ExtraState : number }
function XUiAccumulateRechargeGrid:Refresh(data)
    if not data then
        return
    end

    self._Data = data

    local itemConfig = XPurchaseConfigs.GetAccumulateRewardConfigById(data.Id)
    local extraItemConfig = XPurchaseConfigs.GetAccumulateExtraRewardConfigById(itemConfig.ExtraPayRewardId)

    if not itemConfig or not extraItemConfig then
        return
    end

    local money = itemConfig.Money
    local isNormalReceive = data.State == XPurchaseConfigs.PurchaseRewardAddState.Geted
    local isExtraReceive = data.ExtraState == XPurchaseConfigs.PurchaseRewardAddState.Geted

    if data.State == XPurchaseConfigs.PurchaseRewardAddState.Geted and
        data.ExtraState == XPurchaseConfigs.PurchaseRewardAddState.Geted then
        self.BtnTcanchaungBlue.gameObject:SetActiveEx(false)
        self.BtnReceiveHave.gameObject:SetActiveEx(true)
    else
        self.BtnTcanchaungBlue.gameObject:SetActiveEx(true)
        self.BtnReceiveHave.gameObject:SetActiveEx(false)

        if data.State == XPurchaseConfigs.PurchaseRewardAddState.CanGet or
            data.ExtraState == XPurchaseConfigs.PurchaseRewardAddState.CanGet then
            self.BtnTcanchaungBlue:SetButtonState(XUiButtonState.Normal)
        else
            self.BtnTcanchaungBlue:SetButtonState(XUiButtonState.Disable)
        end
    end

    self:_RefreshNormalSmallReward(itemConfig.SmallRewardId, isNormalReceive)
    self:_RefreshExtraSmallReward(extraItemConfig.ExtraSmallRewardId, isExtraReceive)
    self:_RefreshNormalBigReward(itemConfig.BigRewardId, isNormalReceive)
    self:_RefreshExtraBigReward(extraItemConfig.ExtraBigRewardId, isExtraReceive)

    self.TxtRewareTitle.text = XUiHelper.GetText("AccumulateMonyDes", money)
end

--region 私有方法
function XUiAccumulateRechargeGrid:_RegisterButtonClicks()
    --在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnTcanchaungBlue, self.OnBtnTcanchaungBlueClick, true)
end

function XUiAccumulateRechargeGrid:_RefreshNormalSmallReward(rewardId, isReceive)
    self:_RefreshSmallReward(self._RewardGridList, rewardId, self.SmallOldRewardGrid, self.RewardOldContent, 
        isReceive)
end

function XUiAccumulateRechargeGrid:_RefreshExtraSmallReward(rewardId, isReceive)
    self:_RefreshSmallReward(self._RewardExtraGridList, rewardId, self.SmallNewRewardGrid, self.RewardNewContent,
        isReceive)
end

function XUiAccumulateRechargeGrid:_RefreshSmallReward(gridList, rewardId, uiObject, content, isReceive)
    if not XTool.IsNumberValid(rewardId) then
        for i = 1, #gridList do
            gridList[i].GameObject:SetActiveEx(false)
        end

        return
    end
    
    local rewards = XRewardManager.GetRewardList(rewardId)

    if not rewards then
        for i = 1, #gridList do
            gridList[i].GameObject:SetActiveEx(false)
        end
        
        return
    end

    local rewardCount = #rewards

    for i = 1, rewardCount do
        local grid = gridList[i]

        if not grid then
            local ui = XUiHelper.Instantiate(uiObject, content)

            grid = self:_CreateRewardGrid(ui)
            gridList[i] = grid
        end

        grid.GameObject:SetActiveEx(true)
        grid:Refresh(rewards[i])
        grid.PanelReceived.gameObject:SetActiveEx(isReceive)
        grid:SetNameplateEffectActive(not isReceive)
    end

    for i = rewardCount + 1, #gridList do
        gridList[i].GameObject:SetActiveEx(false)
    end
end

function XUiAccumulateRechargeGrid:_RefreshNormalBigReward(rewardId, isReceive)
    local rewards = XRewardManager.GetRewardList(rewardId)

    if not self._NormalBigGrid then
        self._NormalBigGrid = self:_CreateRewardGrid(self.BigOldRewardGrid)
    end
    if rewards and rewards[1] then
        self._NormalBigGrid:Refresh(rewards[1])
        self._NormalBigGrid.PanelReceived.gameObject:SetActiveEx(isReceive)
        self._NormalBigGrid:SetNameplateEffectActive(not isReceive)
    end
end

function XUiAccumulateRechargeGrid:_RefreshExtraBigReward(rewardId, isReceive)
    local rewards = XRewardManager.GetRewardList(rewardId)

    if not self._ExtraBigGrid then
        self._ExtraBigGrid = self:_CreateRewardGrid(self.BigNewRewardGrid)
    end
    if rewards and rewards[1] then
        self._ExtraBigGrid:Refresh(rewards[1])
        self._ExtraBigGrid.PanelReceived.gameObject:SetActiveEx(isReceive)
        self._ExtraBigGrid:SetNameplateEffectActive(not isReceive)
    end
end

function XUiAccumulateRechargeGrid:_CreateRewardGrid(ui)
    local grid = XUiGridCommon.New(self.Parent, ui)

    XTool.InitUiObject(grid)
    grid.ButtonClick.CallBack = Handler(grid, grid.OnBtnClickClick)
    grid.PanelReceived = grid.Transform:Find("PanelReceived")

    return grid
end

--endregion

return XUiAccumulateRechargeGrid
