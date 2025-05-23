local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridElementDetail = require("XUi/XUiCharacter/XUiGridElementDetail")

local tableInsert = table.insert

local XUiCharacterElementDetail = XLuaUiManager.Register(XLuaUi, "UiCharacterElementDetail")

function XUiCharacterElementDetail:OnAwake()
    self.GridElementDetail.gameObject:SetActiveEx(false)
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self:InitDynamicTable()
end

function XUiCharacterElementDetail:OnStart(characterId)
    self.CharacterId = characterId
end

function XUiCharacterElementDetail:OnEnable()
    self.TxtTitle.text = CS.XTextManager.GetText(self.Name)
    self:UpdateDynamicTable()
end

function XUiCharacterElementDetail:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelElementDetails)
    self.DynamicTable:SetProxy(XUiGridElementDetail)
    self.DynamicTable:SetDelegate(self)
end

function XUiCharacterElementDetail:UpdateDynamicTable()
    self.SortedElementIds = XUiCharacterElementDetail.ConstructSortedElementIds(self.CharacterId)
    self.DynamicTable:SetDataSource(self.SortedElementIds)
    self.DynamicTable:ReloadDataASync()
end

function XUiCharacterElementDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.CharacterId, self.SortedElementIds[index])
    end
end

function XUiCharacterElementDetail.ConstructSortedElementIds(characterId)
    local sortedElementIds = {}

    local curElementIdsCheckDic = {}
    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(characterId)
    local curElementList = detailConfig.ObtainElementList
    for _, elementId in pairs(curElementList) do
        curElementIdsCheckDic[elementId] = true
        tableInsert(sortedElementIds, -elementId)
    end

    local allElementIds = XMVCA.XCharacter:GetModelCharacterElement()
    for _, element in pairs(allElementIds) do
        local elementId = element.Id
        if not curElementIdsCheckDic[elementId] then
            tableInsert(sortedElementIds, elementId)
        end
    end

    return sortedElementIds
end