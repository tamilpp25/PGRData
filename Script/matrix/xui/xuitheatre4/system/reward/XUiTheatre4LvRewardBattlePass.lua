local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTheatre4LvRewardBattlePassGrid = require("XUi/XUiTheatre4/System/Reward/XUiTheatre4LvRewardBattlePassGrid")

---@class XUiTheatre4LvRewardBattlePass : XUiNode
---@field PanelReward UnityEngine.RectTransform
---@field PanelGrid UnityEngine.RectTransform
---@field BtnGridLeft XUiComponent.XUiButton
---@field BtnGridRight XUiComponent.XUiButton
---@field BtnCurrentGo XUiComponent.XUiButton
---@field BtnRareGo XUiComponent.XUiButton
---@field _Control XTheatre4Control
local XUiTheatre4LvRewardBattlePass = XClass(XUiNode, "XUiTheatre4LvRewardBattlePass")

-- region 生命周期

function XUiTheatre4LvRewardBattlePass:OnStart()
    self._CurrentLevelEntity = self._Control.SystemControl:GetCurrentBattlePassEntity()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelReward)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiTheatre4LvRewardBattlePassGrid, self)
    self._UpdateTimer = nil
    self._IsReloadComplete = false
    self._CurrentDisplayEntity = nil

    self:_InitLimitPos()
    self:_RegisterButtonClicks()
    self.PanelGrid.gameObject:SetActiveEx(false)
end

function XUiTheatre4LvRewardBattlePass:OnEnable()
    self:_RefreshSuspendedGrid()
    self:_RefreshDynamicList()
    self:_RegisterSchedules()
    self:_RegisterListeners()
end

function XUiTheatre4LvRewardBattlePass:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

-- endregion

function XUiTheatre4LvRewardBattlePass:RefreshCurrent()
    self._CurrentLevelEntity = self._Control.SystemControl:GetCurrentBattlePassEntity()
    self._CurrentDisplayEntity = nil
end

-- region 按钮事件

function XUiTheatre4LvRewardBattlePass:OnRefresh(rewardType)
    if rewardType == XEnumConst.Theatre4.BattlePassGetRewardType.GetAll then
        self:_RefreshDynamicList()
    end
end

function XUiTheatre4LvRewardBattlePass:OnBtnGridLeftClick()
    self:_ShowItemDetail(self._CurrentLevelEntity)
end

function XUiTheatre4LvRewardBattlePass:OnBtnGridRightClick()
    self:_ShowItemDetail(self._CurrentDisplayEntity)
end

function XUiTheatre4LvRewardBattlePass:OnBtnCurrentGoClick()
    self:_ScrollToIndex(self._CurrentLevelEntity)
end

function XUiTheatre4LvRewardBattlePass:OnBtnRareGoClick()
    self:_ScrollToIndex(self._CurrentDisplayEntity)
end

---@param grid XUiTheatre4LvRewardBattlePassGrid
function XUiTheatre4LvRewardBattlePass:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetAlpha(0)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        if self._IsReloadComplete then
            grid:SetAlpha(1)
        end
        grid:Refresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnTouch()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_RefreshCurrentRightGrid()
        self._IsReloadComplete = true
        self:_PlayGridAnimation()
    end
end

-- endregion

-- region 私有方法

function XUiTheatre4LvRewardBattlePass:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnGridLeft, self.OnBtnGridLeftClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnGridRight, self.OnBtnGridRightClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnCurrentGo, self.OnBtnCurrentGoClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnRareGo, self.OnBtnRareGoClick, true)
end

function XUiTheatre4LvRewardBattlePass:_RegisterSchedules()
    -- 在此处注册定时器
    self:_RegisterUpdateTimer()
end

function XUiTheatre4LvRewardBattlePass:_RemoveSchedules()
    -- 在此处移除定时器
    self:_RemoveUpdateTimer()
end

function XUiTheatre4LvRewardBattlePass:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE4_BP_REFRESH, self.OnRefresh, self)
end

function XUiTheatre4LvRewardBattlePass:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE4_BP_REFRESH, self.OnRefresh, self)
end

function XUiTheatre4LvRewardBattlePass:_RefreshDynamicList()
    local battleEntitys = self._Control.SystemControl:GetBattlePassEntitys()
    local receiveIndex = self._Control.SystemControl:GetFirstReceiveBattlePassIndex(self._CurrentLevelEntity:GetIndex())

    self._IsReloadComplete = false
    self:_SetAllAlpha(0)
    self._DynamicTable:SetDataSource(battleEntitys)
    self._DynamicTable:ReloadDataSync(receiveIndex)
end

function XUiTheatre4LvRewardBattlePass:_RefreshSuspendedGrid()
    self:_RefreshGridInfo(self.BtnGridLeft, self._CurrentLevelEntity)
end

---@param entity XTheatre4BattlePassEntity
function XUiTheatre4LvRewardBattlePass:_RefreshGridInfo(btnGrid, entity)
    if not self._Control.SystemControl:CheckBattlePassEntityInitial(entity) then
        if btnGrid then
            btnGrid.gameObject:SetActiveEx(false)
        end

        return
    end

    local reward = entity:GetReward()
    local config = entity:GetConfig()
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(reward.TemplateId)
    local name = nil

    if goodsShowParams.RewardType == XArrangeConfigs.Types.Character then
        name = goodsShowParams.TradeName
    else
        name = goodsShowParams.Name
    end

    btnGrid:SetRawImage(goodsShowParams.BigIcon)
    btnGrid:SetNameByGroup(0, config:GetLevel())
    btnGrid:SetNameByGroup(1, name)
    btnGrid:SetNameByGroup(2, "")
    btnGrid:SetNameByGroup(3, "x" .. reward.Count)
end

function XUiTheatre4LvRewardBattlePass:_RefreshLeftGrid()
    if not self._Control.SystemControl:CheckBattlePassEntityInitial(self._CurrentLevelEntity) then
        return
    end

    local startIndex = self._DynamicTable:GetStartIndex()
    local endIndex = self._DynamicTable:GetEndIndex()
    ---@type XUiTheatre4LvRewardBattlePassGrid
    local startGrid = self._DynamicTable:GetGridByIndex(startIndex)
    ---@type XUiTheatre4LvRewardBattlePassGrid
    local endGrid = self._DynamicTable:GetGridByIndex(endIndex)
    local currentLevel = self._CurrentLevelEntity:GetConfig():GetLevel()

    if startGrid:GetLevel() <= currentLevel and endGrid:GetLevel() >= currentLevel and self._LeftPos and self._RightPos then
        local grids = self._DynamicTable:GetGrids()

        for _, grid in pairs(grids) do
            if grid:IsEquals(self._CurrentLevelEntity) then
                local gridTransform = grid.GameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
                local gridPos = XUiHelper.ConvertLocalToWorldPosWithPiovt(gridTransform, grid.Transform.parent)
                local leftX = self._LeftPos.x
                local rightX = self._RightPos.x

                if gridPos then
                    self.BtnGridLeft.gameObject:SetActiveEx(leftX >= gridPos.x or rightX <= gridPos.x)
                else
                    self.BtnGridLeft.gameObject:SetActiveEx(true)
                end

                break
            end
        end
    else
        self.BtnGridLeft.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre4LvRewardBattlePass:_RefreshRightGrid()
    local grids = self._DynamicTable:GetGrids()
    local targetX = self.BtnGridRight.transform.position.x

    for index, grid in pairs(grids) do
        if grid.Transform.position.x >= targetX then
            local nextEntity = self._Control.SystemControl:GetNextDisplayBattlePassEntity(index)

            if nextEntity then
                if not self._CurrentDisplayEntity then
                    self._CurrentDisplayEntity = nextEntity
                    self:_RefreshGridInfo(self.BtnGridRight, nextEntity)
                elseif not self._CurrentDisplayEntity:IsEquals(nextEntity) then
                    self._CurrentDisplayEntity = nextEntity
                    self:_RefreshGridInfo(self.BtnGridRight, nextEntity)
                end
                self.BtnGridRight.gameObject:SetActiveEx(true)
            else
                self._CurrentDisplayEntity = nil
                self.BtnGridRight.gameObject:SetActiveEx(false)
            end

            break
        end
    end
end

function XUiTheatre4LvRewardBattlePass:_RefreshCurrentRightGrid()
    local maxIndex = 0
    local grids = self._DynamicTable:GetGrids()

    for index, grid in pairs(grids) do
        if grid:IsSpecial() then
            if index > maxIndex then
                maxIndex = index
            end
        end
    end

    local nextEntity = self._Control.SystemControl:GetNextDisplayBattlePassEntity(maxIndex)

    if nextEntity then
        if not self._CurrentDisplayEntity then
            self._CurrentDisplayEntity = nextEntity
            self:_RefreshGridInfo(self.BtnGridRight, nextEntity)
        elseif not self._CurrentDisplayEntity:IsEquals(nextEntity) then
            self._CurrentDisplayEntity = nextEntity
            self:_RefreshGridInfo(self.BtnGridRight, nextEntity)
        end
        self.BtnGridRight.gameObject:SetActiveEx(true)
    else
        self._CurrentDisplayEntity = nil
        self.BtnGridRight.gameObject:SetActiveEx(false)
    end
end

---@param entity XTheatre4BattlePassEntity
function XUiTheatre4LvRewardBattlePass:_ScrollToIndex(entity)
    if self._Control.SystemControl:CheckBattlePassEntityInitial(entity) then
        local index = entity:GetIndex()

        self._DynamicTable:ScrollToIndex(index, 0.5, function()
            XLuaUiManager.SetMask(true)
        end, function()
            XLuaUiManager.SetMask(false)
        end)
    end

end

function XUiTheatre4LvRewardBattlePass:_Update()
    if self._IsReloadComplete then
        self:_RefreshLeftGrid()
        self:_RefreshRightGrid()
    end
end

function XUiTheatre4LvRewardBattlePass:_RegisterUpdateTimer()
    self:_RemoveUpdateTimer()

    self._UpdateTimer = XScheduleManager.ScheduleForever(Handler(self, self._Update), 1)
end

function XUiTheatre4LvRewardBattlePass:_RemoveUpdateTimer()
    if self._UpdateTimer then
        XScheduleManager.UnSchedule(self._UpdateTimer)
        self._UpdateTimer = nil
    end
end

---@param entity XTheatre4BattlePassEntity
function XUiTheatre4LvRewardBattlePass:_ShowItemDetail(entity)
    if self._Control.SystemControl:CheckBattlePassEntityInitial(entity) then
        local itemId = entity:GetItemId()

        if XTool.IsNumberValid(itemId) then
            XLuaUiManager.Open("UiTheatre4PopupItemDetail", itemId)
        end
    end
end

function XUiTheatre4LvRewardBattlePass:_InitLimitPos()
    local leftTransform = self.BtnGridLeft.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    local rightTransform = self.BtnGridRight.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self._LeftPos = XUiHelper.ConvertLocalToWorldPosWithPiovt(leftTransform, self.BtnGridLeft.transform.parent)
    self._RightPos = XUiHelper.ConvertLocalToWorldPosWithPiovt(rightTransform, self.BtnGridRight.transform.parent)
end

function XUiTheatre4LvRewardBattlePass:_PlayGridAnimation()
    if self._IsReloadComplete then
        RunAsyn(Handler(self, self._PlayAnimationAsync))
    end
end

function XUiTheatre4LvRewardBattlePass:_PlayAnimationAsync()
    asynWaitSecond(0.04)

    local startIndex, count = self._DynamicTable:GetFirstUseGridIndexAndUseCount()

    for i = startIndex, startIndex + count do
        local grid = self._DynamicTable:GetGridByIndex(i)

        if grid then
            grid:PlayEnableAnimation()
        end

        asynWaitSecond(0.04)
    end
end

function XUiTheatre4LvRewardBattlePass:_SetAllAlpha(alpha)
    local grids = self._DynamicTable:GetGrids()

    for _, grid in pairs(grids) do
        grid:SetAlpha(alpha)
    end
end

-- endregion

return XUiTheatre4LvRewardBattlePass
