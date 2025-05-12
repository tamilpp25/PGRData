local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiStorySpringFestivalStageDetail = XLuaUiManager.Register(XLuaUi, "UiStorySpringFestivalStageDetail")

function XUiStorySpringFestivalStageDetail:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
    self.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
end

function XUiStorySpringFestivalStageDetail:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiStorySpringFestivalStageDetail:SetStageDetail(stageId, festivalId)
    self.StageId = stageId
    self.FestivalId = festivalId
    local chapterTemplate = XFestivalActivityConfig.GetFestivalById(festivalId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)

    self.TxtTitle.text = stageCfg.Name
    self.TxtStoryDes.text = stageCfg.Description
    self.RImgNandu:SetRawImage(chapterTemplate.TitleIcon)
    self.RImgTitleBg:SetRawImage(chapterTemplate.TitleBg)
end

function XUiStorySpringFestivalStageDetail:OnBtnEnterClick()
    if not self.StageId then return end

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if not stageCfg or not stageInfo then return end

    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(self.StageId)
    if stageInfo.Passed then
        self:PlayStoryId(beginStoryId, self.StageId)
    else
        XDataCenter.FubenFestivalActivityManager.FinishStoryRequest(self.StageId, function()
            XDataCenter.FubenFestivalActivityManager.RefreshStagePassedBySettleDatas({ StageId = self.StageId })
            self:PlayStoryId(beginStoryId, self.StageId)
        end)
    end
end

function XUiStorySpringFestivalStageDetail:PlayStoryId(movieId)
    self.RootUi:ClearNodesSelect()
    self.RootUi:ShowPanel(false)
    XDataCenter.MovieManager.PlayMovie(movieId, function()
        self.RootUi:EndScrollViewMove()
        self.RootUi:CloseStageDetails()
        self.RootUi:Refresh()
        self.RootUi:ShowPanel(true)
    end)
end

function XUiStorySpringFestivalStageDetail:CloseDetailWithAnimation()
    self:PlayAnimation("AnimDisableEnd", function()
        self:Close()
    end)
end

function XUiStorySpringFestivalStageDetail:OnDestroy()
end