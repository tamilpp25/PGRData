local XPanelQualityUpgradeDetailV2P6 = XClass(XUiNode, "XPanelQualityUpgradeDetailV2P6")
local AttributeShow = {
    Life = 1,
    AttackNormal = 2,
    DefenseNormal = 3,
    Crit = 4,
}

local AttributeNpcAttribType = {
    [AttributeShow.Life] = 1,
    [AttributeShow.AttackNormal] = 11,
    [AttributeShow.DefenseNormal] = 23,
    [AttributeShow.Crit] = 44,
}

function XPanelQualityUpgradeDetailV2P6:OnStart(closeFun)
    self.CloseFun = closeFun
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self:InitButton()
end

function XPanelQualityUpgradeDetailV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDetail, self.OnCloseClick)
end

function XPanelQualityUpgradeDetailV2P6:Refresh(afterEvoQuality)
    self.AfterEvoQuality = afterEvoQuality
    local characterId = self.Parent.ParentUi.CurCharacter.Id
     
    -- 名字和职业
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    local career = self.CharacterAgency:GetCharacterCareer(characterId)
    local careerIcon = XCharacterConfigs.GetNpcTypeIcon(career)
    self.BtnType:SetRawImage(careerIcon)
    self.TxtCharName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName
    -- 独域提示
    local showUniframe = XCharacterConfigs.IsIsomer(characterId)
    self.BtnUniframeTip.gameObject:SetActiveEx(showUniframe)
    
    local oldAttribute = XCharacterConfigs.GetNpcPromotedAttribByQuality(characterId, afterEvoQuality - 1)
    local newAttribute = XCharacterConfigs.GetNpcPromotedAttribByQuality(characterId, afterEvoQuality)
    
    for name, index in pairs(AttributeShow) do
        local panel = self["PanelChar".. index]
        panel:FindTransform("TxtOld"):GetComponent("Text").text = string.format("%.2f", FixToDouble(oldAttribute[AttributeNpcAttribType[index]]))  
        panel:FindTransform("TxtCur"):GetComponent("Text").text = string.format("%.2f", FixToDouble(newAttribute[AttributeNpcAttribType[index]]))  
    end
end

function XPanelQualityUpgradeDetailV2P6:OnCloseClick()
    if self.CloseFun then
        self.CloseFun(self.AfterEvoQuality)
    end
end

return XPanelQualityUpgradeDetailV2P6
