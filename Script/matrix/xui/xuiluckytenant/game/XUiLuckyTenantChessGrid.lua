local XUiLuckyTenantTag = require("XUi/XUiLuckyTenant/Game/XUiLuckyTenantTag")

---@class XUiLuckyTenantChessGrid : XUiNode
---@field _Control XLuckyTenantControl
local XUiLuckyTenantChessGrid = XClass(XUiNode, "XUiLuckyTenantChessGrid")

function XUiLuckyTenantChessGrid:OnStart()
    self._Tags = {}
    self._DescLabels = { self.TxtChessDoc, self.TxtResult }
    self.GridType.gameObject:SetActiveEx(true)
end

---@param data XUiLuckyTenantChessGridData
function XUiLuckyTenantChessGrid:Update(data)
    self._Data = data
    self.TxtName.text = data.Name
    self.RImgIcon:SetRawImage(data.Icon)
    if data.QualityValue then
        self.ImgQuality:SetSprite(self._Control:GetQualityIconCircle(data.QualityValue))
    else
        self.ImgQuality:SetSprite(data.Quality)
    end
    self.TxtCost.text = data.Value
    if self.TxtTag then
        self.TxtTag.text = data.TypeName
    end
    self.TxtChessDoc.text = data.Desc[1]
    if self.TxtCostDeletion then
        self.TxtCostDeletion.text = data.ValueUponDeletion
    end
    for i = 2, #data.Desc do
        local label = self._DescLabels[i]
        if not label then
            label = CS.UnityEngine.Object.Instantiate(self.TxtResult, self.TxtResult.transform.parent)
            self._DescLabels[i] = label
        end
        label.text = data.Desc[i]
        label.gameObject:SetActiveEx(true)
    end
    for i = #data.Desc + 1, #self._DescLabels do
        local label = self._DescLabels[i]
        label.gameObject:SetActiveEx(false)
    end
    --self.TxtDelete.gameObject:SetActiveEx(not data.IsCanDelete)
    self:UpdateTag()
end

function XUiLuckyTenantChessGrid:UpdateTag()
    local tagData = self._Data.Tag
    XTool.UpdateDynamicItem(self._Tags, tagData, self.GridType, XUiLuckyTenantTag, self)
end

return XUiLuckyTenantChessGrid