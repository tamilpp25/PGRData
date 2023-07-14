local XUiGridRewardLine = XClass(nil, "XUiGridRewardLine")

function XUiGridRewardLine:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GridReward.gameObject:SetActiveEx(false)
    self.RewardGrids = {}
end

function XUiGridRewardLine:InitRootUi(rootUi)
    self.RootUi = rootUi
end

--[[    [MessagePackObject(keyAsPropertyName: true)]
public class StrongholdFightResultInfo
{
    public int GroupId;
    public List<XRewardGoods> RewardGoodsList;
}
]]
function XUiGridRewardLine:Refresh(info)
    local groupId = info.GroupId
    self.TxtOrder.text = XStrongholdConfigs.GetGroupOrder(groupId)

    local rewardGoodsList = info.RewardGoodsList or {}

    --增加电能
    local addElectric = XStrongholdConfigs.GetGroupAddElectricEnergy(groupId)
    if addElectric > 0 then
        table.insert(rewardGoodsList, XRewardManager.CreateRewardGoods(XDataCenter.StrongholdManager.GetBatteryItemId(), addElectric))
    end

    local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    for idx, item in ipairs(rewards) do
        local grid = self.RewardGrids[idx]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            grid = XUiGridCommon.New(self.RootUi, ui)
            grid.Transform:SetParent(self.PanelRewardContent, false)
            grid.GameObject:SetActiveEx(true)
            self.RewardGrids[idx] = grid
        end
        grid:Refresh(item, nil, nil, true)
    end

    for i = #rewards + 1, #self.RewardGrids do
        self.RewardGrids[i].GameObject:SetActiveEx(false)
    end
end

return XUiGridRewardLine