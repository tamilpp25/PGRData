local XUiGuildDormTalkGrid = require("XUi/XUiGuildDorm/XUiGuildDormTalkGrid")
local XUiGuildDormNameGrid = require("XUi/XUiGuildDorm/XUiGuildDormNameGrid")
local XUiGuildDormSpecialUiGrid = require("XUi/XUiGuildDorm/XUiGuildDormSpecialUiGrid")
local XUiGrid3DObj = require("XUi/XUiDormComponent/XUiGrid3DObj")
local XUiGuildDormCommon = XLuaUiManager.Register(XLuaUi, "UiGuildDormCommon")

function XUiGuildDormCommon:OnAwake()
    self.ActiveTaklGrids = {}
    self.RecycledTalkGrids = {}
    self.ActiveNameGrids = {}
    self.RecycledNameGrids = {}
    self.SpecialNameGrids = {}
    self.Obj3DGridDic = {}
    self.Obj3DGridsList = {}
    self.GuildDormManager = XDataCenter.GuildDormManager
    self.TalkSpiltLenght = XGuildDormConfig.GetTalkSpiltLenght()
end

function XUiGuildDormCommon:OnStart()
    XDataCenter.GuildDormManager.SetUiGuildDormCommon(true)
    local currentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    local running = currentRoom:GetRunning()
    running:SetUiGuildDormCommon(self)
    -- 角色
    for _, role in ipairs(currentRoom:GetRoles()) do
        self:OnEntityEnter(role)
    end
    -- npc
    for _, npc in ipairs(currentRoom:GetNpcs(true)) do
        self:OnEntityEnter(npc)
    end
    -- 家具
    self:RefreshFurnitureNames()
    -- 特殊Ui
    self:RefreshAllSpecialUiEntity()
    self.Transform:GetComponent("Canvas").sortingOrder = XDataCenter.GuildDormManager.GetCommonSortingOrder()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ENTITY_ENTER, self.OnEntityEnter, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ENTITY_EXIT, self.OnEntityExit, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ENTITY_TALK, self.OnEntityTalk, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ENTITY_SHOW_EFFECT, self.OnShow3DObj, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ENTITY_HIDE_EFFECT, self.OnHide3DObj, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_SWITCH_CHANNEL, self.OnSwitchChannel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_DESTROY_SPECIAL_UI, self.OnDestroySpecialUi, self)
    
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_3D_UI_SHOW)
end

function XUiGuildDormCommon:Update(dt)
    -- 处理聊天隐藏
    for i = #self.ActiveTaklGrids, 1, -1 do
        if self.ActiveTaklGrids[i]:GetIsArriveHideTime() then
            self:HideTalkGrid(self.ActiveTaklGrids[i], i)
        else
            if self.GuildDormManager.GetIsHideTalkUi() then
                -- 如果是白名单范围内，不隐藏
                if self.GuildDormManager.CheckIsWhiteEntityName(self.ActiveNameGrids[i]:GetEntityId()) then
                    self.ActiveTaklGrids[i]:UpdateTransform()
                else
                    self.ActiveTaklGrids[i]:Hide()
                end
            else
                self.ActiveTaklGrids[i]:UpdateTransform()
                self.ActiveTaklGrids[i]:Show()
            end
        end
    end
    -- 显示玩家的名字
    for i = #self.ActiveNameGrids, 1, -1 do
        if self.GuildDormManager.GetIsHideNameUi() then
            -- 如果是白名单范围内，不隐藏
            if self.GuildDormManager.CheckIsWhiteEntityName(self.ActiveNameGrids[i]:GetEntityId()) then
                self.ActiveNameGrids[i]:UpdateTransform()
            else
                self.ActiveNameGrids[i]:Hide()
            end
        else
            self.ActiveNameGrids[i]:Show()
            self.ActiveNameGrids[i]:UpdateTransform()
        end
    end
    -- 特殊Ui刷新
    for i = #self.SpecialNameGrids, 1, -1 do
        if self.GuildDormManager.GetIsHideNameUi() then
            -- 如果是白名单范围内，不隐藏
            if self.GuildDormManager.CheckIsWhiteEntityName(self.SpecialNameGrids[i]:GetEntityId()) then
                self.SpecialNameGrids[i]:UpdateTransform()
            else
                self.SpecialNameGrids[i]:Hide()
            end
        else
            self.SpecialNameGrids[i]:Show()
            self.SpecialNameGrids[i]:UpdateTransform()
        end
    end
end

function XUiGuildDormCommon:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ENTITY_ENTER, self.OnEntityEnter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ENTITY_EXIT, self.OnEntityExit, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ENTITY_TALK, self.OnEntityTalk, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ENTITY_SHOW_EFFECT, self.OnShow3DObj, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ENTITY_HIDE_EFFECT, self.OnHide3DObj, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_SWITCH_CHANNEL, self.OnSwitchChannel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_DESTROY_SPECIAL_UI, self.OnDestroySpecialUi, self)
    -- 家具
    if XDataCenter.GuildDormManager.GetCurrentRoom() then
        for _, furniture in pairs(XDataCenter.GuildDormManager.GetCurrentRoom():GetFurnitureDic()) do
            if furniture:CheckIsShowName() then
                self:OnEntityExit(furniture:GetEntityId())
            end
        end
    end

    XDataCenter.GuildDormManager.SetUiGuildDormCommon(false)
end

function XUiGuildDormCommon:HideTalkGrid(grid, activeIndex)
    grid:Hide()
    table.insert(self.RecycledTalkGrids, grid)
    table.remove(self.ActiveTaklGrids, activeIndex)
end

function XUiGuildDormCommon:OnEntityTalk(entity, content, isEmoji, hideTime)
    local grid = nil
    for i = #self.ActiveTaklGrids, 1, -1 do
        if self.ActiveTaklGrids[i]:GetEntityId() == entity:GetEntityId() then
            self:HideTalkGrid(self.ActiveTaklGrids[i], i)
        end
    end
    if #self.RecycledTalkGrids > 0 then
        grid = table.remove(self.RecycledTalkGrids, 1)
    else
        grid = XUiGuildDormTalkGrid.New(CS.UnityEngine.Object.Instantiate(self.GridDialogBox))
    end
    if not isEmoji then
        content = XTool.LoopSplitStr(content, "\n", self.TalkSpiltLenght)
    end
    grid:SetData(entity, content, isEmoji, hideTime)
    XScheduleManager.ScheduleOnce(function()
        grid:Show(self.DialogContainer)    
    end, 1)
    table.insert(self.ActiveTaklGrids, grid)
end

function XUiGuildDormCommon:HideNameGrid(grid, activeIndex)
    grid:Hide()
    table.insert(self.RecycledNameGrids, grid)
    table.remove(self.ActiveNameGrids, activeIndex)
end

function XUiGuildDormCommon:OnEntityEnter(entity)
    local entityId = entity:GetEntityId()
    for i = #self.ActiveNameGrids, 1, -1 do
        if self.ActiveNameGrids[i]:GetEntityId() == entityId then
            self:HideNameGrid(self.ActiveNameGrids[i], i)
        end
    end
    local grid
    if #self.RecycledNameGrids > 0 then
        grid = table.remove(self.RecycledNameGrids, 1)
    else
        grid = XUiGuildDormNameGrid.New(CS.UnityEngine.Object.Instantiate(self.GridName))
    end
    local offsetHeight = entity:GetNameHeightOffset()
    grid:SetData(entity:GetRLEntity(), offsetHeight)
    grid:SetName(entity:GetName())
    grid:SetTriangle(entity:GetTriangleType())
    grid:SetShowDistance(entity:GetUiShowDistance())
    local sortIndex = XGuildDormConfig.UiGridSortIndex["GridName"]
    if sortIndex and grid.Canvas then
        grid.Canvas.sortingOrder = sortIndex
    end
    XScheduleManager.ScheduleOnce(function()
        grid:Show(self.NameContainer)
    end, 1)
    grid:SetEntityId(entityId)
    table.insert(self.ActiveNameGrids, grid)
end

function XUiGuildDormCommon:OnEntityExit(entityId)
    for i = #self.ActiveNameGrids, 1, -1 do
        if self.ActiveNameGrids[i]:GetEntityId() == entityId then
            self.ActiveNameGrids[i]:Hide()
            table.insert(self.RecycledNameGrids, self.ActiveNameGrids[i])
            table.remove(self.ActiveNameGrids, i)
            break
        end
    end
    self:OnHide3DObj(entityId)
    for i = #self.ActiveTaklGrids, 1, -1 do
        if self.ActiveTaklGrids[i]:GetEntityId() == entityId then
            self:HideTalkGrid(self.ActiveTaklGrids[i], i)
            break
        end
    end
end

function XUiGuildDormCommon:OnShow3DObj(entityId, characterId, effectId, transform, bindWorldPos)
    -- 处理已经在显示中
    if self.Obj3DGridDic[entityId] then
        self.Obj3DGridDic[entityId]:RefreshEffect(effectId, bindWorldPos)
        return
    end
    -- 处理缓存中的
    if #self.Obj3DGridsList > 0 then
        local temp = table.remove(self.Obj3DGridsList, 1)
        temp:Show(characterId, effectId, transform, bindWorldPos)
        self.Obj3DGridDic[entityId] = temp
        return
    end
    -- 重新实例一个
    local grid = CS.UnityEngine.Object.Instantiate(self.Grid3DObj)
    local gridBox = XUiGrid3DObj.New(grid)
    gridBox:Show(characterId, effectId, transform, bindWorldPos)
    self.Obj3DGridDic[entityId] = gridBox
end

function XUiGuildDormCommon:OnHide3DObj(entityId)
    if not self.Obj3DGridDic[entityId] then
        return
    end
    self.Obj3DGridDic[entityId]:Hide()
    table.insert(self.Obj3DGridsList, self.Obj3DGridDic[entityId])
    self.Obj3DGridDic[entityId].Transform:SetParent(self.SpecialContainer, false)
    self.Obj3DGridDic[entityId] = nil
end

function XUiGuildDormCommon:Clear()
    if XTool.UObjIsNil(self.GameObject) then
        return 
    end
    for i = #self.ActiveTaklGrids, 1, -1 do
        self:HideTalkGrid(self.ActiveTaklGrids[i], i)
    end
    for i = #self.ActiveNameGrids, 1, -1 do
        self:HideNameGrid(self.ActiveNameGrids[i], i)
    end
    for entityId, _ in pairs(self.Obj3DGridDic) do
        self:OnHide3DObj(entityId)
    end
end

function XUiGuildDormCommon:OnSwitchChannel()
    local currentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    local running = currentRoom:GetRunning()
    running:SetUiGuildDormCommon(self)
    self:RefreshFurnitureNames()
    self:RefreshAllSpecialUiEntity()
end

function XUiGuildDormCommon:RefreshFurnitureNames()
    for _, furniture in pairs(XDataCenter.GuildDormManager.GetCurrentRoom():GetFurnitureDic()) do
        if furniture:CheckIsShowName() then
            self:OnEntityEnter(furniture)
        end
    end
end

function XUiGuildDormCommon:HandleSpecialUiEnter(entity, uiname, proxyPath, offset, showDistance)
    if showDistance == nil then showDistance = 0 end
    if self[uiname] == nil then
        XLog.Error("HandleSpecialUiEnter uiname is not find", uiname)
        return
    end
    local proxy
    if proxyPath == nil then
        proxy = XUiGuildDormSpecialUiGrid
    else
        proxy = require(proxyPath)
    end
    local grid = proxy.New(CS.UnityEngine.Object.Instantiate(self[uiname]))
    grid:SetData(entity, uiname)
    grid:SetOffset(offset)
    grid:SetShowDistance(showDistance)
    local sortIndex = XGuildDormConfig.UiGridSortIndex[uiname]
    if sortIndex and grid.Canvas then
        grid.Canvas.sortingOrder = sortIndex
    end
    table.insert(self.SpecialNameGrids, grid)
    XScheduleManager.ScheduleOnce(function()
        grid:Show(self.SpecialContainer)
    end, 1)
end

function XUiGuildDormCommon:RefreshAllSpecialUiEntity()
    for i = #self.SpecialNameGrids, 1, -1 do
        self.SpecialNameGrids[i]:Destroy()
        table.remove(self.SpecialNameGrids, i)
    end
    ---@type XGuildDormRoom
    local currentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    local entities = currentRoom:GetSpecialUiEntities()
    for _, entity in ipairs(entities) do
        local uinames = entity:GetSpecialUiNames()
        for i, uiname in ipairs(uinames) do
            self:HandleSpecialUiEnter(entity, uiname, entity:GetUiNameProxyPath(i)
                , entity:GetSpecialUiNameHeightOffset(i), entity:GetUiShowDistance())
        end
    end
end

function XUiGuildDormCommon:OnDestroySpecialUi(entityId, uiname)
    for i = #self.SpecialNameGrids, 1, -1 do
        local grid = self.SpecialNameGrids[i]
        if grid:GetEntityId() == entityId and grid:GetUiName() == uiname  then
            grid:Destroy()
            table.remove(self.SpecialNameGrids, i)
        end
    end
end

return XUiGuildDormCommon