local XUiStoryStageDetail = XLuaUiManager.Register(XLuaUi, "UiStoryStageDetail")

function XUiStoryStageDetail:OnAwake()
    self:InitAutoScript()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiStoryStageDetail:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiStoryStageDetail:OnEnable()
    self:Refresh()

end

function XUiStoryStageDetail:OnDisable()

end


function XUiStoryStageDetail:Refresh()
    local stageCfg = self.RootUi.Stage
    local stageId = stageCfg.StageId
    local chapterOrderId = XDataCenter.FubenMainLineManager.GetChapterOrderIdByStageId(stageId)

    self.TxtTitle.text = chapterOrderId .. "-" .. stageCfg.OrderId .. stageCfg.Name
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
function XUiStoryStageDetail:InitAutoScript()
    self:AutoAddListener()
end

function XUiStoryStageDetail:AutoAddListener()
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
end
-- auto
function XUiStoryStageDetail:OnBtnEnterClick()
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

function XUiStoryStageDetail:Hide()
    self:Close()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
end