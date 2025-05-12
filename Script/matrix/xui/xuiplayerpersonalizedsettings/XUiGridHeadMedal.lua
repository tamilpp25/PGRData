local XUiGridHeadMedal = XClass(XUiNode, 'XUiGridHeadMedal')

function XUiGridHeadMedal:OnStart(rootUi)
    self._RootUi = rootUi
    self.BtnRole.CallBack = handler(self, self.OnBtnRoleClick)
end

function XUiGridHeadMedal:OnBtnRoleClick()
    self.Base:SetHeadMedalImgRole(self.HeadMedalId)
    self:SetSelectShow(self.Base)
    if self.Base.OldMedalSelectGrig then
        self.Base.OldMedalSelectGrig:SetSelectShow(self.Base)
    end
    self.Base.OldMedalSelectGrig = self
    self:ShowRedPoint(false, true)

    self.Base:ShowHeadMedalPanel()
    self.Base:RefreshHeadMedalDynamicTable()
end

function XUiGridHeadMedal:UpdateGrid(medalCfg, parent)
    self.Base = parent
    self.HeadMedalId = medalCfg.Id
    
    if medalCfg.MedalImg ~= nil then
        self.UnLockImgHeadImg:SetRawImage(medalCfg.MedalImg)
        self.LockImgHeadImg:SetRawImage(medalCfg.MedalImg)
        self.HeadIcon = medalCfg.MedalImg
    end

    self.HeadIconEffect.gameObject:SetActiveEx(false)
    
    local timeLimit = XTool.IsNumberValid(medalCfg.KeepTime)
    
    self.LockIconTime.gameObject:SetActiveEx(timeLimit)
    self.SelIconTime.gameObject:SetActiveEx(timeLimit)
    self:SetSelectShow(parent)
    self:ShowLock(XPlayer.IsMedalUnlock(medalCfg.Id))
end

function XUiGridHeadMedal:SetSelectShow(parent)
    local accessor = self._RootUi or parent

    if accessor.TempHeadMedalId == self.HeadMedalId then
        self:ShowSelect(true)
    else
        self:ShowSelect(false)
    end
    if accessor.CurrHeadMedalId == self.HeadMedalId then
        self:ShowTxt(true)
        if not self.Base.OldMedalSelectGrig then
            self.Base.OldMedalSelectGrig = self
            self:ShowRedPoint(false,true)
        end
    else
        self:ShowTxt(false)
    end
end

function XUiGridHeadMedal:ShowSelect(bShow)
    self.ImgRoleSelect.gameObject:SetActive(bShow)
end

function XUiGridHeadMedal:ShowTxt(bShow)
    self.TxtDangqian.gameObject:SetActive(bShow)
end

function XUiGridHeadMedal:ShowLock(unLock)
    self.SelRoleHead.gameObject:SetActive(unLock)
    self.LockRoleHead.gameObject:SetActive(not unLock)

    if unLock then
        XDataCenter.MedalManager.LoadMedalEffect(self, self.UnLockImgHeadImg, self.HeadMedalId)
    end
end

function XUiGridHeadMedal:ShowRedPoint(bShow,IsClick)
    if not XDataCenter.MedalManager.CheckIsNewMedalById(self.HeadMedalId, XMedalConfigs.MedalType.Normal) then
        self.Red.gameObject:SetActive(false)
    else
        self.Red.gameObject:SetActive(bShow)
    end

    if not bShow and IsClick then
        local accessor = self._RootUi or self.Base

        XDataCenter.MedalManager.SetMedalForOld(self.HeadMedalId, XMedalConfigs.MedalType.Normal)
        accessor:ShowHeadMedalRedPoint()
    end
end

return XUiGridHeadMedal