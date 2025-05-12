---@class XUiDlcCasualplayerSettlementGrid : XUiNode
---@field TxtName UnityEngine.UI.Text
---@field ImgMvp UnityEngine.UI.RawImage
---@field TxtScore UnityEngine.UI.Text
---@field PanelNew UnityEngine.RectTransform
---@field BtnLike XUiComponent.XUiButton
---@field BtnAdd XUiComponent.XUiButton
---@field PanelCharacterBg UnityEngine.RectTransform
---@field _Control XDlcCasualControl
local XUiDlcCasualplayerSettlementGrid = XClass(XUiNode, "XUiDlcCasualplayerSettlementGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")

---@param playerData XDlcCasualPlayerResult
function XUiDlcCasualplayerSettlementGrid:OnStart(playerData, isMvp, case)
    self._Player = playerData
    self._IsLiked = false
    self._IsMvp = isMvp
    self._RoleModel = XUiPanelRoleModel.New(case, self.Parent.Name, nil, true)
    self._ActionRandom = XSpecialTrainActionRandom.New()
    self:_Init()
end

function XUiDlcCasualplayerSettlementGrid:OnDisable()
    self._ActionRandom:Stop()
end

function XUiDlcCasualplayerSettlementGrid:OnDestroy()
    self._ActionRandom:Stop()
end

function XUiDlcCasualplayerSettlementGrid:Refresh(score)
    local beginData = XMVCA.XDlcRoom:GetFightBeginData()
    local roomData = beginData:GetRoomData()
    local playerId = self._Player:GetPlayerId()
    local characterId = roomData:GetPlayerDataById(playerId):GetCharacterId()
    local character = self._Control:GetCharacterCuteById(characterId)

    self.TxtName.text = roomData:GetPlayerDataById(playerId):GetNickname()
    self.ImgMvp.gameObject:SetActiveEx(self._IsMvp or false)
    self.TxtScore.text = score
    self._ActionRandom:Stop()
    self._RoleModel:UpdateCuteModelByModelName(character:GetCharacterId(), nil, nil, nil, nil,
        character:GetModelId(), Handler(self, self._ModelLoadCallback), true)
end

function XUiDlcCasualplayerSettlementGrid:OnBtnLikeClick()
    if not self._IsLiked then
        XMVCA.XDlcRoom:AddLike(self._Player:GetPlayerId())
        XUiManager.TipMsg(XUiHelper.GetText("DlcRoomAddLikeSuccess"))
    end

    self._IsLiked = true
    self.BtnLike:SetButtonState(CS.UiButtonState.Disable)
end

function XUiDlcCasualplayerSettlementGrid:OnBtnAddClick()
    XDataCenter.SocialManager.ApplyFriend(self._Player:GetPlayerId())
end

function XUiDlcCasualplayerSettlementGrid:_Init()
    self.PanelCharacterBg.gameObject:SetActiveEx(false)
    if self._Player:GetPlayerId() ~= XPlayer.Id then
        self.BtnAdd.gameObject:SetActiveEx(true)
        self.BtnLike.gameObject:SetActiveEx(true)
        XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick)
        XUiHelper.RegisterClickEvent(self, self.BtnLike, self.OnBtnLikeClick)
    else
        self.BtnAdd.gameObject:SetActiveEx(false)
        self.BtnLike.gameObject:SetActiveEx(false)
    end
end

function XUiDlcCasualplayerSettlementGrid:_ModelLoadCallback()
    local beginData = XMVCA.XDlcRoom:GetFightBeginData()
    local roomData = beginData:GetRoomData()
    local characterId = roomData:GetPlayerDataById(self._Player:GetPlayerId()):GetCharacterId()
    local character = self._Control:GetCharacterCuteById(characterId)
    local animator = self._RoleModel:GetAnimator()
    local action = nil

    if self._IsMvp then
        action = character:GetMVPAction()
    elseif self._Player:IsOffline() then
        action = character:GetFailAction()
    else
        action = character:GetVictoryAction()
    end
    
    self._ActionRandom:SetAnimatorWithCustomActionArray(animator, { action }, self._RoleModel, 0)
    self._ActionRandom:Play()
end

return XUiDlcCasualplayerSettlementGrid
