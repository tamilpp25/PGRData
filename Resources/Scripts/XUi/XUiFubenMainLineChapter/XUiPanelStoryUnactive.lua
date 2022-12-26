local XUiPanelStoryUnactive = XClass(nil, "XUiPanelStoryUnactive")

function XUiPanelStoryUnactive:Ctor(ui, stageId, chapterOrderId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId
    self.ChapterOrderId = chapterOrderId
    self:InitAutoScript()
    self:Refresh()
end

function XUiPanelStoryUnactive:Refresh()
    local stageId = self.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.Mainline then
        local strTxtStage
        if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageId) then
            strTxtStage = self.ChapterOrderId .. "-" .. XDataCenter.BfrtManager.GetGroupOrderIdByStageId(stageId)
        elseif stageInfo.Type == XDataCenter.FubenManager.StageType.ExtraChapter then
            local stageTitle = XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(stageInfo.ChapterId)
            strTxtStage = stageTitle .. "-" .. stageCfg.OrderId
        else
            strTxtStage = self.ChapterOrderId .. "-" .. stageCfg.OrderId
        end
        self.TxtStage.text = strTxtStage
        self.ImgStageOrder.gameObject:SetActive(true)
    else
        self.ImgStageOrder.gameObject:SetActive(false)
    end
end

function XUiPanelStoryUnactive:UpdateStageId(stageId)
    if self.StageId ~= stageId then
        self.StageId = stageId
        self:Refresh()
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelStoryUnactive:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelStoryUnactive:AutoInitUi()
    self.ImgStageOrder = self.Transform:Find("ImgStageOrder"):GetComponent("Image")
    self.TxtStage = self.Transform:Find("ImgStageOrder/TxtStage"):GetComponent("Text")
end

function XUiPanelStoryUnactive:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelStoryUnactive:RegisterClickEvent函数错误, 参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelStoryUnactive:RegisterClickEvent函数错误, 参数func需要是function类型")
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelStoryUnactive:AutoAddListener()
end
-- auto
return XUiPanelStoryUnactive