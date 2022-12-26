local XCharacterViewModel = require("XEntity/XCharacter/XCharacterViewModel")
local XCharacterSkillGroup = require("XEntity/XCharacter/XCharacterSkillGroup")

local type = type

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
    Attribs = {},
    __SkillGroupDatas = {},
}

function XCharacter.GetDefaultFields()
    return Default
end

function XCharacter:Ctor(data)
    -- XCharacterViewModel
    self.CharacterViewModel = nil 
    self.UpdatedData = nil
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_PUTON_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_RESONANCE_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_AWAKE_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_BASE_EQUIP_DATA_CHANGE_NOTIFY, self.RefreshAttribsByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFRESH_CHRACTER_ABLIITY, self.RefreshAbility, self)
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_ABLITYCHANGE, self.RefreshAbility, self)
    
    if data then self:Sync(data) end
end

function XCharacter:RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, self.RefreshAttribsByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_PUTON_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_RESONANCE_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY, self.RefreshAttribsByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_AWAKE_NOTYFY, self.RefreshAttribsByEvent, self)
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
    self:RefreshAttribs(true)
    self:RefreshAbility()
end

function XCharacter:GetSkillGroupData(skillGroupId)
    return self.__SkillGroupDatas[skillGroupId]
end

function XCharacter:UpdateSkillData(skillList, ignoreChangeAbility)
    XTool.LoopCollection(skillList, function(data)
        local skillId = data.Id

        local skillGroupId = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
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
    local skillGroupId = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    local skillGroupData = self:GetSkillGroupData(skillGroupId)
    if not skillGroupData then return end
    skillGroupData:SwitchSkill(skillId)
end

function XCharacter:GetSkillLevelBySkillId(skillId)
    local skillGroupId = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    return self:GetSkillLevel(skillGroupId)
end

function XCharacter:GetSkillLevel(skillGroupId)
    local skillGroupData = self:GetSkillGroupData(skillGroupId)
    return skillGroupData and skillGroupData:GetLevel() or 0
end

function XCharacter:GetGroupCurSkillId(skillGroupId)
    local skillGroupData = self:GetSkillGroupData(skillGroupId)
    if not skillGroupData then
        return XCharacterConfigs.GetGroupDefaultSkillId(skillGroupId)
    end
    return skillGroupData:GetCurSKillId() or 0
end

function XCharacter:IsSkillUsing(skillId)
    if not skillId or skillId == 0 then return false end
    local skillGroupId = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    return self:GetGroupCurSkillId(skillGroupId) == skillId
end

function XCharacter:RefreshAttribs(ignoreChangeAbility)
    local attribs = XDataCenter.CharacterManager.GetCharacterAttribs(self)
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
    self.Ability = XDataCenter.CharacterManager.GetCharacterAbility(self)
end

function XCharacter:ChangeNpcId()
    local npcId = XCharacterConfigs.GetCharNpcId(self.Id, self.Quality)
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