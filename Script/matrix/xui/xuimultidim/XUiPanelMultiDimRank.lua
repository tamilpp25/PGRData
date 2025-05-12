local XUiPanelMultiDimRank = XClass(nil, "XUiPanelMultiDimRank")

function XUiPanelMultiDimRank:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiPanelMultiDimRank:Refresh(rankType, rankInfo)
    self.RankInfo = rankInfo
    -- 排名
    local rankNum = self.RankInfo.Rank
    if rankType == XMultiDimConfig.RANK_MODEL.SINGLE_RANK then
        local percentCount, percent = XDataCenter.MultiDimManager.GetSingleRankFringe(rankNum, self.RankInfo.MemberCount, true)
        if rankNum <= percentCount then
            self:RefreshRankAndIcon(rankNum)
        else
            self.TxtRankPrecent.gameObject:SetActiveEx(true)
            self.TxtRankNormal.gameObject:SetActiveEx(false)
            self.ImgRankSpecial.gameObject:SetActiveEx(false)
            self.TxtRankPrecent.text = CSXTextManagerGetText("MultiDimTeamPercentDesc", percent)
        end
    elseif rankType == XMultiDimConfig.RANK_MODEL.TEAM_RANK then
        self:RefreshRankAndIcon(rankNum)
    end

    -- 积分
    self.TxtRankScore.text = self:GetRankScoreText(rankType, self.RankInfo.Score)
    -- 玩家信息
    local elements = self.RankInfo.Elements
    local count = self:GetPlayerCount(rankType)
    for i = 1, count do
        local grid = self["GridMember" .. i]
        local head = XUiHelper.TryGetComponent(grid, "Head")
        local txtPlayerName = XUiHelper.TryGetComponent(grid, "TxtPlayerName", "Text")
        local captainTrans = XUiHelper.TryGetComponent(grid, "Img")
        local btnHead = XUiHelper.TryGetComponent(grid, "BtnHead", "Button")

        local info = elements[i]
        if info then
            txtPlayerName.gameObject:SetActiveEx(true)
            txtPlayerName.text = info.Name
            captainTrans.gameObject:SetActiveEx(info.IsCaptain == 1)
            -- 头像
            XUiPlayerHead.InitPortrait(info.HeadPortraitId, info.HeadFrameId, head)
            XUiHelper.RegisterClickEvent(self, btnHead, function()
                if not XTool.IsNumberValid(info.PlayerId) or info.PlayerId == XPlayer.Id then
                    return
                end
                XDataCenter.PersonalInfoManager.ReqShowInfoPanel(info.PlayerId)
            end, true)
        else
            txtPlayerName.gameObject:SetActiveEx(false)
            captainTrans.gameObject:SetActiveEx(false)
            XUiPlayerHead.Hide(head)
        end
    end
end

function XUiPanelMultiDimRank:RefreshRankAndIcon(rankNum)
    local maxSpecialNum = XMultiDimConfig.MAX_SPECIAL_NUM
    local isShowIcon = rankNum <= maxSpecialNum and rankNum > 0
    self.TxtRankPrecent.gameObject:SetActiveEx(false)
    self.TxtRankNormal.gameObject:SetActiveEx(not isShowIcon)
    self.ImgRankSpecial.gameObject:SetActiveEx(isShowIcon)

    if isShowIcon then
        local icon = XMultiDimConfig.GetMultiDimConfigValue("RankIconNo" .. rankNum)
        self.RootUi:SetUiSprite(self.ImgRankSpecial, icon)
    else
        self.TxtRankNormal.text = rankNum
    end
end

function XUiPanelMultiDimRank:GetRankScoreText(rankType, score)
    local text = "MultiDimTeamSingleRankPoint"
    if rankType == XMultiDimConfig.RANK_MODEL.TEAM_RANK then
        text = "MultiDimTeamManyRankPoint"
    end
    return CSXTextManagerGetText(text, score)
end

function XUiPanelMultiDimRank:GetPlayerCount(rankType)
    local count = 1
    if rankType == XMultiDimConfig.RANK_MODEL.TEAM_RANK then
        count = 3
    end
    return count
end

function XUiPanelMultiDimRank:SetActivePanel(action)
    self.GameObject:SetActiveEx(action)
end

return XUiPanelMultiDimRank