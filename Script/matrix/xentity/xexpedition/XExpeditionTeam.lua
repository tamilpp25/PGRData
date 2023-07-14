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
    if a:GetIsDefaultTeamMember() and not b:GetIsDefaultTeamMember() then
        return true
    elseif not a:GetIsDefaultTeamMember() and b:GetIsDefaultTeamMember() then
        return false
    end
    return a:GetBaseId() > b:GetBaseId()
end
--================
--按战力排序(大的在前面)
--================
local SortByAbility = function(a, b)
    return a:GetAbility() > b:GetAbility()
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
--展示组合排序 核心羁绊＞当前羁绊星级＞人数 (激活状态按照星级排序，未激活状态按照人数排序)
--================
local SortDisplayComboFunc = function(a, b)
    local aActive = a:GetComboActive()
    local aDefaultTeamId = a:GetDefaultTeamId()
    local aRank = a:GetTotalRank()
    local aReachNum = a:GetReachConditionNum()
    local bActive = b:GetComboActive()
    local bDefaultTeamId = b:GetDefaultTeamId()
    local bRank = b:GetTotalRank()
    local bReachNum = b:GetReachConditionNum()
    if aActive ~= bActive then
        return aActive and not bActive
    end
    if aDefaultTeamId ~= bDefaultTeamId then
        return aDefaultTeamId > bDefaultTeamId
    end
    if aActive and bActive and aRank ~= bRank then
        return aRank > bRank
    end
    if not aActive and not bActive and aReachNum ~= bReachNum then
        return aReachNum > bReachNum
    end
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
function XExpeditionTeam:Ctor(teamId)
    if teamId and teamId > 0 then
        self.IsPlayer = true
        self:SetOtherPlayerDefaultTeamId(teamId)
    end
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
function XExpeditionTeam:InitTeamPos(recruitRobotMaxNum)
    self.TeamPos = {}
    for i = 1, recruitRobotMaxNum do
        table.insert(self.TeamPos, XTeamPos.New(i))
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
function XExpeditionTeam:Reset(notResetDefaultTeam)
    self.TeamChara = {}
    for _, chara in pairs(self.BaseMembers) do
        chara:Fired(notResetDefaultTeam)
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
    return unLockPosNum > (self:GetTeamNum() - 2)
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
    self:CheckCombos()
end
--================
--刷新Combo状态
--================
function XExpeditionTeam:CheckCombos()
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
    self.TeamChara[eBaseId]:SetIsNew()
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
    self.CoreDisplayTeamList = nil
    self.FetterDisplayTeamList = nil
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
        self.CoreDisplayTeamList = {}
        self.FetterDisplayTeamList = {}
        
        for _, chara in pairs(self.TeamChara) do
            table.insert(self.DisplayTeamList, chara)
            
            if chara:GetIsDefaultTeamMember() then
                table.insert(self.CoreDisplayTeamList, chara)
            else
                table.insert(self.FetterDisplayTeamList, chara)
            end
        end
        table.sort(self.DisplayTeamList, SortDisplayTeamFunc)
        table.sort(self.CoreDisplayTeamList, SortDisplayTeamFunc)
        table.sort(self.FetterDisplayTeamList, SortDisplayTeamFunc)
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

function XExpeditionTeam:GetFetterCharaByPos(pos)
    if not self.DisplayTeamList then
        self:GetDisplayTeamList()
    end
    return self.FetterDisplayTeamList and self.FetterDisplayTeamList[pos]
end

function XExpeditionTeam:GetCoreChara()
    if not self.DisplayTeamList then
        self:GetDisplayTeamList()
    end
    return self.CoreDisplayTeamList or {}
end

--================
--检查成员展示列表中是否含有指定序号的成员
--================
function XExpeditionTeam:CheckCharaInDisplayListByPos(pos)
    return self.FetterDisplayTeamList and self.FetterDisplayTeamList[pos] ~= nil
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
--================
--重置预设队伍
--================
function XExpeditionTeam:ResetDefaultTeamMember()
    for _, chara in pairs(self.BaseMembers) do
        chara:SetDefaultTeamMember(false)
    end
end
--================
--获取是否玩家自身队伍(用于判断是否排位里面其他玩家的队伍数据)
--================
function XExpeditionTeam:CheckIsPlayer()
    return self.IsPlayer
end
--================
--设置非玩家队伍预设队伍ID
--================
function XExpeditionTeam:SetOtherPlayerDefaultTeamId(teamId)
    self.OtherDefaultTeamId = teamId
end
--================
--检查给定ID是否跟非玩家队伍预设队伍ID相同
--================
function XExpeditionTeam:CheckOtherPlayerDefaultTeam(checkId)
    return self.OtherDefaultTeamId == checkId
end
--================
--自动上阵成员
--@param banDic:筛选ID字典
--使用的是BaseId，改列表指定的BaseId角色将会被筛掉不参与最后选择
--@param getIndex:获取最后排序列表角色的索引位置
--================
function XExpeditionTeam:GetAutoNextMember(banDic, getIndex)
    --构建临时用的筛选成员列表
    local tempList = {}
    for baseId, chara in pairs(self.TeamChara) do
        if not banDic[baseId] then --筛选掉队伍中的和筛选ID列表相同BaseId的成员
            table.insert(tempList, chara)
        end
    end
    --按给定规则（现在是按战力）排序
    table.sort(tempList, SortByAbility)
    return tempList[getIndex]
end
return XExpeditionTeam