local XUiGridArenaTeamRank = XClass(nil, "XUiGridArenaTeamRank")

function XUiGridArenaTeamRank:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridArenaTeamRank:ResetData(rank, data, rootUi, totalRank)
    if not self.GameObject:Exist() then
        return
    end

    if not data then
        return
    end

    if rank == 1 then
        self.TxtRank.text = CS.XTextManager.GetText("Rank1Color", rank)
    elseif rank == 2 then
        self.TxtRank.text = CS.XTextManager.GetText("Rank2Color", rank)
    elseif rank == 3 then
        self.TxtRank.text = CS.XTextManager.GetText("Rank3Color", rank)
    else
        if totalRank and rank > 100 and totalRank > 0 then
            local rankRate = math.ceil(rank / totalRank * 100)
            if rankRate >= 100 then
                rankRate = 99
            end
            local rankRateDesc = rankRate .. "%"
            self.TxtRank.text = CS.XTextManager.GetText("RankOtherColor", rankRateDesc)
        else
            self.TxtRank.text = CS.XTextManager.GetText("RankOtherColor", rank)
        end
    end

    if self.ImgTeamBg then
        self.ImgTeamBg.gameObject:SetActive(rank % 2 == 0)
    end

    self.TxtPoint.text = data.Point

    local captain = data.Captain

    for i = 1, 3 do
        local grid = self["GridMember" .. i]
        local head = XUiHelper.TryGetComponent(grid, "Head")
        local nickname = XUiHelper.TryGetComponent(grid, "GridName/TxtNickname", "Text")
        local captainTrans = XUiHelper.TryGetComponent(grid, "GridName/ImgCaptain", nil)
        local btnHead = XUiHelper.TryGetComponent(grid, "BtnHead", "Button")

        CsXUiHelper.RegisterClickEvent(btnHead, function()
            local player = data.PlayerList[i]
            if not player or player.Id == XPlayer.Id then
                return
            end
            XDataCenter.PersonalInfoManager.ReqShowInfoPanel(player.Id)
        end, true)

        local info = data.PlayerList[i]
        if info then
            nickname.gameObject:SetActive(true)
            nickname.text = XDataCenter.SocialManager.GetPlayerRemark(info.Id, info.Name)
            captainTrans.gameObject:SetActive(info.Id == captain)
            XUiPLayerHead.InitPortrait(info.CurrHeadPortraitId, info.CurrHeadFrameId, head)
        else
            nickname.gameObject:SetActive(false)
            captainTrans.gameObject:SetActive(false)
            XUiPLayerHead.Hide(head)
        end
    end
end

return XUiGridArenaTeamRank