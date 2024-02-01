local XUiGridMultiDimRank = XClass(nil, "XUiGridMultiDimRank")

function XUiGridMultiDimRank:Ctor()

end

function XUiGridMultiDimRank:Init(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiGridMultiDimRank:Refresh(rankType, rankInfo)
    self.RankInfo = rankInfo
    -- 排名
    local rankNum = self.RankInfo.Rank
    local maxSpecialNum = XMultiDimConfig.MAX_SPECIAL_NUM
    local isShowIcon = rankNum <= maxSpecialNum and rankNum > 0
    self.TxtRankNormal.gameObject:SetActiveEx(not isShowIcon)
    self.ImgRankSpecial.gameObject:SetActiveEx(isShowIcon)
    if isShowIcon then
        local icon = XMultiDimConfig.GetMultiDimConfigValue("RankIconNo" .. rankNum)
        self.RootUi:SetUiSprite(self.ImgRankSpecial, icon)
    else
        self.TxtRankNormal.text = rankNum
    end
    
    -- 单人排行特殊处理
    if rankType == XMultiDimConfig.RANK_MODEL.SINGLE_RANK then
        if rankNum == 0 and self.RankInfo.Percent > 0 then
            self.TxtRankNormal.text = string.format("%d%%", self.RankInfo.Percent)
        end
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
            XUiPLayerHead.InitPortrait(info.HeadPortraitId, info.HeadFrameId, head)
            XUiHelper.RegisterClickEvent(self, btnHead, function()
                if not XTool.IsNumberValid(info.PlayerId) or info.PlayerId == XPlayer.Id then
                    return
                end
                XDataCenter.PersonalInfoManager.ReqShowInfoPanel(info.PlayerId)
            end, true)
        else
            txtPlayerName.gameObject:SetActiveEx(false)
            captainTrans.gameObject:SetActiveEx(false)
            XUiPLayerHead.Hide(head)
        end
    end
    -- 玩家使用的角色头像（只有个人排行有）
    if rankType == XMultiDimConfig.RANK_MODEL.SINGLE_RANK then
        local info = elements[1]
        if info then
            local roleId = info.CharacterId
            local charIcon = self:GetSmallHeadIcon(roleId)
            self.RImgTeam1.gameObject:SetActiveEx(charIcon ~= nil)
            if charIcon then
                self.RImgTeam1:SetRawImage(charIcon)
            end
        else
            self.RImgTeam1.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridMultiDimRank:GetRankScoreText(rankType, score)
    local text = "MultiDimTeamSingleRankPoint"
    if rankType == XMultiDimConfig.RANK_MODEL.TEAM_RANK then
        text = "MultiDimTeamManyRankPoint"
    end
    return CSXTextManagerGetText(text, score)
end

function XUiGridMultiDimRank:GetPlayerCount(rankType)
    local count = 1
    if rankType == XMultiDimConfig.RANK_MODEL.TEAM_RANK then
        count = 3
    end
    return count
end

function XUiGridMultiDimRank:GetSmallHeadIcon(roleId)
    if roleId > 0 then
        return XMVCA.XCharacter:GetCharSmallHeadIcon(roleId, true)
    end
    return nil
end

return XUiGridMultiDimRank