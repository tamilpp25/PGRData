local XUiGridNierRepeatStage = XClass(nil, "XUiGridNierRepeatStage")

function XUiGridNierRepeatStage:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.RootUi:RegisterClickEvent(self.BtnChapter, function()
        self:OnBtnChapterClick()
    end)

    self.GridList = {}
    self.LockGridList = {}
end

function XUiGridNierRepeatStage:UpdateInfo(data, index)
    self.RepeatData = data
    self.NierRepeatStageId = data:GetNieRRepeatStageId()
    local stageId = data:GetNieRExStageIds()[index]
    local nierRepeatCondit = data:GetNieRExStageConditions()[index]
    self.StageId = stageId
    self.Stage = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.TextTitle.text = self.Stage.Name
    self.TextTitleLock.text = self.Stage.Name
    local stageIsPassed = XDataCenter.FubenManager.CheckStageIsPass(stageId)
    
    self.ImgFinish.gameObject:SetActiveEx(stageIsPassed)
    self.GetTips.gameObject:SetActiveEx(stageIsPassed)
    if data:CheckNieRRepeatStageUnlock(stageId) then
        self.PanelChapter.gameObject:SetActiveEx(true)
        self.PanelNewEffect.gameObject:SetActiveEx(false)
        self.ImgRedDot.gameObject:SetActiveEx(false)
        self.PanelChapterLock.gameObject:SetActiveEx(false)
        if data:CheckNieRRepeatStagePass(stageId) then
            self.ImgFinish.gameObject:SetActiveEx(true)
        else
            self.ImgFinish.gameObject:SetActiveEx(false)
        end
        self.RImgChapter:SetRawImage(self.Stage.Icon)
    
    else
        self.PanelChapter.gameObject:SetActiveEx(false)
        self.PanelNewEffect.gameObject:SetActiveEx(false)
        self.ImgRedDot.gameObject:SetActiveEx(false)
        self.ImgFinish.gameObject:SetActiveEx(false)
        self.PanelChapterLock.gameObject:SetActiveEx(true)
        self.RImgChapterLock:SetRawImage(self.Stage.Icon)
    end

    self:UpdateRewardShow(data)
end

function XUiGridNierRepeatStage:UpdateRewardShow(data)
    local cfg = XNieRConfigs.GetNieRRepeatableStageClient(self.StageId)
    --
    self.RImgIcon:SetRawImage(cfg.RewardIcon)
    self.RImgIconL:SetRawImage(cfg.RewardIcon)
    if cfg.RewardQuality ~= 0 then
        XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, cfg.RewardQuality)
        XUiHelper.SetQualityIcon(self.RootUi, self.ImgQualityL, cfg.RewardQuality)
    end
    self.TxtName.text = cfg.RewardTitle
    self.TxtNameL.text = cfg.RewardTitle

    
end

function XUiGridNierRepeatStage:OnBtnChapterClick()
    local condit, desc = self.RepeatData:CheckNieRRepeatStageUnlock(self.StageId)
    if condit then
        self.RootUi:OnBtnChapterClick(self.StageId, self.NierRepeatStageId)
    else
        XUiManager.TipMsg(desc)
    end
end

return XUiGridNierRepeatStage