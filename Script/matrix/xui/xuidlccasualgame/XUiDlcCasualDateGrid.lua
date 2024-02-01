---@class XUiDlcCasualDateGrid : XUiNode
---@field BtnPalyer XUiComponent.XUiButton
---@field RImgHead UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field TxtHitScore UnityEngine.UI.Text
---@field TxtDeductScore UnityEngine.UI.Text
---@field TxtCollaborationScore UnityEngine.UI.Text
---@field TxtPersonalScore UnityEngine.UI.Text
---@field PanelNew UnityEngine.RectTransform
---@field ImgOffline UnityEngine.UI.Image
---@field ImgHeadBg UnityEngine.UI.Image
---@field RImgGridBg UnityEngine.UI.RawImage
---@field RImgGridSelfBg UnityEngine.UI.RawImage
---@field ImgHeadSelfBg UnityEngine.UI.Image
---@field _Control XDlcCasualControl
local XUiDlcCasualDateGrid = XClass(XUiNode, "XUiDlcCasualDateGrid")

---@param playerResult XDlcCasualPlayerResult
function XUiDlcCasualDateGrid:OnStart(playerResult, isNew)
    local beginData = XMVCA.XDlcRoom:GetFightBeginData()
    local playerId = playerResult:GetPlayerId()
    local roomData = beginData:GetRoomData()
    local player = roomData:GetPlayerDataById(playerId)
    local characterId = player:GetCharacterId()
    local headIcon = self._Control:GetCharacterCuteById(characterId):GetRoundHeadImage()
    local isSelf = playerId == XPlayer.Id

    self._PlayerId = playerId
    self.TxtName.text = player:GetName()
    self.TxtDeductScore.text = "-" .. playerResult:GetBeHitDamage()
    self.TxtHitScore.text = "+" .. playerResult:GetHitScore()
    self.TxtCollaborationScore.text = "+" .. playerResult:GetCooperateBonus()
    self.TxtPersonalScore.text = playerResult:GetPersonalScore()
    self.RImgHead:SetRawImage(headIcon)
    self.PanelNew.gameObject:SetActiveEx(isNew and self._PlayerId == XPlayer.Id)
    self.RImgGridBg.gameObject:SetActiveEx(not isSelf)
    self.RImgGridSelfBg.gameObject:SetActiveEx(isSelf)
    self.ImgHeadBg.gameObject:SetActiveEx(not isSelf)
    self.ImgHeadSelfBg.gameObject:SetActiveEx(isSelf)
    self.ImgOffline.gameObject:SetActiveEx(playerResult:IsOffline())
end

return XUiDlcCasualDateGrid