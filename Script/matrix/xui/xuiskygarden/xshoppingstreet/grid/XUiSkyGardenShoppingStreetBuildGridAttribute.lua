---@class XUiSkyGardenShoppingStreetBuildGridAttribute : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetBuildGridAttribute = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuildGridAttribute")
local XUiSkyGardenShoppingStreetEmpty = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetEmpty")

function XUiSkyGardenShoppingStreetBuildGridAttribute:OnStart()
    if self.ImgDetail then
        self.ImgDetail.CallBack = function()
            self:ShowBubbleTips()
        end
    end
    self._TxtNum = self.TxtDetailNum or self.TxtNum
end

function XUiSkyGardenShoppingStreetBuildGridAttribute:Update(data)
    local resCfgs = self._Control:GetStageResConfigs()
    local resCfg = resCfgs[data.ResConfigId]
    self.ImgAttribute:SetSprite(resCfg.Icon)
    if resCfg.IconColor then
        self.ImgAttribute.color = XUiHelper.Hexcolor2Color(resCfg.IconColor)
    end

    if not self._IconList then self._IconList = {} end

    local textInfo = self._Control:GetValueByResConfig(data.Value, resCfg)
    if not string.IsNilOrEmpty(resCfg.FormatStr) then
        textInfo = string.format(resCfg.FormatStr, textInfo)
    end

    local isStarShow = 30001 == resCfg.Id
    if isStarShow then
        local count = self._Control:GetShopCustomerStar(data.ShopId, data.Value)
        if count <= 0 then
            self:Close()
            return
        end
        count = math.min(count, 10)
        local array = {}
        for i = 1, count do
            table.insert(array, 1)
        end
        XTool.UpdateDynamicItem(self._IconList, array, self.ImgAttribute.gameObject, XUiSkyGardenShoppingStreetEmpty, self)
        self._TxtNum.text = ""
    else
        XTool.UpdateDynamicItem(self._IconList, nil, self.ImgAttribute.gameObject, XUiSkyGardenShoppingStreetEmpty, self)
        self._TxtNum.text = textInfo
    end
    self.ImgAttribute.gameObject:SetActive(not isStarShow)

    if self.ImgUp then
        self.ImgUp.gameObject:SetActive(data.IsUp)
    end
    if data.IsNew ~= nil and self.TxtNew then
        self.TxtNew.gameObject:SetActive(data.IsNew)
    end
    if self.ImgDetail then
        if resCfg.HasBubble then
            self._BubbleDesc = resCfg.BubbleDesc
        end
        self.ImgDetail.gameObject:SetActive(resCfg.HasBubble)
        self.ImgDetail.transform:SetAsLastSibling()
    end
end

function XUiSkyGardenShoppingStreetBuildGridAttribute:ShowBubbleTips()
    XMVCA.XSkyGardenShoppingStreet:ShowBubbleTips(self._BubbleDesc, self.ImgDetail.transform.position)
end

return XUiSkyGardenShoppingStreetBuildGridAttribute
