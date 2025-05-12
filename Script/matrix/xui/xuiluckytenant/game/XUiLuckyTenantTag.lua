---@class XUiLuckyTenantTag : XUiNode
---@field _Control XLuckyTenantControl
local XUiLuckyTenantTag = XClass(XUiNode, "XUiLuckyTenantTag")

function XUiLuckyTenantTag:OnStart()
end

---@param data XUiLuckyTenantTagData
function XUiLuckyTenantTag:Update(data)
    if data then
        if self.RImgType.SetRawImage then
            self.RImgType:SetRawImage(data.Icon)
        elseif self.RImgType.SetSprite then
            self.RImgType:SetSprite(data.Icon)
        end
        if self.TxtNum then
            self.TxtNum.text = data.Amount
        end
    end
end

return XUiLuckyTenantTag