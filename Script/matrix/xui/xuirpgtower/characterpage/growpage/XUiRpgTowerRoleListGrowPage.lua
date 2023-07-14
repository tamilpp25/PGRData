-- 兵法蓝图成员列表养成页面
local XUiRpgTowerRoleListGrowPage = XClass(nil, "XUiRpgTowerRoleListGrowPage")
local XUiRpgTowerGrowPageTabsPanel = require("XUi/XUiRpgTower/CharacterPage/GrowPage/XUiRpgTowerGrowPageTabsPanel")
local XUiRpgTowerGrowPageNaturePanel = require("XUi/XUiRpgTower/CharacterPage/GrowPage/XUiRpgTowerGrowPageNaturePanel")
local XUiRpgTowerGrowPageLevelUpPanel = require("XUi/XUiRpgTower/CharacterPage/GrowPage/XUiRpgTowerGrowPageLevelUpPanel")
--================
--子面板索引
--================
local ChildIndex = {
    LevelUp = "LevelUp",
    Nature = "Nature"
}
--================
--子面板配置
--================
local ChildUiWindows

function XUiRpgTowerRoleListGrowPage:Ctor(rootUi)
    self.RootUi = rootUi
    self.ChildList = {}
    self:InitChildUiWindows()
    self:CreateTabs()
end
--================
--初始化子面板配置
--================
function XUiRpgTowerRoleListGrowPage:InitChildUiWindows()
    ChildUiWindows = 
    {
        [ChildIndex.LevelUp] = {
            ChildClass = XUiRpgTowerGrowPageLevelUpPanel,
            AssetPath = XUiConfigs.GetComponentUrl("RpgTowerRoleListChildWindow" .. ChildIndex.LevelUp),
        },
        [ChildIndex.Nature] = {
            ChildClass = XUiRpgTowerGrowPageNaturePanel,
            AssetPath = XUiConfigs.GetComponentUrl("RpgTowerRoleListChildWindow" .. ChildIndex.Nature),
        }
    }
end
--================
--创建页签面板（默认显示面板）
--================
function XUiRpgTowerRoleListGrowPage:CreateTabs()
    local ui = self.RootUi:LoadChildPrefab("NatureTabs", XUiConfigs.GetComponentUrl("RpgTowerRoleListChildWindowNatureTabs"))
    self.Tabs = XUiRpgTowerGrowPageTabsPanel.New(ui, self, self.RootUi)
end
--================
--显示页面
--================
function XUiRpgTowerRoleListGrowPage:ShowPage()
    self.Tabs:ShowPanel()
    self.RootUi:SetModelDragFieldActive(true)
end
--================
--刷新页面
--================
function XUiRpgTowerRoleListGrowPage:RefreshPage(rChara)
    self.Tabs:RefreshData(rChara)
    for _, window in pairs(self.ChildList) do
        window:RefreshData(rChara)
    end
end
--================
--隐藏页面
--================
function XUiRpgTowerRoleListGrowPage:HidePage()
    for _, window in pairs(self.ChildList) do
        window:HidePanel()
    end
    self.Tabs:HidePanel()
    self.CurrentChildIndex = nil
end
--================
--在面板被销毁时
--================
function XUiRpgTowerRoleListGrowPage:OnCollect()
    for _, window in pairs(self.ChildList) do
        if window.OnCollect then window:OnCollect() end
    end
end
--================
--打开子面板
--================
function XUiRpgTowerRoleListGrowPage:OpenChildWindow(panelIndex)
    if self.CurrentChildIndex == panelIndex then return end
    if self.CurrentChildIndex then
        self.ChildList[self.CurrentChildIndex]:HidePanel()
    end
    self.CurrentChildIndex = panelIndex
    if not self.ChildList[panelIndex] then self:CreateChild(panelIndex) end
    self.ChildList[panelIndex]:ShowPanel()
    self.ChildList[panelIndex]:RefreshData(self.RootUi.RCharacter)
end
--================
--创建子面板
--================
function XUiRpgTowerRoleListGrowPage:CreateChild(panelIndex)
    local ui = self.RootUi:LoadChildPrefab(panelIndex, ChildUiWindows[panelIndex].AssetPath)
    self.ChildList[panelIndex] = ChildUiWindows[panelIndex].ChildClass.New(ui, self)
end

return XUiRpgTowerRoleListGrowPage