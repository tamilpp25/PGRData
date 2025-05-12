local XUiGridBagOrganizeOptionPrice = XClass(XUiNode, 'XUiGridBagOrganizeOptionPrice')

function XUiGridBagOrganizeOptionPrice:SetAddShow(label, value)
    self.TxtName.text = label
    self.TxtNumExtraAdd.text = XUiHelper.FormatText(self._Control:GetClientConfigText('GoodsValueShowLabel'), value)
    self.TxtNumExtraAdd.gameObject:SetActiveEx(true)
    self.TxtNumExtraMinus.gameObject:SetActiveEx(false)
end

function XUiGridBagOrganizeOptionPrice:SetMinusShow(label, value)
    self.TxtName.text = label
    self.TxtNumExtraMinus.text = XUiHelper.FormatText(self._Control:GetClientConfigText('GoodsCostShowLabel'), value)
    self.TxtNumExtraAdd.gameObject:SetActiveEx(false)
    self.TxtNumExtraMinus.gameObject:SetActiveEx(true)
end

return XUiGridBagOrganizeOptionPrice