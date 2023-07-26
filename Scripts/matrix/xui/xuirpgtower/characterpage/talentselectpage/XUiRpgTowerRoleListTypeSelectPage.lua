-- 兵法蓝图成员列表天赋选择页面
local XUiRpgTowerRoleListTypeSelectPage = XClass(nil, "XUiRpgTowerRoleListTypeSelectPage")

function XUiRpgTowerRoleListTypeSelectPage:Ctor(rootUi)
    self.RootUi = rootUi
    self:CreatePage()
end
--================
--创建子面板控件（默认显示控件）
--================
function XUiRpgTowerRoleListTypeSelectPage:CreatePage()
    local ui = self.RootUi:LoadChildPrefab("TypeSelect", XUiConfigs.GetComponentUrl("RpgTowerRoleListChildWindowTypeSelect"))
    local panelScript = require("XUi/XUiRpgTower/CharacterPage/TalentSelectPage/XUiRpgTowerRoleListTypeSelectPanel")
    self.TypeSelectPanel = panelScript.New(ui, self, self.RootUi)
end
--================
--打开页面
--================
function XUiRpgTowerRoleListTypeSelectPage:ShowPage()
    self.RootUi:UpdateCamera(XDataCenter.RpgTowerManager.UiCharacter_Camera.NATURE)
    self.TypeSelectPanel:ShowPanel()
    self.RootUi:SetModelDragFieldActive(false)
end
--================
--刷新页面
--================
function XUiRpgTowerRoleListTypeSelectPage:RefreshPage(rChara)
    self.TypeSelectPanel:RefreshData(rChara)
end
--================
--隐藏页面
--================
function XUiRpgTowerRoleListTypeSelectPage:HidePage()
    self.TypeSelectPanel:HidePanel()
end
--================
--在面板被销毁时
--================
function XUiRpgTowerRoleListTypeSelectPage:OnCollect()
    if self.TypeSelectPanel.OnCollet then self.TypeSelectPanel:OnCollect() end
end
return XUiRpgTowerRoleListTypeSelectPage