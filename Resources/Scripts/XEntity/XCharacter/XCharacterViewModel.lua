local XCharacterViewModel = XClass(nil, "XCharacterViewModel")

--######################## 静态方法 begin ########################

-- 已废弃，使用XEntityHelper.GetCharacterName
function XCharacterViewModel.GetNameById(id)
    local config = XCharacterConfigs.GetCharacterTemplate(id)
    if not config then return "none" end
    return config.Name
end

-- 已废弃，使用XEntityHelper.GetCharacterSmallIcon
function XCharacterViewModel.GetSmallIconById(id)
    return XDataCenter.CharacterManager.GetCharSmallHeadIcon(id, 0, true)
end

--######################## 静态方法 end ########################

function XCharacterViewModel:Ctor(characterCid)
    self.Config = XCharacterConfigs.GetCharacterTemplate(characterCid)
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

-- 职业类型
function XCharacterViewModel:GetProfessionType()
    if self.ProfessionType == nil then
        local npcId = XCharacterConfigs.GetCharNpcId(self.Config.Id, self.Quality)
        local npcConfig = XCharacterConfigs.GetNpcTemplate(npcId)
        self.ProfessionType = npcConfig and npcConfig.Type or 0
    end
    return self.ProfessionType
end

-- 职业图标
function XCharacterViewModel:GetProfessionIcon()
    return XCharacterConfigs.GetNpcTypeIcon(self:GetProfessionType())
end

-- 品质图标
function XCharacterViewModel:GetQualityIcon()
    return XCharacterConfigs.GetCharacterQualityIcon(self.Quality)
end

function XCharacterViewModel:GetSmallHeadIcon()
    return XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.Config.Id, self.LiberateLv, not self.IsBelongPlayer, self.FashionId)
end

function XCharacterViewModel:GetBigHeadIcon()
    return XDataCenter.CharacterManager.GetCharBigHeadIcon(self.Config.Id, self.LiberateLv, not self.IsBelongPlayer, self.FashionId)
end

function XCharacterViewModel:GetHalfBodyIcon() --获得角色半身像（剧情用）
    return XDataCenter.CharacterManager.GetCharHalfBodyBigImage(self.Config.Id)
end

function XCharacterViewModel:GetHalfBodyCommonIcon() --获得角色半身像（通用）
    return XDataCenter.CharacterManager.GetCharHalfBodyImage(self.Config.Id)
end

function XCharacterViewModel:GetGradeLevel()
    return self.Grade
end

function XCharacterViewModel:GetGradeIcon()
    return XCharacterConfigs.GetCharGradeIcon(self.Config.Id, self.Grade)
end

function XCharacterViewModel:GetAbility()
    if self.IsBelongPlayer and self.Character then
        return self.Character.Ability
    end
    return self.Ability
end

function XCharacterViewModel:GetCareer()
    return XCharacterConfigs.GetCharDetailTemplate(self.Config.Id).Career
end

-- 获取能量元素（物理，火，暗...）
function XCharacterViewModel:GetObtainElements()
    return XCharacterConfigs.GetCharDetailTemplate(self.Config.Id).ObtainElementList
end

-- 获取能量元素图标（物理，火，暗...）
function XCharacterViewModel:GetObtainElementIcons()
    local result = {}
    local obtainElements = self:GetObtainElements()
    local elementConfig = nil
    for _, v in ipairs(obtainElements) do
        elementConfig = XCharacterConfigs.GetCharElement(v)
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
    self.Attribs = XDataCenter.CharacterManager.GetCharacterAttribsOther(character, equips)
    return self.Attribs
end

-- 获取队长技能信息
function XCharacterViewModel:GetCaptainSkillInfo()
    local result
    if XRobotManager.CheckIsRobotId(self.SourceEntityId) then
        result = XRobotManager.GetRobotCaptainSkillInfo(self.SourceEntityId)
    elseif self.IsBelongPlayer then
        result = XDataCenter.CharacterManager.GetCaptainSkillInfo(self.SourceEntityId)
    -- 可能存在第三种情况，是角色同时不属于玩家本身，后面有业务需求再扩展
    end
    return result
end

-- return : XCharacterConfigs.CharacterType
function XCharacterViewModel:GetCharacterType()
    return XCharacterConfigs.GetCharacterType(self.Config.Id)
end

return XCharacterViewModel