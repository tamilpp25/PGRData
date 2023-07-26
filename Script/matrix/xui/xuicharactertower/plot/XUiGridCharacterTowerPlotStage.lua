---@class XUiGridCharacterTowerPlotStage
local XUiGridCharacterTowerPlotStage = XClass(nil, "XUiGridCharacterTowerPlotStage")

function XUiGridCharacterTowerPlotStage:Ctor(ui, rootUi, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = cb
    XTool.InitUiObject(self)
    if self.ImgComplete then
        self.ImgComplete.gameObject:SetActiveEx(false)
    end
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridCharacterTowerPlotStage:Refresh(chapterId, stageId)
    self.StageId = stageId
    self.ChapterId = chapterId
    ---@type XCharacterTowerChapter
    self.ChapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    -- 刷新基本信息
    self:RefreshStageData()
    -- 刷新关卡状态
    self:RefreshStageStatus()
end

function XUiGridCharacterTowerPlotStage:RefreshStageData()
    -- 通关背景图
    self.RImgPassedBg:SetRawImage(self.ChapterViewModel:GetChapterPassedBg())
    -- 未通关背景图
    self.RImgUnPassedBg:SetRawImage(self.ChapterViewModel:GetChapterUnPassedBg())
    -- 关卡名
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.BtnClick:SetNameByGroup(0, stageCfg.Name)
    -- 按钮图标
    local rewardIcon
    local textDesc
    if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        rewardIcon = XFubenCharacterTowerConfigs.GetCharacterTowerConfigValueByKey("CharacterTowerBtnPlay")
        textDesc = XFubenCharacterTowerConfigs.GetCharacterTowerConfigValueByKey("CharacterTowerTextPlay")
    else
        rewardIcon = XFubenCharacterTowerConfigs.GetCharacterTowerConfigValueByKey("CharacterTowerBtnBattle")
        textDesc = XFubenCharacterTowerConfigs.GetCharacterTowerConfigValueByKey("CharacterTowerTextBattle")
    end
    self.BtnClick:SetSprite(rewardIcon)
    self.BtnClick:SetNameByGroup(1, textDesc)
end

function XUiGridCharacterTowerPlotStage:RefreshStageStatus()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    -- 锁
    self.PanelLock.gameObject:SetActiveEx(not stageInfo.Unlock)
    self.BtnClick:SetButtonState(stageInfo.Unlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)

    if stageInfo.Unlock then
        local nextStageInfo = XDataCenter.FubenManager.GetStageInfo(stageInfo.NextStageId)
        if not (nextStageInfo and nextStageInfo.Unlock or stageInfo.Passed) then
            self:SetPanelSelect(true)
        else
            self:SetPanelSelect(false)
        end
    end
    
    local chapterInfo = self.ChapterViewModel:GetChapterInfo()
    if stageInfo.Passed and chapterInfo:CheckVideoPlayed(self.StageId) then
        self.PanelPassed.gameObject:SetActiveEx(stageInfo.Passed)
        self.PanelUnPassed.gameObject:SetActiveEx(not stageInfo.Passed)
        if self.ImgComplete then
            self.ImgComplete.gameObject:SetActiveEx(true)
        end
    end
end

function XUiGridCharacterTowerPlotStage:PlayAnimation()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local chapterInfo = self.ChapterViewModel:GetChapterInfo()
    if stageInfo.Passed and not chapterInfo:CheckVideoPlayed(self.StageId) then
        -- 播放动画
        self.PanelPassedBgEnable:PlayTimelineAnimation(function()
            self.PanelUnPassed.gameObject:SetActiveEx(false)
            if self.ImgComplete then
                self.ImgComplete.gameObject:SetActiveEx(true)
            end
            XDataCenter.CharacterTowerManager.CharacterTowerSaveVideoStageIdRequest(self.ChapterId, self.StageId)
        end)
    end
end

function XUiGridCharacterTowerPlotStage:SetStageSelect(isActive)
    if self.ImageSelect then
        self.ImageSelect.gameObject:SetActiveEx(isActive)
    end
end

function XUiGridCharacterTowerPlotStage:SetPanelSelect(isActive)
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(isActive)
    end
end

function XUiGridCharacterTowerPlotStage:OnBtnClick()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if not stageInfo.Unlock then
        XUiManager.TipText("FubenPreStageNotPass")
        return
    end
    if self.ClickCb then
        self.ClickCb(self)
    end
end

return XUiGridCharacterTowerPlotStage