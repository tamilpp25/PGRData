--- 剧情跳过梗概
---@class XUiMovieSummary: XLuaUi
local XUiMovieSummary = XLuaUiManager.Register(XLuaUi, 'UiMovieSummary')
local CSXTextManagerGetText = CS.XTextManager.GetText


function XUiMovieSummary:OnAwake()
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
    self:RegisterClickEvent(self.BtnContinue, self.OnBtnContinueClick)
end

function XUiMovieSummary:OnStart(skipType, summaryCfg, cancelCb, sureCb)
    self.SkipType = skipType
    self.Cfg = summaryCfg
    self.CancelCb = cancelCb
    self.SureCb = sureCb
    
    self.SummaryPanelRoot.gameObject:SetActiveEx(self.SkipType == XMVCA.XMovie.XEnumConst.SkipType.Summary)
    self.TipsPanelRoot.gameObject:SetActiveEx(self.SkipType == XMVCA.XMovie.XEnumConst.SkipType.OnlyTips)

    if self.SkipType == XMVCA.XMovie.XEnumConst.SkipType.Summary then
        self:RefreshSummary()
    else
        self:RefreshTips()
    end
end

function XUiMovieSummary:OnBtnSkipClick()
    self:Close()
    if self.SureCb then
        self.SureCb()
    end
end

function XUiMovieSummary:OnBtnContinueClick()
    self:Close()
    if self.CancelCb then
        self.CancelCb()
    end
end

function XUiMovieSummary:RefreshSummary()
    self.TxtSummaryTitle.text = XUiHelper.ReplaceTextNewLine(self.Cfg.Title)
    self.TxtSummary.text = XDataCenter.MovieManager.GetSummaryContentByGenderCheck(XUiHelper.ReplaceTextNewLine(self.Cfg.SummaryContent))
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.SummaryContent)
end

function XUiMovieSummary:RefreshTips()
    self.TxtTipsTitle.text = CSXTextManagerGetText("MovieSkipTipTitle")
    self.TxtTips.text = CSXTextManagerGetText("MovieSkipTipContent")
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.TipsContent)
end

function XUiMovieSummary:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_UI_SUMMARY_CLOSED)
end

return XUiMovieSummary