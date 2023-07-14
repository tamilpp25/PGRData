-- 兵法蓝图成员列表主页面控件
local XUiRpgTowerRoleListMainPage = XClass(nil, "XUiRpgTowerRoleListMainPage")
local XUiRpgTowerTeamList = require("XUi/XUiRpgTower/CharacterPage/PanelCharacterList/XUiRpgTowerTeamList")
local XUiRpgTowerRoleListCharaInfo = require("XUi/XUiRpgTower/CharacterPage/MainPage/XUiRpgTowerRoleListCharaInfo")
local XUiRpgTowerTeamBar = require("XUi/XUiRpgTower/Common/XUiRpgTowerTeamBar")
--================
--子控件索引
--================
local ChildIndex = {
    CharaInfo = "CharaInfo",
}
--================
--子控件配置
--================
local ChildUiWindows

function XUiRpgTowerRoleListMainPage:Ctor(rootUi)
    self.RootUi = rootUi
    self:InitChildUiWindows()
    self:InitCharacterList()
    self.ChildList = {}
end
--================
--初始化子控件配置
--================
function XUiRpgTowerRoleListMainPage:InitChildUiWindows()
    ChildUiWindows =
    {
        [ChildIndex.CharaInfo] = {
            ChildClass = XUiRpgTowerRoleListCharaInfo,
            AssetPath = XUiConfigs.GetComponentUrl("RpgTowerRoleListChildWindow" .. ChildIndex.CharaInfo),
        }
    }
end
--================
--初始化角色列表（页面默认显示控件）
--================
function XUiRpgTowerRoleListMainPage:InitCharacterList()
    self.TeamBar = XUiRpgTowerTeamBar.New(self.RootUi.PanelTeamLevel, self.RootUi)
    self.CharacterList = XUiRpgTowerTeamList.New(self.RootUi.PanelCharacterList, self.RootUi)
end
--================
--显示子页面
--================
function XUiRpgTowerRoleListMainPage:ShowPage(index)
    if not self.ChildList[ChildIndex.CharaInfo] then self:CreateChild(ChildIndex.CharaInfo) end
    self.ChildList[ChildIndex.CharaInfo]:ShowPanel()
    self.CharacterList:ShowPanel(index)
    self.RootUi.PanelBtn.gameObject:SetActiveEx(true)
    self.TeamBar:RefreshBar()
    self.TeamBar.GameObject:SetActiveEx(true)
    self.RootUi:UpdateCamera(XDataCenter.RpgTowerManager.UiCharacter_Camera.MAIN)
    self.RootUi:SetModelDragFieldActive(true)
end
--================
--刷新子页面
--================
function XUiRpgTowerRoleListMainPage:RefreshPage(rChara)
    for _, window in pairs(self.ChildList) do
        window:RefreshData(rChara)
    end
end
--================
--隐藏子页面
--================
function XUiRpgTowerRoleListMainPage:HidePage()
    for _, window in pairs(self.ChildList) do
        window:HidePanel()
    end
    self.CharacterList:HidePanel()
    self.RootUi.PanelBtn.gameObject:SetActiveEx(false)
    self.TeamBar.GameObject:SetActiveEx(false)
end
--================
--创建子控件
--================
function XUiRpgTowerRoleListMainPage:CreateChild(panelIndex)
    local ui = self.RootUi:LoadChildPrefab(panelIndex, ChildUiWindows[panelIndex].AssetPath)
    self.ChildList[panelIndex] = ChildUiWindows[panelIndex].ChildClass.New(ui, self)
end

return XUiRpgTowerRoleListMainPage