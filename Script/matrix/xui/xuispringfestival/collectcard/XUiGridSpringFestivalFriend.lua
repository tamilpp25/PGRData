local XUiGridSpringFestivalFriend = XClass(nil, "XUiGridSpringFestivalFriend")

function XUiGridSpringFestivalFriend:Ctor(ui, callback)
    self.GameObject = ui
    self.Transform = ui.transform
    self.CallBack = callback
    XTool.InitUiObject(self)
    self.BtnGive.CallBack = function()
        self:OnClickGiveBtn()
    end
end

function XUiGridSpringFestivalFriend:Refresh(friendRequestInfo)
    if not friendRequestInfo then
        return
    end
    self.FriendRequestInfo = friendRequestInfo
    self.WordId = friendRequestInfo:GetWordId()
    self.RequesterId = friendRequestInfo:GetRequesterId()
    if self.TxtNumber then
        local f = function()
            local number = XDataCenter.ItemManager.GetCount(self.WordId)
            self.TxtNumber.text = number
        end
        XDataCenter.ItemManager.AddCountUpdateListener(self.WordId, f, self.TxtNumber)
        f()
    end

    local friendName = friendRequestInfo:GetRequesterName()
    if friendName and self.TxtName then
        self.TxtName.text = friendName
    end

    if self.TxtFriend then
        if friendRequestInfo:GetFromType() == XSpringFestivalActivityConfigs.WordsGiftFromType.Friend then
            self.TxtFriend.text = CS.XTextManager.GetText("SpringFestivalFromFriend")
        elseif friendRequestInfo:GetFromType() == XSpringFestivalActivityConfigs.WordsGiftFromType.Guild then
            self.TxtFriend.text = CS.XTextManager.GetText("SpringFestivalFromGuild")
        end
    end

    local icon = XDataCenter.ItemManager.GetItemIcon(self.WordId)
    if icon and self.RImgIcon then
        self.RImgIcon:SetRawImage(icon)
    end
end

function XUiGridSpringFestivalFriend:OnClickGiveBtn()
        XDataCenter.SpringFestivalActivityManager.CollectWordsGiveWordToOthersRequest(self.WordId, self.RequesterId,true, function(rewards)
            if rewards then
                XUiManager.OpenUiTipReward(rewards)
            end
            XUiManager.TipText("SpringFestivalSendWordSuccess")
            if self.CallBack then
                self.CallBack()
            end
        end)
end

return XUiGridSpringFestivalFriend