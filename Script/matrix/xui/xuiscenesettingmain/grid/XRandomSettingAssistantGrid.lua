-- 好感度专用
---@field _Control XFavorabilityControl
---@class XRandomSettingAssistantGrid
local XRandomSettingAssistantGrid = XClass(XUiNode, "XRandomSettingAssistantGrid")

function XRandomSettingAssistantGrid:OnStart()
    self.BtnJoinRandom.CallBack = function () self:OnBtnJoinRandomClick() end
    self.BtnClick.CallBack = function () self:OnBtnClick() end
end

function XRandomSettingAssistantGrid:Refresh(characterId, parentRecordCharFashionSelecteRandomList)
    self.ClickCount = 0
    self.CharacterId = characterId
    self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
    self.TxtName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
    local isRandom = parentRecordCharFashionSelecteRandomList[characterId]
    self.BtnJoinRandom:SetButtonState((isRandom) and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XRandomSettingAssistantGrid:SetJoinClickCallBack(fun)
    self.JoinClickCallBack = fun
end

function XRandomSettingAssistantGrid:OnBtnJoinRandomClick()
    if self.JoinClickCallBack then
        self.JoinClickCallBack(self.CharacterId, self.BtnJoinRandom)
    end
end

function XRandomSettingAssistantGrid:SetClickCallBack(fun)
    self.ClickCallBack = fun
end

function XRandomSettingAssistantGrid:OnBtnClick()
    if self.ClickCallBack then
        self.ClickCallBack(self.CharacterId)
    end
end

function XRandomSettingAssistantGrid:SetSelect(flag)
    self.ImgSelect.gameObject:SetActiveEx(flag)
end

return XRandomSettingAssistantGrid