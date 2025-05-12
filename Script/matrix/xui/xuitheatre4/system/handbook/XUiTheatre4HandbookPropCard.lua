local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")

---@class XUiTheatre4HandbookPropCard : XUiNode
---@field GridProp UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field TxtDetail XUiComponent.XUiRichTextCustomRender
---@field TxtNone UnityEngine.UI.Text
---@field TxtStory UnityEngine.UI.Text
---@field TxtCondition UnityEngine.UI.Text
---@field ImgSelect UnityEngine.UI.Image
---@field BtnYes XUiComponent.XUiButton
---@field TxtNow UnityEngine.UI.Text
---@field BtnClick XUiComponent.XUiButton
---@field _Control XTheatre4Control
local XUiTheatre4HandbookPropCard = XClass(XUiNode, "XUiTheatre4HandbookPropCard")

-- region 生命周期

function XUiTheatre4HandbookPropCard:OnStart()
    ---@type XUiGridTheatre4Prop
    self._GridProp = XUiGridTheatre4Prop.New(self.GridProp, self)
end

-- endregion

---@param entity XTheatre4ItemEntity
function XUiTheatre4HandbookPropCard:Refresh(entity)
    ---@type XTheatre4ItemConfig
    local config = entity:GetConfig()
    local isEligible, desc = entity:IsEligible()
    local isUnlock = entity:IsUnlock()

    self.TxtName.text = config:GetName()
    self._GridProp:Refresh({
        Id = config:GetId(),
        Type = XEnumConst.Theatre4.AssetType.Item,
    })
    self._GridProp:SetLock(not isEligible)
    self._GridProp:SetMask(not isUnlock)
    self.TxtCondition.gameObject:SetActiveEx(not isEligible)
    self.TxtNone.gameObject:SetActiveEx(not isUnlock and isEligible)
    self.TxtDetail.gameObject:SetActiveEx(isEligible and isUnlock)
    
    if isEligible and isUnlock then
        self:_RefreshDetail(config:GetId(), config:GetDesc())
    elseif not isUnlock and isEligible then
        self.TxtNone.text = self._Control:GetClientConfig("NotFoundItemAndGeniusDesc", 1)
    elseif not isEligible then
        self.TxtCondition.text = desc
    end
end

function XUiTheatre4HandbookPropCard:_RefreshDetail(itemId ,desc)
    self.TxtDetail.requestImage = function(key, img)
        if key == "Img1" then
            local descIcon = self._Control:GetItemDescIcon(itemId)
            if descIcon then
                img:SetSprite(descIcon)
            end
        end
    end
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(desc)
end

return XUiTheatre4HandbookPropCard
