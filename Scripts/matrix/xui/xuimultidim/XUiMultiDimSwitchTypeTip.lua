local XUiMultiDimSwitchTypeTip = XLuaUiManager.Register(XLuaUi, "UiMultiDimSwitchTypeTip")
local XUiGridMultiDimCareerTip = require("XUi/XUiMultiDim/XUiGridMultiDimCareerTip")
function XUiMultiDimSwitchTypeTip:OnStart(currCareer,pos,callBack)
    self.CurrCareer = currCareer
    self.CallBack = callBack
    self.Pos = pos
    self:InitGrid()
    self.BtnTanchuangCloseBig.CallBack = function() 
        self:Close()
    end
end
function XUiMultiDimSwitchTypeTip:InitGrid()
    self.CareerGrids = {}
    local careerConfigs = XMultiDimConfig.GetMultiDimCareerInfo()
    for i, cfg in pairs(careerConfigs) do
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridCareer, self.PanelCareerList)
        local grid = XUiGridMultiDimCareerTip.New(obj,cfg,function(career)
            self:OnSelectCareer(career)
        end)
        grid:SetGridState(self.CurrCareer)
        self.CareerGrids[i] = grid
    end
    self.GridCareer.gameObject:SetActiveEx(false)
end

function XUiMultiDimSwitchTypeTip:OnSelectCareer(career)
    XDataCenter.MultiDimManager.ChangeRecommendCareer(self.CurrCareer, career,function()
        self.CurrCareer = career
        for _,grid in pairs(self.CareerGrids) do
            grid:SetGridState(career)
        end
        if self.CallBack then
            self.CallBack(career)
        end
    end)
end

return XUiMultiDimSwitchTypeTip