-- 兵法蓝图天赋总览天赋列表面板
local XUiRpgTowerCollectPanelTalent = XClass(nil, "XUiRpgTowerCollectPanelTalent")
local TalentItem = require("XUi/XUiRpgTower/CharacterPage/TalentTotalView/XUiRpgTowerCollectTalentGrid")
function XUiRpgTowerCollectPanelTalent:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.TalentGridSample.gameObject:SetActiveEx(false)
end

function XUiRpgTowerCollectPanelTalent:Refresh(rChara)
    local talents = rChara:GetTalents()
    local isEmpty = true
    for layerId, rTalentLayer in pairs(talents) do
        for index, rTalent in pairs(rTalentLayer) do
            if rTalent:GetIsUnLock() then
                isEmpty = false
                local ui = CS.UnityEngine.GameObject.Instantiate(self.TalentGridSample)
                ui.transform:SetParent(self.PanelParent, false)
                local item = TalentItem.New(ui)
                item:Refresh(rTalent)
                item.GameObject:SetActiveEx(true)
            end
        end
    end
    if self.ImgEmpty then self.ImgEmpty.gameObject:SetActiveEx(isEmpty) end
end

return XUiRpgTowerCollectPanelTalent