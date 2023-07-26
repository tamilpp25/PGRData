-- 兵法蓝图关卡词缀图标控件
local XUiRpgTowerStageBuffIcon = XClass(nil, "XUiRpgTowerStageBuffIcon")

function XUiRpgTowerStageBuffIcon:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end
--================
--刷新Buff
--================
function XUiRpgTowerStageBuffIcon:RefreshBuff(buffCfg)
    self.RImgIcon:SetRawImage(buffCfg.Icon)
end
--================
--显示控件
--================
function XUiRpgTowerStageBuffIcon:Show()
    self.GameObject:SetActiveEx(true)
end
--================
--隐藏控件
--================
function XUiRpgTowerStageBuffIcon:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiRpgTowerStageBuffIcon