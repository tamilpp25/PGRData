local XUiPurchasePayAddListItem = XClass(nil, "XUiPurchasePayAddListItem")
local TextManager = CS.XTextManager
local Object = CS.UnityEngine.Object

function XUiPurchasePayAddListItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RewardItemList = {}
    self.RewardGetedCb = function() self:RewardGetedUpdate() end
    XTool.InitUiObject(self)
    self.BtnTcanchaungBlueCb = function()self:BtnGetClick() end
end

-- 更新数据
function XUiPurchasePayAddListItem:OnRefresh(id)
    if not id then
        return
    end

    self.Id = id
    self.ItemData = XPurchaseConfigs.GetAccumulateRewardConfigById(id)
    if not self.ItemData then
        return
    end

    local money = self.ItemData.Money
    local count = XDataCenter.PurchaseManager.GetAccumulatedPayCount()
    if count >= money then
        if not XDataCenter.PurchaseManager.AccumulateRewardGeted(id) then
            self.BtnTcanchaungBlue.gameObject:SetActiveEx(true)
            self.BtnReceiveHave.gameObject:SetActiveEx(false)
            self.BtnTcanchaungBlue:SetButtonState(XUiButtonState.Normal)
            self.BtnTcanchaungBlue.CallBack = self.BtnTcanchaungBlueCb
        else
            self.BtnTcanchaungBlue.gameObject:SetActiveEx(false)
            self.BtnReceiveHave.gameObject:SetActiveEx(true)
            self.BtnTcanchaungBlue.CallBack = nil
        end
    else
        if XDataCenter.PurchaseManager.AccumulateRewardGeted(id) then
            self.BtnTcanchaungBlue.gameObject:SetActiveEx(false)
            self.BtnReceiveHave.gameObject:SetActiveEx(true)
            self.BtnTcanchaungBlue.CallBack = nil
        else
            self.BtnTcanchaungBlue.gameObject:SetActiveEx(true)
            self.BtnReceiveHave.gameObject:SetActiveEx(false)
            self.BtnTcanchaungBlue:SetButtonState(XUiButtonState.Disable)
        end
    end

    local bigRewardId = self.ItemData.BigRewardId
    local smallRewardId = self.ItemData.SmallRewardId
    if self.SmallRewardId ~= smallRewardId then
        self.SmallRewardId = smallRewardId
        self:SetReward(smallRewardId)
    end
    if self.BigRewardId ~= bigRewardId then
        self.BigRewardId = bigRewardId
        if not self.BigItem then
            self.BigItem = XUiGridCommon.New(self.UiRoot, self.BigRewardGrid)
            XTool.InitUiObject(self.BigItem)
            self.BigItem.ButtonClick.CallBack = function() self.BigItem:OnBtnClickClick() end
        end
        local rewards = XRewardManager.GetRewardList(bigRewardId)
        if rewards and rewards[1] then
            self.BigItem:Refresh(rewards[1])
        end
    end

    self.TxtRewareTitle.text = TextManager.GetText("AccumulateMonyDes",money)
end

function XUiPurchasePayAddListItem:SetReward(rewardId)
    local rewards = XRewardManager.GetRewardList(rewardId)
    if not rewards then
        return
    end

    local rewardCount = #rewards
    for i = 1, rewardCount do
        local item = self.RewardItemList[i]
        if not item then
            local ui = Object.Instantiate(self.SmallRewardGrid)
            ui.transform:SetParent(self.RewardContent, false)
            ui.gameObject:SetActive(true)
            item = XUiGridCommon.New(self.UiRoot, ui)
            XTool.InitUiObject(item)
            item.ButtonClick.CallBack = function() item:OnBtnClickClick() end
            table.insert(self.RewardItemList,item)
        end
    end

    for i = 1, #self.RewardItemList do
        self.RewardItemList[i].GameObject:SetActive(i <= rewardCount)
        if i <= rewardCount then
            self.RewardItemList[i]:Refresh(rewards[i])
        end
    end
end

function XUiPurchasePayAddListItem:Init(uiRoot, parent)
    self.UiRoot = uiRoot
    self.Parent = parent
end

function XUiPurchasePayAddListItem:BtnGetClick()
    local payId = XDataCenter.PurchaseManager.GetAccumulatePayId()
    XDataCenter.PurchaseManager.GetAccumulatePayReq(payId, self.Id, self.RewardGetedCb)
end

function XUiPurchasePayAddListItem:RewardGetedUpdate()
    if not self.Id then
        return
    end

    self:OnRefresh(self.Id)
end

return XUiPurchasePayAddListItem