local XUiGridFubenSideTab = require("XUi/XUiFuben/UiDynamicList/XUiGridFubenSideTab")
local XUiGridSimulationChallengeTab = XClass(XUiGridFubenSideTab, "XUiGridSimulationChallengeTab")

function XUiGridSimulationChallengeTab:Ctor(ui, clickFunc)
    self.GroupConfig = nil
    self.ClickFunc = clickFunc
end

function XUiGridSimulationChallengeTab:RefreshRedPoint()
    -- 再拿一次该标签下的manager检查红点
    local isRed = false
    local allManagers = {}
    for k, chapterType in pairs(self.GroupConfig.ChapterType) do
        for k, manager in pairs(XDataCenter.FubenManagerEx.GetManagers(chapterType)) do
            table.insert(allManagers, manager) -- 根据2级标签拿到所有manager
        end
    end
    for k, manager in pairs(allManagers) do
        if manager:ExCheckIsShowRedPoint() then
            isRed = true
            break
        end
    end
    self.BtnTab:ShowReddot(isRed)
    self.BtnPressNm:ShowReddot(isRed)
    self.BtnPressDisable:ShowReddot(isRed)
end

function XUiGridSimulationChallengeTab:SetData(index, tagConfig)
    XUiGridSimulationChallengeTab.Super.SetData(self, index)
    self.GroupConfig = tagConfig
    self.BtnTab:SetNameByGroup(0, tagConfig.TagName)

    self:RefreshRedPoint()
    -- 限时开放标签
    for i = 1, 3 do
        self["Tag" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiGridSimulationChallengeTab:OnBtnTabClicked()
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

return XUiGridSimulationChallengeTab