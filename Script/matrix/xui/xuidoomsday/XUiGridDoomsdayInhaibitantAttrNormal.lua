local XUiGridDoomsdayInhaibitantAttrNormal = XClass(nil, "XUiGridDoomsdayInhaibitantAttrNormal")

function XUiGridDoomsdayInhaibitantAttrNormal:Ctor(stageId)
    self.StageId = stageId
end

function XUiGridDoomsdayInhaibitantAttrNormal:Refresh(attr)
    local stageId = self.StageId

    local attrType = attr:GetProperty("_Type")
    self.TxtState1.text = XDoomsdayConfigs.AttributeTypeConfig:GetProperty(attrType, "Name")

    local max = XDoomsdayConfigs.AttributeTypeConfig:GetProperty(attrType, "MaxValue")
    self.Parent:BindViewModelPropertyToObj(
        attr,
        function(cur)
            self.ImgProgress.fillAmount = cur / max

            self.TxtState1Num.text =
                string.format("%d/%d", cur, max)
            -- .. XDataCenter.DoomsdayManager.GetAverageInhabitantAttrValueText(stageId, attrType)
        end,
        "_Value"
    )
end

return XUiGridDoomsdayInhaibitantAttrNormal
