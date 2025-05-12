local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--================
--怪物头像动态列表
--================
local XUiSSBPickMonsterHeadList = XClass(nil, "XUiSSBPickMonsterHeadList")

function XUiSSBPickMonsterHeadList:Ctor(ui, panel, isChangeMonsterOnFighting, mode)
    self.Panel = panel
    self.IsChangeMonsterOnFighting = isChangeMonsterOnFighting
    ---@type XSmashBMode
    self.Mode = mode
    XTool.InitUiObjectByUi(self, ui)
    self.GridMonsterHead.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end
--================
--初始化动态列表
--================
function XUiSSBPickMonsterHeadList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiSuperSmashBros/Pick/Grids/XUiSSBPickGridMonsterHead")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiSSBPickMonsterHeadList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self, self.Mode)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:Refresh(self.DataList[index], self.TeamData)
        end
    end
end
--================
--刷新动态列表
--@param
--teamData[pos] : {RoleId = roleId}
--================
function XUiSSBPickMonsterHeadList:Refresh(teamData, changePos, dataList)
    self.TeamData = teamData
    self.ChangePos = changePos
    self:CreateDataList(dataList)
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end
--================
--建立数据列表
--================
function XUiSSBPickMonsterHeadList:CreateDataList(dataList)
    if self.Mode:GetId() == XSuperSmashBrosConfig.ModeType.DeathRandom then
        self.DataList = {}
    else
        self.DataList = { [1] = {RandomGrid = true}}
    end
    for _, monster in pairs(dataList) do
        table.insert(self.DataList, monster)
    end
end
--================
--选中项
--================
function XUiSSBPickMonsterHeadList:OnGridSelect(grid)
    local monsterGroup = grid.MonsterGroup
    if  monsterGroup and not monsterGroup:IsWinAmountEnoughToChallenge(self.Mode) then
        return
    end
    if self.IsChangeMonsterOnFighting then
        local monsterGroupId = grid:GetMonsterId()
        ---@type XSmashBMode
        local mode = self.Mode or XDataCenter.SuperSmashBrosManager.GetPlayingMode()
        local stageId = mode:GetStageId(monsterGroupId)
        local currentStageId = mode:GetNextStageId()
        if currentStageId == stageId then
            XLuaUiManager.Close("UiSuperSmashBrosPick")
            return
        end
        XDataCenter.SuperSmashBrosManager.ChangeStage(stageId, function()
            XLuaUiManager.Close("UiSuperSmashBrosPick")
        end)
        return
    end
    local roleId = grid:GetMonsterId() -- 若是-1则表示随机
    if roleId == XSuperSmashBrosConfig.PosState.Random then
        --若选的是随机，则直接赋值
        self.TeamData[self.ChangePos] = roleId
    elseif self.TeamData[self.ChangePos] == XSuperSmashBrosConfig.PosState.Empty or self.TeamData[self.ChangePos] == XSuperSmashBrosConfig.PosState.Random then
        --若替换位是空位或随机,则直接把选中的Id赋值
        for pos, teamRoleId in pairs(self.TeamData) do
            if teamRoleId > 0 and teamRoleId == roleId then --若跟其他位置相同且不为随机，则交换位置
                self.TeamData[pos] = self.TeamData[self.ChangePos]
                break
            end
        end
        self.TeamData[self.ChangePos] = roleId
    elseif self.TeamData[self.ChangePos] == roleId then --怪物重复选中为取消选中，则变为默认的随机
        self.TeamData[self.ChangePos] = XSuperSmashBrosConfig.PosState.Random
    else
        local switch = false
        for pos, teamRoleId in pairs(self.TeamData) do
            if teamRoleId == roleId then --若跟其他位置相同,则交换位置
                local temp = teamRoleId
                self.TeamData[pos] = self.TeamData[self.ChangePos]
                self.TeamData[self.ChangePos] = teamRoleId
                switch = true
                break
            end
        end
        if not switch then
            self.TeamData[self.ChangePos] = roleId
        end
    end
    self.Panel.RootUi:SwitchPage(XSuperSmashBrosConfig.PickPage.Pick)
end

function XUiSSBPickMonsterHeadList:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiSSBPickMonsterHeadList:Hide()
    self.GameObject:SetActiveEx(false)
end
return XUiSSBPickMonsterHeadList