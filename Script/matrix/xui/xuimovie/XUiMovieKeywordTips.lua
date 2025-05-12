---@class XUiMovieKeywordTips:XLuaUi
---@field private _Control XMovieControl
local XUiMovieKeywordTips = XLuaUiManager.Register(XLuaUi, "UiMovieKeywordTips")

function XUiMovieKeywordTips:OnAwake()
    self:RegisterUiEvents()
end

function XUiMovieKeywordTips:OnStart(keywordIdStr)
    self.KeywordId = tonumber(keywordIdStr) 
end

function XUiMovieKeywordTips:OnEnable()
    self:Refresh()
end

function XUiMovieKeywordTips:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiMovieKeywordTips:Refresh()
    local cfg = self._Control:GetKeywordConfig(self.KeywordId)
    self.TxtTitle.text = cfg.KuroTerm
    self.TxtDesc.text = cfg.Interpretation
end

return XUiMovieKeywordTips