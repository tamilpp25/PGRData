---@class XUiSameColorGameGridRole
local XUiSameColorGameGridRole = XClass(nil, "XUiSameColorGameGridRole")
---@param rootUi XUiSameColorGamePanelRole
function XUiSameColorGameGridRole:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    ---@type XSCRole
    self.Role = nil
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
    self.PanelPurchase.gameObject:SetActiveEx(false)
end

---@param role XSCRole
---@param boss XSCBoss
function XUiSameColorGameGridRole:SetData(role, boss)
    self.Role = role
    self.RImgIcon:SetRawImage(XMVCA.XCharacter:GetCharRoundnessHeadIcon(role:GetCharacterViewModel():GetId()))
    -- 推荐标签
    self.PanelRecommend.gameObject:SetActiveEx(boss:CheckRoleIdIsSuggest(role:GetId()))
    -- 是否锁住
    self.PanelLock.gameObject:SetActiveEx(role:GetIsLock())
end

function XUiSameColorGameGridRole:OnBtnSelfClicked()
    if not self.Role:GetIsLock() then
        self.RootUi:UpdateCurrentRole(self.Role)
    else
        XUiManager.TipErrorWithKey("SummerEpisodeMapUnLock", self.Role:GetOpenTimeTipStr())
    end
end

function XUiSameColorGameGridRole:SetSelectStatusByRole(role)
    self.PanelSelect.gameObject:SetActiveEx(self.Role == role)
end

return XUiSameColorGameGridRole