local XUiGridFubenMainLineStage = XClass(nil,"XUiGridFubenMainLineStage")

function XUiGridFubenMainLineStage:Ctor(ui)
    self.GameObject = ui
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:RegisterButtonClick()
end

function XUiGridFubenMainLineStage:RegisterButtonClick()
    self.BtnClick.CallBack = function() 
        self:OnClickBtnStage()
    end
end

function XUiGridFubenMainLineStage:OnClickBtnStage()
    self:SetSelectState(true)
    XEventManager.DispatchEvent(XEventId.EVENT_MAINLINE_SELECT_STAGE, self.ChapterIndex, self.StageIndex, self.StageId)
end

function XUiGridFubenMainLineStage:SetSelectState(isSelect)
    self.IsSelect = isSelect
    self.ClickEffect.gameObject:SetActiveEx(isSelect)
end

function XUiGridFubenMainLineStage:Refresh(chapterIndex,stageIndex,stageId)
    self.ChapterIndex = chapterIndex
    self.StageIndex = stageIndex
    self.StageId = stageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local isStory =  stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG
    self.StoryEffect.gameObject:SetActiveEx(isStory)
    self.FightEffect.gameObject:SetActiveEx(not isStory)
    local isPass = XDataCenter.FubenManager.CheckStageIsPass(self.StageId)
    self.SelectEffect.gameObject:SetActiveEx(not isPass)
    local chapterMainCfg = XDataCenter.FubenMainLineManager.GetChapterMainTemplate(XDataCenter.FubenMainLineManager.MainLine3DId)
    local chapterId = chapterMainCfg.SubChapter[chapterIndex]
    local chapterCfg = XFubenMainLineConfigs.GetSubChapterCfg(chapterId)
    self.TxtName.text = CS.XTextManager.GetText("MainLine3dStagePrefixName",chapterCfg.OrderId,stageCfg.OrderId)
    self.TxtProgress.text = stageCfg.Name
    local eventCfg = XFubenMainLineConfigs.GetStageExById(stageId)
    if eventCfg then
        local effectPath = eventCfg.EventEffect
        if not self.EventEffect then
            if not string.IsNilOrEmpty(effectPath) then
                ---@type UnityEngine.GameObject
                self.EventEffect = self.StoryEffect.parent:LoadPrefab(effectPath)
            end
        else
            self.EventEffect.gameObject:SetActiveEx(true)
        end
    end
end


return XUiGridFubenMainLineStage