---@class XUiGridRogueSimHandbook : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimHandbook = XClass(XUiNode, "XUiGridRogueSimHandbook")

function XUiGridRogueSimHandbook:OnStart()

end

function XUiGridRogueSimHandbook:Refresh(illType, config, isUnlock)
    local isProp = illType == XEnumConst.RogueSim.IllustrateType.Props
    self.GridPorp.gameObject:SetActiveEx(isProp)
    local isBuilding = illType == XEnumConst.RogueSim.IllustrateType.Build
    self.GridBulid.gameObject:SetActiveEx(isBuilding)
    local isNew = self.Parent:IsShowRed(config.Id)

    if isProp then
        local obj = self.GridPorp
        obj:GetObject("PanelLock").gameObject:SetActiveEx(not isUnlock)
        obj:GetObject("RImgProp"):SetRawImage(config.Icon)
        obj:GetObject("TxtName").text = config.Name
        obj:GetObject("TxtDetail").text = config.Desc
        obj:GetObject("TxtStory").text = config.EffectDesc
        obj:GetObject("PanelNew").gameObject:SetActiveEx(isNew)
    end

    if isBuilding then
        local obj = self.GridBulid
        obj:GetObject("PanelLock").gameObject:SetActiveEx(not isUnlock)
        obj:GetObject("RImgProp"):SetSprite(config.Icon)
        obj:GetObject("TxtName").text = config.Name
        obj:GetObject("TxtDetail").text = config.Desc

        local resId = config.CostResourceIds[1]
        local iconPath = self._Control.ResourceSubControl:GetResourceIcon(resId)
        obj:GetObject("RImgCoin"):SetRawImage(iconPath)
        obj:GetObject("TxtProfit").text = config.CostResourceCounts[1]
        obj:GetObject("PanelNew").gameObject:SetActiveEx(isNew)

        local tagIcon = self._Control.MapSubControl:GetLandformSideIcon(config.LandformId)
        obj:GetObject("ImgTag"):SetSprite(tagIcon)
    end
end

return XUiGridRogueSimHandbook