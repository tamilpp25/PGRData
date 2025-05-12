local XCharacterViewModel = require("XEntity/XCharacter/XCharacterViewModel")
local XCharacterSkillGroup = require("XEntity/XCharacter/XCharacterSkillGroup")
local XEnhanceSkillGroup = require("XEntity/XCharacter/XEnhanceSkillGroup")

local type = type
---@class XCharacter
XCharacter = XClass(nil, "XCharacter")

local Default = {
    Id = 0,
    Level = 1,
    Exp = 0,
    Quality = 1,
    Star = 0,
    Grade = 1, -- 军阶等级
    CreateTime = 0,
    Ability = 0,
    TrustLv = 0,
    TrustExp = 0,
    Type = 0, -- 职业类型
    NpcId = 0,
    LiberateAureoleId = 0, -- 超解环颜色
    Attribs = {},
    __SkillGroupDatas = {},
    __EnhanceSkillGroupPosDic = {},
    __EnhanceSkillGroupDatas = {},
    __EnhanceSkillIdToGroupIdDic = {},
    CharacterHeadInfo = {
        HeadFashionId = 0, --涂装头像Id
        HeadFashionType = XFashionConfigs.HeadPortraitType.Default, --涂装头像类型
    }
}

function XCharacter.GetDefaultFields()
    return Default
end

function XCharacter:Ctor(data, isOther)
    -- XCharacterViewModel
    self.CharacterViewModel = nil
    self.UpdatedData = nil
    self.IsOther = isOther -- 是否是其他人的角色
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    --XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_BASE_EQUIP_DATA_CHANGE_NOTIFY, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFRESH_CHRACTER_ABLIITY, self.RefreshAbility, self)
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_ABLITYCHANGE, self.RefreshAbility, self)

    if data then self:Sync(data) end
end

function XCharacter:RemoveEventListeners()
    --XEventManager.RemoveEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, self.RefreshAttribsByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BASE_EQUIP_DATA_CHANGE_NOTIFY, self.RefreshAttribsByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFRESH_CHRACTER_ABLIITY, self.RefreshAbility, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_ABLITYCHANGE, self.RefreshAbility, self)
end

function XCharacter:Sync(data)
    for k, v in pairs(data) do
        self[k] = v
    end
    self.UpdatedData = data
    -- 对视图数据更新
    if self.CharacterViewModel and self.CharacterViewModel:GetUpdatedData() ~= data then
        self.CharacterViewModel:UpdateWithData(data)
    end
    
    self:ChangeNpcId()
    self:UpdateSkillData(data.SkillList, true)
    self:CreateEnhanceSkillData()
    self:UpdateEnhanceSkillData(data.EnhanceSkillList, true)
    self:RefreshAttribs(true)
    self:RefreshAbility()
end

function XCharacter:GetSkillGroupData(skillGroupId)
    return self.__SkillGroupDatas[skillGroupId]
end

function XCharacter:UpdateSkillData(skillList, ignoreChangeAbility)
    XTool.LoopCollection(skillList, function(data)
        local skillId = data.Id

        local skillGroupId = XMVCA.XCharacter:GetSkillGroupIdAndIndex(skillId)
        if not skillGroupId then
            XLog.Error("XCharacter:UpdateSkillData Error: 角色技能数据同步错误，技能Id未配置在技能组中, skillId: " .. skillId)
            return
        end

        local skillGroupData = self:GetSkillGroupData(skillGroupId)
        if not skillGroupData then
            skillGroupData = XCharacterSkillGroup.New()
            self.__SkillGroupDatas[skillGroupId] = skillGroupData
        end

        skillGroupData:UpdateData(data)
    end)

    if not ignoreChangeAbility then
        self:RefreshAbility()
    end
end

function XCharacter:SwithSkill(skillId)
    local skillGroupId = XMVCA.XCharacter:GetSkillGroupIdAndIndex(skillId)
    local skillGroupData = self:GetSkillGroupData(skillGroupId)
    if not skillGroupData then return end
    skillGroupData:SwitchSkill(skillId)
end

function XCharacter:GetSkillLevelBySkillId(skillId)
    local skillGroupId = XMVCA.XCharacter:GetSkillGroupIdAndIndex(skillId)
    return self:GetSkillLevel(skillGroupId)
end

function XCharacter:GetSkillLevel(skillGroupId)
    local skillGroupData = self:GetSkillGroupData(skillGroupId)
    return skillGroupData and skillGroupData:GetLevel() or 0
end

function XCharacter:GetGroupCurSkillId(skillGroupId)
    local skillGroupData = self:GetSkillGroupData(skillGroupId)
    if not skillGroupData then
        return XMVCA.XCharacter:GetGroupDefaultSkillId(skillGroupId)
    end
    return skillGroupData:GetCurSKillId() or 0
end

function XCharacter:IsSkillUsing(skillId)
    if not skillId or skillId == 0 then return false end
    local skillGroupId = XMVCA.XCharacter:GetSkillGroupIdAndIndex(skillId)
    return self:GetGroupCurSkillId(skillGroupId) == skillId
end

function XCharacter:RefreshAttribs(ignoreChangeAbility)
    local attribs = XMVCA.XCharacter:GetCharacterAttribs(self)
    if attribs then
        self.Attribs = attribs
    end

    if not ignoreChangeAbility then
        self:RefreshAbility()
    end
end

function XCharacter:RefreshAttribsByEvent()
    self:RefreshAttribs()
end

function XCharacter:GetAttributes()
    return self.Attribs
end

function XCharacter:RefreshAbility()
    if self.IsOther then
        return
    end

    self.Ability = XMVCA.XCharacter:GetCharacterAbility(self)
end

function XCharacter:ChangeNpcId()
    local npcId = XMVCA.XCharacter:GetCharNpcId(self.Id, self.Quality)
    if npcId == nil then
        return
    end

    if self.NpcId and self.NpcId ~= npcId then
        self.NpcId = npcId
        self:ChangeType()
    end
end

function XCharacter:ChangeType()
    local npcTemplate = CS.XNpcManager.GetNpcTemplate(self.NpcId)
    if not npcTemplate then
        XLog.Error("XCharacter:ChangeType error: can not found npc template, npcId is " .. self.NpcId)
        return
    end

    self.Type = npcTemplate.Type
end

function XCharacter:IsContains(container, item)
    for _, v in pairs(container or {}) do
        if v == item then
            return true
        end
    end
    return false
end

function XCharacter:GetCharacterType()
    return self.Type
end

-- return : XCharacterViewModel
function XCharacter:GetCharacterViewModel()
    if self.CharacterViewModel == nil then
        self.CharacterViewModel = XCharacterViewModel.New(self.Id)
        self.CharacterViewModel:UpdateWithData(self.UpdatedData)
        self.CharacterViewModel:UpdateCharacter(self)
        self.CharacterViewModel:UpdateIsBelongPlayer(true)
    end
    return self.CharacterViewModel
end

function XCharacter:GetId()
    return self.Id
end

-------------------------补强技能相关---------------------------------
function XCharacter:GetEnhanceSkillCfg()
    return XMVCA.XCharacter:GetEnhanceSkillConfig(self:GetId()) or {}
end

function XCharacter:GetEnhanceSkillPosCfg()
    return XMVCA.XCharacter:GetEnhanceSkillPosConfig(self:GetId()) or {}
end

function XCharacter:GetEnhanceSkillGroupIdList()
    return self:GetEnhanceSkillCfg().SkillGroupId
end

function XCharacter:GetEnhanceSkillPosList()
    return self:GetEnhanceSkillCfg().Pos
end

function XCharacter:GetEnhanceSkillPosName(index)
    return self:GetEnhanceSkillPosCfg().MainSkillName and self:GetEnhanceSkillPosCfg().MainSkillName[index] or ""
end

function XCharacter:GetIsHasEnhanceSkill()
    if not self:GetEnhanceSkillGroupIdList() or not next(self:GetEnhanceSkillGroupIdList()) then
        return false
    else
        return true
    end
end

function XCharacter:GetEnhanceSkillGroupByPos(pos)
    return self.__EnhanceSkillGroupPosDic[pos]
end

function XCharacter:GetEnhanceSkillGroupDataDic()
    return self.__EnhanceSkillGroupDatas
end

---@return XEnhanceSkillGroup
function XCharacter:GetEnhanceSkillGroupData(skillGroupId)
    return self.__EnhanceSkillGroupDatas[skillGroupId]
end

function XCharacter:EnhanceSkillIdToGroupId(skillId)
    if not self.__EnhanceSkillIdToGroupIdDic[skillId] then
        XLog.Error("XCharacter:EnhanceSkillIdToGroupId Error: 角色补强技能Id未配置在技能组中, skillId: " .. skillId)
    end
    return self.__EnhanceSkillIdToGroupIdDic[skillId]
end

function XCharacter:CreateEnhanceSkillData()
    if not next(self.__EnhanceSkillGroupDatas) then
        local skillGroupIdList = self:GetEnhanceSkillGroupIdList()
        local skillPosList = self:GetEnhanceSkillPosList()
        for index,skillGroupId in pairs(skillGroupIdList or {}) do
            local pos = skillPosList[index]
            local skillGroup = XEnhanceSkillGroup.New(skillGroupId, pos)
            self.__EnhanceSkillGroupDatas[skillGroupId] = skillGroup
            self.__EnhanceSkillGroupPosDic[pos] = skillGroup
            self:CreateSkillIdToGroupIdDic(skillGroup)
        end
    end
end

function XCharacter:CreateSkillIdToGroupIdDic(skillGroup)
    local skillIdList = skillGroup:GetSkillIdList()
    for _,skillId in pairs(skillIdList or {}) do
        self.__EnhanceSkillIdToGroupIdDic[skillId] = skillGroup:GetSkillGroupId()
    end
end

function XCharacter:UpdateEnhanceSkillData(skillList, ignoreChangeAbility)
    XTool.LoopCollection(skillList, function(data)
            local skillId = data.Id

            local skillGroupId = self:EnhanceSkillIdToGroupId(skillId)
            if not skillGroupId then
                return
            end

            local skillGroupData = self:GetEnhanceSkillGroupData(skillGroupId)
            if not skillGroupData then
               return
            end
            
            local tagData = {
                Level = data.Level,
                IsUnLock = true,
                ActiveSkillId = data.Id,
            }
            skillGroupData:UpdateData(tagData)
        end)

    if not ignoreChangeAbility then
        self:RefreshAbility()
    end
end

function XCharacter:GetEnhanceSkillAbility()
    local skillAbility = 0
    for _, groupEntity in pairs(self.__EnhanceSkillGroupDatas or {}) do
        if groupEntity:GetIsUnLock() then
            skillAbility = skillAbility + groupEntity:GetAbility()
        end
    end
    return skillAbility
end