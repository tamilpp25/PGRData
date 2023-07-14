---@class XUiDlcHuntBattleDialog:XLuaUi
local XUiDlcHuntBattleDialog = XLuaUiManager.Register(XLuaUi, "UiDlcHuntBattleDialog")

function XUiDlcHuntBattleDialog:OnAwake()
    self:RegisterClickEvent(self.BtnConfirm,self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose,self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose,self.OnBtnCloseClick)
end

function XUiDlcHuntBattleDialog:OnStart()
    local roomData = XDataCenter.DlcRoomManager.GetRoom()
    self.TxtInput.text = roomData:GetAbilityLimit()
    -- 最高五位数
    self.TxtInput.characterLimit = 5
end

function XUiDlcHuntBattleDialog:OnBtnConfirmClick()
    local abilityLimit = tonumber(self.TxtInput.text)
    if not abilityLimit or abilityLimit < 0 then
        local msg = CS.XTextManager.GetText("MultiplayerRoomAbilityNotLegal")
        XUiManager.TipMsg(msg)
        return
    end
    abilityLimit = math.floor(abilityLimit)
    XDataCenter.DlcRoomManager.SetAbilityLimit(abilityLimit)
    self:Close()
end

function XUiDlcHuntBattleDialog:OnBtnCloseClick()
    self:Close()
end

return XUiDlcHuntBattleDialog
