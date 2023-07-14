local XUiGridRiftMultiMonster = XClass(nil, "XUiGridRiftMultiMonster")
local XUiGridRiftMonsterDetail = require("XUi/XUiRift/Grid/XUiGridRiftMonsterDetail")

function XUiGridRiftMultiMonster:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridMonsterDic = {}

    XTool.InitUiObject(self)
end

function XUiGridRiftMultiMonster:Refresh(xStage, xStageGroup, index)
    self.XStage = xStage
    self.XStageGroup = xStageGroup
    self.TxtNumber.text = index
    -- 刷新前先隐藏
    for k, grid in pairs(self.GridMonsterDic) do
        grid.GameObject:SetActiveEx(false)
    end
    for k, xMonster in ipairs(self.XStage:GetAllEntityMonsters()) do
        if k > 3 then
            break
        end

        local grid = self.GridMonsterDic[k]
        if not grid then
            local trans = CS.UnityEngine.Object.Instantiate(self.GridMonster, self.GridMonster.parent)
            grid = XUiGridRiftMonsterDetail.New(trans)
            self.GridMonsterDic[k] = grid
        end
        grid:Refresh(xMonster, self.XStageGroup)
        grid.GameObject:SetActiveEx(true)
    end
    self.GridMonster.gameObject:SetActiveEx(false)
end

return XUiGridRiftMultiMonster
