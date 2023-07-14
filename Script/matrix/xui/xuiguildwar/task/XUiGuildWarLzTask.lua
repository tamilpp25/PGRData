local XUiGuildWarLzTaskGrid = require("XUi/XUiGuildWar/Task/XUiGuildWarLzTaskGrid")

---@class XUiGuildWarLzTask:XLuaUi
local XUiGuildWarLzTask = XLuaUiManager.Register(XLuaUi, "UiGuildWarLzTask")

function XUiGuildWarLzTask:Ctor()
    ---@type XUiGuildWarLzTaskGridData[]
    self._Data = {}

    ---@type XTerm4BossGWNode
    self._Node = false
end

function XUiGuildWarLzTask:OnAwake()
    self:BindExitBtns()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XUiGuildWarLzTaskGrid)
    self.DynamicTable:SetDelegate(self)

    XUiHelper.NewPanelActivityAsset({ XGuildWarConfig.ActivityPointItemId }, self.PanelSpecialTool
    , { XDataCenter.GuildWarManager.GetMaxActionPoint() })
end

function XUiGuildWarLzTask:OnEnable()
    self:UpdateData()
    self:UpdateTaskList()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_BOSS_REWARD, self.Update, self)
end

function XUiGuildWarLzTask:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_BOSS_REWARD, self.Update, self)
end

---@param node XTerm4BossGWNode
function XUiGuildWarLzTask:OnStart(node)
    self._Node = node
end

function XUiGuildWarLzTask:Update()
    self:UpdateData()
    self:UpdateTaskList()
end

function XUiGuildWarLzTask:UpdateData()
    local node = self._Node
    local difficulty = node:GetDifficultyId()
    local configs = XGuildWarConfig.GetBossReward(difficulty)
    self._Data = {}
    for i = 1, #configs do
        local config = configs[i]
        local status
        local id = config.Id
        if XDataCenter.GuildWarManager.GetBattleManager():IsRewardReceived(id) then
            status = XGuildWarConfig.RewardStatus.Received
        elseif XGuildWarConfig.IsBossRewardCanReceive(node, config) then
            status = XGuildWarConfig.RewardStatus.Complete
        else
            status = XGuildWarConfig.RewardStatus.Incomplete
        end

        local name
        if config.LimitLevel < 10 and config.LimitLevel >= 0 then
            name = "0" .. config.LimitLevel
        else
            name = config.LimitLevel
        end

        ---@class XUiGuildWarLzTaskGridData
        local data = {
            RewardGoodList = XRewardManager.GetRewardList(config.RewardId) or {},
            Status = status,
            Name = name,
            Id = config.Id,
            ParentUid = node:GetUID(),
        }
        self._Data[#self._Data + 1] = data
    end
end

function XUiGuildWarLzTask:UpdateTaskList()
    if next(self._Data) == nil then
        self.PanelTaskList.gameObject:SetActiveEx(false)
        self.PanelNoneTask.gameObject:SetActiveEx(true)
    else
        self.PanelTaskList.gameObject:SetActiveEx(true)
        self.PanelNoneTask.gameObject:SetActiveEx(false)
        self.DynamicTable:SetDataSource(self._Data)
        local index = 1
        for i = 1, #self._Data do
            local reward = self._Data[i]
            if reward.Status == XGuildWarConfig.RewardStatus.Received then
                index = i
            end
        end
        self.DynamicTable:ReloadDataASync(index)
    end
end

--动态列表事件
function XUiGuildWarLzTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        grid:Update(data)
    end
end

return XUiGuildWarLzTask