-- 白情
local XUiWhiteValenItemGrid = XClass(nil, "XUiWhiteValenItemGrid")

function XUiWhiteValenItemGrid:Ctor(uiGameObject, itemId)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self:InitPanel(itemId)
end

function XUiWhiteValenItemGrid:InitPanel(itemId)
    if not itemId then return end
    self.ItemId = itemId
    self.RImgItemIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
    local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
    local qualityPath = XArrangeConfigs.GeQualityPath(quality)
    self.ImgQuality:SetSprite(qualityPath)
    self.TxtCount.text = "x0"
    if self.ObjContributionAdd then self.ObjContributionAdd.gameObject:SetActiveEx(false) end
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function() 
        XLuaUiManager.Open("UiTip", self.ItemId, true, nil)
    end)
end

function XUiWhiteValenItemGrid:SetCount(count)
    self.TxtCount.text = "x" .. count
end

function XUiWhiteValenItemGrid:SetContributionAdd(contributionAdd)
    self.ObjContributionAdd.gameObject:SetActiveEx(contributionAdd ~= nil and contributionAdd > 0)
    self.TxtContributionAdd.text = CS.XTextManager.GetText("WhiteValentinePercentAdd", contributionAdd or 0)
end

return XUiWhiteValenItemGrid