-- 兵法蓝图天赋总览页面角色属性面板
local XUiRpgTowerCollectPanelStatus = XClass(nil, "XUiRpgTowerCollectPanelStatus")

function XUiRpgTowerCollectPanelStatus:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiRpgTowerCollectPanelStatus:Refresh(rChara)
    local attr = rChara:GetCharaTalentPlusAttr()
    if not attr then
        self.TxtAttackNumber.text = 0
        self.TxtLifeNumber.text = 0
        return 
    end
    self.TxtAttackNumber.text = FixToInt(attr[XNpcAttribType.AttackNormal])
    self.TxtLifeNumber.text = FixToInt(attr[XNpcAttribType.Life])
end

return XUiRpgTowerCollectPanelStatus