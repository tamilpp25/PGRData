local XUiBfrtEchelonFightEventGrid = XClass(XUiNode, "XUiBfrtEchelonFightEventGrid")

function XUiBfrtEchelonFightEventGrid:Refresh(echelonFightEventId)
    local stageFightConfig = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(echelonFightEventId)
    
    self.RImgIconBuff:SetRawImage(stageFightConfig.Icon)
    self.TxtName.text = stageFightConfig.Name
    self.TxtDetail.text = stageFightConfig.Description
end

return XUiBfrtEchelonFightEventGrid