local XUiGridUnionStageMember = XClass(nil, "XUiGridUnionStageMember")

function XUiGridUnionStageMember:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.IsTiping = false
    self.BtnHead.CallBack = function() self:OnBtnHeadClick() end
end

function XUiGridUnionStageMember:UpdateByCache()
    if self.PlayerInfo then
        self:Refresh(self.PlayerInfo)
    end
end

function XUiGridUnionStageMember:OnBtnHeadClick()
    if self.PlayerInfo and self.PlayerInfo.Id ~= XPlayer.Id then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerInfo.Id)
    end
end

function XUiGridUnionStageMember:Refresh(playerInfo)
    self.GameObject:SetActiveEx(true)
    self.PlayerInfo = playerInfo
    self.PlayerId = playerInfo.Id
    local playerName = XDataCenter.SocialManager.GetPlayerRemark(self.PlayerId, playerInfo.PlayerName)
    local playerOnline = playerInfo.Status == 1
    local playerHeadPortraitId = playerInfo.HeadPortraitId
    local playerHeadFrameId = playerInfo.HeadFrameId

    XUiPLayerHead.InitPortrait(playerHeadPortraitId, playerHeadFrameId, self.Head)
    
    self.TxtPlayerName.text = playerName
    self.TxtNum.text = playerInfo.Position
    self.ImgState.gameObject:SetActiveEx(false)
    if not playerOnline then
        self.TxtMessage.text = ""
    end
end

function XUiGridUnionStageMember:RefreshFightStatus(playerId, stageId)
    if self.PlayerInfo and self.PlayerInfo.Id == playerId then
        if stageId then
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            if not stageCfg then
                self.TxtMessage.text = ""
            else
                self.TxtMessage.text = CS.XTextManager.GetText("UnionKillFightStatus", stageCfg.Name)
            end
        else
            self.TxtMessage.text = ""
        end
    end
end

--[[表情、聊天、提示]]
function XUiGridUnionStageMember:ClearUnuseTimer()
    self:EndProcessTipMsg()
end

function XUiGridUnionStageMember:ProcessTipMsg(tip_msg)
    if self.IsTiping then return end
    self:EndProcessTipMsg()

    self.IsTiping = true
    if tip_msg.IsChatMsg then
        -- 聊天弹条
        if tip_msg.ChatData.MsgType == ChatMsgType.Normal then
            self:TipTalk(tip_msg.ChatData.Content)
        elseif tip_msg.ChatData.MsgType == ChatMsgType.Emoji then
            self:TipEmoji(tostring(tip_msg.ChatData.Content))
        end
    else
        -- tip_msg
        if tip_msg.TipsType == XFubenUnionKillConfigs.TipsMessageType.FightBrrow then
            local fullMsg = ""
            local characterName = XCharacterConfigs.GetCharacterFullNameStr(tip_msg.ShareCharacterInfos.CharacterId)
            if tip_msg.ShareCharacterInfos.PlayerId == XPlayer.Id then
                fullMsg = CS.XTextManager.GetText(XFubenUnionKillConfigs.FightBorrowMine, characterName)
            else
                local fightInfo = XDataCenter.FubenUnionKillManager.GetCurRoomData()
                if fightInfo and fightInfo.UnionKillPlayerInfos[tip_msg.ShareCharacterInfos.PlayerId] then
                    local playerName = fightInfo.UnionKillPlayerInfos[tip_msg.ShareCharacterInfos.PlayerId].PlayerName
                    playerName = XDataCenter.SocialManager.GetPlayerRemark(tip_msg.ShareCharacterInfos.PlayerId, playerName)
                    fullMsg = CS.XTextManager.GetText(XFubenUnionKillConfigs.FightBorrowOthers, playerName, characterName)
                end
            end
            self:TipTalk(fullMsg)
        end
    end
    self.TipMsgTimer = XScheduleManager.ScheduleOnce(function()
        self:EndProcessTipMsg()
    end, 3000)
end

function XUiGridUnionStageMember:EndProcessTipMsg()
    if self.TipMsgTimer then
        XScheduleManager.UnSchedule(self.TipMsgTimer)
        self.TipMsgTimer = nil
    end
    self.IsTiping = false
    self:EndTipEmoji()
    self:EndTipTalk()
end

function XUiGridUnionStageMember:TipEmoji(emoji)
    self.EmojiGroup.gameObject:SetActiveEx(true)
    local icon = XDataCenter.ChatManager.GetEmojiIcon(emoji)
    if icon then
        self.RImgEmoji:SetRawImage(icon)
    end
end

function XUiGridUnionStageMember:EndTipEmoji()
    self.EmojiGroup.gameObject:SetActiveEx(false)
end

function XUiGridUnionStageMember:TipTalk(talkContent)
    self.TalkGroup.gameObject:SetActiveEx(true)
    self.TxtTalk.text = talkContent
end

function XUiGridUnionStageMember:EndTipTalk()
    self.TalkGroup.gameObject:SetActiveEx(false)
end

function XUiGridUnionStageMember:ResetTiping()
    self.IsTiping = false
end

return XUiGridUnionStageMember