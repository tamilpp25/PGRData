local XUiNewYearLuckTip = XLuaUiManager.Register(XLuaUi,"UiNewYearLuckTip")
local XUiGridNewYearLuckReward = require("XUi/XUiNewYearLuck/XUiGridNewYearLuckReward")
local XUiGridNewYearLuckRewardTitle = require("XUi/XUiNewYearLuck/XUiGridNewYearLuckRewardTitle")
function XUiNewYearLuckTip:OnStart()
    self.TitleGrid = {}
    self.LevelGrid = {}
    self.BtnTanchuangCloseBig.CallBack = function() 
        self:Close()
    end
    self:InitRewards()
end

function XUiNewYearLuckTip:OnEnable()
    
end

function XUiNewYearLuckTip:InitRewards()
    for i = 2,1,-1 do
        local specialGrid = CS.UnityEngine.GameObject.Instantiate(self.GridTitle, self.PanelSupportContainer)
        local titleGrid = XUiGridNewYearLuckRewardTitle.New(specialGrid, i)
        table.insert(self.TitleGrid,titleGrid)
        local list = XDataCenter.NewYearLuckManager.GetLevelListByType(i)
        for _, level in pairs(list) do
            local levelObj = CS.UnityEngine.GameObject.Instantiate(self.GridInfo, self.PanelSupportContainer)
            local levelGrid = XUiGridNewYearLuckReward.New(levelObj, level,self)
            table.insert(self.LevelGrid,levelGrid)
        end
    end
    self.GridInfo.gameObject:SetActiveEx(false)
    self.GridTitle.gameObject:SetActiveEx(false)
end

return XUiNewYearLuckTip