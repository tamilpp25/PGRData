--===========================
--超级爬塔角色头像控件
--===========================
local XUiSTPluginDetailsRoleHead = XClass(nil, "XUiSTPluginDetailsRoleHead")

function XUiSTPluginDetailsRoleHead:Ctor(uiGameObject)
    XTool.InitUiObjectByUi(self, uiGameObject)
end

function XUiSTPluginDetailsRoleHead:RefreshData(characterId)
    self.CharacterId = characterId
    self:RefreshName()
    self:RefreshIcon()
end

function XUiSTPluginDetailsRoleHead:RefreshName()
    self.TxtName.text = XMVCA.XCharacter:GetCharacterTradeName(self.CharacterId)
end

function XUiSTPluginDetailsRoleHead:RefreshIcon()
    local headIcon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.CharacterId, true)
    self.RImgIcon:SetRawImage(headIcon)
end

function XUiSTPluginDetailsRoleHead:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiSTPluginDetailsRoleHead:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiSTPluginDetailsRoleHead