local XUiPartnerSkillLevelUpAll = XLuaUiManager.Register(XLuaUi, "UiPartnerSkillLevelUpAll")
local CSTextManagerGetText = CS.XTextManager.GetText
local XUiGridCostItem = require("XUi/XUiEquipBreakThrough/XUiGridCostItem")
local DefaultIndex = 1
local MAX_COUNT = 999
local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("0E70BDFF"),
    [false] = CS.UnityEngine.Color.red,
}
function XUiPartnerSkillLevelUpAll:OnStart(partner, base, root)
    self.Partner = partner
    self.Base = base
    self.Root = root
    self.SkillUpCount = 1
    self.MinCount = 1
    self.TxtSelect.text = 1
    self:SetButtonCallBack()
    self:InitPanel()
end

function XUiPartnerSkillLevelUpAll:OnDestroy()

end

function XUiPartnerSkillLevelUpAll:OnEnable()

end

function XUiPartnerSkillLevelUpAll:OnDisable()

end

function XUiPartnerSkillLevelUpAll:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnAdd.CallBack = function()
        self:OnBtnAddSelectClick()
    end
    self.BtnMinus.CallBack = function()
        self:OnBtnMinusSelectClick()
    end
    self.BtnMax.CallBack = function()
        self:OnBtnMaxClick()
    end
    self.BtnSkillUp.CallBack = function()
        self:OnBtnSkillUpClick()
    end

    self.TxtSelect.onValueChanged:AddListener(function()
            self:OnSelectTextChange()
        end)

    self.TxtSelect.onEndEdit:AddListener(function()
            self:OnSelectTextInputEnd()
        end)

end

function XUiPartnerSkillLevelUpAll:InitPanel()
    self.GridCostItems = {}
    self.ItemCost:GetObject("GridCostItem").gameObject:SetActiveEx(false)
    self:SetSelectTextData()
    self:SetCanBuyCount()
    self:CheckSkillCanUp()
    self:SetCanAddOrMinusBtn()
end

function XUiPartnerSkillLevelUpAll:SetSelectTextData()
    self.TxtSelect.characterLimit = 4
    self.TxtSelect.contentType = CS.UnityEngine.UI.InputField.ContentType.IntegerNumber
end

function XUiPartnerSkillLevelUpAll:SetCanBuyCount()
    self.MaxCount = self.Partner:GetSkillLevelGap()
    local canBuyCount = self.MaxCount
    for _, costItem in pairs(self.Partner:GetSkillUpgradeCostItem()) do
        local itemCount = XDataCenter.ItemManager.GetCount(costItem.Id)
        local buyCount = math.floor(itemCount / costItem.Count)
        canBuyCount = math.min(buyCount, canBuyCount)
    end
    canBuyCount = math.max(self.MinCount, canBuyCount)
    self.CanBuyCount = canBuyCount
end

function XUiPartnerSkillLevelUpAll:OnBtnAddSelectClick()
    if self.SkillUpCount + 1 > self.MaxCount then
        XUiManager.TipText("PartnerSkillLevelOverFlow")
        return
    end
    self.SkillUpCount = self.SkillUpCount + 1
    self:CheckSkillCanUp()
    self.TxtSelect.text = self.SkillUpCount
    self:SetCanAddOrMinusBtn()
end

function XUiPartnerSkillLevelUpAll:OnBtnMinusSelectClick()
    if self.SkillUpCount - 1 < self.MinCount then
        return
    end
    self.SkillUpCount = self.SkillUpCount - 1
    self:CheckSkillCanUp()
    self.TxtSelect.text = self.SkillUpCount
    self:SetCanAddOrMinusBtn()
end

function XUiPartnerSkillLevelUpAll:OnBtnMaxClick()
    self.SkillUpCount = math.min(self.MaxCount, self.CanBuyCount)
    self:CheckSkillCanUp()
    self.TxtSelect.text = self.SkillUpCount
    self:SetCanAddOrMinusBtn()
end

function XUiPartnerSkillLevelUpAll:OnSelectTextChange()
    if self.TxtSelect.text == nil or self.TxtSelect.text == "" then
        return
    end
    if self.TxtSelect.text == "0" then
        self.TxtSelect.text = 1
    end
    local tmp = tonumber(self.TxtSelect.text)
    local tmpMax = math.max(math.min(MAX_COUNT, self.MaxCount), 1)
    if tmp > tmpMax then
        tmp = tmpMax
        self.TxtSelect.text = tmp
    end
    self.SkillUpCount = tmp
    self:CheckSkillCanUp()
end

function XUiPartnerSkillLevelUpAll:OnSelectTextInputEnd()
    if self.TxtSelect.text == nil or self.TxtSelect.text == "" then
        self.TxtSelect.text = 1
        local tmp = tonumber(self.TxtSelect.text)
        self.SkillUpCount = tmp
        self:CheckSkillCanUp()
    end
end

function XUiPartnerSkillLevelUpAll:OnBtnSkillUpClick()
    if self.Base.IsPlayingAnim then
        return
    end
    self.Base.IsPlayingAnim = true
    XDataCenter.PartnerManager.PartnerSkillUpRequest(self.Partner:GetId(), self.SkillUpCount, function (skillUpInfo)
            self:OnBtnCloseClick()
            self.Base.IsPlayingAnim = false
            self.Root:SetSkillUpFinish(true)
            self.Root:SetSkillUpInfo(skillUpInfo)
            self.Root:UpdatePanel(self.Partner)
        end,function ()
            self.Base.IsPlayingAnim = false
        end)
end

function XUiPartnerSkillLevelUpAll:OnBtnCloseClick()
    self:Close()
end

function XUiPartnerSkillLevelUpAll:SetCanAddOrMinusBtn()
    self.BtnMinus:SetDisable(self.SkillUpCount <= self.MinCount)
    
    self.BtnAdd:SetDisable(self.SkillUpCount >= self.MaxCount)

    self.BtnMax:SetDisable(self.MaxCount <= 1)
    self.BtnMax.interactable = self.MaxCount > 1
end


function XUiPartnerSkillLevelUpAll:CheckSkillCanUp()
    local costMoney = self.Partner:GetSkillUpgradeMoney().Count * self.SkillUpCount
    self.MoneyCost:GetObject("TxtCost").text = costMoney
    self.MoneyCost:GetObject("TxtCost").color = CONDITION_COLOR[XDataCenter.ItemManager.GetCoinsNum() >= costMoney]
    self.MoneyCost.gameObject:SetActiveEx(costMoney > 0)

    local consumeItems = self.Partner:GetSkillUpgradeItem()
    for index,item in pairs(consumeItems)do
        local grid = self.GridCostItems[index]
        if not grid then
            local tmpObj = self.ItemCost:GetObject("GridCostItem")
            local obj = CS.UnityEngine.Object.Instantiate(tmpObj, self.ItemCost.transform)
            grid = XUiGridCostItem.New(self, obj)
            self.GridCostItems[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(item.Id, item.Count * self.SkillUpCount)
    end

    for i = #consumeItems + 1, #self.GridCostItems do
        self.GridCostItems[i].GameObject:SetActiveEx(false)
    end
end