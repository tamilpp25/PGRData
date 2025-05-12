---@class XUiTheatre4PopupAttackTips : XLuaUi
---@field private _Control XTheatre4Control
---@field BtnCheck XUiComponent.XUiButton
local XUiTheatre4PopupAttackTips = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupAttackTips")

function XUiTheatre4PopupAttackTips:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnCheck, self.OnBtnCheckClick)
end

---@param mapId number 地图Id
---@param callback function 回调
function XUiTheatre4PopupAttackTips:OnStart(mapId, callback)
    self.MapId = mapId
    self.Callback = callback
    -- 提示
    self.TxtName.text = self._Control:GetClientConfig("AttackPopupTitle")
    -- 描述
    self.TxtAttack.text = self._Control:GetClientConfig("AttackPopupDesc")
    -- 当前血量
    local curHp = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Hp)
    local curHpDesc = self._Control:GetClientConfig("AttackPopupHpDesc", 1)
    self.TxtDescription1.text = XUiHelper.FormatText(curHpDesc, curHp)
    -- 扣除血量
    local costHp = 0
    local bossGridData = self._Control.MapSubControl:GetCurrentBossGridData(mapId)
    if bossGridData then
        local contentId = bossGridData:GetGridContentId()
        costHp = self._Control.EffectSubControl:GetPunishEffectGroupHp(contentId)
    end
    local costHpDesc = self._Control:GetClientConfig("AttackPopupHpDesc", 2)
    self.TxtDescription2.text = XUiHelper.FormatText(costHpDesc, costHp)
    -- 刷新BtnCheck状态
    local isCheck = self._Control:GetNotShowAttackWarningPopup()
    self.BtnCheck:SetButtonState(isCheck and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiTheatre4PopupAttackTips:OnBtnBackClick()
    XLuaUiManager.CloseWithCallback(self.Name, self.Callback)
end

-- 本次登录不再提醒
function XUiTheatre4PopupAttackTips:OnBtnCheckClick()
    local isCheck = self.BtnCheck:GetToggleState()
    self._Control:SetNotShowAttackWarningPopup(isCheck)
    -- 勾选则关闭弹窗
    if isCheck then
        XLuaUiManager.CloseWithCallback(self.Name, self.Callback)
    end
end

return XUiTheatre4PopupAttackTips
