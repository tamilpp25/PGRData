local XUiBiancaTheatrePanelReward = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatrePanelReward")
local XUiLvRewardGrid = require("XUi/XUiBiancaTheatre/Reward/XUiLvRewardGrid")

--肉鸽玩法二期奖励界面
local XUiBiancaTheatreLvReward = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreLvReward")

function XUiBiancaTheatreLvReward:OnAwake()
    self:InitButtonCallBack()

    self.LevelRewardIdList = XBiancaTheatreConfigs.GetLevelRewardIdList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelReward)
    self.DynamicTable:SetProxy(XUiLvRewardGrid)
    self.DynamicTable:SetDelegate(self)
    self.PanelGrid.gameObject:SetActiveEx(false)

    --奖励面板
    self.PanelReward = XUiBiancaTheatrePanelReward.New(self.PanelLv, true)
end

function XUiBiancaTheatreLvReward:OnStart(closeCb)
    self.CloseCb = closeCb
end

function XUiBiancaTheatreLvReward:OnEnable()
    self:Refresh(true)
    if XDataCenter.BiancaTheatreManager.GetIsReadNewRewardLevel() then
        self.DynamicTable:ReloadDataSync(#self.LevelRewardIdList)
    end
    XDataCenter.BiancaTheatreManager.SetIsReadNewRewardLevel()
    XEventManager.AddEventListener(XEventId.EVENT_BIANCA_THEATRE_TOTAL_EXP_CHANGE, self.Refresh, self)
end

function XUiBiancaTheatreLvReward:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BIANCA_THEATRE_TOTAL_EXP_CHANGE, self.Refresh, self)
end

function XUiBiancaTheatreLvReward:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiBiancaTheatreLvReward:InitButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, function() 
        XDataCenter.BiancaTheatreManager.ResetAudioFilter()
        self:Close()
    end)
    self:RegisterClickEvent(self.BtnMainUi, function() XDataCenter.BiancaTheatreManager.RunMain() end)
    self:RegisterClickEvent(self.BtnReward, self.OnBtnRewardClick)
end

function XUiBiancaTheatreLvReward:Refresh(isJump)
    local index
    local list = XDataCenter.BiancaTheatreManager.GetCanReceiveLevelRewardIds()
    if isJump then
        index = XTool.IsTableEmpty(list) and XDataCenter.BiancaTheatreManager.GetCurRewardLevel() or list[1]
    end
    self.BtnReward.gameObject:SetActiveEx(#list > 0)
    self.DynamicTable:SetDataSource(self.LevelRewardIdList)
    self.DynamicTable:ReloadDataSync(index)
    self.PanelReward:Refresh()
end

function XUiBiancaTheatreLvReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.LevelRewardIdList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClickGrid(self.LevelRewardIdList[index], handler(self, self.Refresh))
    end
end

--一键领取
function XUiBiancaTheatreLvReward:OnBtnRewardClick()
    local check = XDataCenter.BiancaTheatreManager.IsHaveReward()
    if not check then
        XUiManager.TipMsg(XBiancaTheatreConfigs.GetRewardTips(1))
        return
    end
    --local isAdventure = XDataCenter.BiancaTheatreManager.CheckHasAdventure()
    --if isAdventure then
    --    XUiManager.TipMsg(XBiancaTheatreConfigs.GetRewardTips(2))
    --    return
    --end
    XDataCenter.BiancaTheatreManager.RequestGetAllReward(function()
        self:Refresh()
    end)
end