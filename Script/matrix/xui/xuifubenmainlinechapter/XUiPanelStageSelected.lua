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
        local stageTitle = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(stageInfo.ChapterId)
        strTxtStage = stageTitle .. "-" .. stageCfg.OrderId
    else
        strTxtStage = self.ChapterOrderId .. "-" .. stageCfg.OrderId
    end
    self.TxtStage.text = strTxtStage

    --图标
    local icon = stageCfg.Icon
    if icon then self.RImgNor:SetRawImage(icon) end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelStageSelected:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelStageSelected:AutoInitUi()
    self.TxtStage = self.Transform:Find("TxtStage"):GetComponent("Text")
    self.RImgNor = self.Transform:Find("RImgNor"):GetComponent("RawImage")
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