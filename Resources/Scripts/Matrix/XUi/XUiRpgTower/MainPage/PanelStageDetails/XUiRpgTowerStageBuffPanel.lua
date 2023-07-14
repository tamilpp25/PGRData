-- 兵法蓝图主页面关卡详细面板：Buff展示面板
local XUiRpgTowerStageBuffPanel = XClass(nil, "XUiRpgTowerStageBuffPanel")
local XUiRpgTowerStageBuffIcon = require("XUi/XUiRpgTower/MainPage/PanelStageDetails/XUiRpgTowerStageBuffIcon")
function XUiRpgTowerStageBuffPanel:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.RImgBuffIcon.gameObject:SetActiveEx(false)
    self.BuffIcons = {}
end
--================
--刷新Buff数据
--================
function XUiRpgTowerStageBuffPanel:RefreshBuff(rStage)
    self.BuffList = rStage:GetStageEvents()
    self:ResetBuffIcons()
    self:ShowBuffIcons()
end
--================
--重置Buff图标
--================
function XUiRpgTowerStageBuffPanel:ResetBuffIcons()
    for _, icon in pairs(self.BuffIcons) do
        icon:Hide()
    end
end
--================
--显示Buff图标
--================
function XUiRpgTowerStageBuffPanel:ShowBuffIcons()
    for i = 1, #self.BuffList do
        local icon
        if not self.BuffIcons[i] then
            local ui = CS.UnityEngine.GameObject.Instantiate(self.RImgBuffIcon)
            ui.transform:SetParent(self.Transform, false)
            self.BuffIcons[i] = XUiRpgTowerStageBuffIcon.New(ui, self)
            self.RootUi:RegisterClickEvent(ui, function() self:OnClickIcon() end)
        end
        icon = self.BuffIcons[i]
        self.BuffIcons[i]:RefreshBuff(self.BuffList[i])
        icon:Show()
    end
end
--================
--点击图标
--================
function XUiRpgTowerStageBuffPanel:OnClickIcon()
    XLuaUiManager.Open("UiCommonStageEvent", self.BuffList)
end
return XUiRpgTowerStageBuffPanel