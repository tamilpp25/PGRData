local XUiPanelHideTagNor = XClass(nil, "XUiPanelHideTagNor")

function XUiPanelHideTagNor:Ctor(ui, stageId, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId
    self.RootUi = rootUi
    self:InitAutoScript()
    self:Refresh()
end

function XUiPanelHideTagNor:Refresh()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if self.PanelPass then
        self.PanelPass.gameObject:SetActiveEx(stageInfo.Passed)
    end
end

function XUiPanelHideTagNor:UpdateStageId(stageId)
    self.StageId = stageId
    self:Refresh()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelHideTagNor:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelHideTagNor:AutoInitUi()
    self.BtnOnHideLock = self.Transform:Find("BtnOnHideLock"):GetComponent("Button")
    self.PanelPass = self.Transform:Find("ImageHideTagNor/PanelPass")
end

function XUiPanelHideTagNor:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelHideTagNor:RegisterClickEvent函数错误, 参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelHideTagNor:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelHideTagNor:AutoAddListener()
    self:RegisterClickEvent(self.BtnOnHideLock, self.OnBtnOnHideLockClick)
end
-- auto
function XUiPanelHideTagNor:OnBtnOnHideLockClick()
    if not self.StageId then return end

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)

    if not XDataCenter.PrequelManager.CheckPrequelStageOpen(self.StageId) then
        if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
            XUiManager.TipError(CS.XTextManager.GetText("TeamLevelToOpen", stageCfg.RequireLevel))
            return
        end
        XUiManager.TipError(CS.XTextManager.GetText("PrequelUnTrigger"))
        return
    end

    if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        if stageInfo.Passed then
            self.RootUi:OnEnterStory(self.StageId, function()
                XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId, function()
                    XDataCenter.PrequelManager.UpdateShowChapter(self.StageId)
                end)
            end)
        else
            self.RootUi:OnEnterStory(self.StageId, function()
                XDataCenter.PrequelManager.FinishStoryRequest(self.StageId, function()
                    XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId, function()
                        self.RootUi:RefreshRegional()
                        XDataCenter.PrequelManager.UpdateShowChapter(self.StageId)
                    end)
                end)
            end)
        end
    end

    if stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG then
        if not stageCfg then
            XLog.ErrorTableDataNotFound("XUiPanelHideTagNor:OnBtnOnHideLockClick",
            "stageCfg", "Share/Fuben/Stage.tab", "StageId", tostring(self.StageId))
            return
        end
        self.RootUi:OnEnterFight(self.StageId, function()
            XDataCenter.FubenManager.EnterPrequelFight(self.StageId)
        end)
    end
end

return XUiPanelHideTagNor