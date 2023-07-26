--组合小游戏星级面板UI控件
local XUiComposeGameStarPanelLevel = XClass(nil, "XUiComposeGameStarPanelLevel")
--================
--构造函数
--@param ui:星级面板GameObject
--================
function XUiComposeGameStarPanelLevel:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.Stars = {}
    table.insert(self.Stars, self.StarLevel)
end
--================
--显示指定的星数
--@param starNum:星数
--================
function XUiComposeGameStarPanelLevel:ShowStar(starNum)
    self:HideStars()
    for i = 1, starNum do
        if not self.Stars[i] then
            local ui = CS.UnityEngine.GameObject.Instantiate(self.StarLevel)
            ui.transform:SetParent(self.Transform, false)
            self.Stars[i] = ui
        end
        self.Stars[i].gameObject:SetActiveEx(true)
    end
end
--================
--隐藏所有星
--================
function XUiComposeGameStarPanelLevel:HideStars()
    for _, star in pairs(self.Stars) do
        star.gameObject:SetActiveEx(false)
    end
end

return XUiComposeGameStarPanelLevel