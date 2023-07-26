local XUiDlcHuntSettlementBadge = require("XUi/XUiDlcHunt/Settle/XUiDlcHuntSettlementBadge")

---@class XUiDlcHuntSettlementGrid
local XUiDlcHuntSettlementGrid = XClass(nil, "XUiDlcHuntSettlementGrid")

function XUiDlcHuntSettlementGrid:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
    ---@type XDlcFightSettlePlayerData
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.PanelBtn, self.OnBtnLikeClick)
    XUiHelper.RegisterClickEvent(self, self.PanelBtn2, self.OnBtnAddFriendClick)
    self._LikeCount = 0
    self.PanelPj = XUiHelper.TryGetComponent(self.Transform, "PanelPj", "Transform")
    self.TxtPraise = XUiHelper.TryGetComponent(self.PanelPj, "Text", "Text")
end

---@param data XDlcFightSettlePlayerData
function XUiDlcHuntSettlementGrid:Update(data)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self._Data = data
    self.Rw:SetRawImage(data.Icon)
    self.PanlMz.text = data.Name
    self.TxtValue.text = data.Damage
    self.ImgMvp.gameObject:SetActiveEx(data.IsMvp)

    local uiBadgeList = { self.Icon, self.Icon2, self.Icon3 }
    for i = 1, #uiBadgeList do
        local badge = data.Badge[i]
        local uiBadge = uiBadgeList[i]
        if badge then
            uiBadge.gameObject:SetActiveEx(true)
            uiBadge:SetRawImage(badge.Icon)
        else
            uiBadge.gameObject:SetActiveEx(false)
        end
    end
end

function XUiDlcHuntSettlementGrid:OnBtnLikeClick()
    self.Parent:OnAddLike(self:GetPlayerId())
end

function XUiDlcHuntSettlementGrid:OnBtnAddFriendClick()
    XDataCenter.SocialManager.ApplyFriend(self:GetPlayerId())
end

function XUiDlcHuntSettlementGrid:SwitchDisabledLike()
    --self.ImgLikeDisabled.gameObject:SetActiveEx(true)
    --self.ImgLikeAlready.gameObject:SetActiveEx(false)
    --self.PanelBtn.gameObject:SetActiveEx(false)
end

function XUiDlcHuntSettlementGrid:SwitchAlreadyLike()
    --self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    --self.ImgLikeAlready.gameObject:SetActiveEx(true)
    --self.PanelBtn.gameObject:SetActiveEx(false)
    if self.PanelBtn then
        self.PanelBtn:SetButtonState(CS.UiButtonState.Select)
        --self.PanelBtn:SetButtonState(CS.UiButtonState.Disable)
        self.PanelBtn:SetDisable(true, false)
        local uiEvent = XUiHelper.TryGetComponent(self.PanelBtn.transform, "", "XUguiEventListener")
        uiEvent:SetEventNull()
    end
end

function XUiDlcHuntSettlementGrid:GetPlayerId()
    return self._Data and self._Data.PlayerId or 0
end

function XUiDlcHuntSettlementGrid:AddLikeNumber()
    self._LikeCount = self._LikeCount + 1
    self.TxtPraise.gameObject:SetActiveEx(self._LikeCount ~= 0)
    self.TxtPraise.text = CSXTextManagerGetText("MultiDimAddLike", self._LikeCount)
end

return XUiDlcHuntSettlementGrid