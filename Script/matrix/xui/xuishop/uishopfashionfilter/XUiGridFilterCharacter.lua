--- 涂装筛选界面角色选项
---@class XUiGridFilterCharacter: XUiNode
local XUiGridFilterCharacter = XClass(XUiNode, 'XUiGridFilterCharacter')

function XUiGridFilterCharacter:OnStart()
    
end

function XUiGridFilterCharacter:RefreshData(characterId)
    self.Id = characterId
    
    self.Name.text = XMVCA.XCharacter:GetCharacterTradeName(self.Id)
    self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(self.Id))
end

function XUiGridFilterCharacter:RefreshSelectedState()
    self.PanelSelected.gameObject:SetActiveEx(self.Id == self.Parent:GetCurSelectedCharacterId() and true or false)
end

return XUiGridFilterCharacter