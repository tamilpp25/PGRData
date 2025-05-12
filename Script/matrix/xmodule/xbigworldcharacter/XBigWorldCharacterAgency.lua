---@class XBigWorldCharacterAgency : XAgency
---@field private _Model XBigWorldCharacterModel
---@field private _TeamDict table<any, XBWTeam>
local XBigWorldCharacterAgency = XClass(XAgency, "XBigWorldCharacterAgency")

--常规队伍人数，可能会有大于这个的情况
local FullTeamEntityCount = 3

local CsX3CCommand = CS.X3CCommand

local pairs = pairs

local tableSort = table.sort

local XBWTeam

function XBigWorldCharacterAgency:Reset()
    self._TeamDict = {}
end

function XBigWorldCharacterAgency:OnInit()
    self:Reset()
    self.TeamId = require("XModule/XBigWorldCharacter/Team/XBWTeamId")
end

function XBigWorldCharacterAgency:ResetAll()
    self:Reset()
end

function XBigWorldCharacterAgency:InitRpc()
end

function XBigWorldCharacterAgency:InitEvent()
end

function XBigWorldCharacterAgency:OnFightNpcLoadComplete()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_LOCAL_PLAYER_NPC_LOAD_COMPLETED)
end

function XBigWorldCharacterAgency:OnTrialNpcJoinTeam(data)
    self._Model:UpdateTrialCharacterIds(data.TrialNpcCharacterIds, data.Cover)
end

function XBigWorldCharacterAgency:OnTrialNpcLeaveTeam()
    self._Model:ClearTrialCharacterIds()
end

--region 角色配置

function XBigWorldCharacterAgency:UpdateCharacter(fashionDict)
    if fashionDict then
        for _, info in pairs(fashionDict) do
            local char = self._Model:GetDlcCharacter(info.Character)
            char:SetFashionId(info.FashionId)
            local headInfo = info.DlcCharacterHeadInfo
            if headInfo then
                char:SetHeadInfo(headInfo.HeadFashionId, headInfo.HeadFashionType)
            end
        end
    end
end

function XBigWorldCharacterAgency:IsCommandant(characterId)
    if not characterId or characterId <= 0 then
        return false
    end
    return self._Model:IsCommandant(characterId)
end

function XBigWorldCharacterAgency:GetFashionId(characterId)
    return self._Model:GetFashionId(characterId)
end

function XBigWorldCharacterAgency:GetCharacterName(characterId)
    characterId = XEntityHelper.GetCharacterIdByEntityId(characterId) 
    if self:IsCommandant(characterId) then
        return XPlayer.Name
    end
    return XMVCA.XCharacter:GetCharacterName(characterId)
end

function XBigWorldCharacterAgency:GetCharacterTradeName(characterId)
    characterId = XEntityHelper.GetCharacterIdByEntityId(characterId)
    if self:IsCommandant(characterId) then
        return XMVCA.XBigWorldService:GetText("CommandantTradeName")
    end
    return XMVCA.XCharacter:GetCharacterTradeName(characterId)
end

function XBigWorldCharacterAgency:GetCharacterLogName(characterId)
    characterId = XEntityHelper.GetCharacterIdByEntityId(characterId)
    if self:IsCommandant(characterId) then
        return XPlayer.Name
    end
    return XMVCA.XCharacter:GetCharacterLogName(characterId)
end

function XBigWorldCharacterAgency:GetCharacterNpcId(characterId)
    local t = self._Model:GetDlcCharacterTemplate(characterId)
    return t and t.NpcId or 0
end

function XBigWorldCharacterAgency:GetCharacterPriority(characterId)
    characterId = XEntityHelper.GetCharacterIdByEntityId(characterId)
    local t = self._Model:GetDlcCharacterTemplate(characterId)
    return t and t.Priority or 0
end

function XBigWorldCharacterAgency:GetRoundHeadIcon(characterId)
    local fashionId = self:GetFashionId(characterId)
    local t = self._Model:GetDlcFashionTemplate(fashionId)
    local roundHead = t.RoundHeadImage
    if not string.IsNilOrEmpty(roundHead) or self:IsCommandant(characterId) then
        return roundHead
    end
    return XDataCenter.FashionManager.GetFashionRoundnessHeadIcon(fashionId)
end

function XBigWorldCharacterAgency:GetSquareHeadIcon(characterId)
    local fashionId = self:GetFashionId(characterId)
    local t = self._Model:GetDlcFashionTemplate(fashionId)
    local squareHead = t.SquareHeadImage
    if not string.IsNilOrEmpty(squareHead) or self:IsCommandant(characterId) then
        return squareHead
    end
    local headInfo = self._Model:GetHeadInfo(characterId)
    if headInfo then
        return XDataCenter.FashionManager.GetFashionSmallHeadIcon(headInfo.HeadFashionId, headInfo.HeadFashionType)
    end
    return XDataCenter.FashionManager.GetFashionSmallHeadIconFashion(fashionId)
end

--- 战斗侧获取角色头像
---@param worldNpcData XWorldNpcData  
---@return string
--------------------------
function XBigWorldCharacterAgency:GetFightCharHeadIcon(worldNpcData)
    if not worldNpcData then
        return ""
    end
    local character = worldNpcData.Character
    if not character then
        return ""
    end

    if self:IsCommandant(character.Id) then
        return self:GetRoundHeadIcon(character.Id)
    end

    local headInfo = self._Model:GetHeadInfo(character.Id)

    local headFashionId = headInfo.HeadFashionId
    local headFashionType = headInfo.HeadFashionType
    
    if headFashionType == XFashionConfigs.HeadPortraitType.Liberation then
        return XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIconLiberation(headFashionId)
    end
    return XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIcon(headFashionId)
end

function XBigWorldCharacterAgency:GetCommandantNpcData()
    ---@type XWorldNpcData
    local data = CS.XBigWorldHelper.CreateWorldNpcData()
    local commandantId = XMVCA.XBigWorldCommanderDIY:GetCurrentCommandantId()
    data.Id = self:GetCharacterNpcId(commandantId)
    data.Index = 0
    data.Character = {
        Id = commandantId,
        FashionId = self:GetFashionId(commandantId)
    }
    data.IsPlayerSelf = true
    data.PartData = XMVCA.XBigWorldCommanderDIY:GetNpcPartData()
    
    return data
end

function XBigWorldCharacterAgency:GetAllRoleIds()
    return self._Model:GetAllRoleIds()
end

function XBigWorldCharacterAgency:GetAllUnlockIds()
    local list = self:GetAllUnlockIdsWithoutCommandant()
    list[#list + 1] = XMVCA.XBigWorldCommanderDIY:GetCurrentCommandantId()
    return list
end

function XBigWorldCharacterAgency:GetAllUnlockIdsWithoutCommandant()
    local list = {}
    local all = self:GetAllRoleIds()
    for _, id in pairs(all) do
        if self:IsRoleUnlock(id) then
            list[#list + 1] = id
        end
    end
    return list
end

function XBigWorldCharacterAgency:IsRoleUnlock(characterId)
    return self._Model:IsRoleUnlock(characterId)
end

function XBigWorldCharacterAgency:GetUiModelId(characterId)
    local fashionId = self:GetFashionId(characterId)

    return self:GetUiModelIdByFashionId(fashionId)
end

function XBigWorldCharacterAgency:GetUiModelIdByFashionId(fashionId)
    local t = self._Model:GetDlcFashionTemplate(fashionId)
    return t and t.UiModelId or ""
end

function XBigWorldCharacterAgency:GetModelIdByFashionId(fashionId)
    local uiModelId = self:GetUiModelIdByFashionId(fashionId)

    return XMVCA.XBigWorldResource:GetDlcModelId(uiModelId)
end

--endregion 角色配置

--region 队伍配置

--- 获取Dlc队伍
---@param teamId any
---@return XBWTeam
--------------------------
function XBigWorldCharacterAgency:GetDlcTeam(teamId)
    local team = self._TeamDict[teamId]
    if team then
        return team
    end

    if not XBWTeam then
        XBWTeam = require("XModule/XBigWorldCharacter/Team/XBWTeam")
    end
    team = XBWTeam.New(teamId)
    self._TeamDict[teamId] = team

    return team
end

--- 获取当前编队数据
---@return XBWTeam
--------------------------
function XBigWorldCharacterAgency:GetCurrentTeam()
    local team = self:GetDlcTeam(self:GetCurrentTeamId())
    --首次进去，没有编队数据
    if team:IsEmpty() then
        for pos = 1, FullTeamEntityCount do
            local value = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("DefaultTeamPos" .. pos)
            team:UpdateTeamByPos(pos, value)
        end
        team:Sync()
    end
    
    return team
end

--- 通用编队id
---@param index number 通用编队下标  
---@return number
--------------------------
function XBigWorldCharacterAgency:GetCommonTeamId(index)
    return self.TeamId.Common[index]
end

function XBigWorldCharacterAgency:SortTeamList(teamId, isContainCommandant)
    local list = isContainCommandant and self:GetAllUnlockIds() or self:GetAllUnlockIdsWithoutCommandant()
    if XTool.IsTableEmpty(list) then
        return list
    end
    local team = self:GetDlcTeam(teamId)
    local getPriority = handler(XMVCA.XBigWorldCharacter, XMVCA.XBigWorldCharacter.GetCharacterPriority)
    tableSort(list, function(a, b)
        local orderA = team:GetEntityPos(a)
        local orderB = team:GetEntityPos(b)

        orderA = orderA <= 0 and 100000 or orderA
        orderB = orderB <= 0 and 100000 or orderB

        if orderA ~= orderB then
            return orderA < orderB
        end

        local pA = getPriority(a)
        local pB = getPriority(b)
        if pA ~= pB then
            return pA > pB
        end
        return a > b
    end)
    
    return list
end

--- DIY编辑后，更新队伍数据
--------------------------
function XBigWorldCharacterAgency:TryUpdateTeamAfterDIY()
    local updateTeamIds = {}
    local newRoleId = XMVCA.XBigWorldCommanderDIY:GetCurrentCommandantId()
    local commonIds = self.TeamId.Common
    for _, teamId in pairs(commonIds) do
        local team = self:GetDlcTeam(teamId)
        local pos = team:GetCommandantPos()
        if pos and pos > 0 then
            updateTeamIds[#updateTeamIds + 1] = teamId
            team:UpdateTeamByPos(pos, newRoleId)
        end
    end

    for _, teamId in pairs(updateTeamIds) do
        self:RequestUpdateTeam(teamId)
    end
end

--- 当前编队
---@return number
--------------------------
function XBigWorldCharacterAgency:GetCurrentTeamId()
    return self._Model:GetCurrentTeamId()
end

function XBigWorldCharacterAgency:GetFullTeamEntityCount()
    return FullTeamEntityCount
end

function XBigWorldCharacterAgency:UpdateTeam(currentTeamId, teamData)
    self._Model:SetCurrentTeamId(currentTeamId)
    if not XTool.IsTableEmpty(teamData) then
        for _, data in pairs(teamData) do
            local teamId = data.TeamId
            local team = self:GetDlcTeam(teamId)
            team:UpdateTeam(data.CharacterList)
            
            team:Sync()
        end
    end
end

--- 同步战斗编队数据
--------------------------
function XBigWorldCharacterAgency:SyncTeamData(teamId)
    local team = self:GetDlcTeam(teamId)
    if team:IsSyncFight() then
        -- local data = {
        --     TeamData = team:ToFightData(),
        -- }
        -- XMVCA.X3CProxy:Send(CsX3CCommand.CMD_SYNC_TEAM_DATA, data)
    else --战斗侧不需要重新加载角色
        self:OnFightNpcLoadComplete()
    end
    team:SyncFight()
end

--- 同步所有数据给服务器
function XBigWorldCharacterAgency:SyncTeamDataToServer()
    local teamIds = self.TeamId.Common
    local syncCount = 0
    local curTeamId = self:GetCurrentTeamId()
    for _, teamId in pairs(teamIds) do
        local team = self:GetDlcTeam(teamId)
        if curTeamId == teamId and team:IsEmpty() then
            XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("EmptyTeamTip"))
            team:Restore()
            
            goto continue
        end

        if not team:IsChanged() then
            goto continue
        end
        
        local teamData = {
            TeamId = teamId,
            CharacterList = team:ToServerEntityIds()
        }
        syncCount = syncCount + 1
        XNetwork.Call("BigWorldTeamChangeRequest", { ChangeTeam = teamData }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                team:Restore()
                XLog.Error(string.format("队伍%d数据保存失败！！！", teamId))
                return
            end
            team:Sync()

            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_ROLE_TEAM_STATUS_REFRESH)
        end)
        ::continue::
    end

    if syncCount <= 0 then
        self:OnFightNpcLoadComplete()
    end
end

function XBigWorldCharacterAgency:MarkCurrentTeamNeedSync(characterId)
    --切换头像后标记需要更新
    local teamId = self:GetCurrentTeamId()
    local team = self:GetDlcTeam(teamId)
    if team:HasSameEntity(characterId) then
        team:MarkIsSyncFight()
    end
end

--- 设置登场队伍
---@param teamId number 队伍Id 
--------------------------
function XBigWorldCharacterAgency:RequestSetFightingTeam(teamId, cb)
    XNetwork.Call("BigWorldTeamIndexChangeRequest", { CurrentTeamId = teamId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetCurrentTeamId(teamId)
        self:GetDlcTeam(teamId):MarkIsSyncFight()
        if cb then
            cb()
        end
    end)
end

--- 保存队伍数据
---@param teamId number 队伍Id  
--------------------------
function XBigWorldCharacterAgency:RequestUpdateTeam(teamId, cb)
    local team = self:GetDlcTeam(teamId)
    if not team then
        return
    end
    local currentTeamId = self:GetCurrentTeamId()
    if currentTeamId == teamId then
        if team:IsEmpty() then
            local text = XMVCA.XBigWorldService:GetText("EmptyTeamTip")
            XUiManager.TipMsg(text)
            team:Restore()
            return
        end
    end
    --team:MoveForward()
    -- 队伍数据未改变，不发协议了
    if not team:IsChanged() then
        if cb then cb() end
        team:Restore()
        return
    end
    
    local teamData = {
        TeamId = teamId,
        CharacterList = team:ToServerEntityIds()
    }
    XNetwork.Call("BigWorldTeamChangeRequest", { ChangeTeam = teamData }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            team:Restore()
            if cb then cb() end
            return
        end
        team:MarkIsSyncFight()
        team:Sync()

        if cb then cb() end
        
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_ROLE_TEAM_STATUS_REFRESH)
    end)
end

--endregion 队伍配置

--region 角色时装

function XBigWorldCharacterAgency:CheckFashionUnlock(characterId, fashionId)
    local t = self._Model:GetDlcCharacterTemplate(characterId)
    if t.DefaultFashionId == fashionId then
        return true
    end
    return XDataCenter.FashionManager.IsFashionInTime 
            and XDataCenter.FashionManager.CheckHasFashion(fashionId)
end

function XBigWorldCharacterAgency:CheckHeadUsing(characterId, headFashionId, headFashionType)
    local info = self._Model:GetHeadInfo(characterId)
    if not info then
        return false
    end
    return info.HeadFashionId == headFashionId and info.HeadFashionType == headFashionType
end

function XBigWorldCharacterAgency:CheckHeadUnlock(characterId, headFashionId, headFashionType)
    if not self:CheckFashionUnlock(characterId, headFashionId) then
        return false
    end
    if headFashionType == XFashionConfigs.HeadPortraitType.Default then
        return true

    elseif headFashionType == XFashionConfigs.HeadPortraitType.Liberation then
        if not XTool.IsNumberValid(characterId) then
            return false
        end
        return  XDataCenter.ExhibitionManager.IsAchieveLiberation(characterId, XEnumConst.CHARACTER.GrowUpLevel.Higher)
    end
    
    return true
end

function XBigWorldCharacterAgency:GetUnlockFashionList(characterId)
    if self:IsCommandant(characterId) then
        XLog.Error("指挥官无法获取时装列表")
        return
    end
    local t = self._Model:GetDlcCharacterTemplate(characterId)
    local defaultFashionId = t.DefaultFashionId
    local fashionIds = XDataCenter.FashionManager.GetFashions(characterId)
    local list = {}
    local containDefault = false

    for _, fashionId in pairs(fashionIds) do
        local config = self._Model:GetDlcFashionTemplate(fashionId, true)
        --时间内 & 解锁 & 必须配置
        if config and XDataCenter.FashionManager.IsFashionInTime(fashionId) 
                and XDataCenter.FashionManager.CheckHasFashion(fashionId) then

            if  defaultFashionId == fashionId then
                containDefault = true
            end
            list[#list + 1] = fashionId
        end
    end
    
    if not containDefault and defaultFashionId and defaultFashionId > 0 then
        list[#list + 1] = defaultFashionId
    end

    local useId = self:GetFashionId(characterId)
    if #list > 1 then
        
        tableSort(list, function(a, b)
            local isUsaA = a == useId
            local isUsaB = b == useId
            if isUsaA ~= isUsaB then
                return isUsaA
            end
            local pA = XDataCenter.FashionManager.GetFashionPriority(a)
            local pB = XDataCenter.FashionManager.GetFashionPriority(b)
            
            if pA ~= pB then
                return pA > pB
            end
            return a < b
        end)
    end
    
    return list
end

function XBigWorldCharacterAgency:GetUnlockHeadList(characterId)
    local headDict = XDataCenter.FashionManager.GetHeadPortraitList(characterId)
    local list = {}
    for url, info in pairs(headDict) do
        if self:CheckHeadUnlock(characterId, info.HeadFashionId, info.HeadFashionType) then
            list[#list + 1] = {
                Icon = url,
                HeadFashionId = info.HeadFashionId,
                HeadFashionType = info.HeadFashionType,
            }
        end
    end
    
    if #list > 1 then
        tableSort(list, function(a, b)
            local isUsaA = self:CheckHeadUsing(characterId, a.HeadFashionId, a.HeadFashionType)
            local isUsaB = self:CheckHeadUsing(characterId, b.HeadFashionId, b.HeadFashionType)
            if isUsaA ~= isUsaB then
                return isUsaA
            end
            local pA = XDataCenter.FashionManager.GetFashionPriority(a.HeadFashionId)
            local pB = XDataCenter.FashionManager.GetFashionPriority(b.HeadFashionId)

            if pA ~= pB then
                return pA > pB
            end
            return a.HeadFashionId < b.HeadFashionId
        end)
    end
   
    
    return list
end

function XBigWorldCharacterAgency:RequestSetFashion(characterId, fashionId, cb)
    XNetwork.Call("BigWorldCharacterFashionUseRequest", {FashionId = fashionId}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:MarkCurrentTeamNeedSync(characterId)
        
        local char = self._Model:GetDlcCharacter(characterId)
        char:SetFashionId(fashionId)

        if cb then cb() end
    end)
end

function XBigWorldCharacterAgency:RequestSetHeadInfo(characterId, headFashionId, headFashionType, cb)
    local req = {
        TemplateId = characterId,
        CharacterHeadInfo = {
            HeadFashionId = headFashionId,
            HeadFashionType = headFashionType,
        }
    }
    XNetwork.Call("BigWorldCharacterSetHeadInfoRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:MarkCurrentTeamNeedSync(characterId)
        
        local char = self._Model:GetDlcCharacter(characterId)
        char:SetHeadInfo(headFashionId, headFashionType)
        if cb then cb() end
    end)
end

--endregion 角色时装

-- region 试用角色

function XBigWorldCharacterAgency:CheckCharacterTrial(characterId)
    return self._Model:CheckTrialCharacter(characterId)
end

-- endregion

return XBigWorldCharacterAgency