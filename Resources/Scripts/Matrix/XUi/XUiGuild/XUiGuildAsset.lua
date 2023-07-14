local XUiGuildAsset = XLuaUiManager.Register(XLuaUi, "UiGuildAsset")
local blackColor = CS.UnityEngine.Color.black
local redColor = CS.UnityEngine.Color.red

function XUiGuildAsset:OnAwake()
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCancelClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCancelClick() end
end

function XUiGuildAsset:OnDestroy()

end

function XUiGuildAsset:OnStart(confirmCallBack)
    self.ConfirmCallBack = confirmCallBack
    self.TxtTitle.text = CS.XTextManager.GetText("GuildDissmissLeader")
    self.TxtDissmiss.text = string.gsub(CS.XTextManager.GetText("GuildDissmissDes"), "\\n", "\n")
    
    local coins = CS.XGame.Config:GetString("GuildImpeachCostItem")
    local costs = CS.XGame.Config:GetString("GuildImpeachCostCount")

    self.AllCoins = string.Split(coins, "|")
    self.AllCosts = string.Split(costs, "|")

    local coin1 = tonumber(self.AllCoins[1])
    local coin2 = tonumber(self.AllCoins[2])
    local needNum1 = tonumber(self.AllCosts[1])
    local needNum2 = tonumber(self.AllCosts[2])

    local ownNum1 = XDataCenter.ItemManager.GetCount(coin1)
    local ownNum2 = XDataCenter.ItemManager.GetCount(coin2)
    
    self.RImgCoin1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(coin1))
    self.TxtCostNum1.text = needNum1
    self.RImgCoin2:SetRawImage(XDataCenter.ItemManager.GetItemIcon(coin2))
    self.TxtCostNum2.text = needNum2
    self.TxtCostNum1.color = (ownNum1 >= needNum1) and blackColor or redColor
    self.TxtCostNum2.color = (ownNum2 >= needNum2) and blackColor or redColor

end

function XUiGuildAsset:OnBtnConfirmClick()
    local coin1 = tonumber(self.AllCoins[1])
    local coin2 = tonumber(self.AllCoins[2])
    local needNum1 = tonumber(self.AllCosts[1])
    local needNum2 = tonumber(self.AllCosts[2])

    local ownNum1 = XDataCenter.ItemManager.GetCount(coin1)
    local ownNum2 = XDataCenter.ItemManager.GetCount(coin2)
    if ownNum1 < needNum1 or ownNum2 < needNum2 then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildDissmissCostNotEnough"))
        return
    end

    if self.ConfirmCallBack then
        self.ConfirmCallBack()
    end
    self:Close()
end

function XUiGuildAsset:OnBtnCancelClick()
    self:Close()
end
