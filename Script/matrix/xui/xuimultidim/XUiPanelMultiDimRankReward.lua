local XUiPanelMultiDimRankReward = XClass(nil, "XUiPanelMultiDimRankReward")
local XUiGridMultiDimRankReward = require("XUi/XUiMultiDim/XUiGridMultiDimRankReward")

function XUiPanelMultiDimRankReward:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.GridBossRankReward.gameObject:SetActive(false)
    self.GridRankRewardList = {}
end

function XUiPanelMultiDimRankReward:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBlock, self.OnBtnBlockClick)
end

function XUiPanelMultiDimRankReward:Refresh(themeId, rankNum, memberCount)
    -- 结算时间
    local endTime = XDataCenter.MultiDimManager.GetEndTime()
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, "MM/dd HH:mm")
    self.TxtCurTime.text = endTimeStr
    
    local info = XMultiDimConfig.GetRankRewardInfo(themeId)

    for index, config in pairs(info) do
        local grid = self.GridRankRewardList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridBossRankReward, self.PanelRankContent)
            grid = XUiGridMultiDimRankReward.New(go, self.RootUi)
            self.GridRankRewardList[index] = grid
        end
        
        grid:Refresh(config, rankNum, memberCount)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #info + 1, #self.GridRankRewardList do
        self.GridRankRewardList[i].GameObject:SetActiveEx(false)
    end
    
    self.GameObject:SetActiveEx(true)
end

function XUiPanelMultiDimRankReward:OnBtnBlockClick()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelMultiDimRankReward