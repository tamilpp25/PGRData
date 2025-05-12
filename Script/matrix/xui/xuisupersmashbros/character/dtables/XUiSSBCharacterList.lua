local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--================
--角色页面角色动态列表
--================
local XUiSSBCharacterList = XClass(nil, "XUiSSBCharacterList")

function XUiSSBCharacterList:Ctor(ui, teamIds, pickOrReady, onSelectCb)
    self.GameObject = ui.gameObject
    self.TeamIds = teamIds
    self.PickOrReady = pickOrReady
    self.OnSelectCb = onSelectCb
    self:InitDynamicTable()
end

function XUiSSBCharacterList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiSuperSmashBros/Character/Grids/XUiSSBCharacterGrid")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiSSBCharacterList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshData(self.DataList[index], index, self.InTeamIndex[index])
        if self.CurrentIndex == index then
            self:SelectGrid(grid, index)
        else
            grid:SetSelect(false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SelectGrid(grid, index)
    end
end
--================
--刷新动态列表
--================
function XUiSSBCharacterList:Refresh(dataList)
    self.DataList = dataList
    self:SortDataList()
    self.CurrentIndex = 1
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiSSBCharacterList:SortDataList()
    local result = {}
    local teamIdDic = {} -- 临时队伍列表
    local indexCount = 1
    self.InTeamIndex = {}
    for _, teamId in pairs(self.TeamIds) do
        if teamId > 0 then
            teamIdDic[teamId] = true
        end
    end
    -- 先处理队伍内彩蛋角色， 因为彩蛋角色一定在队伍里
    -- 如果是彩蛋机器人  cxldV2
    -- 1.彩蛋机器人未被roll出 没有绑定原始的被替换的角色，或者为强制随机角色未知状态 不显示，从列表里删除 (彩蛋机器人一定要通过服务器验证才会绑定， 强随机的未知状态出现的彩蛋可能会出现没有orgId的问题)
    -- 2.彩蛋机器人已被roll出 绑定了原始角色，但没有揭开，显示原始角色
    -- 3.彩蛋机器人已被roll出 绑定了原始角色，且已经揭开，显示真实彩蛋机器人角色
    -- ↓总结出：如果是 非（彩蛋机器人且没被roll过 且为未知），则正常加入队伍列表，且如果是 被roll过但没揭开彩蛋 则替换初始角色来显示
    local replaceOrgChars = {}
    for charaId, _ in pairs(teamIdDic) do
        local chara = XDataCenter.SuperSmashBrosManager.GetRoleById(charaId)
        if chara:GetEggRobotOrgId() ~= 0 and not chara:GetIsEggOpen() and not chara:GetIsUnknown() then
            replaceOrgChars[charaId] = true
            teamIdDic[chara:GetEggRobotOrgId()] = true
        end

        if chara:GetIsUnknown() then 
            teamIdDic[charaId] = nil
        end
    end
    for charaId, value in pairs(replaceOrgChars) do
        teamIdDic[charaId] = nil
    end

    -- 再将列表里没有揭开彩蛋角色排除 (没揭开彩蛋的机器人不在角色列表，没揭开未知的角色不在队伍列表但在角色列表)
    local dataList = {} -- 最后处理彩蛋角色
    for key, chara in pairs(self.DataList) do
        if not ((chara:IsSmashEggRobot() and not chara:GetIsEggOpen())) then
            table.insert(dataList, chara)
        end
    end

    -- 将在队伍里的角色排在前面
    for _, chara in pairs(dataList) do
        if teamIdDic[chara:GetId()] then
            table.insert(result, chara)
            self.InTeamIndex[indexCount] = true
            indexCount = indexCount + 1
        end
    end
    -- 再将不在队伍的角色插入
    for _, chara in pairs(dataList) do
        if not teamIdDic[chara:GetId()] then
            table.insert(result, chara)
        end
    end
    self.DataList = result
end

function XUiSSBCharacterList:OnRefresh()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end
--================
--选择角色
--================
function XUiSSBCharacterList:SelectGrid(grid, index)
    if self.CurrentIndex ~= index and self.CurrentGrid then
        self.CurrentGrid:SetSelect(false)
    end
    self.CurrentGrid = grid
    self.CurrentIndex = self.CurrentGrid:GetIndex()
    self.CurrentGrid:SetSelect(true)
    if self.OnSelectCb then
        self.OnSelectCb(self.CurrentGrid:GetChara())
    end
end

return XUiSSBCharacterList