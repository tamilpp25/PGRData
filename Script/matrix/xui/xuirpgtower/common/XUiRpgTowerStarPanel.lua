-- 兵法蓝图星级列表显示控件
local XUiRpgTowerStarPanel = XClass(nil, "XUiRpgTowerStarPanel")
--[[
================
构造函数
================
]]
function XUiRpgTowerStarPanel:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end
--[[
================
显示星数
@param starNum:星数
================
]]
function XUiRpgTowerStarPanel:ShowStar(starNum)
    for i = 1, 6 do
        self[string.format("ImgCurLevel%d", i)].gameObject:SetActiveEx(i <= starNum)
    end
end
return XUiRpgTowerStarPanel