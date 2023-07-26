local XUiGridFubenSideTab = require("XUi/XUiFuben/UiDynamicList/XUiGridFubenSideTab")
local XUiGridResourceCollectionTab = XClass(XUiGridFubenSideTab, "XUiGridResourceCollectionTab")

function XUiGridResourceCollectionTab:Ctor(ui, clickFunc)
    self.GroupConfig = nil
    self.ClickFunc = clickFunc
end

function XUiGridResourceCollectionTab:SetData(index, tagConfig)
    XUiGridResourceCollectionTab.Super.SetData(self, index)
    self.GroupConfig = tagConfig
    self.Manager = XDataCenter.FubenManagerEx.GetManager(tagConfig.ChapterType[1])
    self.BtnTab:SetNameByGroup(0, tagConfig.TagName)

    -- 资源收集界面没有红点
    self.BtnTab:ShowReddot(false)
    -- 限时开放标签
    for i = 1, 3 do
        self["Tag" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiGridResourceCollectionTab:OnBtnTabClicked()
    local isOpen, lockTip = XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(self.GroupConfig.Id)
    if not isOpen then
        XUiManager.TipMsg(lockTip)
        return
    end

    if self.ClickFunc then
        self.ClickFunc(self.Index, self.GroupConfig)
    end

    self.Super.Click(self)
end

return XUiGridResourceCollectionTab