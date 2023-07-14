local XUiPassportRewardGrid = require("XUi/XUiPassport/UpLevel/XUiPassportRewardGrid")

local CSXTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert

local XUiPassportReward = XLuaUiManager.Register(XLuaUi, "UiPassportReward")

function XUiPassportReward:OnAwake()
    self:RegisterButtonEvent()

    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll.transform)
    self.DynamicTable:SetProxy(XUiPassportRewardGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridEquip.gameObject:SetActive(false)
end

--levelAfter：购买后的等级
--spendBuyCount：花费多少购买
--spendBuyExp：购买多少经验
--buyCb：购买成功回调
--levelIdList：购买的等级Id列表
function XUiPassportReward:OnStart(levelAfter, spendBuyCount, spendBuyExp, buyCb, levelIdList)
    self.LevelAfter = levelAfter
    self.SpendBuyCount = spendBuyCount
    self.BuyCallback = buyCb

    local costItemId = XPassportConfigs.GetBuyLevelCostItemId()
    local costItemIcon = XItemConfigs.GetItemIconById(costItemId)
    self.RImgIconSpend:SetRawImage(costItemIcon)
    self.TxtTips.text = CSXTextManagerGetText("PassportSpendBuyDesc", spendBuyCount)

    local expItemIcon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.PassportExp)
    self.RImgIconBuy:SetRawImage(expItemIcon)
    self.TxtBuy.text = CSXTextManagerGetText("PassportRewardTxtBuy", spendBuyExp, levelAfter)

    self.DynamicData = {}
    local level
    local unLockPassportRewardIdList
    local rewardData
    for _, levelId in ipairs(levelIdList or {}) do
        level = XPassportConfigs.GetPassportLevel(levelId)
        unLockPassportRewardIdList = XPassportConfigs.GetUnLockPassportRewardIdListByLevel(level)
        for _, passportRewardId in ipairs(unLockPassportRewardIdList) do
            rewardData = XPassportConfigs.GetPassportRewardData(passportRewardId)
            tableInsert(self.DynamicData, rewardData)
        end
    end

    self.DynamicData = XRewardManager.MergeAndSortRewardGoodsList(self.DynamicData)

    self.DynamicTable:SetDataSource(self.DynamicData)
    self.DynamicTable:ReloadDataSync(1)
    self:ShowSpecialRegulationForJP()
end

function XUiPassportReward:ShowSpecialRegulationForJP() --海外修改
    local isShow = CS.XGame.ClientConfig:GetInt("ShowRegulationEnable")
    if isShow and isShow == 1 then
        local url = CS.XGame.ClientConfig:GetString("RegulationPrefabUrl")
        if url then
            local obj = self.PanelInfo:LoadPrefab(url)
            local data = {type = 1,consumeId = 2}
            self.ShowSpecialRegBtn = obj.transform:GetComponent("XHtmlText")
            self.ShowSpecialRegBtn.text = CS.XTextManager.GetText("JPBusinessLawsDetailsEnter")
            self.ShowSpecialRegBtn.HrefUnderLineColor = CS.UnityEngine.Color(1, 45 / 255, 45 / 255, 1)
            self.ShowSpecialRegBtn.transform.localPosition = CS.UnityEngine.Vector3(-383.3, -344, 0)
            self.ShowSpecialRegBtn.fontSize = 32
            self.ShowSpecialRegBtn.HrefListener = function(link)
                XLuaUiManager.Open("UiSpecialRegulationShow",data)
            end
        end
    end
end

function XUiPassportReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local passportRewardId = self.DynamicData[index]
        grid:Refresh(passportRewardId)
    end
end

function XUiPassportReward:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiPassportReward:OnBtnConfirmClick()
    local costItemId = XPassportConfigs.GetBuyLevelCostItemId()
    local haveItemCount = XDataCenter.ItemManager.GetCount(costItemId)
    if haveItemCount < self.SpendBuyCount then
        XUiManager.TipText("ShopItemPaidGemNotEnough")
        XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
        return
    end

    XDataCenter.PassportManager.RequestPassportBuyExp(self.LevelAfter, function() 
        self:Close()
        if self.BuyCallback then
            self.BuyCallback()
        end
    end)
end