local XUiCoupletStageCtrlPanel = XClass(nil, "XUiCoupletStageCtrlPanel")

local CoupleteStatus = {
    GetWord = 1,
    CheckComplete = 2,
    Complete = 3,
}

function XUiCoupletStageCtrlPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init()
end

function XUiCoupletStageCtrlPanel:Init()
    self:AutoRegisterBtn()
    local cousumeItemId = XDataCenter.CoupletGameManager.GetConsumeItemId()
    local itemIcon = XDataCenter.ItemManager.GetItemIcon(cousumeItemId)
    self.ImgItem:SetRawImage(itemIcon)
end

function XUiCoupletStageCtrlPanel:Refresh(coupletId, isSelfChanged)
    self.CurCoupletId = coupletId
    if XDataCenter.CoupletGameManager.GetCoupletGameStatus(coupletId) == XCoupletGameConfigs.CouPletStatus.Complete then
        self:SetStatus(CoupleteStatus.Complete)
        self:SetBatchImage(false)
        if isSelfChanged then self.RootUi:PlayAnimation("UiQieHuan") end
    else
        if XDataCenter.CoupletGameManager.CheckCoupletIsCheckComplete(coupletId) then
            self:SetStatus(CoupleteStatus.CheckComplete)
            if isSelfChanged then self.RootUi:PlayAnimation("UiQieHuan") end
        else
            self:SetStatus(CoupleteStatus.GetWord)
            if XDataCenter.CoupletGameManager.CheckCanExchangeWord() then
                self.TxtConsumeNum.text = XCoupletGameConfigs.GetCoupletTemplateById(coupletId).ItemConsumeCount
            else
                self.TxtConsumeNum.text = CsXTextManagerGetText("CoupletGameConsumeCount", XCoupletGameConfigs.GetCoupletTemplateById(coupletId).ItemConsumeCount)
            end
        end
        self:SetBatchImage(true)
    end
    self.BtnPlayVideo:ShowReddot(XDataCenter.CoupletGameManager.CheckPlayVideoRedPoint(self.CurCoupletId))
end

function XUiCoupletStageCtrlPanel:AutoRegisterBtn()
    self.BtnComplete.CallBack = function () self:OnBtnCompleteClick() end
    self.BtnPlayVideo.CallBack = function () self:OnBtnPlayVideo() end
end

function XUiCoupletStageCtrlPanel:SetStatus(status)
    if status == CoupleteStatus.GetWord then
        self.PanelStageOne.gameObject:SetActiveEx(true)
        self.PanelStageTwo.gameObject:SetActiveEx(false)
        self.PanelStageThree.gameObject:SetActiveEx(false)
        self.PanelPhaseOne.gameObject:SetActiveEx(true)
        self.PanelPhaseTwo.gameObject:SetActiveEx(false)
        self.PanelPhaseThree.gameObject:SetActiveEx(false)
    elseif status == CoupleteStatus.CheckComplete then
        self.PanelStageOne.gameObject:SetActiveEx(false)
        self.PanelStageTwo.gameObject:SetActiveEx(true)
        self.PanelStageThree.gameObject:SetActiveEx(false)
        self.PanelPhaseOne.gameObject:SetActiveEx(false)
        self.PanelPhaseTwo.gameObject:SetActiveEx(true)
        self.PanelPhaseThree.gameObject:SetActiveEx(false)
    elseif status == CoupleteStatus.Complete then
        self.PanelStageOne.gameObject:SetActiveEx(false)
        self.PanelStageTwo.gameObject:SetActiveEx(false)
        self.PanelStageThree.gameObject:SetActiveEx(true)
        self.PanelPhaseOne.gameObject:SetActiveEx(false)
        self.PanelPhaseTwo.gameObject:SetActiveEx(false)
        self.PanelPhaseThree.gameObject:SetActiveEx(true)
    end
end

function XUiCoupletStageCtrlPanel:OnBtnCompleteClick()
    if not self.CurCoupletId then
        return
    end

    XDataCenter.CoupletGameManager.CompleteCoupletSentence()
end

function XUiCoupletStageCtrlPanel:OnBtnPlayVideo()
    if not self.CurCoupletId then
        return
    end

    local coupletTemplate = XCoupletGameConfigs.GetCoupletTemplateById(self.CurCoupletId)
    XDataCenter.MovieManager.PlayMovie(coupletTemplate.StoryStr)
    XSaveTool.SaveData(string.format("%s%s%s", XCoupletGameConfigs.PLAY_VIDEO_STATE_KEY, XPlayer.Id, self.CurCoupletId), XCoupletGameConfigs.PlayVideoState.Played)
    self.BtnPlayVideo:ShowReddot(false)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_COUPLET_GAME_PLAYED_VIDEO)
    XEventManager.DispatchEvent(XEventId.EVENT_COUPLET_GAME_PLAYED_VIDEO)
end

function XUiCoupletStageCtrlPanel:SetBatchImage(isDefault)
    if isDefault then
        local defaultBatch = XCoupletGameConfigs.GetCoupletDefaultBatch(self.CurCoupletId)
        self.ImgBatch:SetRawImage(defaultBatch)
    else
        local batchImage = XCoupletGameConfigs.GetCoupletBatch(self.CurCoupletId)
        self.ImgBatch:SetRawImage(batchImage)
    end
end

return XUiCoupletStageCtrlPanel