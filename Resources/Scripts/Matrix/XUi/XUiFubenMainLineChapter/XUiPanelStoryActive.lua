local XUiPanelStoryActive = XClass(nil, "XUiPanelStoryActive")

function XUiPanelStoryActive:Ctor(ui, stageId, chapterOrderId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId
    self.ChapterOrderId = chapterOrderId
    self:InitAutoScript()
    self:Refresh()
end

function XUiPanelStoryActive:Refresh()
    local stageId = self.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.Mainline or stageInfo.Type == XDataCenter.FubenManager.StageType.RepeatChallenge
        or stageInfo.Type == XDataCenter.FubenManager.StageType.ExtraChapter then
        local strTxtStage
        if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageId) then
            strTxtStage = self.ChapterOrderId .. "-" .. XDataCenter.BfrtManager.GetGroupOrderIdByStageId(stageId)
        elseif stageInfo.Type == XDataCenter.FubenManager.StageType.ExtraChapter then
            local stageTitle = XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(stageInfo.ChapterId)
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

function XUiPanelStoryActive:UpdateStageId(stageId)
    if self.StageId ~= stageId then
        self.StageId = stageId
        self:Refresh()
    end
end

function XUiPanelStoryActive:GetKillPos()
    if self.KillPos then
        return self.KillPos.position
    else
        return self.Transform.position
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelStoryActive:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelStoryActive:AutoInitUi()
    self.ImgStageOrder = XUiHelper.TryGetComponent(self.Transform, "ImgStageOrder", "Image")
    self.TxtStage = XUiHelper.TryGetComponent(self.Transform, "TxtStage", "Text")
    self.KillPos = XUiHelper.TryGetComponent(self.Transform, "KillPos", "Transform")
end

function XUiPanelStoryActive:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelStoryActive:RegisterClickEvent函数错误, 参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelStoryActive:RegisterClickEvent函数错误, 参数func需要是function类型")
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelStoryActive:AutoAddListener()
end
-- auto
return XUiPanelStoryActive