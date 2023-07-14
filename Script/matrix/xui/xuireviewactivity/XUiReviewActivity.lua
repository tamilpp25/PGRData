--=============
--二周年回顾活动
--=============
local XUiReviewActivity = XLuaUiManager.Register(XLuaUi, "UiReviewActivity2Anniversary")

local TotlePageNum

local PageController = require("XUi/XUiReviewActivity/Panel/XUiReviewActivityPage")

function XUiReviewActivity:OnStart()
    self.CurrentPage = 1
    self.ReadPage = 0
    self.PlayingAnimation = {}
    TotlePageNum = XDataCenter.ReviewActivityManager.GetTotlePageNum()
    XDataCenter.ReviewActivityManager.SetOpenReview(function(isHitFace)
            self.IsHitFace = isHitFace
        end)
    self:InitBtns()
end

function XUiReviewActivity:InitBtns()
    self.BtnClick.CallBack = function() self:OnClick() end
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiReviewActivity:OnEnable()
    self:ShowCurrent()
end

function XUiReviewActivity:ShowCurrent()
    for i = 1, TotlePageNum do
        local panel = self["PanelSequence" .. i]
        if panel then

            panel.gameObject:SetActiveEx(i == self.CurrentPage)
            if i == self.CurrentPage then
                PageController.ShowPanel(self, self.CurrentPage)
            end
        end
    end
end

function XUiReviewActivity:NextPage()
    self.CurrentPage = self.CurrentPage + 1
    if self.CurrentPage <= TotlePageNum then
        self:ShowCurrent()
    else
        self:Close()
    end
end

function XUiReviewActivity:OnClick()
    if self.CurrentPage == 1 and not self.FirstPageAnimFinishFlag then
        if self.FirstPageAnimClosingFlag then return end
        self.FirstPageAnimClosingFlag = true
        self:PlayAnimation("PanelSequence1Disable", function()
                self.FirstPageAnimFinishFlag = true
                self:NextPage()
                self.FirstPageAnimClosingFlag = nil
            end)
        return
    elseif self.CurrentPage == 2 and not self.SecondPageAnimPlayFlag then
        if self.Sequence2NextPage then
            self.Sequence2NextPage:Play()
        end
        self.SecondPageAnimPlayFlag = true
        return
    end
    if self.CurrentPage == 2 then
        local medalInfos = XDataCenter.ReviewActivityManager.GetMedalInfos()
        if not medalInfos or (not next(medalInfos)) then
            self.CurrentPage = 3
        end
    end
    if self.CurrentPage == 3 then
        local collections = XDataCenter.ReviewActivityManager.GetScoreTitlesIdList()
        if not collections or (not next(collections)) then
            self.CurrentPage = 4
        end
    end
    self:NextPage()
end

function XUiReviewActivity:OnDestroy()
    PageController.OnDestroy(self)
    if self.IsHitFace then
        XEventManager.DispatchEvent(XEventId.EVENT_REVIEW_ACTIVITY_HIT_FACE_END)
    end
end