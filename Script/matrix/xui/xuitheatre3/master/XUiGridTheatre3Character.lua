---@class XUiGridTheatre3Character : XUiNode
---@field _Control XTheatre3Control
---@field ImgExp UnityEngine.UI.Image
local XUiGridTheatre3Character = XClass(XUiNode, "XUiGridTheatre3Character")

function XUiGridTheatre3Character:OnStart(callBack)
    self.CallBack = callBack
    self.TxtLoad.gameObject:SetActiveEx(false)
    self._Control:RegisterClickEvent(self, self.CharacterGrid, self.OnBtnCharacterClick)
end

function XUiGridTheatre3Character:Refresh(characterId)
    self.CharacterId = characterId
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local characterIcon = characterAgency:GetCharSmallHeadIcon(characterId)
    -- 角色头像
    self.ImgRole:SetRawImage(characterIcon)
    -- 角色等级
    local level = self._Control:GetCharacterLv(characterId)
    self.TxtLv.text = level
end

function XUiGridTheatre3Character:SetCharacterSelect(isSelect)
    if self.Select then
        self.Select.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridTheatre3Character:ShowRed(isShow)
    if self.CharacterGrid then
        self.CharacterGrid:ShowReddot(isShow)
    end
end

function XUiGridTheatre3Character:OnBtnCharacterClick()
    if self.CallBack then
        self.CallBack(self)
    end
end

return XUiGridTheatre3Character