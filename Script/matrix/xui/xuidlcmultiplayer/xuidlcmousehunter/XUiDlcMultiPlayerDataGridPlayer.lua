local XUiDlcMultiPlayerTitleCommon = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMultiPlayerCommon/XUiDlcMultiPlayerTitleCommon")

---@class XUiDlcMultiPlayerDataGridPlayer : XUiNode
---@field ImgBg UnityEngine.UI.RawImage
---@field ImgOwnBg UnityEngine.UI.RawImage
---@field ImgTeam UnityEngine.UI.Image
---@field TxtRank UnityEngine.UI.Text
---@field ImgMvp UnityEngine.UI.Image
---@field TxtName UnityEngine.UI.Text
---@field TxtLifeTime UnityEngine.UI.Text
---@field PanelLifeLime UnityEngine.RectTransform
---@field TxtDefeatNum UnityEngine.UI.Text
---@field TxtScore UnityEngine.UI.Text
---@field ImgDeath UnityEngine.UI.Image
---@field ImgLife UnityEngine.UI.Image
---@field BtnReport XUiComponent.XUiButton
---@field ImgIcon UnityEngine.UI.RawImage
---@field ImgIconEffect UnityEngine.RectTransform
---@field BtnPlayer XUiComponent.XUiButton
---@field TitleGrid UnityEngine.RectTransform
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerDataGridPlayer = XClass(XUiNode, "XUiDlcMultiPlayerDataGridPlayer")

-- region 生命周期

function XUiDlcMultiPlayerDataGridPlayer:OnStart()
    self._IsSelfCampWin = nil
    self._Data = nil
    self._TitleGrid = nil
    self:_RegisterButtonClicks()
end

-- endregion

function XUiDlcMultiPlayerDataGridPlayer:OnBtnReportClick()
    if self._Data then
        XLuaUiManager.Open("UiReport", {
            Id = self._Data:GetPlayerId(),
            TitleName = self._Data:GetName(),
            PlayerLevel = self._Data:GetPlayerLevel(),
        }, nil, nil, XReportConfigs.EnterType.DlcMultiplayer)
    end
end

function XUiDlcMultiPlayerDataGridPlayer:OnBtnPlayerClick()
    if self._Data then
        local playerId = self._Data:GetPlayerId()

        if playerId ~= XPlayer.Id then
            XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId)
        end
    end
end

---@param data XDlcMultiMouseHunterCampResult
function XUiDlcMultiPlayerDataGridPlayer:Refresh(data, isSelfCampWin)
    if data then
        local titleId = data:GetTitleId()
        local isSelf = data:GetPlayerId() == XPlayer.Id

        self._Data = data
        self.TxtRank.text = data:GetRank()
        self.ImgMvp.gameObject:SetActiveEx(data:GetIsMvp() and isSelfCampWin)
        self.ImgSvp.gameObject:SetActiveEx(data:GetIsMvp() and not isSelfCampWin)
        self.TxtName.text = data:GetName()
        self.TxtScore.text = data:GetScore()
        self.ImgBg.gameObject:SetActiveEx(not isSelf)
        self.ImgOwnBg.gameObject:SetActiveEx(isSelf)
        self.ImgTeam.gameObject:SetActiveEx(not isSelf and self:_CheckSameTeam(data:GetPlayerId()))
        self.BtnReport.gameObject:SetActiveEx(not isSelf)

        self.ImgIcon:SetRawImage(self._Control:GetCharacterCuteHeadIconByCharacterId(data:GetCharacterId()))
        if XTool.IsNumberValid(titleId) then
            self.TitleGrid.gameObject:SetActiveEx(true)
            self._TitleGrid = XUiDlcMultiPlayerTitleCommon.New(self.TitleGrid, self, titleId)
        else
            self.TitleGrid.gameObject:SetActiveEx(false)
        end
        if data:IsMouseCamp() then
            self.PanelLifeLime.gameObject:SetActiveEx(true)
            self.TxtDefeatNum.gameObject:SetActiveEx(false)
            self.TxtLifeTime.text = data:GetSurvivalTime()
            self.ImgDeath.gameObject:SetActiveEx(not data:GetIsSurvive())
            self.ImgLife.gameObject:SetActiveEx(data:GetIsSurvive())
        end
        if data:IsCatCamp() then
            self.PanelLifeLime.gameObject:SetActiveEx(false)
            self.TxtDefeatNum.gameObject:SetActiveEx(true)
            self.TxtDefeatNum.text = data:GetEliminatePlayers()
            self.ImgDeath.gameObject:SetActiveEx(false)
            self.ImgLife.gameObject:SetActiveEx(false)
        end
    end
end

-- region 私有方法

function XUiDlcMultiPlayerDataGridPlayer:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnPlayer, self.OnBtnPlayerClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnReport, self.OnBtnReportClick, true)
end

function XUiDlcMultiPlayerDataGridPlayer:_CheckSameTeam(playerId)
    local fightBeginData = XMVCA.XDlcRoom:GetFightBeginData()

    if fightBeginData then
        local roomData = fightBeginData:GetRoomData()

        if roomData then
            return roomData:GetPlayerDataById(playerId) ~= nil
        end
    end

    return false
end

-- endregion

return XUiDlcMultiPlayerDataGridPlayer
