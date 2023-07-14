local XUiSocialRename = XLuaUiManager.Register(XLuaUi, "UiSocialRename")


function XUiSocialRename:OnAwake()
    self.BtnClose.CallBack = function() self:OnDialogClose() end
    self.BtnTanchuangClose.CallBack = function() self:OnDialogClose() end
    self.BtnNameSure.CallBack = function() self:OnBtnNameSureClick() end
    self.BtnNameCancel.CallBack = function() self:OnDialogClose() end
end

function XUiSocialRename:OnStart(friendId, defaultName, callBack)
    self.FriendId = friendId
    self.DefaultName = defaultName
    self.CallBack = callBack
    self.InFSigm.placeholder.text = XDataCenter.SocialManager.GetFriendRemark(self.FriendId)
end

function XUiSocialRename:OnBtnNameSureClick()
    if self.FriendId then
        local editName = self.TxtName.text
        -- if editName == "" then
        --     XUiManager.TipError(CS.XTextManager.GetText("XSocialNameEmpty"))
        --     return
        -- end
        local MaxNameLength = CS.XGame.ClientConfig:GetInt("MaxNameLength")
        local utf8Count = self.InFSigm.textComponent.cachedTextGenerator.characterCount - 1
        if utf8Count > MaxNameLength then
            XUiManager.TipError(CS.XTextManager.GetText("MaxNameLengthTips", MaxNameLength))
            return
        end

        -- 两次空处理
        local friendRemark = XDataCenter.SocialManager.GetFriendRemark(self.FriendId)
        if (friendRemark == nil or friendRemark == "") and (editName == nil or editName == "") then
            self:OnDialogClose()
            return
        end

        XDataCenter.SocialManager.RemarkFriendName(self.FriendId, editName, function()
            if self.CallBack then
                self.CallBack()
            end
            self:OnDialogClose()
        end)
    end
end

function XUiSocialRename:OnDialogClose()
    self:Close()
end