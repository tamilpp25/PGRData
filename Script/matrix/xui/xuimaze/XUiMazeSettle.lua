---@class XUiMazeSettle:XLuaUi
local XUiMazeSettle = XLuaUiManager.Register(XLuaUi, "UiMazeSettle")

function XUiMazeSettle:Ctor()
    self._Score = 0
    self._TimeCanClose = 0.5
end

function XUiMazeSettle:OnStart(data)
    self._Score = data and data.Score or 0
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.CloseAfterCountDown)
    self._TimeCanClose = self._TimeCanClose + XTime.GetServerNowTimestamp()
end

function XUiMazeSettle:OnEnable()
    self:Update()
end

function XUiMazeSettle:Update()
    local score = self._Score
    local playerName = XPlayer.Name
    local robotId = XDataCenter.MazeManager.GetPartnerRobotId()
    local characterId = XRobotManager.GetCharacterId(robotId)
    local partnerName = XMVCA.XCharacter:GetCharacterName(characterId)
    local partnerIcon = XCharacterCuteConfig.GetCuteModelSmallHeadIcon(characterId)
    local timeStr = XUiHelper.GetTimeYearMonthDay()
    local gradeIcon = XMazeConfig.GetGradeIconByScore(score)
    local bg = XMazeConfig.GetSettleBg(robotId)
    self.TxtPlayerName.text = playerName
    self.TxtRoleName.text = partnerName
    self.RImgRoleHead:SetRawImage(partnerIcon)
    self.TxtPassTime.text = timeStr
    self.TxtTacit.text = score
    self.RImgRate:SetRawImage(gradeIcon)
    self.Panel100.gameObject:SetActiveEx(score >= 100)
    self.RImgCharPhoto:SetRawImage(bg)
end

function XUiMazeSettle:CloseAfterCountDown()
    if XTime.GetServerNowTimestamp() > self._TimeCanClose then
        self:Close()
    end
end

return XUiMazeSettle