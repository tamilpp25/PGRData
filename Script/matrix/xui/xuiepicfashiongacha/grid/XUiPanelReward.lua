local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelReward = XClass(nil, "XUiPanelReward")

function XUiPanelReward:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiPanelReward:RefreshUiShow(gachaConfig)
    if self.GachaConfig then
        return
    end

    self.GachaConfig = gachaConfig
    local rewardRareLevelList = XDataCenter.GachaManager.GetGachaRewardSplitByRareLevel(gachaConfig.Id)
    -- 生成奖励格子
    for i, group in pairs(rewardRareLevelList) do
        local parent = self["PanelItem"..i]
        for _, v in pairs(group) do
            local go = CS.UnityEngine.Object.Instantiate(self.GridItem, parent)
            go.gameObject:SetActiveEx(true)
            local item = XUiGridCommon.New(self.RootUi, go)

            local tmpData = {}
            tmpData.TemplateId = v.TemplateId
            tmpData.Count = v.Count

            local curCount
            if v.RewardType == XGachaConfigs.RewardType.Count then
                curCount = v.CurCount
            end
            item:Refresh(tmpData, nil, nil, nil, curCount)
        end
    end
end

function XUiPanelReward:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelReward:Hide()
    self.GameObject:SetActiveEx(false)
end
return XUiPanelReward