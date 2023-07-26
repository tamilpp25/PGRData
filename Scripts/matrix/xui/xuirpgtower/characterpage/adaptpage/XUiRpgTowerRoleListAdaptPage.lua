-- 兵法蓝图成员列表改造页面
local XUiRpgTowerRoleListAdaptPage = XClass(nil, "XUiRpgTowerRoleListAdaptPage")
function XUiRpgTowerRoleListAdaptPage:Ctor(rootUi)
    self.RootUi = rootUi
    self:CreatePage()
end
--================
--创建子面板控件（默认显示控件）
--================
function XUiRpgTowerRoleListAdaptPage:CreatePage()
    local ui = self.RootUi:LoadChildPrefab("Adapt", XUiConfigs.GetComponentUrl("RpgTowerRoleListChildWindowAdapt"))
    local panelScript = require("XUi/XUiRpgTower/CharacterPage/AdaptPage/XUiRpgTowerRoleListAdaptPanel")
    self.AdaptPanel = panelScript.New(ui, self, self.RootUi)
end
--================
--打开页面
--================
function XUiRpgTowerRoleListAdaptPage:ShowPage(...)
    self.RootUi:UpdateCamera(XDataCenter.RpgTowerManager.UiCharacter_Camera.ADAPT)
    self.AdaptPanel:ShowPanel(...)
    self.RootUi:SetModelDragFieldActive(true)
end
--================
--刷新页面
--================
function XUiRpgTowerRoleListAdaptPage:RefreshPage(rChara)
    self.AdaptPanel:RefreshData(rChara)
end
--================
--隐藏页面
--================
function XUiRpgTowerRoleListAdaptPage:HidePage()
    self.AdaptPanel:HidePanel()
end
--================
--在面板被销毁时
--================
function XUiRpgTowerRoleListAdaptPage:OnCollect()
    if self.AdaptPanel.OnCollet then self.AdaptPanel:OnCollect() end
end
return XUiRpgTowerRoleListAdaptPage