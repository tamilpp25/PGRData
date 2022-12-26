-- 虚像地平线队伍对象
local XExpeditionTeam = XClass(nil, "XExpeditionTeam")
local XTeamPos = require("XEntity/XExpedition/XExpeditionTeamPos")
local XComboList = require("XEntity/XExpedition/XExpeditionComboList")
local XEChara = require("XEntity/XExpedition/XExpeditionCharacter")
--================
--加入队员失败
--================
local AddMemberFailed = function()
    XLog.Debug("加入成员失败！")
end
--================
--展示队伍排序
--================
local SortDisplayTeamFunc = function(a, b)
    return a:GetBaseId() > b:GetBaseId()
end
--================
--按大小排序，大的往前
--================
local SortByBigger = function(a, b)
    return a > b
end
--================
--展示组合排序
--================
local SortByComboId = function(a, b)
    return a:GetComboId() > b:GetComboId()
end
--================
--展示组合排序
--================
local SortDisplayComboFunc = function(a, b)
    if a:GetComboActive() and not b:GetComboActive() then return true end
    if not a:GetComboActive() and b:GetComboActive() then return false end
    return a:GetComboId() > b:GetComboId()
end
--================
--当队员变化时
--@param isPlayEffect:是否播放特效
--================
local OnMemberChange = function(isPlayEffect)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_EXPEDITION_MEMBERLIST_CHANGE, isPlayEffect)
end
--================
--构造函数
--================
function XExpeditionTeam:Ctor()
    self:InitBaseMembers()
    self:InitTeamChara()
    self:InitComboList()
end
--================
--初始化所有基础成员
--================
function XExpeditionTeam:InitBaseMembers()
    local allMembers = XExpeditionConfig.GetBaseCharacterCfg()
    self.BaseMembers = {}
    for eBaseId, member in pairs(allMembers) do
        self.BaseMembers[eBaseId] = XEChara.New(eBaseId)
    end
end
--================
--初始化队伍位置
--@param chapterId:当前章节ID
--================
function XExpeditionTeam:InitTeamPos(chapterId)
    self.TeamPos = {}
    local posList = XExpeditionConfig.GetTeamPosListByChapterId(chapterId)
    for _, posCfg in pairs(posList) do
        table.insert(self.TeamPos, XTeamPos.New(posCfg.Id))
    end
end
--================
--初始化队伍角色
--================
function XExpeditionTeam:InitTeamChara()
    self.TeamChara = {}
end
--================
--初始化队伍角色
--================
function XExpeditionTeam:InitComboList()
    self.ComboList = XComboList.New(self)
end
--================
--重置队伍
--================
function XExpeditionTeam:Reset()
    self.TeamChara = {}
    for _, chara in pairs(self.BaseMembers) do
        chara:Fired()
    end
    self:ResetDisplayTeam()
end
--================
--使用角色对象检查角色是否在队伍中
--@param eChara:玩法角色对象
--================
function XExpeditionTeam:CheckInTeamByEChara(eChara)
    return eChara:GetIsInTeam()
end
--================
--使用玩法角色ID检查角色是否在队伍中
--@param eBaseId:玩法角色基础Id
--================
function XExpeditionTeam:CheckInTeamByEBaseId(eBaseId)
    local eChara = self.BaseMembers[eBaseId]
    return eChara:GetIsInTeam()
end
--================
--检查有没空格子
--================
function XExpeditionTeam:CheckHaveNewPos()
    local unLockPosNum = 0
    for _, pos in pairs(self.TeamPos) do
        if pos:GetIsUnLock() then
            unLockPosNum = unLockPosNum + 1
        end
    end
    return unLockPosNum > self:GetTeamNum()
end
--================
--使用ECharaId列表批量加入成员并更新
--@param eCharaIds:ECharacterId列表
--================
function XExpeditionTeam:AddMemberListByECharaIds(eCharaIds)
    if not eCharaIds then return end
    for _, eCharaId in pairs(eCharaIds) do
        if eCharaId > 0 then
            local eCharaCfg = XExpeditionConfig.GetCharacterCfgById(eCharaId)
            self:AddMemberByEBaseIdAndRank(eCharaCfg.BaseId, eCharaCfg.Rank, false)
        end
    end
    self.ComboList:CheckCombos(self.TeamChara)
    self:ResetDisplayTeam()
end
--================
--用玩法角色ID和初始等级把角色加入队伍
--@param eBaseId:加入队伍的玩法角色ID
--@param rank:初始等级
--================
function XExpeditionTeam:AddMemberByEBaseIdAndRank(eBaseId, rank, needCheck)
    local canAdd, isExist = self:GetCanAddMember(eBaseId)
    if not canAdd then AddMemberFailed() return end
    if isExist then
        self.TeamChara[eBaseId]:RankUp(rank)
    else
        local eChara = self.BaseMembers[eBaseId]
        self.TeamChara[eBaseId] = eChara
        eChara:SetRank(rank)
        eChara:SetIsInTeam(true)
    end
    if needCheck then
        self.ComboList:CheckCombos(self.TeamChara)
        self:ResetDisplayTeam()
    end
end
--================
--用EChara对象把角色加入队伍(用于招募角色时)
--@param eChara:加入队伍的角色对象
--================
function XExpeditionTeam:AddMemberByEChara(eChara)
    if not eChara then return end
    local eBaseId = eChara:GetBaseId()
    self:AddMemberByEBaseIdAndRank(eBaseId, eChara:GetRank(), true)
    self.TeamChara[eBaseId]:GetIsNew()
    self.ComboList:CheckCombos(self.TeamChara)
    self:OnTeamMemberChange()
end
--================
--检查能不能加入新成员
--@param eBaseId:要加入队伍的玩法角色ID
--================
function XExpeditionTeam:GetCanAddMember(eBaseId)
    if self.TeamChara[eBaseId] then
        return not self.TeamChara[eBaseId]:GetIsMaxLevel(), true
    else
        return self:CheckHaveNewPos(), false
    end
end
--================
--从队伍移除角色
--@param pos:要移除的角色位置
--================
function XExpeditionTeam:RemoveMember(eBaseId)
    if (not eBaseId) or (not self.TeamChara[eBaseId]) then return end
    self.TeamChara[eBaseId]:Fired()
    self.TeamChara[eBaseId] = nil
    self:OnTeamMemberChange()
end

--================
--获取队伍位置
--================
function XExpeditionTeam:GetTeamPos()
    return self.TeamPos
end
--================
--获取队伍队员对象列表
--================
function XExpeditionTeam:GetTeam()
    return self.TeamChara
end
--================
--获取队伍队员数量
--================
function XExpeditionTeam:GetTeamNum()
    local count = 0
    for i in pairs(self:GetTeam()) do
        count = count + 1
    end
    return count
end
--================
--获取所有羁绊对象列表（包括没激活的）
--================
function XExpeditionTeam:GetAllCombos()
    return self.ComboList:GetAllCombos()
end
--================
--获取所有队员组合对象列表
--================
function XExpeditionTeam:GetTeamComboList()
    local team = self:GetTeam()
    local comboList = self.ComboList:GetCurrentCombos(team)
    table.sort(comboList, SortDisplayComboFunc)
    return comboList
end
--================
--获取所有有效的队员组合对象列表
--================
function XExpeditionTeam:GetActiveTeamComboList()
    local team = self:GetTeam()
    local comboList = self.ComboList:GetCurrentCombos(team)
    local activeList = {}
    for _, combo in pairs(comboList) do
        if combo:GetComboActive() then
            table.insert(activeList, combo)
        end
    end
    table.sort(activeList, SortByComboId)
    return activeList
end
--================
--获取所有羁绊列表对象
--================
function XExpeditionTeam:GetComboList()
    return self.ComboList
end
--================
--队伍成员变动时调用方法
--================
function XExpeditionTeam:OnTeamMemberChange()
    self:ResetDisplayTeam()
    self.AverageLevel = nil
    OnMemberChange()
end
--================
--重置队伍展示列表状态
--================
function XExpeditionTeam:ResetDisplayTeam()
    self.DisplayTeamList = nil
end
--================
--获取招募界面队伍显示列表
--================
function XExpeditionTeam:GetTeamPosDisplayList()
    local displayTeamPosList = {}
    local unLockPosList = {}
    local lockPosList = {}
    for _, teamPos in pairs(self.TeamPos) do
        if teamPos:GetIsUnLock() then
            table.insert(unLockPosList, teamPos)
        else
            table.insert(lockPosList, teamPos)
        end
    end
    for i in pairs(unLockPosList) do
        table.insert(displayTeamPosList, unLockPosList[i])
    end
    for i in pairs(lockPosList) do
        table.insert(displayTeamPosList, lockPosList[i])
    end
    return displayTeamPosList
end
--================
--获取展示用队伍成员显示列表
--================
function XExpeditionTeam:GetDisplayTeamList()
    if not self.DisplayTeamList then
        self.DisplayTeamList = {}
        for _, chara in pairs(self.TeamChara) do
            table.insert(self.DisplayTeamList, chara)
        end
        table.sort(self.DisplayTeamList, SortDisplayTeamFunc)
    end
    return self.DisplayTeamList
end
--================
--根据位置获取展示用队伍成员显示列表中的成员
--================
function XExpeditionTeam:GetCharaByDisplayPos(pos)
    if not self.DisplayTeamList then
        return self:GetDisplayTeamList() and self.DisplayTeamList[pos]
    end
    return self.DisplayTeamList and self.DisplayTeamList[pos]
end
--================
--检查成员展示列表中是否含有指定序号的成员
--================
function XExpeditionTeam:CheckCharaInDisplayListByPos(pos)
    return self.DisplayTeamList and self.DisplayTeamList[pos] ~= nil
end
--================
--根据玩法角色Id获取成员展示列表中指定角色的序号
--================
function XExpeditionTeam:GetCharaDisplayIndexByBaseId(eBaseId)
    if not self.DisplayTeamList then
        self:GetDisplayTeamList()
    end
    for index, v in pairs(self.DisplayTeamList) do
        if v:GetBaseId() == eBaseId then return index end
    end
    return -1
end
--================
--根据成员展示列表中指定角色的序号获取角色对象
--================
function XExpeditionTeam:GetECharaByDisplayIndex(displayIndex)
    for index, v in pairs(self.DisplayTeamList) do
        if index == displayIndex then return v end
    end
end
--================
--根据玩法角色Id获取成员对象
--================
function XExpeditionTeam:GetCharaByEBaseId(eBaseId)
    return self.TeamChara[eBaseId]
end
--================
--获取出战队伍平均星级
--================
function XExpeditionTeam:GetAverageStar()
    local list = {}
    for _, eChara in pairs(self.TeamChara) do
        table.insert(list, eChara:GetRank())
    end
    table.sort(list, SortByBigger)
    local totalLevel = 0
    for i = 1, 3 do
        totalLevel = totalLevel + (list and list[i] ~= nil and list[i] or 0)
    end
    return math.floor(totalLevel / (#list > 0 and #list <= 3 and #list or 3))
end
--================
--获取出战队伍对象
--================
function XExpeditionTeam:GetBattleTeam()
    local team = XDataCenter.ExpeditionManager.GetExpeditionTeam()
    local teamData = team.TeamData
    local eCharaList = {}
    for _, eBaseId in pairs(teamData) do
        if eBaseId > 0 then
            local eChara = self.TeamChara[eBaseId]
            if eChara then table.insert(eCharaList, eChara) end
        end
    end
    table.sort(eCharaList, SortDisplayTeamFunc)
    return eCharaList
end
return XExpeditionTeam