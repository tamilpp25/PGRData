local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiGridRewardLine = require("XUi/XUiStronghold/XUiGridRewardLine")

local handler = handler
local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdFightSettleWin = XLuaUiManager.Register(XLuaUi, "UiStrongholdFightSettleWin")

function XUiStrongholdFightSettleWin:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.GridRewardLine.gameObject:SetActiveEx(false)
end

function XUiStrongholdFightSettleWin:OnStart(data)
    self.WinData = data
    self:InitInfo(data)
end

function XUiStrongholdFightSettleWin:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

function XUiStrongholdFightSettleWin:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRewards)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridRewardLine)
end

function XUiStrongholdFightSettleWin:AutoAddListener()
    self.BtnConfirm.CallBack = handler(self, self.OnClickBtnConfirm)
end

function XUiStrongholdFightSettleWin:OnClickBtnConfirm()
    self:Close()
end

function XUiStrongholdFightSettleWin:InitInfo(data)
    self:UpdatePlayerInfo(data)
    self:UpdateDynamicTable(data.SettleData.StrongholdFightResult)
    self:CheckIsOpenStrongholdMinerUp(data.SettleData.StrongholdFightResult.GroupFightResultInfos)
end

-- 玩家经验
function XUiStrongholdFightSettleWin:UpdatePlayerInfo(data)
    if not data or not next(data) then return end

    local lastLevel = data.RoleLevel
    local lastExp = data.RoleExp
    local lastMaxExp = XPlayerManager.GetMaxExp(lastLevel, XPlayer.IsHonorLevelOpen())
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local curMaxExp = XPlayerManager.GetMaxExp(curLevel, XPlayer.IsHonorLevelOpen())
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or nil

    local addExp = 0--你知道有多恶心？
    local rewardLineList = data.SettleData.StrongholdFightResult.GroupFightResultInfos
    for _, info in pairs(rewardLineList or {}) do
        local rewardGoodsList = info.RewardGoodsList or {}
        local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
        for idx, item in ipairs(rewards) do
            if item.Id == XDataCenter.ItemManager.ItemId.TeamExp then
                addExp = addExp + XDataCenter.ItemManager.GetTeamExp() * item.Count
            end
        end
    end

    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, addExp, txtLevelName)
end

--[[        
// 战斗结算数据
[MessagePackObject(keyAsPropertyName: true)]
public class StrongholdFightResult
{
    public List<StrongholdFightResultInfo> GroupFightResultInfos = new List<StrongholdFightResultInfo>();
}
]]
function XUiStrongholdFightSettleWin:UpdateDynamicTable(result)
    local rewardLineList = result.GroupFightResultInfos

    local isMulti = #rewardLineList > 1
    self.TxtStageName.gameObject:SetActiveEx(isMulti)

    self.RewardLineList = rewardLineList
    self.DynamicTable:SetDataSource(self.RewardLineList)
    self.DynamicTable:ReloadDataSync(-1)
end

function XUiStrongholdFightSettleWin:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardGoodsList = self.RewardLineList[index]
        grid:Refresh(rewardGoodsList)
    end
end

function XUiStrongholdFightSettleWin:CheckIsOpenStrongholdMinerUp(groupFightResultInfos)
    local minerItemId = XDataCenter.StrongholdManager.GetMinerItemId()
    local oldMinerCount = XDataCenter.StrongholdManager.GetCookieMinerCount()
    local maxCount = XDataCenter.ItemManager.GetMaxCount(minerItemId)

    local addMinerCount = 0
    for _, groupFightResultInfo in ipairs(groupFightResultInfos) do
        if groupFightResultInfo and groupFightResultInfo.RewardGoodsList then
            for _, v in ipairs(groupFightResultInfo.RewardGoodsList) do
                if v.TemplateId == minerItemId then
                    addMinerCount = addMinerCount + v.Count
                end
            end
        end
    end

    if oldMinerCount ~= maxCount and addMinerCount > 0 then
        local lastGroupFightResultInfos = groupFightResultInfos and groupFightResultInfos[#groupFightResultInfos]
        local groupId = lastGroupFightResultInfos and lastGroupFightResultInfos.GroupId
        XLuaUiManager.Open("UiStrongholdMinerUp", groupId)
    end
end