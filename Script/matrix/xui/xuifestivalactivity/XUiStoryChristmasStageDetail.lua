local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiStoryChristmasStageDetail = XLuaUiManager.Register(XLuaUi, "UiStoryChristmasStageDetail")

function XUiStoryChristmasStageDetail:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
    self.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
end

function XUiStoryChristmasStageDetail:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiStoryChristmasStageDetail:SetStageDetail(stageId, festivalId)
    self.StageId = stageId
    self.FestivalId = festivalId
    local chapterTemplate = XFestivalActivityConfig.GetFestivalById(festivalId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)

    self.TxtTitle.text = stageCfg.Name
    self.TxtStoryDes.text = stageCfg.Description
    self.RImgNandu:SetRawImage(chapterTemplate.TitleIcon)
    self.RImgTitleBg:SetRawImage(chapterTemplate.TitleBg)
end

function XUiStoryChristmasStageDetail:OnBtnEnterClick()
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

function XUiStoryChristmasStageDetail:PlayStoryId(movieId)
    XDataCenter.MovieManager.PlayMovie(movieId, function()
        self.RootUi:EndScrollViewMove()
    end)
end

function XUiStoryChristmasStageDetail:CloseDetailWithAnimation()
    self:PlayAnimation("AnimDisableEnd", function()
        self:Close()
    end)
end

function XUiStoryChristmasStageDetail:OnDestroy()
end