XUiPanelLikeGiveGift = XClass(nil, "XUiPanelLikeGiveGift")

local Default_Min_Num = 1
local CSTextManagerGetText = CS.XTextManager.GetText
local CommunicationGiftMaxCount = CS.XGame.ClientConfig:GetInt("CommunicationGiftMaxCount")

function XUiPanelLikeGiveGift:Ctor(ui, uiRoot, parentUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.ParentUi = parentUi
    XTool.InitUiObject(self)
    self:InitUiAfterAuto()
    self.GridGiftItem.gameObject:SetActiveEx(false)

end

function XUiPanelLikeGiveGift:InitUiAfterAuto()

    --self:InitBtnLongClicks()
    --self.BtnIncrease.CallBack = function() self:OnBtnIncreaseClick() end
    --self.BtnDecrease.CallBack = function() self:OnBtnDecreaseClick() end
    --self.BtnMax.CallBack = function() self:OnBtnMaxClick() end
    self.BtnUse.CallBack = function() self:OnBtnUseClick() end
    self.BtnGo.CallBack = function() self:OnBtnGoClick() end

end


function XUiPanelLikeGiveGift:OnRefresh()
    self:RefreshDatas()
end

function XUiPanelLikeGiveGift:RefreshDatas()
    self.CurTrustItem = nil
    self.SelectedGifts = {}
    self.SelectGiftItemList = {}
    local trustItems = self:FilterTrustItems(XFavorabilityConfigs.GetAllCharacterSendGift())


    table.sort(trustItems, XDataCenter.FavorabilityManager.SortTrustItems)
    self:UpdateTrustItemList(trustItems)

    -- self:UpdateBottomByClickItem()
    -- self:UpdateTextCount(0)
end

function XUiPanelLikeGiveGift:FilterTrustItems(items)

    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local trustItems = {}
    for _, v in pairs(items) do
        local count = XDataCenter.ItemManager.GetCount(v.Id)
        if count > 0 then
            v.IsFavourWeight = self:IsContains(v.FavorCharacterId, characterId) and 1 or 0
            v.TrustItemQuality = XDataCenter.ItemManager.GetItemQuality(v.Id)
            table.insert(trustItems, v)
        end
    end
    return trustItems
end

function XUiPanelLikeGiveGift:ResetSelectStatus()
    for _, v in pairs(self.TrustItemList or {}) do
        v.IsSelect = false
    end
end

-- [????????????ListView]
function XUiPanelLikeGiveGift:UpdateTrustItemList(trustItemList)
    if not trustItemList then
        XLog.Warning("XUiPanelLikeGiveGift:UpdateTrustItemList ????????????: ??????trustItemList????????????")
    end

    self.TrustItemList = trustItemList
    self:ResetSelectStatus()

    if not self.DynamicTableTrustItem then
        self.DynamicTableTrustItem = XDynamicTableNormal.New(self.SViewGiftList.gameObject)
        self.DynamicTableTrustItem:SetProxy(XUiGridLikeSendGiftItem)
        self.DynamicTableTrustItem:SetDelegate(self)
    end

    local isZero = self:IsZeroGift(self.TrustItemList)
    self.SViewGiftList.gameObject:SetActive(not isZero)
    self.PanelEmpty.gameObject:SetActive(isZero)
    self.BtnUse.gameObject:SetActiveEx(not isZero)

    if not isZero then
        self.DynamicTableTrustItem:SetDataSource(self.TrustItemList)
        self.DynamicTableTrustItem:ReloadDataASync()

    end
end

function XUiPanelLikeGiveGift:IsZeroGift(itemList)
    for _, itemData in pairs(itemList or {}) do
        local itemNum = XDataCenter.ItemManager.GetCount(itemData.Id)
        if itemNum > 0 then
            return false
        end
    end
    return true
end

-- [????????????????????????]
function XUiPanelLikeGiveGift:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot, handler(self, self.Check), handler(self, self.OnGiftChangeCallBack), handler(self, self.PreCheck))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.TrustItemList[index]
        if not data then return end
        local id = data.Id
        local count = self.SelectedGifts[id]
        grid:OnRefresh(data, count)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self:ChekMaxFavorability(self.TrustItemList[index].TrustItemType) then return end
        self.CurTrustItem = self.TrustItemList[index]
    end
end

function XUiPanelLikeGiveGift:PreCheck(itemId)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isMax = XDataCenter.FavorabilityManager.IsMaxFavorabilityLevel(characterId)
    if isMax and itemId ~= 40801 then --????????????????????????????????????????????????????????????????????????
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityMaxLevel"))
        return false
    end

    local curExp = tonumber(XDataCenter.FavorabilityManager.GetCurrCharacterExp(characterId))
    local startLevel = XDataCenter.FavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)

    local addExp = 0
    for i, var in ipairs(self.SelectGiftItemList) do
        local favorExp = var.TrustItem.Exp
        for _, v in pairs(var.TrustItem.FavorCharacterId) do
            if v == characterId then
                favorExp = var.TrustItem.FavorExp
                break
            end
        end
        addExp = addExp + favorExp * var.Count
    end

    local totalExp = addExp + curExp
    local trustLv, leftExp, levelExp = XFavorabilityConfigs.GetFavorabilityLevel(characterId, totalExp, startLevel)

    local maxLevel = XFavorabilityConfigs.GetMaxFavorabilityLevel(characterId)
    if maxLevel == trustLv and itemId ~= 40801 then --????????????????????????????????????????????????????????????????????????
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityMaxLevel"))
        return false
    end

    return true
end


function XUiPanelLikeGiveGift:Check()
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()

    local curExp = tonumber(XDataCenter.FavorabilityManager.GetCurrCharacterExp(characterId))
    local startLevel = XDataCenter.FavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)

    local addExp = 0
    for i, var in ipairs(self.SelectGiftItemList) do
        local favorExp = var.TrustItem.Exp
        for _, v in pairs(var.TrustItem.FavorCharacterId) do
            if v == characterId then
                favorExp = var.TrustItem.FavorExp
                break
            end
        end
        addExp = addExp + favorExp * var.Count
    end

    local totalExp = addExp + curExp
    local trustLv, leftExp, levelExp = XFavorabilityConfigs.GetFavorabilityLevel(characterId, totalExp, startLevel)

    local maxLevel = XFavorabilityConfigs.GetMaxFavorabilityLevel(characterId)
    if maxLevel == trustLv then
        return false
    end

    return true
end


function XUiPanelLikeGiveGift:OnGiftChangeCallBack(itemId, addCount)

    local selectedGifts = self.SelectedGifts[itemId]
    if not selectedGifts then
        selectedGifts = 0
    end

    self.SelectedGifts[itemId] = selectedGifts + addCount
    self.SelectGiftItemList = {}

    for _, v in ipairs(self.TrustItemList) do
        local count = self.SelectedGifts[v.Id]
        if count and count > 0 then
            local gift = {}
            gift.TrustItem = v
            gift.Count = count
            table.insert(self.SelectGiftItemList, gift)
        else
            self.SelectedGifts[v.Id] = nil
        end

    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FAVORABILITY_ON_GIFT_CHANGED, self.SelectGiftItemList)
end

function XUiPanelLikeGiveGift:UpdateSelectStatus(index)
    for i = 1, #self.TrustItemList do
        local item = self.TrustItemList[i]
        if i == index then
            item.IsSelect = not item.IsSelect
        else
            item.IsSelect = false
        end
        local grid = self.DynamicTableTrustItem:GetGridByIndex(i)
        if grid then
            grid:OnRefresh(item, i)
        end
    end
end


function XUiPanelLikeGiveGift:UpdateBottomByClickItem()
    if not self.CurTrustItem then
        self:HideNumBtns()
        self:UpdateTextCount(0)
        return
    end
    local playerCount = XDataCenter.ItemManager.GetCount(self.CurTrustItem.Id)
    if playerCount < Default_Min_Num or (not self.CurTrustItem.IsSelect) then
        self:HideNumBtns()
        self:UpdateTextCount(0)
    else
        self:ShowNumBtns()
        self:UpdateTextCount(Default_Min_Num)
    end
end

function XUiPanelLikeGiveGift:UpdateTextCount(count)
    self.CurrentCount = count
    self.TxtNum.text = self.CurrentCount
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FAVORABILITY_ON_GIFT_CHANGED, self.CurTrustItem, self.CurrentCount)
end


function XUiPanelLikeGiveGift:OnBtnUseClick()

    if not self.SelectedGifts or next(self.SelectedGifts) == nil then
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityChooseAGift"))
        return
    end


    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local characterName = XCharacterConfigs.GetCharacterName(characterId)
    local trustLv = XDataCenter.FavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)
    local curExp = tonumber(XDataCenter.FavorabilityManager.GetCurrCharacterExp(characterId))
    local IsDoCommunication = false
    local IsGivenItem = XDataCenter.FavorabilityManager.IsInGivenItemCharacterIdList(characterId)
    local args = {}

    args.CharacterId = characterId
    args.CharacterName = characterName
    args.GiftItems = self.SelectedGifts
    local addExp = 0

    for i, var in ipairs(self.SelectGiftItemList) do
        local exp = var.TrustItem.Exp

        for _, v in pairs(var.TrustItem.FavorCharacterId) do
            if v == characterId then
                exp = var.TrustItem.FavorExp
                break
            end
        end
        
        if var.TrustItem.TrustItemType == XFavorabilityConfigs.TrustItemType.Communication then
            IsDoCommunication = true
        end

        addExp = addExp + exp * var.Count
    end


    if addExp == 0 then
        return
    end


    local fun = function()
        XDataCenter.FavorabilityManager.OnSendCharacterGift(args, function()
            self.ParentUi:DoFillAmountTween(trustLv, curExp, addExp)
            self:RefreshDatas()
            if IsDoCommunication and not IsGivenItem then
                XDataCenter.CommunicationManager.ShowItemCommunication(args.CharacterId)
                XDataCenter.FavorabilityManager.AddGivenItemCharacterId(args.CharacterId)
            end
            local text
            if self:ChekCharacterIsMaxLevel() then
                text = CS.XTextManager.GetText("GiftGiven")
            else
                text = CS.XTextManager.GetText("FavorabilityAddExp", tostring(args.CharacterName), addExp)
            end
            XUiManager.TipMsg(text)
        end)
    end


    if IsDoCommunication then
        if IsGivenItem then
            self:TipDialog(nil, fun, "GivenGiftText")
        else
            if self:ChekCharacterIsMaxLevel() then
                self:TipDialog(nil, fun, "ExFullGiftText")
            else
                if addExp > 1 then
                    self:TipDialog(nil, fun, "OverGiftText")
                else
                    fun()
                end
            end
        end
    else
        fun()
    end
end



function XUiPanelLikeGiveGift:TipDialog(cancelCb, confirmCb, TextKey)
    local tipTitle = CSTextManagerGetText("TipTitle")
    local content = CSTextManagerGetText(TextKey)

    CsXUiManager.Instance:Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, cancelCb, confirmCb)
end

function XUiPanelLikeGiveGift:OnBtnGoClick()
    XLuaUiManager.Open("UiEquipStrengthenSkip", XDataCenter.FavorabilityManager.GetFavorabilitySkipIds())
end

function XUiPanelLikeGiveGift:IsContains(container, item)
    for _, v in pairs(container or {}) do
        if v == item then
            return true
        end
    end
    return false
end

function XUiPanelLikeGiveGift:GetMaxCountByItem(trustItem)
    if trustItem.TrustItemType == XFavorabilityConfigs.TrustItemType.Communication then
        return CommunicationGiftMaxCount
    end

    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isFavor = self:IsContains(trustItem.FavorCharacterId, characterId)
    local favorExp = isFavor and trustItem.FavorExp or trustItem.Exp
    local curExp = tonumber(XDataCenter.FavorabilityManager.GetCurrCharacterExp(characterId))
    local trustLv = XDataCenter.FavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)
    local maxTrustLv = XFavorabilityConfigs.GetMaxFavorabilityLevel(characterId)
    local levelUpDatas = XFavorabilityConfigs.GetTrustExpById(characterId)

    if trustLv >= maxTrustLv then return 0 end
    local totalNeedExp = 0
    for i = trustLv, maxTrustLv - 1 do
        if i == trustLv then
            totalNeedExp = totalNeedExp + levelUpDatas[i].Exp - curExp
        else
            totalNeedExp = totalNeedExp + levelUpDatas[i].Exp
        end
    end

    local count = math.modf(totalNeedExp / favorExp)
    count = (totalNeedExp % favorExp == 0) and count or count + 1
    return count
end

function XUiPanelLikeGiveGift:OnBtnMaxClick()
    if not self.CurTrustItem then
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityChooseAGift"))
        return
    end

    local playerCount = XDataCenter.ItemManager.GetCount(self.CurTrustItem.Id)
    local count = self:GetMaxCountByItem(self.CurTrustItem)
    if self.CurrentCount >= count then
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityMaxGiftNum"))
        return
    end
    playerCount = (playerCount > count) and count or playerCount

    self:UpdateTextCount(playerCount)
end

function XUiPanelLikeGiveGift:HideNumBtns()
    --self.TxtNum.gameObject:SetActive(false)
    self.BtnIncrease.gameObject:SetActive(false)
    self.BtnDecrease.gameObject:SetActive(false)
    self.BtnMax.gameObject:SetActive(false)
    self.BtnUse.gameObject:SetActive(false)
end

function XUiPanelLikeGiveGift:ShowNumBtns()
    -- self.TxtNum.gameObject:SetActive(true)
    self.BtnIncrease.gameObject:SetActive(true)
    self.BtnDecrease.gameObject:SetActive(true)
    self.BtnMax.gameObject:SetActive(true)
    self.BtnUse.gameObject:SetActive(true)
end

function XUiPanelLikeGiveGift:SetViewActive(isActive)
    self.GameObject:SetActive(isActive)
    if isActive then
        self:RefreshDatas()
    end
end

function XUiPanelLikeGiveGift:ChekMaxFavorability(itemType)
    local isMax = self:ChekCharacterIsMaxLevel()
    local IsCommunicationItem = itemType == XFavorabilityConfigs.TrustItemType.Communication
    if isMax and not IsCommunicationItem then
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityMaxLevel"))
        return true
    end
    return false
end

function XUiPanelLikeGiveGift:ChekCharacterIsMaxLevel()
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isMax = XDataCenter.FavorabilityManager.IsMaxFavorabilityLevel(characterId)
    return isMax
end


function XUiPanelLikeGiveGift:OnSelected(isSelected)
    self.GameObject:SetActive(isSelected)
    if isSelected then
        self:RefreshDatas()
    end
end

return XUiPanelLikeGiveGift