local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGeneralSkillObtainTips = XLuaUiManager.Register(XLuaUi, "UiGeneralSkillObtainTips")

function XUiGeneralSkillObtainTips:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    self:InitDynamicTable()
end

function XUiGeneralSkillObtainTips:OnStart(generalSkillIdList, characterId)
    self.GeneralSkillIdList = generalSkillIdList
    self.CharacterId = characterId
end

function XUiGeneralSkillObtainTips:InitDynamicTable()
    local XUiGridGeneralSkillObtain = require("XUi/XUiCharacterV2P6/Grid/XUiGridGeneralSkillObtain")
    self.DynamicTable = XDynamicTableNormal.New(self.ListGeneralSkill)
    self.DynamicTable:SetProxy(XUiGridGeneralSkillObtain, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiGeneralSkillObtainTips:UpdateDynamicTable()
    self.DynamicTable:SetDataSource(self.GeneralSkillIdList)
    self.DynamicTable:ReloadDataASync()
end

function XUiGeneralSkillObtainTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.GeneralSkillIdList[index], self.CharacterId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local generalSkillId = self.GeneralSkillIdList[index]
        local charaterAllGeneralSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(self.CharacterId) 
        local isIn, realIndexInCharaterAllGeneralSkillIds = table.contains(charaterAllGeneralSkillIds, generalSkillId)
        if not isIn then
            return
        end
        XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill, realIndexInCharaterAllGeneralSkillIds)
    end
end

function XUiGeneralSkillObtainTips:OnEnable()
    self:UpdateDynamicTable()
end