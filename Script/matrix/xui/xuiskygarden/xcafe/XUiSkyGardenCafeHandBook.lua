local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")


---@class XUiSkyGardenCafeHandBook : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
local XUiSkyGardenCafeHandBook = XLuaUiManager.Register(XLuaUi, "UiSkyGardenCafeHandBook")

local XUiGridSGCardItem = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardItem")
local XUiSGGridQualityLimit = require("XUi/XUiSkyGarden/XCafe/Grid/XUiSGGridQualityLimit")

local UiType = XMVCA.XSkyGardenCafe.UIType
local CsSelect = CS.UiButtonState.Select
local CsNormal = CS.UiButtonState.Normal

local ClickSmallCd = 0.1

function XUiSkyGardenCafeHandBook:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafeHandBook:OnStart(uiType, maxCustomer, stageId)
    self._UiType = uiType
    self._MaxCustomer = maxCustomer
    self._StageId = stageId
    self:InitView()
end

function XUiSkyGardenCafeHandBook:OnEnable()
    local id = self._Control:GetAndClearStageIdCache()
    if id and id > 0 and id ~= self._StageId then
        self._StageId = id
        self:InitView()
    end
end

function XUiSkyGardenCafeHandBook:OnDisable()
    self._AddCardId = nil
end

function XUiSkyGardenCafeHandBook:OnDestroy()
    self._Control:RestoreDeck()
end

function XUiSkyGardenCafeHandBook:InitUi()
    self._ClickSmallTime = os.clock()
    local qualityDict = self._Control:GetQualityLimitDict()
    local list = {}
    for quality, limit in pairs(qualityDict) do
        list[#list + 1] = {
            Quality = quality,
            Limit = limit
        }
    end
    table.sort(list, function(a, b) 
        return a.Quality < b.Quality
    end)
    self._QualityList = list
    self._GridQualities = {}
    local tab = {
        self.BtnTab1,
        self.BtnTab2,
        self.BtnTab3,
    }
    self.PanelTab:Init(tab, function(index) self:OnSelectTab(index) end)
    
    self._VDynamicTable = XDynamicTableNormal.New(self.VListCard)
    self._VDynamicTable:SetProxy(XUiGridSGCardItem, self)
    self._VDynamicTable:SetDelegate(self)
    self._VDynamicTable:SetDynamicEventDelegate(handler(self, self.OnVDynamicTableEvent))
    self.GridCard.gameObject:SetActiveEx(false)
    
    
    self._GDynamicTable = XDynamicTableNormal.New(self.GListCard)
    self._GDynamicTable:SetProxy(XUiGridSGCardItem, self)
    self._GDynamicTable:SetDelegate(self)
    self._GDynamicTable:SetDynamicEventDelegate(handler(self, self.OnGDynamicTableEvent))
    self.UiSkyGardenCafeCard.gameObject:SetActiveEx(false)

    local isShowDetail = self._Control:IsShowCardDetail()
    local state = isShowDetail and CsSelect or CsNormal
    self.BtnToggle:SetButtonState(state)
end

function XUiSkyGardenCafeHandBook:InitCb()
    self.BtnBack.CallBack = function() self:Close() end
    
    self.BtnDelete.CallBack = function() self:OnBtnDeleteClick() end
    
    self.BtnStart.CallBack = function() self:OnBtnStartClick() end
    
    self.BtnSave.CallBack = function() self:OnBtnSaveClick() end
    
    self.BtnToggle.CallBack = function() self:OnBtnToggleClick() end
    
    self._SortCardIdCb = function(idA, idB)
        local pA = self._Control:GetCustomerQuality(idA)
        local pB = self._Control:GetCustomerQuality(idB)
        if pA ~= pB then
            return pA > pB
        end
        local qA = self._Control:GetCustomerPriority(idA)
        local qB = self._Control:GetCustomerPriority(idB)
        if qA ~= qB then
            return qA > qB
        end
        return idA < idB
    end
    
    self._SortCardCb = function(a, b) 
        return self._SortCardIdCb(a:GetId(), b:GetId())
    end
end

function XUiSkyGardenCafeHandBook:InitView()
    self.BtnDelete.gameObject:SetActiveEx(true)
    local isDeckEditor = self._UiType == UiType.DeckEditor
    self.BtnStart.gameObject:SetActiveEx(isDeckEditor)
    self.BtnSave.gameObject:SetActiveEx(self._UiType == UiType.HandleBook)
    --self.PanelScore.gameObject:SetActiveEx(isDeckEditor)
    --if isDeckEditor then
    --    self.TxtCoffeeNum.text = self._Control:GetHighestChallengeScore()
    --end

    self.UiSkyGardenCafeGridBuff.gameObject:SetActiveEx(false)
    if isDeckEditor then
        local buffListId = self._Control:GetStageBuffListId(self._StageId)
        if buffListId and buffListId > 0 then
            self._GridBuff = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGBuffItem").New(self.UiSkyGardenCafeGridBuff, self, buffListId)
            self._GridBuff:Open()
        end
    end
    
    local selectId = self._Control:GetSelectDeckId()
    self.PanelTab:SelectIndex(selectId)
    
    self:RefreshQualityLimit()
end

function XUiSkyGardenCafeHandBook:OnBtnDeleteClick()
    self._Deck:Clear()
    
    self:SetupDynamicTable()
    self:SetupOwnDynamicTable(true)
    
    self:RefreshQualityLimit()
end

function XUiSkyGardenCafeHandBook:OnBtnStartClick()
    if self._Deck:Total() < self._MaxCustomer then
        XUiManager.TipMsg(self._Control:GetDeckNumNotEnoughText())
        return
    end
    if not XTool.IsTableEmpty(self._Quality2Count) then
        for q, data in pairs(self._Quality2Count) do
            local limit = data.Limit
            if limit > 0 and limit < data.Count then
                XUiManager.TipMsg(self._Control:GetQualityReachedLimitText())
                return
            end
        end
    end
    self._Control:SetFightData(self._StageId, self._Deck:GetId())
    XMVCA.XSkyGardenCafe:EnterGameLevel()
end

function XUiSkyGardenCafeHandBook:OnBtnSaveClick()
    if self._Deck:Total() < self._MaxCustomer then
        XUiManager.TipMsg(self._Control:GetDeckNumNotEnoughText())
        return
    end
    if not XTool.IsTableEmpty(self._Quality2Count) then
        for q, data in pairs(self._Quality2Count) do
            local limit = data.Limit
            if limit > 0 and limit < data.Count then
                XUiManager.TipMsg(self._Control:GetQualityReachedLimitText())
                return
            end
        end
    end
    local deckId = self._Deck:GetId()
    self._Control:SaveDeckRequest(deckId)
end

function XUiSkyGardenCafeHandBook:OnBtnToggleClick()
    local isShowDetail = self._Control:IsShowCardDetail()
    isShowDetail = not isShowDetail
    local state = isShowDetail and CsSelect or CsNormal
    self.BtnToggle:SetButtonState(state)
    
    self._Control:MarkShowCardDetailValue(isShowDetail)
    
    self:SetupOwnDynamicTable(true)
end

function XUiSkyGardenCafeHandBook:OnSelectTab(index)
    if self._TabIndex == index then
        return
    end
    
    local deckId = XMVCA.XSkyGardenCafe.DeckIds[index]
    if not deckId then
        index = 1
        deckId = XMVCA.XSkyGardenCafe.DeckIds[index]
        XLog.Error("不存在卡组Id")
        self.PanelTab:SelectIndex(index, false)
        return
    end
    self:PlayAnimationWithMask("PageSwitch")
    self._Deck = self._Control:GetCardDeck(deckId)
    self._TabIndex = index
    self:SetupDynamicTable()
    self:SetupOwnDynamicTable()
end

function XUiSkyGardenCafeHandBook:SetupDynamicTable(cardId, isAdd)
    local dataList = self._Deck:GetCardList()
    table.sort(dataList, self._SortCardCb)
    self._CardList = dataList
    local startIndex
    if cardId and isAdd then
        for i, card in pairs(dataList) do
            if card:GetId() == cardId then
                startIndex = i
                break
            end
        end
    end
    self._AddCardId = isAdd and cardId or nil
    self._VDynamicTable:SetDataSource(dataList)
    self._VDynamicTable:ReloadDataSync(startIndex)
    
    local total = self._Deck:Total()
    self.TxtNum.text = string.format("%d/%d", total, self._MaxCustomer)
    if self._UiType == UiType.DeckEditor then
        local disable = total < self._MaxCustomer
        self.BtnStart:SetDisable(disable)
    end
end

function XUiSkyGardenCafeHandBook:SetupOwnDynamicTable(isRefreshOnly)
    local dataList = self._Control:GetAllShowCustomerIds()
    table.sort(dataList, self._SortCardIdCb)
    self._AllList = dataList
    
    self._GDynamicTable:SetDataSource(dataList)
    if isRefreshOnly then
        for i, cardId in pairs(dataList) do
            local grid = self._GDynamicTable:GetGridByIndex(i)
            if grid then
                self:DoRefreshBigItem(grid, cardId)
            end
        end
    else
        self._GDynamicTable:ReloadDataSync()
    end
    
end

---@param grid XUiGridSGCardItem
function XUiSkyGardenCafeHandBook:DoRefreshBigItem(grid, cardId)
    if not grid then
        return
    end
    local card = self._Control:GetOwnCardDeck():GetOrAddCard(cardId)
    local deckCard = self._Deck:GetOrAddCard(cardId)
    local userCount = deckCard:Count()
    grid:RefreshBig(card, userCount)
end

function XUiSkyGardenCafeHandBook:OnVDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshSmall(self._CardList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickSmallItem(index, grid)
    elseif evt  == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self._AddCardId then
            ---@type XUiGridSGCardItem[]
            local grids = self._VDynamicTable:GetGrids()
            ---@type XUiGridSGCardItem
            local t
            for _, g in pairs(grids) do
                if g:GetCardId() == self._AddCardId then
                    t = g
                    break
                end
            end
            if t then
                t:PlayEnableEffect()
            end
        end
    end
end

function XUiSkyGardenCafeHandBook:OnGDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local cardId = self._AllList[index]
        self:DoRefreshBigItem(grid, cardId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickBigItem(index, grid)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Recycle()
    end
end

function XUiSkyGardenCafeHandBook:OnClickSmallItem(index, grid)
    local now = os.clock()
    if now - self._ClickSmallTime < ClickSmallCd then
        return
    end
    self._ClickSmallTime = now
    local card = self._CardList[index]
    local cardId = card:GetId()
    self._Deck:RemoveAt(cardId)
    local targetId
    if card:Count() <= 0 then
        local targetIndex = index == 1 and 2 or index - 1
        local targetCard = self._CardList[targetIndex]
        if targetCard then
            targetId = targetCard:GetId()
        end
    else
        targetId = cardId
    end
    self:SetupDynamicTable(targetId)
    self:SetupOwnDynamicTable(true)
    self:RefreshQualityLimit()
end

function XUiSkyGardenCafeHandBook:OnClickBigItem(index, grid)
    local id = self._AllList[index]
    local card = self._Control:GetOwnCardDeck():GetOrAddCard(id)
    if not card then
        return
    end
    if not card:IsUnlock() then
        XUiManager.TipMsg(self._Control:GetCardLockedText())
        return
    end
    local userCount = self._Deck:GetOrAddCard(id):Count()
    if card:PreviewCount(userCount) <= 0 then
        XUiManager.TipMsg(self._Control:GetCardUsedUpText())
        return
    end
    if self._Deck:Total() >= self._MaxCustomer then
        XUiManager.TipMsg(self._Control:GetDeckNumIsFullText())
        return
    end
    local quality = self._Control:GetCustomerQuality(id)
    local data = self._Quality2Count[quality]
    if data and data.Limit <= data.Count then
        XUiManager.TipMsg(self._Control:GetQualityReachedLimitText())
        return
    end
    self._Deck:Insert(id)
    userCount = userCount + 1
    grid:RefreshBig(card, userCount)
    self:SetupDynamicTable(id, true)

    self:RefreshQualityLimit()
end

function XUiSkyGardenCafeHandBook:RefreshQualityLimit()
    local cardList = self._Deck:GetCardList()
    local quality2Count = {}
    for _, card in pairs(cardList) do
        local id = card:GetId()
        local quality = self._Control:GetCustomerQuality(id)
        local count = 0
        if not quality2Count[quality] then
            quality2Count[quality] = {
                Count = 0,
                Limit = 0
            }
        else
            count = quality2Count[quality].Count
        end
        count = count + card:Count()
        quality2Count[quality].Count = count
    end
    for i, data in pairs(self._QualityList) do
        local grid = self._GridQualities[i]
        if not grid then
            local ui = i == 1 and self.GridConfine or XUiHelper.Instantiate(self.GridConfine, self.PanelConfine)
            grid = XUiSGGridQualityLimit.New(ui, self)
            self._GridQualities[i] = grid
        end
        local quality = data.Quality
        local limit = data.Limit
        local count = quality2Count[quality] and quality2Count[quality].Count or 0
        grid:Refresh(quality, limit, count)
        if quality2Count[quality] then
            quality2Count[quality].Limit = data.Limit
        end
    end
    self._Quality2Count = quality2Count
end