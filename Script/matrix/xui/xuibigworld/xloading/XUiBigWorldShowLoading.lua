---@class XUiBigWorldShowLoading : XBigWorldUi
---@field SpineRoot XUiLoadPrefab
---@field Loading UnityEngine.RectTransform
---@field _Control XBigWorldLoadingControl
local XUiBigWorldShowLoading = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldShowLoading")

function XUiBigWorldShowLoading:OnStart()
end

return XUiBigWorldShowLoading
