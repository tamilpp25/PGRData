---@class XUiTemple2PopupStory : XLuaUi
---@field _Control XTemple2Control
local XUiTemple2PopupStory = XLuaUiManager.Register(XLuaUi, "UiTemple2PopupStory")

function XUiTemple2PopupStory:OnAwake()
    self:BindExitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiTemple2PopupStory:OnEnable()
end

---@param data XUiTemple2StoryGridData
function XUiTemple2PopupStory:OnStart(data)
    self._Data = data
    self:Init()
    self:SetButtonCallBack()
end

function XUiTemple2PopupStory:Init()
    self.TxtStoryDec.text = self._Data.StoryDesc
    self.TxtStoryName.text = self._Data.StoryTitle
end

function XUiTemple2PopupStory:SetButtonCallBack()
    self.BtnMask.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnEnterStoryAfter.CallBack = function()
        self:OnBtnPlayClick()
    end
end

function XUiTemple2PopupStory:OnBtnBackClick()
    self:Close()
end

function XUiTemple2PopupStory:OnBtnPlayClick()
    XDataCenter.MovieManager.PlayMovie(self._Data.Id, nil, nil, nil, false)
end

return XUiTemple2PopupStory