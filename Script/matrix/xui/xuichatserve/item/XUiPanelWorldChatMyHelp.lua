XUiPanelWorldChatMyHelp = XClass(nil, "XUiPanelWorldChatMyHelp")
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")
function XUiPanelWorldChatMyHelp:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    if self.BtnGive then
        self.BtnGive.CallBack = function()
            self:OnClickBtnGive()
        end
    end
    if self.BtnView then
        XUiHelper.RegisterClickEvent(self, self.BtnView, self.OnBtnViewClick)
    end

    local prefab = self.PanelMsg:Find("PanelName"):LoadPrefab(XMedalConfigs.XNameplatePanelPath)
    self.UiPanelNameplate = XUiPanelNameplate.New(prefab, self)
    -- self.UiPanelNameplate = XUiPanelNameplate.New(self.PanelNameplate, self)
end

function XUiPanelWorldChatMyHelp:OnClickBtnGive()
    if self.SenderId and self.WordId then
        XDataCenter.SpringFestivalActivityManager.CollectWordsGiveWordToOthersRequest(self.WordId,self.SenderId,true,function(rewards)
            XUiManager.TipText("SpringFestivalSendWordSuccess")
            if not rewards then return end
            XUiManager.OpenUiTipReward(rewards)
        end)
    end
end

function XUiPanelWorldChatMyHelp:Refresh(chatData)
    self.ChatContent = chatData
    self.CreateTime = chatData.CreateTime
    self.SenderId = chatData.SenderId
    self.WordId = chatData.CollectWordId
    self.TxtWord.text = chatData.Content
    if self.TxtName then
        self.TxtName.text = chatData.NickName
    end
    if self.TxtNameGuild then
        self.TxtNameGuild.text = chatData.GuildName
    end
    local medalConfig = XMedalConfigs.GetMeadalConfigById(chatData.CurrMedalId)
    local medalIcon = nil
    if medalConfig then
        medalIcon = medalConfig.MedalIcon
    end
    if medalIcon ~= nil then
        self.ImgMedalIcon:SetRawImage(medalIcon)
        self.ImgMedalIcon.gameObject:SetActiveEx(true)
    else
        self.ImgMedalIcon.gameObject:SetActiveEx(false)
    end
    XUiPLayerHead.InitPortrait(chatData.Icon, chatData.HeadFrameId, self.Head)

    if XTool.IsNumberValid(chatData.NameplateId) then
        self.UiPanelNameplate:UpdateDataById(chatData.NameplateId)
        self.UiPanelNameplate.GameObject:SetActiveEx(true)
    else
        self.UiPanelNameplate.GameObject:SetActiveEx(false)
    end
end

function XUiPanelWorldChatMyHelp:OnBtnViewClick()
    if XDataCenter.RoomManager.RoomData and self.playerId == XPlayer.Id then
        --在房间中不能在聊天打开自己详情面板
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.SenderId, nil, nil, self.ChatContent)
end