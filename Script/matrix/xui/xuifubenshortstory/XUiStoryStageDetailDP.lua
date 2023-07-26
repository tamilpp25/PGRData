local XUiStoryStageDetailDP = XLuaUiManager.Register(XLuaUi,"UiStoryStageDetailDP")

function XUiStoryStageDetailDP:OnAwake()
    self:InitAutoScript()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiStoryStageDetailDP:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiStoryStageDetailDP:OnEnable()
    self:Refresh()
end

function XUiStoryStageDetailDP:Refresh()
    local stageCfg = self.RootUi.Stage
    local stageId = stageCfg.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local stageTitle = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(stageInfo.ChapterId)
    self.TxtTitle.text = stageTitle .. "-" .. stageCfg.OrderId .. stageCfg.Name
    self.TxtStoryDes.text = stageCfg.Description
    if stageCfg.Icon then
        self.RImgNandu:SetRawImage(stageCfg.Icon)
    end
    if stageCfg.StoryIcon then
        self.RImgTitleBg:SetRawImage(stageCfg.StoryIcon)
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiStoryStageDetailDP:InitAutoScript()
    self:AutoAddListener()
end

function XUiStoryStageDetailDP:AutoAddListener()
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
end
-- auto
function XUiStoryStageDetailDP:OnBtnEnterClick()
    local stageCfg = self.RootUi.Stage
    local stageId = stageCfg.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    self:Hide()
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId)
    else
        XDataCenter.FubenManager.FinishStoryRequest(stageId, function()
            XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId, function()
                if self.RootUi then
                    self.RootUi:RefreshForChangeDiff()
                end
            end)
        end)
    end
end

function XUiStoryStageDetailDP:Hide()
    self:Close()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
end

return XUiStoryStageDetailDP