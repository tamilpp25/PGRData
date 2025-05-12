local XUiGridTheatre4Genius = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Genius")

---@class XUiTheatre4HandbookGeniusCard : XUiNode
---@field GridGenius UnityEngine.RectTransform
---@field ListTag UnityEngine.RectTransform
---@field GridTag UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field TxtNum UnityEngine.UI.Text
---@field TxtNone UnityEngine.UI.Text
---@field TxtCondition UnityEngine.UI.Text
---@field ImgSelect UnityEngine.UI.Image
---@field BtnClick XUiComponent.XUiButton
---@field BtnYes XUiComponent.XUiButton
local XUiTheatre4HandbookGeniusCard = XClass(XUiNode, "XUiTheatre4HandbookGeniusCard")

-- region 生命周期

function XUiTheatre4HandbookGeniusCard:OnStart()
    ---@type XUiGridTheatre4Genius
    self._GeniusGrid = XUiGridTheatre4Genius.New(self.GridGenius, self)
end

-- endregion

---@param entity XTheatre4ColorTalentEntity
function XUiTheatre4HandbookGeniusCard:Refresh(entity)
    if not entity then
        self._GeniusGrid:SetQuestionMarkState(true)
        self.TxtName.text = XUiHelper.GetText("UnKnown")
        self.ListTag.gameObject:SetActiveEx(false)
        self.TxtDetail.text = ""
        return
    end
    self._GeniusGrid:SetQuestionMarkState(false)

    ---@type XTheatre4ColorTalentConfig
    local config = entity:GetConfig()

    self._GeniusGrid:Refresh(config:GetId())
    self._GeniusGrid:SetLvIcon(self._Control:GetClientConfig("GeniusLevelIcon", config:GetShowLevel()))
    self.ListTag.gameObject:SetActiveEx(false)
    self.TxtName.text = config:GetName()
    
    if entity:IsInGame() then
        -- self.TxtCondition.text = entity:GetTextCondition()
        self.TxtDetail.text = config:GetDesc()
        self.TxtCondition.gameObject:SetActiveEx(false)
        self._GeniusGrid:SetLock(not entity:IsActiveOnGame())
        self._GeniusGrid:SetMask(not entity:IsActiveOnGame())
        -- self.RImgIcon2.gameObject:SetActiveEx()
    else
        local isEligible, desc = entity:IsEligible()
        local isUnlock = entity:IsUnlock()
        
        self._GeniusGrid:SetLock(not isEligible)
        self._GeniusGrid:SetMask(not isUnlock)
        self.TxtCondition.gameObject:SetActiveEx(not isEligible)
        self.TxtNone.gameObject:SetActiveEx(not isUnlock and isEligible)
        self.TxtDetail.gameObject:SetActiveEx(isEligible and isUnlock)
        
        if isEligible and isUnlock then
            self.TxtDetail.text = config:GetDesc()
        elseif not isUnlock and isEligible then
            self.TxtNone.text = self._Control:GetClientConfig("NotFoundItemAndGeniusDesc", 1)
        elseif not isEligible then
            self.TxtCondition.text = desc
        end
    end
end

return XUiTheatre4HandbookGeniusCard
