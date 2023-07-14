local XUiScheduleGridPlayer = XClass(nil, "XUiScheduleGridPlayer")

function XUiScheduleGridPlayer:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    --XTool.InitUiObject(self)
    self:AutoRegister()
end

function XUiScheduleGridPlayer:AutoRegister()
    self.RImgHeadIcon = self.Transform:Find("Head/StandIcon"):GetComponent("RawImage")
    self.PanelLose = self.Transform:Find("Head/PanelLose")
    self.PanelUnknown = self.Transform:Find("Head/PanelWenhao")
    self.TxtName = self.Transform:Find("TextName"):GetComponent("Text")
    self.RImgItemIcon = self.Transform:Find("PanelRoleNum/RawImage"):GetComponent("RawImage")
    self.TxtItemCount = self.Transform:Find("PanelRoleNum/TextName"):GetComponent("Text")
end

function XUiScheduleGridPlayer:Refresh(player, match)
    self.Player = player
    if not player then
        self.RImgHeadIcon.gameObject:SetActiveEx(false)
        self.PanelLose.gameObject:SetActiveEx(false)
        self.RImgHeadIcon.gameObject:SetActiveEx(false)
        self.RImgItemIcon.gameObject:SetActiveEx(false)
        self.TxtItemCount.gameObject:SetActiveEx(false)

        self.PanelUnknown.gameObject:SetActiveEx(true)
        self.TxtName.text = "-"
    else
        local matchInfo = player.MatchInfoDic[match.Id]
        self.RImgHeadIcon.gameObject:SetActiveEx(true)
        self.RImgHeadIcon:SetRawImage(self.Player:GetCircleHead())
        self.PanelLose.gameObject:SetActiveEx(matchInfo.IsOver and not matchInfo.IsWin)
        self.PanelUnknown.gameObject:SetActiveEx(false)
        self.TxtName.text = self.Player:GetName()
        self.TxtName.color = matchInfo.IsWin and XMoeWarConfig.ScheNameColor.WIN or XMoeWarConfig.ScheNameColor.NORMAL
        local scoreText = matchInfo.VoteCount
        if match:GetVoteEnd() and not match:GetResultOut() then
            scoreText = CsXTextManagerGetText("MoeWarMatchVoteNoResult")
        elseif not match:GetVoteEnd() and matchInfo.VoteCount == 0 then
            scoreText = CsXTextManagerGetText("MoeWarMatchVoteNotRefresh")
        end
        self.TxtItemCount.text = scoreText
        self.TxtItemCount.color = matchInfo.IsWin and XMoeWarConfig.ScheNumColor.WIN or XMoeWarConfig.ScheNumColor.NORMAL
        -- 应援道具图标
        self.RImgItemIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarScheduleSupportIcon"))
    end
end

function XUiScheduleGridPlayer:SetFinalRank(rank)
    if not self.RImgRankIcon then
        self.RImgRankIcon = self.Transform:Find("RawImage"):GetComponent("RawImage")
    end

    if rank > 0 then
        self.RImgRankIcon:SetRawImage(XMoeWarConfig.ScheduleIcon[rank])
    else
        self.RImgRankIcon.gameObject:SetActiveEx(false)
    end
end

return XUiScheduleGridPlayer