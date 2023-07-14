local XUiGridQualityAttributeV2P6 = XClass(XUiNode, "XUiGridQualityAttributeV2P6")

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

function XUiGridQualityAttributeV2P6:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
end

function XUiGridQualityAttributeV2P6:Refresh(attributeData, characterId)
    local charQuality = self.CharacterAgency:GetCharacterQuality(characterId)
    local qualityIndex = 5
    local quality = attributeData[qualityIndex]
    self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(quality))

    local isCurQuality = charQuality == quality
    self.PanelQualityOn.gameObject:SetActiveEx(isCurQuality)
    self.PanelQualityOff.gameObject:SetActiveEx(not isCurQuality)

    -- 普通属性文本
    for _, i in pairs(AttributeShow) do
        local panel = self["PanelGrowUp"..i]
        local text = panel:FindTransform("TxtGrowUP"):GetComponent("Text")
        text.text = attributeData[i]

        if charQuality == quality then
            text.color = XUiHelper.Hexcolor2Color("34AFF8")
        elseif charQuality > quality then
            text.color = XUiHelper.Hexcolor2Color("000000")
        else
            text.color = XUiHelper.Hexcolor2Color("999999")
        end
    end

    -- 属性加成文本
    local addAttrRes = {} 
    if charQuality == quality then
        addAttrRes = self.CharacterAgency:GetCharQualityAddAttributeTotalInfoV2P6(characterId)
    elseif charQuality > quality then
        addAttrRes = self.CharacterAgency:GetCharQualityAddAttributeTotalInfoV2P6(characterId, quality, XEnumConst.CHARACTER.MAX_QUALITY_STAR)
    end

    local isMaxQuality = quality >= XEnumConst.CHARACTER.MAX_QUALITY
    for panelIndex, npcAttrIndex in pairs(AttributeNpcAttribType) do
        local value = addAttrRes[npcAttrIndex]
        local panel = self["PanelGrowUp"..panelIndex]
        local text = panel:FindTransform("TxtAdd"):GetComponent("Text")
        local max = panel:FindTransform("TxtAddMax")
        
        if value then
            text.text = "+" .. value
        else    
            text.text = "+0"
        end

        text.gameObject:SetActiveEx(not isMaxQuality)
        max.gameObject:SetActiveEx(isMaxQuality)
    
        if charQuality >= quality then
            text.color = XUiHelper.Hexcolor2Color("34AFF8")
        else
            text.color = XUiHelper.Hexcolor2Color("999999")
        end
    end
end

return XUiGridQualityAttributeV2P6