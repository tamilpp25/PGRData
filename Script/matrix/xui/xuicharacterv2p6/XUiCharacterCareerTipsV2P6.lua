local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
local XUiCharacterCareerTipsV2P6 = XLuaUiManager.Register(XLuaUi, "UiCharacterCareerTipsV2P6")
local XUiGridCharacterCareerV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiGridCharacterCareerV2P6")

function XUiCharacterCareerTipsV2P6:OnAwake()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self.GridElementDetail.gameObject:SetActiveEx(false)

    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    self:InitDynamicTable()
end

function XUiCharacterCareerTipsV2P6:OnStart(characterId)
    self.CharacterId = characterId
end

function XUiCharacterCareerTipsV2P6:OnEnable()
    self.TxtTitle.text = CS.XTextManager.GetText(self.Name)
    self:UpdateDynamicTable()
end

function XUiCharacterCareerTipsV2P6:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelElementDetails)
    self.DynamicTable:SetProxy(XUiGridCharacterCareerV2P6, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiCharacterCareerTipsV2P6:UpdateDynamicTable()
    local careerIds = XMVCA.XCharacter:GetAllCharacterCareerIds()
    self.DataSources = careerIds
    self.DynamicTable:SetDataSource(careerIds)

    local curCareerId = self.CharacterAgency:GetCharacterCareer(self.CharacterId)
    local _, index = table.contains(careerIds, curCareerId)
    self.DynamicTable:ReloadDataASync(index or 1)
end

function XUiCharacterCareerTipsV2P6:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataSources[index], self.CharacterId)
    end
end