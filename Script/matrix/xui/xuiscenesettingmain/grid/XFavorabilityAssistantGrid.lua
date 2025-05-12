-- 好感度专用
---@field _Control XFavorabilityControl
---@class XFavorabilityAssistantGrid
local XFavorabilityAssistantGrid = XClass(XUiNode, "XFavorabilityAssistantGrid")

function XFavorabilityAssistantGrid:OnStart()
    self.BtnAdd.CallBack = function () self.Parent:OnBtnAddAssistListClick() end
end

function XFavorabilityAssistantGrid:RefreshAssist(value)
    self.Value = value
    if value == CS.XTextManager.GetText("AddButton") then
        self:RefreshAddButton(true)
        return
    end
    self:RefreshAddButton(false)

    self.CharId = value
    local data = XMVCA.XCharacter:GetCharacter(value)

    self.CharacterData = data
    self.TrustExp = self._Control:GetTrustExpById(data.Id)
    self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(data.Id))

    local trustLv = data.TrustLv or 1
    self.TxtLevel.text = trustLv
    self.TxtDisplayLevel.text = self._Control:GetWordsWithColor(trustLv, self.TrustExp[trustLv].Name)
    self.Parent:SetUiSprite(self.RImgAIxin, self._Control:GetTrustLevelIconByLevel(data.TrustLv))

    self:OnSelect()
end

-- 如果是AddButton，则这个格子显示一个 + 按钮
function XFavorabilityAssistantGrid:RefreshAddButton(isAdd)
    if isAdd then
        for i = 0, self.Transform.childCount - 1 do
            local childGo = self.Transform:GetChild(i).gameObject
            childGo:SetActiveEx(self.BtnAdd.gameObject.name == childGo.name) 
        end
    else
        for i = 0, self.Transform.childCount - 1 do
            local childGo = self.Transform:GetChild(i).gameObject
            childGo:SetActiveEx(self.BtnAdd.gameObject.name ~= childGo.name) 
        end
    end
end

function XFavorabilityAssistantGrid:OnSelect(flag)
    self.ImgSelected.gameObject:SetActiveEx(flag)
end

return XFavorabilityAssistantGrid