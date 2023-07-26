--兵法蓝图成员列表养成页面页签
local XUiRpgTowerGrowPageTabsPanel = XClass(nil, "XUiRpgTowerGrowPageTabsPanel")
--================
--页签项枚举
--================
local TAB_BTN_INDEX = {
    LevelUp = 1,
    Nature = 2,
}
--================
--页签项对应的子面板索引
--================
local PANEL_INDEX = {
    [TAB_BTN_INDEX.LevelUp] = "LevelUp",
    [TAB_BTN_INDEX.Nature] = "Nature"
}
--================
--子面板to场景相机字典
--================
local CAMERA_INDEX

function XUiRpgTowerGrowPageTabsPanel:Ctor(ui, page, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.Page = page
    self.RootUi = rootUi
    self:InitCameraIndex()
    self:InitTabs()
    self.BtnExchange.CallBack = function() self:OnClickChangeMember() end
    self.PanelButtons:SelectIndex(TAB_BTN_INDEX.LevelUp)
end

--================
--初始化子面板to场景相机字典
--================
function XUiRpgTowerGrowPageTabsPanel:InitCameraIndex()
    CAMERA_INDEX = {
        [TAB_BTN_INDEX.LevelUp] = XDataCenter.RpgTowerManager.UiCharacter_Camera.LEVELUP,
        [TAB_BTN_INDEX.Nature] = XDataCenter.RpgTowerManager.UiCharacter_Camera.NATURE
    }
end
--================
--初始化页签组控件
--================
function XUiRpgTowerGrowPageTabsPanel:InitTabs()
    local tabGroup = {
        self.BtnTabLevelUp,
        self.BtnTabNature,
    }
    self.PanelButtons:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
end
--================
--点击页签时方法
--================
function XUiRpgTowerGrowPageTabsPanel:OnClickTabCallBack(tabIndex)
    self.CurrentTab = tabIndex
    self:ShowPanel()
end
--================
--显示面板
--================
function XUiRpgTowerGrowPageTabsPanel:ShowPanel()
    self.GameObject:SetActiveEx(true)
    self.Page:OpenChildWindow(PANEL_INDEX[self.CurrentTab])
    self.RootUi:UpdateCamera(CAMERA_INDEX[self.CurrentTab])
end
--================
--刷新面板
--================
function XUiRpgTowerGrowPageTabsPanel:RefreshData(rChara)
    self:RefreshTabRed(rChara)
end
--================
--刷新页签红点
--================
function XUiRpgTowerGrowPageTabsPanel:RefreshTabRed(rChara)
    self.BtnTabLevelUp:ShowReddot(rChara:CheckCanLevelUp())
    self.BtnTabNature:ShowReddot(rChara:CheckCanActiveTalent())
end
--================
--隐藏面板
--================
function XUiRpgTowerGrowPageTabsPanel:HidePanel()
    self.GameObject:SetActiveEx(false)
end
--================
--点击更换队员按钮
--================
function XUiRpgTowerGrowPageTabsPanel:OnClickChangeMember()
    self.RootUi:OpenChildPage(XDataCenter.RpgTowerManager.PARENT_PAGE.CHANGEMEMBER)
end
return XUiRpgTowerGrowPageTabsPanel