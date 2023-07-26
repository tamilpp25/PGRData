local XUiPanelStageLock = XClass(nil, "XUiPanelStageLock")

function XUiPanelStageLock:Ctor(ui, stageId, chapterOrderId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId
    self.ChapterOrderId = chapterOrderId
    self:InitAutoScript()
    self:Refresh()
end

function XUiPanelStageLock:Refresh()
    local stageId = self.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

    if not XTool.UObjIsNil(self.TxtStage) then
        local strTxtStage

        if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageId) then
            strTxtStage = self.ChapterOrderId .. "-" .. XDataCenter.BfrtManager.GetGroupOrderIdByStageId(stageId)
        else
            strTxtStage = self.ChapterOrderId .. "-" .. stageCfg.OrderId
        end
        self.TxtStage.text = strTxtStage
    end

    --图标
    if not XTool.UObjIsNil(self.RImgNor) then
        local icon = stageCfg.Icon
        if icon then self.RImgNor:SetRawImage(icon) end
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelStageLock:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelStageLock:AutoInitUi()
    self.TxtStage = XUiHelper.TryGetComponent(self.Transform, "TxtStage", "Text")
    self.RImgNor = XUiHelper.TryGetComponent(self.Transform, "RImgNor", "RawImage")
end

function XUiPanelStageLock:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelStageLock:RegisterClickEvent函数错误, 参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelStageLock:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelStageLock:AutoAddListener()
end
-- auto
return XUiPanelStageLock