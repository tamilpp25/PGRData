---@class XUiGridTheatre3CharacterEnding : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiPanelTheatre3CharacterDetail
local XUiGridTheatre3CharacterEnding = XClass(XUiNode, "XUiGridTheatre3CharacterEnding")

function XUiGridTheatre3CharacterEnding:OnStart()
    if not self.Lock then
        ---@type UnityEngine.Transform
        self.Lock = XUiHelper.TryGetComponent(self.Transform, "Lock")
    end
end

function XUiGridTheatre3CharacterEnding:Refresh(id)
    local isEnding = self._Control:CheckCharacterEnding(id)
    
    self.TxtTitle.text = self._Control:GetCharacterEndingTitle(id)
    self.TxtDescribe.text = self._Control:GetCharacterEndingDesc(id)
    self.TxtTitle.gameObject:SetActiveEx(true)
    self.TxtDescribe.gameObject:SetActiveEx(true)
    self.TxtComplete.gameObject:SetActiveEx(isEnding)
    self.PanelUnComplete.gameObject:SetActiveEx(not isEnding)
    if self.Lock then
        self.Lock.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre3CharacterEnding:RefreshLock()
    self.TxtTitle.gameObject:SetActiveEx(false)
    self.TxtDescribe.gameObject:SetActiveEx(false)
    self.TxtComplete.gameObject:SetActiveEx(false)
    self.PanelUnComplete.gameObject:SetActiveEx(true)
    if self.Lock then
        self.Lock.gameObject:SetActiveEx(true)
    end
end

return XUiGridTheatre3CharacterEnding