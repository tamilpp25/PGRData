local XUiGridSummerEpisodeMap = XClass(nil, "XUiGridSummerEpisodeMap")

function XUiGridSummerEpisodeMap:Ctor(ui,stageId,rootUi)
    self.GameObject = ui
    self.Transform = ui.transform
    self.StageId = stageId
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitUiView()
end

function XUiGridSummerEpisodeMap:InitUiView()
    local isRandomStage = XDataCenter.FubenSpecialTrainManager.CheckHasRandomStage(self.StageId)
    if not isRandomStage then
        local config = XDataCenter.FubenManager.GetStageCfg(self.StageId)
        if config then
            self.RImgMap:SetRawImage(config.StoryIcon)
            self.TxtMapName.text = config.Description
        end
        self.UnLock=XDataCenter.FubenSpecialTrainManager.CheckStageIsUnlock(self.StageId)
        if self.Lock then
            self.Lock.gameObject:SetActiveEx(not self.UnLock)
            local unlockTime=XDataCenter.FubenSpecialTrainManager.GetMapUnLockTime(self.StageId)
            self.TxtCondition.text=XUiHelper.GetText("SummerEpisodeMapUnLock",XUiHelper.GetTimeMonthDayHourMinutes(unlockTime))
        end

        if self.Red then
            self.Red.gameObject:SetActiveEx(XDataCenter.FubenSpecialTrainManager.CheckStageIsNewUnLock(self.StageId) and not self.RootUi.IgnoreRedPoint)
        end
        
    else
        self.UnLock=true
        local storyIcon = XFubenSpecialTrainConfig.GetRandomStageStoryIconById(self.StageId)
        self.RImgMap:SetRawImage(storyIcon)
        self.TxtMapName.text = XFubenSpecialTrainConfig.GetRandomStageNameById(self.StageId)
    end
end

function XUiGridSummerEpisodeMap:SetClickEvent(event)
    self.RootUi:RegisterClickEvent(self.BtnMap, function()
        if self.UnLock then
            event(self.StageId)
        end
    end)
end

function XUiGridSummerEpisodeMap:SetSelect(isSelect)
    self.Activate.gameObject:SetActiveEx(isSelect)
end

return XUiGridSummerEpisodeMap