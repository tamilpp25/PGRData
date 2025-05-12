local XUiPanelStory = require("XUi/XUiActivityBrief/XUiPanelStory")
local XUiPanelStorySelected = XClass(nil, "XUiPanelStorySelected")

function XUiPanelStorySelected:Ctor(ui, stageId, chapterOrderId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId
    self.ChapterOrderId = chapterOrderId
    self:InitAutoScript()
    self:Refresh()
end

function XUiPanelStorySelected:Refresh()
    local stageId = self.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.Mainline or stageInfo.Type == XDataCenter.FubenManager.StageType.RepeatChallenge
        or stageInfo.Type == XDataCenter.FubenManager.StageType.ExtraChapter
        or stageInfo.Type == XDataCenter.FubenManager.StageType.ShortStory then
        local strTxtStage
        if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageId) then
            strTxtStage = self.ChapterOrderId .. "-" .. XDataCenter.BfrtManager.GetGroupOrderIdByStageId(stageId)
        elseif stageInfo.Type == XDataCenter.FubenManager.StageType.ExtraChapter then
            local stageTitle = XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(stageInfo.ChapterId)
            strTxtStage = stageTitle .. "-" .. stageCfg.OrderId
        elseif stageInfo.Type == XDataCenter.FubenManager.StageType.ShortStory then
            local stageTitle = XFubenShortStoryChapterConfigs.GetStageTitleByStageId(stageId)
            strTxtStage = stageTitle .. "-" .. stageCfg.OrderId
        else
            strTxtStage = self.ChapterOrderId .. "-" .. stageCfg.OrderId
        end
        if self.TxtStage then
            self.TxtStage.text = strTxtStage
        end
        if self.ImgStageOrder then
            self.ImgStageOrder.gameObject:SetActive(true)
        end
    else
        if self.ImgStageOrder then
            self.ImgStageOrder.gameObject:SetActive(false)
        end
    end
end

function XUiPanelStorySelected:UpdateStageId(stageId)
    if self.StageId ~= stageId then
        self.StageId = stageId
        self:Refresh()
    end
end

function XUiPanelStorySelected:GetKillPos()
    if self.KillPos then
        return self.KillPos.position
    else
        return self.Transform.position
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelStorySelected:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelStorySelected:AutoInitUi()
    self.ImgStageOrder = XUiHelper.TryGetComponent(self.Transform, "ImgStageOrder", "Image")
    self.TxtStage = XUiHelper.TryGetComponent(self.Transform, "TxtStage", "Text")
    self.KillPos = XUiHelper.TryGetComponent(self.Transform, "KillPos", "Transform")
end

function XUiPanelStorySelected:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelStorySelected:RegisterClickEvent函数错误, 参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelStorySelected:RegisterClickEvent函数错误, 参数func需要是function类型")
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelStorySelected:AutoAddListener()
end
-- auto
return XUiPanelStorySelected