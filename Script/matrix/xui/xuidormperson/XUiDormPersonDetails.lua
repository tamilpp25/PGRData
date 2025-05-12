local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")



local XUiDormPersonDetails = XClass(nil, "XUiDormPersonDetails")

local TabConfig = {
    XDormConfig.DORM_CHAR_INDEX.CHARACTER,
    XDormConfig.DORM_CHAR_INDEX.INFESTOR,
    XDormConfig.DORM_CHAR_INDEX.EMNEY,
    XDormConfig.DORM_CHAR_INDEX.HUMAN,
    XDormConfig.DORM_CHAR_INDEX.NIER
}

function XUiDormPersonDetails:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.CharacterIdsMap = {}
    self.FromDorm = false
    self:InitTab()
end

function XUiDormPersonDetails:RegisterAnimationCb(animCb)
    self.PlayAnimationCb = animCb
end

function XUiDormPersonDetails:InitTab()
    local tab = {}
    for idx, charType in ipairs(TabConfig) do
        local btn = idx == 1 and self.BtnBase1 or XUiHelper.Instantiate(self.BtnBase1, self.BtnTogs.transform)
        btn:SetNameByGroup(0, XUiHelper.GetText("DormTextCharType" .. charType))
        table.insert(tab, btn)
    end
    self.BtnTogs:Init(tab, function(tabIndex) self:OnSelectTab(tabIndex)  end)
    
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetProxy(require("XUi/XUiDormBag/XUiGridDormCharacter"), self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDormPersonDetails:Show()
    local tabIndex = self.TabIndex or 1
    self.GameObject:SetActiveEx(true)
    self.BtnTogs:SelectIndex(tabIndex)
end

function XUiDormPersonDetails:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiDormPersonDetails:OnSelectTab(tabIndex)
    if self.TabIndex == tabIndex then
        return
    end
    self.TabIndex = tabIndex
    self.PlayAnimationCb("QieHuanDetails")
    self:SetupDynamicTable()
    
end

function XUiDormPersonDetails:SetupDynamicTable()
    local ids = self:GetCharacterIdsList()
    local allCount = XDormConfig.GetDormCharacterTemplatesCountByType(XDormConfig.GetDormCharacterType(TabConfig[self.TabIndex]))
    self.TxtCount.text = XUiHelper.GetText(self:GetTextKey(), #ids, allCount)
    
    self.DataList = ids
    self.PanelEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(ids))
    self.DynamicTable:SetDataSource(ids)
    self.DynamicTable:ReloadDataSync()
    self.Item.gameObject:SetActiveEx(false)
end

function XUiDormPersonDetails:OnDynamicTableEvent(evt, index, grid) 
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end

function XUiDormPersonDetails:GetTextKey()
    local charType = TabConfig[self.TabIndex]
    if not charType then
        return "DormBagCharacterCount"
    end

    if charType == XDormConfig.DORM_CHAR_INDEX.CHARACTER then
        return "DormBagCharacterCount"
    elseif charType == XDormConfig.DORM_CHAR_INDEX.INFESTOR then
        return "DormBagInfestorCount"
    elseif charType == XDormConfig.DORM_CHAR_INDEX.EMNEY then
        return "DormBagEmneyCount"
    elseif charType == XDormConfig.DORM_CHAR_INDEX.HUMAN then
        return "DormBagHumanrCount"
    elseif charType == XDormConfig.DORM_CHAR_INDEX.NIER then
        return "DormBagNiErCount"
    end
    return "DormBagCharacterCount"
end

function XUiDormPersonDetails:GetCharacterIdsList()
    if not XTool.IsNumberValid(self.TabIndex) then
        return {}
    end
    
    if self.CharacterIdsMap[self.TabIndex] then
        return self.CharacterIdsMap[self.TabIndex]
    end

    local charType = TabConfig[self.TabIndex]
    local characterIds = XDataCenter.DormManager.GetDormCharacterIds(XDormConfig.GetDormCharacterType(charType))
    self.CharacterIdsMap[self.TabIndex] = characterIds
    return characterIds
end

return XUiDormPersonDetails