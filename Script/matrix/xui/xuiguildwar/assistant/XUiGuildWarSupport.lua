local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local INTERVAL_REFRESH = 30
local EMPTY_STR = "--"

local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiGuildWarSupport:XLuaUi
local XUiGuildWarSupport = XLuaUiManager.Register(XLuaUi, "UiGuildWarSupport")

function XUiGuildWarSupport:Ctor()
    self._Timer = false
    self._TimerRefresh = false
    self.DynamicTableLog = false
end

function XUiGuildWarSupport:OnStart()
    self:Init()
    XDataCenter.GuildWarManager.RequestAssistantDetail()
end

function XUiGuildWarSupport:Init()
    local uiPanelAsset = XUiPanelAsset.New(self, self.PanelAsset, tonumber(XGuildWarConfig.GetServerConfigValue('RewardItemId')))
    uiPanelAsset:HideBtnBuy()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)

    -- model
    local panelModel = self.UiModelGo.transform:FindTransform("PanelRoleModel2")
    ---@type XUiPanelRoleModel
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelModel, self.Name, nil, true)

    -- button click
    self:RegisterClickEvent(self.BtnChar2, self.OpenUiSelectAssistant)
    self:RegisterClickEvent(self.BtnDeploy, self.GetRewardSupply)

    -- log
    self.DynamicTableLog = XDynamicTableNormal.New(self.PanelRecordList)
    self.DynamicTableLog:SetProxy(require("XUi/XUiGuildWar/Assistant/XUiGuildWarSupportGrid"))
    self.DynamicTableLog:SetDelegate(self)

    -- reward icon
    local itemId = tonumber(XGuildWarConfig.GetServerConfigValue('RewardItemId'))
    local rewardItem1 = XUiGridCommon.New(self.RootUi, self.GridCostItem01)
    local rewardItem2 = XUiGridCommon.New(self.RootUi, self.GridCostItem02)
    rewardItem1:Refresh(itemId)
    rewardItem2:Refresh(itemId)
end

function XUiGuildWarSupport:OnEnable()
    self:Update()
    self:StartTimer()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE, self.Update, self)
end

function XUiGuildWarSupport:OnDisable()
    self:StopTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE, self.Update, self)
end

function XUiGuildWarSupport:Update()
    self:UpdateLog()
    self:UpdateModel()
    self:UpdateSupply()
    self:UpdateRedDot()
end

function XUiGuildWarSupport:UpdateSupply()
    local isSendAssistant = XDataCenter.GuildWarManager.HasSendAssistant()
    local supplyAssistant = math.floor(XDataCenter.GuildWarManager.GetAssistantSupply())
    local isMax = XDataCenter.GuildWarManager.IsAssistantSupplyMax()
    if supplyAssistant > 0 or isSendAssistant then
        local text = supplyAssistant
        if isMax then
            if supplyAssistant > 0 then
                text = XUiHelper.GetText("GuildWarSupplyLimit", supplyAssistant)
            else
                text = XUiHelper.GetText("GuildWarSupplyLimit", EMPTY_STR)
            end
        end
        self.TxtSupportRewardNum.text = text
    else
        if isMax then
            self.TxtSupportRewardNum.text = XUiHelper.GetText("GuildWarSupplyLimit", EMPTY_STR)
        else
            self.TxtSupportRewardNum.text = EMPTY_STR
        end
    end

    if isSendAssistant then
        self.ImgAdd2.gameObject:SetActiveEx(false)
    else
        self.ImgAdd2.gameObject:SetActiveEx(true)
    end

    self:UpdateTimeSupply()
    self:UpdateBtnDeploy()
end

function XUiGuildWarSupport:UpdateLog()
    local dataSource = XDataCenter.GuildWarManager.GetAssistantLog()
    self.DynamicTableLog:SetDataSource(dataSource)
    self.DynamicTableLog:ReloadDataASync(1)
    self.TxtNoRecord.gameObject:SetActiveEx(#dataSource == 0)
end

---@param grid XUiGuildWarSupportGrid
function XUiGuildWarSupport:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTableLog.DataSource[index]
        grid:Update(data)
    end
end

function XUiGuildWarSupport:UpdateModel()
    local characterId = XDataCenter.GuildWarManager.GetAssistantCharacterId()
    if XTool.IsNumberValid(characterId) then
        self.PanelFirstRole2.gameObject:SetActiveEx(true)
        self.UiPanelRoleModel:ShowRoleModel()
        if self.UiPanelRoleModel:GetModelName(characterId) ~= self.UiPanelRoleModel:GetCurRoleName() then
            self.UiPanelRoleModel:UpdateCharacterModel(characterId, nil, "UiGuildWarSupport")
        end
    else
        self.UiPanelRoleModel:HideRoleModel()
        self.PanelFirstRole2.gameObject:SetActiveEx(false)
    end
end

function XUiGuildWarSupport:OpenUiSelectAssistant()
    XDataCenter.GuildWarManager.OpenUiSendAssistant()
end

function XUiGuildWarSupport:GetRewardSupply()
    if not self:IsSupplyValid() then
        return
    end
    XDataCenter.GuildWarManager.ReceiveSupportSupply()
end

function XUiGuildWarSupport:UpdateTimeSupply()
    local supplyTime, isMax = XDataCenter.GuildWarManager.GetTimeSupply()
    local isSendAssistant = XDataCenter.GuildWarManager.HasSendAssistant()
    if isSendAssistant or supplyTime > 0 then
        local text = math.floor(supplyTime)
        if isMax then
            if supplyTime > 0 then
                text = XUiHelper.GetText("GuildWarSupplyLimit", text)
            else
                text = XUiHelper.GetText("GuildWarSupplyLimit", EMPTY_STR)
            end
        end
        self.TxtTimeRewardNum.text = text
    else
        if isMax then
            self.TxtTimeRewardNum.text = XUiHelper.GetText("GuildWarSupplyLimit", EMPTY_STR)
        else
            self.TxtTimeRewardNum.text = EMPTY_STR
        end
    end
    self:UpdateBtnDeploy(supplyTime)
end

function XUiGuildWarSupport:StartTimer()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTimeSupply()
        end, 1)
    end
    if not self._TimerRefresh then
        self._TimerRefresh = XScheduleManager.ScheduleForever(function()
            XDataCenter.GuildWarManager.RequestAssistantDetail()
        end, INTERVAL_REFRESH * XScheduleManager.SECOND)
    end
end

function XUiGuildWarSupport:StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    if self._TimerRefresh then
        XScheduleManager.UnSchedule(self._TimerRefresh)
        self._TimerRefresh = false
    end
end

function XUiGuildWarSupport:UpdateBtnDeploy(supplyTime, assistantSupply)
    self.BtnDeploy:SetDisable(not self:IsSupplyValid(supplyTime, assistantSupply))
end

function XUiGuildWarSupport:IsSupplyValid(supplyTime, assistantSupply)
    supplyTime = supplyTime or XDataCenter.GuildWarManager.GetTimeSupply()
    assistantSupply = assistantSupply or XDataCenter.GuildWarManager.GetAssistantSupply()
    return supplyTime > 0 or assistantSupply > 0
end

function XUiGuildWarSupport:UpdateRedDot()
    XRedPointManager.CheckOnceByButton(self.BtnDeploy, {
        XRedPointConditions.Types.CONDITION_GUILDWAR_SUPPLY
    })
    XRedPointManager.CheckOnce(self.OnCheckRedDotSupport, self, { XRedPointConditions.Types.CONDITION_GUILDWAR_ASSISTANT })
end

function XUiGuildWarSupport:OnCheckRedDotSupport(count)
    self.Red.gameObject:SetActiveEx(count >= 0)
end

return XUiGuildWarSupport
