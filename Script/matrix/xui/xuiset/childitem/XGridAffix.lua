local XGridAffix = XClass(XUiNode, "XGridAffix")

function XGridAffix:Refresh(data)
    local fight = CS.XFight.Instance
    if not fight then
        return
    end

    local uiAffix = fight.UiManager:GetUi(typeof(CS.XUiFightAffix))
    if not uiAffix then
        return
    end

    self.TxtName.text = data.AffixData.Name
    self.TxtSkillDesc.text = data.AffixData.Description
    self.Image:SetRawImage(data.AffixData.Icon)
end

return XGridAffix