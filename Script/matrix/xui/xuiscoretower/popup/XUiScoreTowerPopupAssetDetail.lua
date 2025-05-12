---@class XUiScoreTowerPopupAssetDetail : XLuaUi
---@field private _Control XScoreTowerControl
local XUiScoreTowerPopupAssetDetail = XLuaUiManager.Register(XLuaUi, "UiScoreTowerPopupAssetDetail")

function XUiScoreTowerPopupAssetDetail:OnAwake()
    self:RegisterUiEvents()
end

function XUiScoreTowerPopupAssetDetail:OnStart()
    -- 标题
    self.TxtTitle.text = self._Control:GetClientConfig("AssetDetailPopupTitle")
    -- 内容
    self.TxtDetail.text = XUiHelper.ConvertLineBreakSymbol(self._Control:GetClientConfig("AssetDetailPopupContent"))
end

function XUiScoreTowerPopupAssetDetail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnBackClick)
end

function XUiScoreTowerPopupAssetDetail:OnBtnBackClick()
    self:Close()
end

return XUiScoreTowerPopupAssetDetail
