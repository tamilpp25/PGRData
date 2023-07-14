---@class XGridTheatre3MainCharacter : XUiNode
---@field _Control XTheatre3Control
local XGridTheatre3MainCharacter = XClass(XUiNode, "XGridTheatre3MainCharacter")

function XGridTheatre3MainCharacter:OnStart()
end

function XGridTheatre3MainCharacter:Refresh(slotId)
    local characterId = self._Control:GetSlotCharacter(slotId)
    self.PanelLv.gameObject:SetActiveEx(false)
    self.ImgExp.gameObject:SetActiveEx(false)
    self.ImgRole.gameObject:SetActiveEx(true)
    if not XTool.IsNumberValid(characterId) then
        local noneIcon = self._Control:GetClientConfig("Theatre3NoneCharacterIcon")
        if not string.IsNilOrEmpty(noneIcon) then
            self.ImgRole:SetRawImage(noneIcon)
        else
            self.ImgRole.gameObject:SetActiveEx(false)
        end
    else
        -- 角色头像
        ---@type XCharacterAgency
        local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
        local characterIcon = characterAgency:GetCharSmallHeadIcon(characterId)
        self.ImgRole:SetRawImage(characterIcon)
    end
end

return XGridTheatre3MainCharacter