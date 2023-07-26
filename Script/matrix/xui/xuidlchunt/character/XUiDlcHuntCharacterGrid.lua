---@class XUiDlcHuntCharacterGrid
local XUiDlcHuntCharacterGrid = XClass(nil, "XUiDlcHuntCharacterGrid")

function XUiDlcHuntCharacterGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntCharacter
    self._ViewModel = false
    self._Character = false
    self:Init()
end

function XUiDlcHuntCharacterGrid:Init()
    self._UiPanelNormal = { Transform = self.PanelNormal.transform, GameObject = self.PanelNormal.gameObject }
    XTool.InitUiObject(self._UiPanelNormal)
    self._UiPanelSelected = { Transform = self.PanelSelected.transform, GameObject = self.PanelSelected.gameObject }
    XTool.InitUiObject(self._UiPanelSelected)
end

function XUiDlcHuntCharacterGrid:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

---@param character XDlcHuntCharacter
function XUiDlcHuntCharacterGrid:Update(character)
    self._Character = character
    self:UpdateSelected()
end

function XUiDlcHuntCharacterGrid:UpdateSelected()
    local character = self._Character
    local isSelected = self._ViewModel:IsSelected(self._Character)
    local panel
    if isSelected then
        panel = self._UiPanelSelected
        self._UiPanelSelected.GameObject:SetActiveEx(true)
        self._UiPanelNormal.GameObject:SetActiveEx(false)
    else
        panel = self._UiPanelNormal
        self._UiPanelSelected.GameObject:SetActiveEx(false)
        self._UiPanelNormal.GameObject:SetActiveEx(true)
    end
    panel.RImgHeadIcon:SetRawImage(character:GetIcon())
    panel.TxtLevel.text = character:GetFightingPower()
    panel.ImgWar.gameObject:SetActiveEx(character:IsOnFight())
    local strCode = character:GetCode()
    local number = tonumber(strCode)
    if number and number < 10 then
        strCode = "0" .. strCode
    end
    if isSelected then
        strCode = string.gsub(strCode, "0", "<color=#A1CACC>0</color>")
    else
        strCode = string.gsub(strCode, "0", "<color=#54B1B7>0</color>")
    end
    panel.TxtNumber.text = strCode
    self.ImgRedPoint.gameObject:SetActiveEx(self._Character:IsCanEquipMoreChip())
end

return XUiDlcHuntCharacterGrid