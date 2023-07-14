local XUiChessPursuitRankGrid = XClass(nil, "XUiChessPursuitRankGrid")

local MAX_SPECIAL_NUM = 3

function XUiChessPursuitRankGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.BtnTcanchaungBlue.CallBack = function() self:OnBtnTcanchaungBlueClick() end
    self.BtnDetail.CallBack = function() self:OnBtnDetailClick() end
end

function XUiChessPursuitRankGrid:Refresh(rankDataTemplate, rankNum, groupId)
    if not rankDataTemplate then return end
    self.RankDataTemplate = rankDataTemplate
    self.GroupId = groupId

    self.TxtRankNormal.gameObject:SetActive(rankNum > MAX_SPECIAL_NUM)
    self.ImgRankSpecial.gameObject:SetActive(rankNum <= MAX_SPECIAL_NUM)
    if rankNum <= MAX_SPECIAL_NUM then
        local icon = XChessPursuitConfig.GetBabelRankIcon(rankNum)
        self.RootUi:SetUiSprite(self.ImgRankSpecial, icon)
    else
        self.TxtRankNormal.text = rankNum
    end

    self.TxtPlayerName.text = rankDataTemplate:GetName()
    local headPortraitId = rankDataTemplate:GetHead()
    local headFrameId = rankDataTemplate:GetFrame()
    XUiPLayerHead.InitPortrait(headPortraitId, headFrameId, self.Head)

    self.TxtRankScore.text = rankDataTemplate:GetScore()
end

function XUiChessPursuitRankGrid:OnBtnTcanchaungBlueClick()
    local playerId = self.RankDataTemplate:GetPlayerId()
    XDataCenter.ChessPursuitManager.ChessPursuitGetRankPlayerDetailRequest(playerId, self.GroupId)
end

function XUiChessPursuitRankGrid:OnBtnDetailClick()
    local playerId = self.RankDataTemplate:GetPlayerId()
    if playerId and playerId ~= XPlayer.Id then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId)
    end
end

return XUiChessPursuitRankGrid