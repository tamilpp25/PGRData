local XUiPanelStageSelected = XClass(nil, "XUiPanelStageSelected")

function XUiPanelStageSelected:Ctor(ui, stageId, chapterOrderId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId
    self.ChapterOrderId = chapterOrderId
    self:InitAutoScript()
    self:Refresh()
end

function XUiPanelStageSelected:Refresh()
    local stageId = self.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    --文字
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
    self.TxtStage.text = strTxtStage

    --图标
    local icon = stageCfg.Icon
    if icon then self.RImgNor:SetRawImage(icon) end

    -- v1.31隐藏模式
    if not XTool.UObjIsNil(self.Normal) and not XTool.UObjIsNil(self.Hidden) then
        local haveHideAction = stageCfg.HideAction == 1 and #stageCfg.RobotId > 0
        self.Normal.gameObject:SetActiveEx(not haveHideAction)
        self.Hidden.gameObject:SetActiveEx(haveHideAction)
        self.TxtStage2.text = strTxtStage
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelStageSelected:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelStageSelected:AutoInitUi()
    self.TxtStage = XUiHelper.TryGetComponent(self.Transform, "TxtStage", "Text")
    self.RImgNor = XUiHelper.TryGetComponent(self.Transform, "RImgNor", "RawImage")

    -- v1.31隐藏模式
    if XTool.UObjIsNil(self.TxtStage) then 
        self.TxtStage = XUiHelper.TryGetComponent(self.Transform, "Normal/TxtStage", "Text")
    end
    self.TxtStage2 = XUiHelper.TryGetComponent(self.Transform, "Hidden/TxtStage2", "Text")
    self.Normal = XUiHelper.TryGetComponent(self.Transform, "Normal", "RectTransform")
    self.Hidden = XUiHelper.TryGetComponent(self.Transform, "Hidden", "RectTransform")
end

function XUiPanelStageSelected:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelStageSelected:RegisterClickEvent函数错误, 参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelStageSelected:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelStageSelected:AutoAddListener()
end
-- auto
return XUiPanelStageSelected