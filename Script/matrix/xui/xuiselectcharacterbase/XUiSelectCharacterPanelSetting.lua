local XUiSelectCharacterBase = require("XUi/XUiSelectCharacterBase/XUiSelectCharacterBase")

---@class XUiSelectCharacterPanelSetting:XUiSelectCharacterBase
local XUiSelectCharacterPanelSetting = XLuaUiManager.Register(XUiSelectCharacterBase, "UiSelectCharacterPanelSetting")

function XUiSelectCharacterPanelSetting:Ctor()
    self._Team = false
    self._Index = 0
    self._Callback = false
end

function XUiSelectCharacterPanelSetting:OnStart(team, index, callback)
    self.InitSeleCharId = team[index] -- 默认选择的角色
    self._Team = team
    self._Callback = callback
    self._Index = index
    self:InitFilter()
end

function XUiSelectCharacterPanelSetting:RefreshMid()
    if not self.CurCharacter then
        self.BtnJoin.gameObject:SetActiveEx(false)
        self.BtnQuit.gameObject:SetActiveEx(false)
        return
    end
    if not self._Team then
        return
    end
    local selectCharacterId = self.CurCharacter.Id
    if self:IsOnTeam(selectCharacterId) then
        self.BtnJoin.gameObject:SetActiveEx(false)
        self.BtnQuit.gameObject:SetActiveEx(true)
    else
        self.BtnJoin.gameObject:SetActiveEx(true)
        self.BtnQuit.gameObject:SetActiveEx(false)
    end
end

function XUiSelectCharacterPanelSetting:OnBtnJoinClick(...)
    if not self._Team then
        return
    end
    local selectCharacterId = self.CurCharacter.Id
    self._Team[self._Index] = selectCharacterId
    self._Callback(self._Team)
    self:RefreshMid()
    XUiSelectCharacterBase.OnBtnJoinClick(self, ...)
end

function XUiSelectCharacterPanelSetting:OnBtnQuitClick(...)
    if not self.CurCharacter then
        return
    end
    local selectCharacterId = self.CurCharacter.Id
    local isOnTeam, index = self:IsOnTeam(selectCharacterId)
    if isOnTeam then
        self._Team[index] = 0
        self._Callback(self._Team)
    end
    XUiSelectCharacterBase.OnBtnQuitClick(self, ...)
end

function XUiSelectCharacterPanelSetting:GetGridProxy()
    local XUiSelectCharacterPanelSettingGrid = require("XUi/XUiSelectCharacterBase/XUiSelectCharacterPanelSettingGrid")
    return XUiSelectCharacterPanelSettingGrid
end

function XUiSelectCharacterPanelSetting:IsOnTeam(characterId)
    for i = 1, #self._Team do
        local id = self._Team[i]
        if id == characterId then
            return true, i
        end
    end
    return false
end

return XUiSelectCharacterPanelSetting
