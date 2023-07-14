local XUiGridFubenSideTab = require("XUi/XUiFuben/UiDynamicList/XUiGridFubenSideTab")
local XUiGridMainLineTab = XClass(XUiGridFubenSideTab, "XUiGridMainLineTab")

function XUiGridMainLineTab:Ctor(ui, clickFunc)
    self.GroupConfig = nil
    self.ClickFunc = clickFunc
    self.MainLineManager = XDataCenter.FubenManagerEx.GetMainLineManager()
end

function XUiGridMainLineTab:SetData(index, groupConfig)
    XUiGridMainLineTab.Super.SetData(self, index)
    self.GroupConfig = groupConfig
    self.BtnTab:SetNameByGroup(0, groupConfig.Name)
    self.BtnTab:ShowReddot(self.MainLineManager:ExCheckChapterGroupHasRedPoint(groupConfig.Id))
    for i = 1, 6 do
        if self["Tag" .. i] then
            self["Tag" .. i].gameObject:SetActiveEx(self.MainLineManager:ExCheckChapterGroupHasTimeLimitTag(groupConfig.Id
                , XDataCenter.FubenManager.DifficultNormal))
        end
    end
end

function XUiGridMainLineTab:OnBtnTabClicked()
    if self.ClickFunc then
        self.ClickFunc(self.Index, self.GroupConfig)
    end

    self.Super.Click(self)
end

function XUiGridMainLineTab:ExCheckOwnLock()
    return self.MainLineManager:ExCheckGroupIsLocked(self.GroupConfig.Id)
end

function XUiGridMainLineTab:RefreshRedPoint()
    local isRed = self.MainLineManager:ExCheckChapterGroupHasRedPoint(self.GroupConfig.Id)
    self.BtnTab:ShowReddot(isRed)
    self.BtnPressNm:ShowReddot(isRed)
    self.BtnPressDisable:ShowReddot(isRed)
end

return XUiGridMainLineTab