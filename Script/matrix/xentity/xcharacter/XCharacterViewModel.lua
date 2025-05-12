---@class XCharacterViewModel
local XCharacterViewModel = XClass(nil, "XCharacterViewModel")

function XCharacterViewModel:Ctor(characterCid)
    self.Config = XMVCA.XCharacter:GetCharacterTemplate(characterCid)
    self.ProfessionType = nil
    -- 解放等级
    self.LiberateLv = 0
    self.FashionId = nil
    -- 该角色是否属于玩家
    self.IsBelongPlayer = false
    -- XCharacter
    self.Character = nil
    self.UpdatedData = nil
    -- 来源实体Id，默认读取角色的
    self.SourceEntityId = characterCid
    -- 队长技能等级
    self._CaptainSkillLevel = false
    -- 初始化来自XCharacter的默认字段,保持一致性
    for key, value in pairs(XCharacter.GetDefaultFields()) do
        if type(value) == "table" then
            self[key] = XTool.Clone(value)
        else
            self[key] = value
        end
    end
    self.Id = self.Config.Id
end

-- data : 同XCharacter.GetDefaultFields()一致
function XCharacterViewModel:UpdateWithData(data)
    self.UpdatedData = data
    for key, value in pairs(data) do
        self[key] = value
    end
end

function XCharacterViewModel:UpdateAbility(value)
    self.Ability = value
end

function XCharacterViewModel:UpdateSourceEntityId(value)
    self.SourceEntityId = value
end

function XCharacterViewModel:UpdateFashionId(value)
    self.FashionId = value
end

function XCharacterViewModel:UpdateLiberateLv(value)
    self.LiberateLv = value
end

function XCharacterViewModel:UpdateIsBelongPlayer(value)
    self.IsBelongPlayer = value
end

-- value : XCharacter
function XCharacterViewModel:UpdateCharacter(value)
    self.Character = value
end

function XCharacterViewModel:UpdateCaptainSkillLevelByList(skillList)
    local characterId = self:GetId()
    local captainSkillId = XMVCA.XCharacter:GetCharacterCaptainSkill(characterId)
    local captainLevel = 0
    for i = 1, #skillList do
        local skillData = skillList[i]
        local skillId = skillData.Id
        if captainSkillId == skillId then
            captainLevel = skillData.Level
        end
    end
    self._CaptainSkillLevel = captainLevel
end

function XCharacterViewModel:GetId()
    return self.Id
end

function XCharacterViewModel:GetCharacter()
    if self.Character == nil then
        self.Character = XCharacter.New(self.UpdatedData)
        self.Character:RemoveEventListeners()
    end
    return self.Character
end

function XCharacterViewModel:GetSourceEntityId()
    return self.SourceEntityId
end

function XCharacterViewModel:GetConfigId()
    return self.Config.Id
end

function XCharacterViewModel:GetUpdatedData()
    return self.UpdatedData
end

function XCharacterViewModel:GetName()
    return self.Config.Name
end

function XCharacterViewModel:GetEnName()
    return self.Config.EnName
end

function XCharacterViewModel:GetLogName()
    return self.Config.LogName
end

function XCharacterViewModel:GetFashionId()
    return self.FashionId
end

function XCharacterViewModel:GetLevel()
    return self.Level
end

function XCharacterViewModel:GetQuality()
    return self.Quality
end

-- 型号名称
function XCharacterViewModel:GetTradeName()
    return self.Config.TradeName
end

function XCharacterViewModel:GetFullName()
    return XUiHelper.GetText("CharacterFullName", self:GetName(), self:GetTradeName())
end

-- 职业类型
function XCharacterViewModel:GetProfessionType()
    if self.ProfessionType == nil then
        local npcId = XMVCA.XCharacter:GetCharNpcId(self.Config.Id, self.Quality)
        local npcConfig = XMVCA.XCharacter:GetNpcTemplate(npcId)
        self.ProfessionType = npcConfig and npcConfig.Type or 0
    end
    return self.ProfessionType
end

-- 职业图标
function XCharacterViewModel:GetProfessionIcon()
    return XMVCA.XCharacter:GetNpcTypeIcon(self:GetProfessionType())
end

-- 品质图标
function XCharacterViewModel:GetQualityIcon()
    return XMVCA.XCharacter:GetCharacterQualityIcon(self.Quality)
end

function XCharacterViewModel:GetSmallHeadIcon()
    return XMVCA.XCharacter:GetCharSmallHeadIcon(self.Config.Id, not self.IsBelongPlayer)
end

function XCharacterViewModel:GetBigHeadIcon()
    return XMVCA.XCharacter:GetCharBigHeadIcon(self.Config.Id, not self.IsBelongPlayer)
end

function XCharacterViewModel:GetHalfBodyIcon()
    --获得角色半身像（剧情用）
    return XMVCA.XCharacter:GetCharHalfBodyBigImage(self.Config.Id)
end

function XCharacterViewModel:GetHalfBodyCommonIcon()
    --获得角色半身像（通用）
    return XMVCA.XCharacter:GetCharHalfBodyImage(self.Config.Id)
end

function XCharacterViewModel:GetGradeLevel()
    return self.Grade
end

function XCharacterViewModel:GetGradeIcon()
    return XMVCA.XCharacter:GetCharGradeIcon(self.Config.Id, self.Grade)
end

function XCharacterViewModel:GetAbility()
    if self.IsBelongPlayer and self.Character then
        return self.Character.Ability
    end
    return self.Ability
end

function XCharacterViewModel:GetCareer()
    return XMVCA.XCharacter:GetCharDetailCareer(self.Config.Id)
end

-- 获取能量元素（物理，火，暗...）
function XCharacterViewModel:GetObtainElements()
    return XMVCA.XCharacter:GetCharacterAllElement(self.Config.Id, true)
end

-- 获取能量元素图标（物理，火，暗...）
function XCharacterViewModel:GetObtainElementIcons()
    local result = {}
    local obtainElements = self:GetObtainElements()
    local elementConfig = nil
    for _, v in ipairs(obtainElements) do
        elementConfig = XMVCA.XCharacter:GetCharElement(v)
        table.insert(result, elementConfig.Icon)
    end
    return result
end

-- equipViewModels : XEquipViewModel array
function XCharacterViewModel:GetAttributes(equipViewModels)
    local character = self:GetCharacter()
    -- 如果是属于自身玩家的数据，直接返回原来的写法
    if self.IsBelongPlayer then
        return character:GetAttributes()
    end
    local equips = {}
    for _, value in ipairs(equipViewModels or {}) do
        table.insert(equips, value:GetEquip())
    end
    self.Attribs = XMVCA.XCharacter:GetCharacterAttribsOther(character, equips)
    return self.Attribs
end

-- 获取队长技能信息
function XCharacterViewModel:GetCaptainSkillInfo()
    local result
    if XRobotManager.CheckIsRobotId(self.SourceEntityId) then
        result = XRobotManager.GetRobotCaptainSkillInfo(self.SourceEntityId)
    elseif self.IsBelongPlayer then
        result = XMVCA.XCharacter:GetCaptainSkillInfoByCharId(self.SourceEntityId)
    else
        -- 可能存在第三种情况，是角色同时不属于玩家本身，后面有业务需求再扩展
        local skillLevel = self._CaptainSkillLevel or 1 
        result = XMVCA.XCharacter:GetCaptainSkillInfo(self.SourceEntityId, skillLevel)
    end
    return result
end

-- return : XEnumConst.CHARACTER.CharacterType
function XCharacterViewModel:GetCharacterType()
    return XMVCA.XCharacter:GetCharacterType(self.Config.Id)
end

-- 获得当前经验
function XCharacterViewModel:GetCurExp()
    local character = self:GetCharacter()
    return character.Exp
end

-- 获得升至下一等级的经验
function XCharacterViewModel:GetNextLevelExp()
    local character = self:GetCharacter()
    local charId = self:GetId()
    return XMVCA.XCharacter:GetNextLevelExp(charId, character.Level)
end

-- 获得满级
function XCharacterViewModel:GetMaxLevel()
    local character = self:GetCharacter()
    local charId = self:GetId()
    return XMVCA.XCharacter:GetCharMaxLevel(charId)
end

function XCharacterViewModel:UpdateByFightNpcData(fightNpcData)
    self:UpdateWithData(fightNpcData.Character)
    self:UpdateAbility(fightNpcData.Character.Ability)
    self:UpdateFashionId(fightNpcData.Character.FashionId)
    self:UpdateLiberateLv(fightNpcData.Character.LiberateLv)
    self:UpdateSourceEntityId(fightNpcData.Character.Id)
    local skillList = fightNpcData.Character.SkillList
    self:UpdateCaptainSkillLevelByList(skillList)
end

return XCharacterViewModel