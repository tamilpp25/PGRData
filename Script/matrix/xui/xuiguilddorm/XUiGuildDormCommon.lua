local XUiGuildDormTalkGrid = require("XUi/XUiGuildDorm/XUiGuildDormTalkGrid")
local XUiGuildDormNameGrid = require("XUi/XUiGuildDorm/XUiGuildDormNameGrid")
local XUiGrid3DObj = require("XUi/XUiDormComponent/XUiGrid3DObj")
local XUiGuildDormCommon = XLuaUiManager.Register(XLuaUi, "UiGuildDormCommon")

function XUiGuildDormCommon:OnAwake()
    self.ActiveTaklGrids = {}
    self.RecycledTalkGrids = {}
    self.ActiveNameGrids = {}
    self.RecycledNameGrids = {}
    self.Obj3DGridDic = {}
    self.Obj3DGridsList = {}
    self.GuildDormManager = XDataCenter.GuildDormManager
    self.TalkSpiltLenght = XGuildDormConfig.GetTalkSpiltLenght()
end

function XUiGuildDormCommon:OnStart()
    local currentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    local running = currentRoom:GetRunning()
    running:SetUiGuildDormCommon(self)
    for _, role in ipairs(currentRoom:GetRoles()) do
        self:OnPlayerEnter(role)
    end
    self.Transform:GetComponent("Canvas").sortingOrder = 49
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_PLAYER_ENTER, self.OnPlayerEnter, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_PLAYER_EXIT, self.OnPlayerExit, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ROLE_TALK, self.OnRoleTalk, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ROLE_SHOW_EFFECT, self.OnShow3DObj, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_ROLE_HIDE_EFFECT, self.OnHide3DObj, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DORM_SWITCH_CHANNEL, self.OnSwitchChannel, self)
end

function XUiGuildDormCommon:Update(dt)
    -- 处理聊天隐藏
    for i = #self.ActiveTaklGrids, 1, -1 do
        if self.ActiveTaklGrids[i]:GetIsArriveHideTime() then
            self:HideTalkGrid(self.ActiveTaklGrids[i], i)
        else
            if self.GuildDormManager.GetIsHideTalkUi() then
                self.ActiveTaklGrids[i]:Hide()
            else
                self.ActiveTaklGrids[i]:UpdateTransform()
                self.ActiveTaklGrids[i]:Show()
            end
        end
    end
    -- 显示玩家的名字
    for i = #self.ActiveNameGrids, 1, -1 do
        if self.GuildDormManager.GetIsHideNameUi() then
            self.ActiveNameGrids[i]:Hide()
        else
            self.ActiveNameGrids[i]:Show()
            self.ActiveNameGrids[i]:UpdateTransform()
        end
    end
end

function XUiGuildDormCommon:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_PLAYER_ENTER, self.OnPlayerEnter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_PLAYER_EXIT, self.OnPlayerExit, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ROLE_TALK, self.OnRoleTalk, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ROLE_SHOW_EFFECT, self.OnShow3DObj, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_ROLE_HIDE_EFFECT, self.OnHide3DObj, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DORM_SWITCH_CHANNEL, self.OnSwitchChannel, self)
end

function XUiGuildDormCommon:HideTalkGrid(grid, activeIndex)
    grid:Hide()
    table.insert(self.RecycledTalkGrids, grid)
    table.remove(self.ActiveTaklGrids, activeIndex)
end

function XUiGuildDormCommon:OnRoleTalk(playerId, content, isEmoji)
    local role = XDataCenter.GuildDormManager.GetCurrentRoom():GetRoleByPlayerId(playerId)
    if role == nil then return end
    local grid = nil
    for i = #self.ActiveTaklGrids, 1, -1 do
        if self.ActiveTaklGrids[i]:GetPlayerId() == playerId then
            self:HideTalkGrid(self.ActiveTaklGrids[i], i)
        end
    end
    if #self.RecycledTalkGrids > 0 then
        grid = table.remove(self.RecycledTalkGrids, 1)
    else
        grid = XUiGuildDormTalkGrid.New(CS.UnityEngine.Object.Instantiate(self.GridDialogBox))
    end
    local offsetHeight = XGuildDormConfig.GetRoleTalkHeightOffset(role:GetId())
    local rlRole = role:GetRLRole()
    if not isEmoji then
        content = XTool.LoopSplitStr(content, "\n", self.TalkSpiltLenght)
    end
    grid:SetData(content, rlRole, offsetHeight, isEmoji)
    grid:Show(self.DialogContainer)
    grid:SetPlayerId(playerId)
    table.insert(self.ActiveTaklGrids, grid)
end

function XUiGuildDormCommon:HideNameGrid(grid, activeIndex)
    grid:Hide()
    table.insert(self.RecycledNameGrids, grid)
    table.remove(self.ActiveNameGrids, activeIndex)
end

function XUiGuildDormCommon:OnPlayerEnter(role)
    local playerId = role:GetPlayerId()
    for i = #self.ActiveNameGrids, 1, -1 do
        if self.ActiveNameGrids[i]:GetPlayerId() == playerId then
            self:HideNameGrid(self.ActiveNameGrids[i], i)
        end
    end
    local grid
    if #self.RecycledNameGrids > 0 then
        grid = table.remove(self.RecycledNameGrids, 1)
    else
        grid = XUiGuildDormNameGrid.New(CS.UnityEngine.Object.Instantiate(self.GridName))
    end
    local offsetHeight = XGuildDormConfig.GetRoleNameHeightOffset(role:GetId())
    local rlRole = role:GetRLRole()
    grid:SetData(rlRole, offsetHeight, playerId)
    XScheduleManager.ScheduleOnce(function()
        grid:Show(self.NameContainer)
    end, 1)
    grid:SetPlayerId(playerId)
    table.insert(self.ActiveNameGrids, grid)
end

function XUiGuildDormCommon:OnPlayerExit(playerId)
    for i = #self.ActiveNameGrids, 1, -1 do
        if self.ActiveNameGrids[i]:GetPlayerId() == playerId then
            self.ActiveNameGrids[i]:Hide()
            table.insert(self.RecycledNameGrids, self.ActiveNameGrids[i])
            table.remove(self.ActiveNameGrids, i)
            break
        end
    end
    self:OnHide3DObj(playerId)
    for i = #self.ActiveTaklGrids, 1, -1 do
        if self.ActiveTaklGrids[i]:GetPlayerId() == playerId then
            self:HideTalkGrid(self.ActiveTaklGrids[i], i)
            break
        end
    end
end

function XUiGuildDormCommon:OnShow3DObj(playerId, characterId, effectId, transform, bindWorldPos)
    -- 处理已经在显示中
    if self.Obj3DGridDic[playerId] then
        self.Obj3DGridDic[playerId]:RefreshEffect(effectId, bindWorldPos)
        return
    end
    -- 处理缓存中的
    if #self.Obj3DGridsList > 0 then
        local temp = table.remove(self.Obj3DGridsList, 1)
        temp:Show(characterId, effectId, transform, bindWorldPos)
        self.Obj3DGridDic[playerId] = temp
        return
    end
    -- 重新实例一个
    local grid = CS.UnityEngine.Object.Instantiate(self.Grid3DObj)
    local gridBox = XUiGrid3DObj.New(grid)
    gridBox:Show(characterId, effectId, transform, bindWorldPos)
    self.Obj3DGridDic[playerId] = gridBox
end

function XUiGuildDormCommon:OnHide3DObj(playerId)
    if not self.Obj3DGridDic[playerId] then
        return
    end
    self.Obj3DGridDic[playerId]:Hide()
    table.insert(self.Obj3DGridsList, self.Obj3DGridDic[playerId])
    self.Obj3DGridDic[playerId].Transform:SetParent(self.Obje3DContainer, false)
    self.Obj3DGridDic[playerId] = nil
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
    for playerId, _ in pairs(self.Obj3DGridDic) do
        self:OnHide3DObj(playerId)
    end
end

function XUiGuildDormCommon:OnSwitchChannel()
    local currentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    local running = currentRoom:GetRunning()
    running:SetUiGuildDormCommon(self)
end

return XUiGuildDormCommon