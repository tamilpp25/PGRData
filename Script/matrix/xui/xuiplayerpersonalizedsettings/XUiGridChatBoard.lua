local XUiGridChatBoard = XClass(XUiNode, "XUiGridChatBoard")

function XUiGridChatBoard:OnStart(rootUi)
    self._RootUi = rootUi
    self:AutoAddListener()
end

function XUiGridChatBoard:AutoAddListener()
    self.BtnRole.CallBack = function()
        self:OnBtnRoleClick()
    end
end

function XUiGridChatBoard:OnBtnRoleClick()
    self.Base:SetChatBoardImgRole(self.ChatBoardId)
    self:SetSelectShow(self.Base)
    if self.Base.OldChatBoardSelectGrig then
        self.Base.OldChatBoardSelectGrig:SetSelectShow(self.Base)
    end
    self.Base.OldChatBoardSelectGrig = self
    self:ShowRedPoint(false, true)

    self.Base:ShowChatBoardPanel()
    self.Base:RefreshChatBoardDynamicTable()
end

---@param chapter XTableChatBoard
function XUiGridChatBoard:UpdateGrid(chapter, parent)
    self.Base = parent
    self.ChatBoardId = chapter.Id
    if chapter.Icon ~= nil then
        self.UnLockImgHeadImg:SetRawImage(chapter.Icon)
        self.LockImgHeadImg:SetRawImage(chapter.Icon)
        self.HeadIcon = chapter.Icon
    end

    if chapter.EffectRes then
        self.HeadIconEffect.gameObject:LoadPrefab(chapter.EffectRes)
        self.HeadIconEffect.gameObject:SetActiveEx(true)
    else
        self.HeadIconEffect.gameObject:SetActiveEx(false)
    end
    
    -- 判断是否是限时聊天框
    local timeLimit = XTool.IsNumberValid(chapter.Duration) or not string.IsNilOrEmpty(chapter.ExpireTimeStr)
    self.LockIconTime.gameObject:SetActiveEx(timeLimit)
    self.SelIconTime.gameObject:SetActiveEx(timeLimit)
    
    self:SetSelectShow(parent)
    self:ShowLock(not XDataCenter.ChatManager.CheckChatBoardIsLockById(self.ChatBoardId))
end

function XUiGridChatBoard:SetSelectShow(parent)
    local accessor = self._RootUi or parent

    if accessor.TempChatBoardId == self.ChatBoardId then
        self:ShowSelect(true)
    else
        self:ShowSelect(false)
    end
    if accessor.CurrChatBoardId == self.ChatBoardId then
        self:ShowTxt(true)
        if not self.Base.OldChatBoardSelectGrig then
            self.Base.OldChatBoardSelectGrig = self
            self:ShowRedPoint(false,true)
        end
    else
        self:ShowTxt(false)
    end
end

function XUiGridChatBoard:ShowSelect(bShow)
    self.ImgRoleSelect.gameObject:SetActive(bShow)
end

function XUiGridChatBoard:ShowTxt(bShow)
    self.TxtDangqian.gameObject:SetActive(bShow)
end

function XUiGridChatBoard:ShowLock(unLock)
    self.SelRoleHead.gameObject:SetActive(unLock)
    self.LockRoleHead.gameObject:SetActive(not unLock)
end

function XUiGridChatBoard:ShowRedPoint(bShow,IsClick)
    if not XDataCenter.ChatManager.IsChatBoardValid(self.ChatBoardId) then
        self.Red.gameObject:SetActive(false)
    else
        self.Red.gameObject:SetActive(bShow)
    end

    if not bShow and IsClick then
        local accessor = self._RootUi or self.Base

        XDataCenter.ChatManager.SetChatBoardForOld(self.ChatBoardId)
        accessor:ShowHeadChatBoardRedPoint()
        XEventManager.DispatchEvent(XEventId.EVENT_CHAT_BOARD_REFRESH_RED)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_BOARD_REFRESH_RED)
    end
end

return XUiGridChatBoard