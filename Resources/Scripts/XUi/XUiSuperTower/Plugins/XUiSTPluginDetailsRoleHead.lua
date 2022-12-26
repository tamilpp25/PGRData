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
    self.TxtName.text = XCharacterConfigs.GetCharacterTradeName(self.CharacterId)
end

function XUiSTPluginDetailsRoleHead:RefreshIcon()
    local headIcon = XDataCenter.CharacterManager.GetDefaultCharSmallHeadIcon(self.CharacterId)
    self.RImgIcon:SetRawImage(headIcon)
end

function XUiSTPluginDetailsRoleHead:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiSTPluginDetailsRoleHead:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiSTPluginDetailsRoleHead