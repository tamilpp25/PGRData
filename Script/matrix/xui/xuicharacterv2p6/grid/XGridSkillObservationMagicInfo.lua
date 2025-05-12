---@class XGridSkillObservationMagicInfo:XUiNode
local XGridSkillObservationMagicInfo = XClass(XUiNode, "XGridSkillObservationMagicInfo")

--- func desc
---@param cfg XTableCharacterObsTriggerMagic
---@param index number
function XGridSkillObservationMagicInfo:Refresh(cfg, index)
    if not cfg then
        return
    end

    local element = cfg.ObservationElement[index]
    local desc = XUiHelper.ConvertLineBreakSymbol(cfg.Des[index])

    local elementCfg = XMVCA.XCharacter:GetCharElement(element)
    self.TxtElement.text = XMVCA.XCharacter:GetCharElement(element).ElementName
    self.TxtDes.text = desc
    self.RImgIcon:SetRawImage(elementCfg.Icon)
end

return XGridSkillObservationMagicInfo