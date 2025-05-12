---@class XUiBigWorldLoadingPartial : XLuaUi
---@field ImgLoading UnityEngine.UI.RawImage
---@field Desc UnityEngine.UI.Text
---@field TitleText UnityEngine.UI.Text
---@field SpineRoot XUiLoadPrefab
---@field Loading UnityEngine.RectTransform
---@field _Control XBigWorldLoadingControl
local XUiBigWorldLoading = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldLoading")

function XUiBigWorldLoading:OnAwake()
    ---@type XTableBigWorldLoading
    self._Loading = false
end

function XUiBigWorldLoading:OnStart(worldId, levelId)
    self._Loading = self._Control:GetRandomLoadingByLevelId(levelId, worldId)
end

function XUiBigWorldLoading:OnEnable()
    self:_RefreshBackground()
end

function XUiBigWorldLoading:_RefreshBackground()
    local config = self._Loading

    if config then
        self.Desc.text = XUiHelper.ReplaceTextNewLine(config.Desc)
        self.TitleText.text = XUiHelper.ReplaceTextNewLine(config.Name)
        self.ImgLoading:SetRawImage(config.ImageUrl)
    end
end

return XUiBigWorldLoading
