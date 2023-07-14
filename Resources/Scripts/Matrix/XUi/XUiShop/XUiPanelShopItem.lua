XUiPanelShopItem = XClass(nil, "XUiPanelShopItem")

local MAX_COUNT = CS.XGame.Config:GetInt("ShopBuyGoodsCountLimit")
function XUiPanelShopItem:Ctor(ui, parent, rootUi, isActivityShop)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsActivityShop = isActivityShop
    self.Parent = parent
    self.RootUi = rootUi or parent
    self:InitAutoScript()
    self:SetSelectTextData()
    self.Grid = XUiGridCommon.New(self.RootUi, self.GridBuyCommon)
    self.Price = {}
    table.insert(self.Price, self.PanelCostItem1)
    table.insert(self.Price, self.PanelCostItem2)
    table.insert(self.Price, self.PanelCostItem3)

    self.WgtBtnAddSelect = self.BtnAddSelect.gameObject:GetComponent("XUiPointer")
    self.WgtBtnMinusSelect = self.BtnMinusSelect.gameObject:GetComponent("XUiPointer")

    XUiButtonLongClick.New(self.WgtBtnAddSelect, 100, self, nil, self.BtnAddSelectLongClickCallback, nil, true)
    XUiButtonLongClick.New(self.WgtBtnMinusSelect, 100, self, nil, self.BtnMinusSelectLongClickCallback, nil, true)

    self.MinCount = 1
end

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelShopItem:InitAutoScript()
    --self:AutoInitUi()
    XTool.InitUiObject(self)
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelShopItem:AutoInitUi()
--[[self.BtnBlock = self.Transform:Find("BtnBlock"):GetComponent("Button")
    self.GridBuyCommon = self.Transform:Find("GameObject/GridBuyCommon")
    self.ImgQuality = self.Transform:Find("GameObject/GridBuyCommon/ImgQuality"):GetComponent("Image")
    self.RImgIcon = self.Transform:Find("GameObject/GridBuyCommon/RImgIcon"):GetComponent("RawImage")
    self.RImgType = self.Transform:Find("GameObject/GridBuyCommon/RImgType"):GetComponent("RawImage")
    self.TxtCount = self.Transform:Find("GameObject/GridBuyCommon/TxtCount"):GetComponent("Text")
    self.TxtOwnCount = self.Transform:Find("GameObject/GridBuyCommon/TxtOwnCount"):GetComponent("Text")
    self.PanelPrice = self.Transform:Find("GameObject/Count/PanelPrice")
    self.PanelCostItem1 = self.Transform:Find("GameObject/Count/PanelPrice/PanelCostItem1")
    self.RImgCostIcon1 = self.Transform:Find("GameObject/Count/PanelPrice/PanelCostItem1/RImgCostIcon1"):GetComponent("RawImage")
    self.TxtCostCount1 = self.Transform:Find("GameObject/Count/PanelPrice/PanelCostItem1/TxtCostCount1"):GetComponent("Text")
    self.PanelCostItem2 = self.Transform:Find("GameObject/Count/PanelPrice/PanelCostItem2")
    self.RImgCostIcon2 = self.Transform:Find("GameObject/Count/PanelPrice/PanelCostItem2/RImgCostIcon2"):GetComponent("RawImage")
    self.TxtCostCount2 = self.Transform:Find("GameObject/Count/PanelPrice/PanelCostItem2/TxtCostCount2"):GetComponent("Text")
    self.PanelCostItem3 = self.Transform:Find("GameObject/Count/PanelPrice/PanelCostItem3")
    self.RImgCostIcon3 = self.Transform:Find("GameObject/Count/PanelPrice/PanelCostItem3/RImgCostIcon3"):GetComponent("RawImage")
    self.TxtCostCount3 = self.Transform:Find("GameObject/Count/PanelPrice/PanelCostItem3/TxtCostCount3"):GetComponent("Text")
    self.BtnAddSelect = self.Transform:Find("GameObject/BtnAddSelect"):GetComponent("Button")
    self.BtnMinusSelect = self.Transform:Find("GameObject/BtnMinusSelect"):GetComponent("Button")
    self.BtnMax = self.Transform:Find("GameObject/BtnMax"):GetComponent("Button")
    self.TxtCanBuy = self.Transform:Find("GameObject/TxtCanBuy"):GetComponent("Text")
    self.TxtSelect = self.Transform:Find("GameObject/TxtSelect"):GetComponent("InputField")
    self.BtnUse = self.Transform:Find("GameObject/BtnUse"):GetComponent("Button")]]
end

function XUiPanelShopItem:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelShopItem:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelShopItem:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelShopItem:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnBlock, self.OnBtnBlockClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMaxBtnMax, self.OnBtnMaxClick)

    if self.UiBtnMax then
        self.UiBtnMax.CallBack = function()
            self:OnBtnMaxClick()
        end
    end

    if self.BtnUse then
        self.BtnUse.CallBack = function()
            self:OnBtnUseClick()
        end
    end

    if self.BtnAddSelect then
        self.BtnAddSelect.CallBack = function()
            self:OnBtnAddSelectClick()
        end
    end

    if self.BtnMinusSelect then
        self.BtnMinusSelect.CallBack = function()
            self:OnBtnMinusSelectClick()
        end
    end

    self.TxtSelect.onValueChanged:AddListener(function()
        self:OnSelectTextChange()
    end)

    self.TxtSelect.onEndEdit:AddListener(function()
        self:OnSelectTextInputEnd()
    end)

    if self.BtnTanchuangClose then
        self.BtnTanchuangClose.CallBack = function()
            self:OnBtnBlockClick()
        end
    end
end

function XUiPanelShopItem:SetSelectTextData()
    self.TxtSelect.characterLimit = 4
    self.TxtSelect.contentType = CS.UnityEngine.UI.InputField.ContentType.IntegerNumber
end

-- auto
function XUiPanelShopItem:OnBtnBlockClick()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelShopItem:OnBtnAddSelectClick()



    if self.Count + 1 > self.MaxCount then
        XDataCenter.EquipManager.ShowBoxOverLimitText()
        return
    end
    self.Count = self.Count + 1
    self:RefreshConsumes()
    self:JudgeBuy()
    self.TxtSelect.text = self.Count
    self:SetCanAddOrMinusBtn()
end

function XUiPanelShopItem:OnBtnMinusSelectClick()
    if self.Count - 1 < self.MinCount then
        return
    end
    self.Count = self.Count - 1
    self:RefreshConsumes()
    self:JudgeBuy()
    self.TxtSelect.text = self.Count
    self:SetCanAddOrMinusBtn()
end

function XUiPanelShopItem:BtnAddSelectLongClickCallback(time)
    if self.Count + 1 > self.MaxCount then
        XDataCenter.EquipManager.ShowBoxOverLimitText()
        return
    end

    local delta = math.max(0, math.floor(time / 150))
    self.Count = self.Count + delta
    if self.MaxCount and self.Count >= self.MaxCount then
        self.Count = self.MaxCount
    end

    self:RefreshConsumes()
    self:JudgeBuy()
    self.TxtSelect.text = self.Count
    self:SetCanAddOrMinusBtn()
end

function XUiPanelShopItem:BtnMinusSelectLongClickCallback(time)
    if self.Count - 1 < self.MinCount then
        return
    end
    local delta = math.max(0, math.floor(time / 150))
    self.Count = self.Count - delta
    if self.Count <= 0 then
        self.Count = 0
    end
    self:RefreshConsumes()
    self:JudgeBuy()
    self.TxtSelect.text = self.Count
    self:SetCanAddOrMinusBtn()
end



function XUiPanelShopItem:OnBtnMaxClick()
    if self.Count == self.MaxCount then
        return
    end
    self.Count = math.min(self.MaxCount, self.CanBuyCount)
    self:RefreshConsumes()
    self:JudgeBuy()
    self.TxtSelect.text = self.Count
    self:SetCanAddOrMinusBtn()
end

function XUiPanelShopItem:OnSelectTextChange()
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
    self.Count = tmp
    self:RefreshConsumes()
    self:JudgeBuy()
end

function XUiPanelShopItem:OnSelectTextInputEnd()
    if self.TxtSelect.text == nil or self.TxtSelect.text == "" then
        self.TxtSelect.text = 1
        local tmp = tonumber(self.TxtSelect.text)
        self.Count = tmp
        self:RefreshConsumes()
        self:JudgeBuy()
    end
end

function XUiPanelShopItem:SetCanAddOrMinusBtn()
    self.BtnMinusSelect.interactable = self.Count > self.MinCount
    self.BtnAddSelect.interactable = self.MaxCount > self.Count

    if self.BtnMax then
        self.BtnMax.gameObject:GetComponent("Image").color = self.MaxCount > 1 and CS.UnityEngine.Color(1, 1, 1, 1) or CS.UnityEngine.Color(1, 1, 1, 0.8)
        self.BtnMax.interactable = self.MaxCount > 1
    end

    if self.UiBtnMax then
        self.UiBtnMax:SetDisable(self.MaxCount <= 1)
    end

    if self.PanelTxt then
        self.PanelTxt.gameObject:SetActiveEx(self.MaxCount < MAX_COUNT)
    end

    if self.BuyHintText then
        self.BuyHintText.gameObject:SetActiveEx(self.MaxCount < MAX_COUNT)
    end

    if self.TxtCanBuy then
        self.TxtCanBuy.gameObject:SetActiveEx(self.MaxCount < MAX_COUNT)
        self.TxtCanBuy.text = self.MaxCount
    end
end

function XUiPanelShopItem:OnBtnUseClick()
    if not XDataCenter.PayManager.CheckCanBuy(self.Data.Id) then
        return
    end
    if self.HaveNotBuyCount then
        if not XDataCenter.EquipManager.ShowBoxOverLimitText() then
            XUiManager.TipText("ShopHaveNotBuyCount")
        end
        return
    end

    if not self.Data.PayKeySuffix then
        for k,v in pairs(self.NotEnough or {}) do
            if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(v.ItemId,
                    v.UseItemCount,
                    1,
                    function()
                        self:OnBtnUseClick()
                    end,
                    "BuyNeedItemInsufficient") then
                return
            end
            self.NotEnough[k] = nil
        end
    end

    local func = function()
        self.Cb(self.Count)
        XUiManager.TipText("BuySuccess")
        self.Parent:RefreshBuy()
        self.GameObject:SetActiveEx(false)
    end
    if self.Data.PayKeySuffix then
        local key
        if Platform == RuntimePlatform.Android then
            key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), self.Data.PayKeySuffix)
        else
            key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), self.Data.PayKeySuffix)
        end
        XDataCenter.PayManager.Pay(key, 2, { self.Parent:GetCurShopId(), self.Data.Id }, self.Data.Id, function()
                self.GameObject:SetActiveEx(false)
            end)
    else
        XShopManager.BuyShop(self.Parent:GetCurShopId(), self.Data.Id, self.Count, func)
    end
end

function XUiPanelShopItem:ShowPanel(data, cb)
    if data then
        self.Data = data
    else
        return
    end

    if cb then
        self.Cb = cb
    end

    self.Count = 1
    self.Consumes = {}
    self.BuyConsumes = {}

    XTool.LoopMap(self.Data.ConsumeList, function(_, consume)
        local buyitem = {}
        buyitem.Id = consume.Id
        buyitem.Count = consume.Count
        table.insert(self.Consumes, buyitem)
        local consumes = {}
        consumes.Id = consume.Id
        consumes.Count = 0
        table.insert(self.BuyConsumes, consumes)
    end)

    self:RefreshCommon()
    self:RefreshPrice()
    self:GetSalesInfo()
    self:GetMaxCount()
    self:RefreshConsumes()
    self:SetCanBuyCount()
    self:JudgeBuy()
    self:HaveItem()
    self:SetCanAddOrMinusBtn()
    self.GameObject:SetActiveEx(true)
    self.TxtSelect.text = self.Count
end

function XUiPanelShopItem:HaveItem()
    if XArrangeConfigs.GetType(self.Data.RewardGoods.TemplateId) == XArrangeConfigs.Types.Furniture then
        self.TxtOwnCount.gameObject:SetActiveEx(false)
    else
        local count = XGoodsCommonManager.GetGoodsCurrentCount(self.Data.RewardGoods.TemplateId)
        self.TxtOwnCount.text = CS.XTextManager.GetText("CurrentlyHas", count)
        self.TxtOwnCount.gameObject:SetActiveEx(true)
    end
end

function XUiPanelShopItem:RefreshCommon()
    self.RImgType.gameObject:SetActiveEx(false)

    local rewardGoods = self.Data.RewardGoods
    self.Grid:Refresh(rewardGoods, nil, true)
    self.Grid:ShowCount(true)
end

function XUiPanelShopItem:RefreshPrice()
    if self.TxtYuan then
        self.TxtYuan.gameObject:SetActiveEx(false)
    end
    if self.Data.PayKeySuffix then
        self.PanelPrice.gameObject:SetActiveEx(false)
        if self.TxtYuan then
            self.TxtYuan.gameObject:SetActiveEx(true)
            self.TxtYuan.text = self:GetPayAmount()
        end
    else
        if self.TxtYuan then
            self.TxtYuan.gameObject:SetActiveEx(false)
        end
        if #self.Consumes ~= 0 then
            self.PanelPrice.gameObject:SetActiveEx(true)
            for i = 1, #self.Price do
                if i <= #self.Consumes then
                    self.Price[i].gameObject:SetActiveEx(true)
                else
                    self.Price[i].gameObject:SetActiveEx(false)
                end
            end
        else
            self.PanelPrice.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelShopItem:GetPayAmount()
    local key
    if Platform == RuntimePlatform.Android then
        key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), self.Data.PayKeySuffix)
    else
        key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), self.Data.PayKeySuffix)
    end

    local payConfig = XPayConfigs.GetPayTemplate(key)
    return payConfig and payConfig.Amount or 0
end

function XUiPanelShopItem:RefreshOnSales(buyCount)
    self.OnSales = {}
    XTool.LoopMap(self.Data.OnSales, function(k, sales)
        self.OnSales[k] = sales
    end)
    local sumbuy = buyCount + self.Data.TotalBuyTimes
    if #self.OnSales ~= 0 then
        local curLevel = 0
        for k, v in pairs(self.OnSales) do
            if sumbuy >= k and k > curLevel then
                self.Sales = v
                curLevel = k
            end
        end
    else
        self.Sales = 100
    end
end

function XUiPanelShopItem:RefreshConsumes()
    for i = 1, #self.BuyConsumes do
        self.BuyConsumes[i].Count = 0
    end
    for k, v in pairs(self.Consumes) do
        self.BuyConsumes[k].Id = v.Id
        self.BuyConsumes[k].Count = math.floor(v.Count * self.Sales / 100) * self.Count
    end
    for i = 1, #self.Consumes do
        self["RImgCostIcon" .. i]:SetRawImage(XDataCenter.ItemManager.GetItemBigIcon(self.BuyConsumes[i].Id))
        self["TxtCostCount" .. i].text = math.floor(self.BuyConsumes[i].Count)
    end
end

function XUiPanelShopItem:HidePanel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
end


function XUiPanelShopItem:GetSalesInfo()
    self.OnSales = {}
    XTool.LoopMap(self.Data.OnSales, function(k, sales)
        self.OnSales[k] = sales
    end)
end

function XUiPanelShopItem:GetMaxCount()
    self.Sales = 100
    local sortedKeys = {}
    for k, _ in pairs(self.OnSales) do
        table.insert(sortedKeys, k)
    end
    table.sort(sortedKeys)

    local leftSalesGoods = MAX_COUNT

    for i = 1, #sortedKeys do
        if self.Data.TotalBuyTimes >= sortedKeys[i] - 1 then
            self.Sales = self.OnSales[sortedKeys[i]]
        else
            leftSalesGoods = sortedKeys[i] - self.Data.TotalBuyTimes - 1
            break
        end
    end

    local leftShopTimes = XShopManager.GetShopLeftBuyTimes(self.Parent:GetCurShopId())
    if not leftShopTimes then
        leftShopTimes = MAX_COUNT
    end

    local leftGoodsTimes = MAX_COUNT
    if self.Data.BuyTimesLimit and self.Data.BuyTimesLimit > 0 then
        local buyCount = self.Data.TotalBuyTimes and self.Data.TotalBuyTimes or 0
        leftGoodsTimes = self.Data.BuyTimesLimit - buyCount
    end
    local tmpMaxCount = math.min(leftGoodsTimes, math.min(leftShopTimes, leftSalesGoods))
    self.MaxCount = tmpMaxCount
    self.MaxCount = XDataCenter.EquipManager.GetMaxCountOfBoxOverLimit(self.Data.RewardGoods.TemplateId, self.MaxCount, self.Data.RewardGoods.Count)

    if self.MaxCount < tmpMaxCount then
        self.BuyHintText.text = CS.XTextManager.GetText("MaxCanBuyText")
    else
        self.BuyHintText.text = CS.XTextManager.GetText("CanBuyText")
    end
end

function XUiPanelShopItem:SetCanBuyCount()
    local canBuyCount = self.MaxCount
    for _, v in pairs(self.BuyConsumes) do
        local itemCount = XDataCenter.ItemManager.GetCount(v.Id)
        local buyCount = math.floor(itemCount / v.Count)
        canBuyCount = math.min(buyCount, canBuyCount)
    end
    canBuyCount = math.max(self.MinCount, canBuyCount)
    self.CanBuyCount = canBuyCount
end

function XUiPanelShopItem:JudgeBuy()
    self.HaveNotBuyCount = self.Count > self.MaxCount or self.Count == 0
    if self.HaveNotBuyCount then
        return
    end

    local index = 1
    local enoughIndex = {}
    self.NotEnough = {}

    for _, v in pairs(self.BuyConsumes) do
        local itemCount = XDataCenter.ItemManager.GetCount(v.Id)
        if v.Count > itemCount then
            self:ChangeCostColor(false, index)
            if not self.NotEnough[index] then self.NotEnough[index] = {} end
            self.NotEnough[index].ItemId = v.Id
            self.NotEnough[index].UseItemCount = v.Count
        else
            table.insert(enoughIndex, index)
        end
        index = index + 1
    end

    for _, v in pairs(enoughIndex) do
        self:ChangeCostColor(true, v)
    end
end


function XUiPanelShopItem:ChangeCostColor(bool, index)
    if bool then
        self["TxtCostCount" .. index].color = CS.UnityEngine.Color(0, 0, 0)
    else
        self["TxtCostCount" .. index].color = CS.UnityEngine.Color(1, 0, 0)
    end
end