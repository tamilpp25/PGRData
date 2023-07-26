local XUiGridFubenSideTab = require("XUi/XUiFuben/UiDynamicList/XUiGridFubenSideTab")
local XUiGridExtralLineTab = XClass(XUiGridFubenSideTab, "XUiGridExtralLineTab")

function XUiGridExtralLineTab:Ctor(ui, clickFunc)
    self.Manager = nil
    self.ClickFunc = clickFunc
end

function XUiGridExtralLineTab:SetData(index, tagConfig)
    XUiGridExtralLineTab.Super.SetData(self, index)
    self.GroupConfig = tagConfig
    self.Manager = XDataCenter.FubenManagerEx.GetManager(tagConfig.ChapterType[1])
    self.BtnTab:SetNameByGroup(0, tagConfig.TagName)

    self:RefreshRedPoint()
    for i = 1, 6 do
        if self["Tag" .. i] then
            self["Tag" .. i].gameObject:SetActiveEx(self.Manager:ExCheckHasTimeLimitTag())
        end
    end
end

function XUiGridExtralLineTab:OnBtnTabClicked()
    local isOpen, lockTip = XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(self.GroupConfig.Id)
    if not isOpen then
        XUiManager.TipMsg(lockTip)
        return
    end

    if self.ClickFunc then
        self.ClickFunc(self.Index, self.Manager)
    end
    self.Super.Click(self)
end

function XUiGridExtralLineTab:RefreshRedPoint()
    local isRed = false
    if self.Manager:ExGetChapterType() == XFubenConfigs.ChapterType.Festival then
        isRed = self.Manager:ExCheckIsShowRedPoint(XFestivalActivityConfig.UiType.ExtralLine)
    else
        isRed = self.Manager:ExCheckIsShowRedPoint()
    end
    self.BtnTab:ShowReddot(isRed)
    self.BtnPressNm:ShowReddot(isRed)
    self.BtnPressDisable:ShowReddot(isRed)
end

return XUiGridExtralLineTab