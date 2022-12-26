local next = next
local XUiGridReviewItem = require("XUi/XUiMovie/XUiGridReviewItem")

local XUiMovieReview = XLuaUiManager.Register(XLuaUi, "UiMovieReview")

function XUiMovieReview:OnAwake()
    self.GridReviewItem.gameObject:SetActiveEx(false)
    self.HighlightColor = XUiHelper.Hexcolor2Color(CS.XGame.ClientConfig:GetString("MovieReviewHighlightColor"))
    self:AddListener()
end

function XUiMovieReview:OnEnable()
    self:RefreshView()
end

function XUiMovieReview:RefreshView()
    local reviewDialogList = XDataCenter.MovieManager.GetReviewDialogList()
    --if not next(reviewDialogList) then return end

    self.GridList = self.GridList or {}
    self.LastColor = self.LastColor or {}
    for i, data in pairs(reviewDialogList) do
        local grid = self.GridList[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridReviewItem)
            grid = XUiGridReviewItem.New(obj, data)
            grid.Transform:SetParent(self.PanelReviewContent, false)
            self.GridList[i] = grid
            self.LastColor[i] = grid:GetTextColor()
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(data)
        grid:SetTextColor(i == #reviewDialogList and self.HighlightColor or self.LastColor[i])
    end

    local dataNum = #reviewDialogList
    local gridNum = #self.GridList
    for i = dataNum + 1, gridNum do
        self.GridList[i].GameObject:SetActiveEx(false)
    end
    if self.SViewReview then
        self.SViewReview.verticalNormalizedPosition = 0
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelReviewContent)
end

function XUiMovieReview:AddListener()
    self.BtnClose.CallBack = function() self:OnClickBtnClose() end
end

function XUiMovieReview:OnClickBtnClose()
    self:Close()
end