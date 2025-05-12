local XUiSkyGardenShoppingStreetBuildGridAttribute = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuildGridAttribute")

---@class XUiSkyGardenShoppingStreetUpgradeGridUpgrade : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetUpgradeGridUpgrade = XClass(XUiNode, "XUiSkyGardenShoppingStreetUpgradeGridUpgrade")

function XUiSkyGardenShoppingStreetUpgradeGridUpgrade:OnStart()
    self._BuildingAttrs = {}
    self.GridUpgrade.CallBack = function() self:OnGridUpgradeClick() end
end

function XUiSkyGardenShoppingStreetUpgradeGridUpgrade:OnGridUpgradeClick()
    self.Parent:SelectUpgradeInfo(self._SelectIndex)
end

function XUiSkyGardenShoppingStreetUpgradeGridUpgrade:SetSelect(isSelect)
    self.GridUpgrade:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiSkyGardenShoppingStreetUpgradeGridUpgrade:Update(upgradeBranchId, i)
    self._SelectIndex = i
    -- data.Key
    -- data.Value
    -- SGStreetLvAdd
    local shopAreaData =  self.Parent:GetShopAreaData()
    local shopId =  shopAreaData:GetShopId()
    self.TxtNum.text = shopAreaData:GetShopLevel() + 1
    
    local attrDatas = self._Control:GetUpgradeAttributes(upgradeBranchId, shopId)
    local baseAttrDatas = self.Parent:GetAttrDatas()
    local upgradeAttrDatas = self.Parent:GetUpgradeAttrDatas()

    local upgradeBranchAttr = {}
    for i = 1, #attrDatas do
        local attrData = attrDatas[i]
        upgradeBranchAttr[attrData.Id] = i
    end

    local cache = {}
    for i = 1, #baseAttrDatas do
        local baseAttr = baseAttrDatas[i]
        cache[baseAttr.Id] = baseAttr
    end

    for j = 1, #upgradeAttrDatas do
        local upgradeAttr = upgradeAttrDatas[j]
        local attrIndex = upgradeBranchAttr[upgradeAttr.Id]
        local base = cache[upgradeAttr.Id]
        if attrIndex then
            if base then
                attrDatas[attrIndex].Value = base.Value + attrDatas[attrIndex].Value
            else
                attrDatas[attrIndex].Value = upgradeAttr.Value + attrDatas[attrIndex].Value
            end
        else
            if base.Value < upgradeAttr.Value then
                upgradeAttr.IsUp = true
            else
                upgradeAttr.Value = base.Value
            end
            table.insert(attrDatas, upgradeAttr)
        end
    end

    for i = 1, #attrDatas do
        local attrData = attrDatas[i]
        attrData.IsNew = not cache[attrData.Id]
    end

    table.sort(attrDatas, function(a, b)
        return a.Id < b.Id
    end)
    XTool.UpdateDynamicItem(self._BuildingAttrs, attrDatas, self.GridAttribute, XUiSkyGardenShoppingStreetBuildGridAttribute, self)
end

return XUiSkyGardenShoppingStreetUpgradeGridUpgrade
