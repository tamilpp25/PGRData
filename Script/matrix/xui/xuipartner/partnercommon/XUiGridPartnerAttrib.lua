local ATTR_COLOR = {
    BELOW = XUiHelper.Hexcolor2Color("d11e38ff"),
    EQUAL = XUiHelper.Hexcolor2Color("000000ff"),
    OVER = XUiHelper.Hexcolor2Color("188649ff"),
}

local XUiGridPartnerAttrib = XClass(nil, "XUiGridPartnerAttrib")

function XUiGridPartnerAttrib:Ctor(ui, name, doNotChangeColor)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self.TxtName.text = name
    self.DoNotChangeColor = doNotChangeColor
end

function XUiGridPartnerAttrib:UpdateData(curAttrValue, newattrvalue)
    if self.TxtCurAttr then
        if curAttrValue then
            self.TxtCurAttr.text = curAttrValue
        else
            self.TxtCurAttr.gameObject:SetActive(false)
        end
    end
    
    if self.TxtSelectAttr then
        if not newattrvalue or (newattrvalue == curAttrValue) then
            self.TxtSelectAttr.gameObject:SetActive(false)
        else
            self.TxtSelectAttr.text = newattrvalue
            self.TxtSelectAttr.gameObject:SetActive(true)

            if not self.DoNotChangeColor then
                if curAttrValue == newattrvalue then
                    self.TxtSelectAttr.color = ATTR_COLOR.EQUAL
                elseif curAttrValue < newattrvalue then
                    self.TxtSelectAttr.color = ATTR_COLOR.OVER
                elseif curAttrValue > newattrvalue then
                    self.TxtSelectAttr.color = ATTR_COLOR.BELOW
                end
            end
        end
    end
    
    if self.TxtCurLevel then
        self.TxtCurLevel.text = curAttrValue
    end
end

return XUiGridPartnerAttrib