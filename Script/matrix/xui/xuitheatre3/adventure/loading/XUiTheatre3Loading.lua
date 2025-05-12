---@class XUiTheatre3Loading : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3Loading = XLuaUiManager.Register(XLuaUi, "UiTheatre3Loading")

function XUiTheatre3Loading:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3Loading:OnStart(chapterId)
    self._Chapter = self._Control:GetChapterById(chapterId)
    if not self._Chapter then
        return
    end
    if not string.IsNilOrEmpty(self._Chapter.LoadingTitle) then
        self.RImgTitleIcon:SetRawImage(self._Chapter.LoadingTitle)
    end
    if not string.IsNilOrEmpty(self._Chapter.LoadingDesc) then
        self.RImgDescIcon:SetRawImage(self._Chapter.LoadingDesc)
    end
    if not string.IsNilOrEmpty(self._Chapter.LoadingBgUrl) then
        self.BgCommonBai:SetRawImage(self._Chapter.LoadingBgUrl)
    end
    if XTool.IsNumberValid(self._Chapter.BgmCueId) then
        self._Control:AdventurePlayBgm(self._Chapter.BgmCueId)
    end
    local effectName = self._Chapter.TitleEffect
    if self[effectName] then
        self[effectName].gameObject:SetActiveEx(true)
    end
end

--region Ui - BtnListener
function XUiTheatre3Loading:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnBackClick)
end

function XUiTheatre3Loading:OnBtnBackClick()
    self._Control:CheckAndOpenAdventureNextStep(true)
end
--endregion

return XUiTheatre3Loading