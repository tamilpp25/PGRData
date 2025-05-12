---@class XUiDlcMultiPlayerTitleCommon : XUiNode
---@field RImgTitle UnityEngine.UI.RawImage
---@field TxtTitle UnityEngine.UI.Text
---@field RImgIcon UnityEngine.UI.RawImage
local XUiDlcMultiPlayerTitleCommon = XClass(XUiNode, "XUiDlcMultiPlayerTitleCommon")

function XUiDlcMultiPlayerTitleCommon:OnStart(titleId)
    self:Refresh(titleId)
end

function XUiDlcMultiPlayerTitleCommon:Refresh(titleId)
    if XTool.IsNumberValid(titleId) then
        self.TxtTitle.text = XMVCA.XDlcMultiplayer:GetDlcMultiplayerTitleTitleContentById(titleId)
        self.RImgTitle:SetRawImage(XMVCA.XDlcMultiplayer:GetDlcMultiplayerTitleBackgroundById(titleId))
        self.RImgIcon:SetRawImage(XMVCA.XDlcMultiplayer:GetDlcMultiplayerTitleIconById(titleId))
    end
end

return XUiDlcMultiPlayerTitleCommon
