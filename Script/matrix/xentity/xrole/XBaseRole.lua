--===================
--基础角色数据(同时用于Robot和Character)
--===================
---@class XBaseRole
local XBaseRole = XClass(nil, "XBaseRole")

function XBaseRole:Ctor(rawData)
    self.RawData = rawData
end

--==================
--获取Id
--==================
function XBaseRole:GetId()
    return self.RawData.Id
end


function XBaseRole:GetName()
    local charaViewModel = self:GetCharacterViewModel()
    return charaViewModel and charaViewModel:GetName()
end

function XBaseRole:GetCareer()
    local charaViewModel = self:GetCharacterViewModel()
    return charaViewModel and charaViewModel:GetCareer()
end

function XBaseRole:GetTradeName()
    local charaViewModel = self:GetCharacterViewModel()
    return charaViewModel and charaViewModel:GetTradeName()
end

function XBaseRole:GetObtainElementIcons()
    local charaViewModel = self:GetCharacterViewModel()
    return charaViewModel and charaViewModel:GetObtainElementIcons()
end

function XBaseRole:GetLevel()
    local charaViewModel = self:GetCharacterViewModel()
    return charaViewModel and charaViewModel:GetLevel()
end

--==================
--检查是否是机器人
--==================
function XBaseRole:GetIsRobot()
    return XRobotManager.CheckIsRobotId(self.RawData.Id)
end
--==================
--获取角色ViewModel
--==================
function XBaseRole:GetCharacterViewModel()
    return self.RawData:GetCharacterViewModel()
end

function XBaseRole:GetCharacterType()
    return self.RawData:GetCharacterViewModel():GetCharacterType()
end
--==================
--获取CharacterId
--==================
function XBaseRole:GetCharacterId()
    if XRobotManager.CheckIsRobotId(self.RawData.Id) then
        local robotConfig = XRobotManager.GetRobotTemplate(self.RawData.Id)
        return robotConfig.CharacterId
    else
        return self.RawData.Id
    end
end
--==================
--获取角色小头像
--==================
function XBaseRole:GetSmallHeadIcon()
    return self:GetCharacterViewModel():GetSmallHeadIcon()
end

function XBaseRole:GetBigHeadIcon()
    return self:GetCharacterViewModel():GetBigHeadIcon()
end
--==================
--获得角色半身像（大半身像，一般剧情用）
--==================
function XBaseRole:GetHalfBodyIcon() --获得角色半身像（剧情用）
    return self:GetCharacterViewModel():GetHalfBodyIcon()
end
--==================
--获得角色半身像（通用）
--==================
function XBaseRole:GetHalfBodyCommonIcon()
    return self:GetCharacterViewModel():GetHalfBodyCommonIcon()
end
--==================
--获得角色阶级
--==================
function XBaseRole:GetQuality()
    if self:GetIsRobot() then
        return self.RawData.Character.Quality
    else
        return self.RawData.Quality
    end
end
--==================
--获得角色阶级图标
--==================
function XBaseRole:GetQualityIcon()
    local quality = self:GetQuality()
    return XMVCA.XCharacter:GetCharacterQualityIcon(quality)
end
--==================
--获取当前角色战力
--==================
function XBaseRole:GetAbility()
    return self:GetCharacterViewModel():GetAbility()
end
--==================
--获取队长技能描述
--==================
function XBaseRole:GetCaptainSkillDesc()
    if self:GetIsRobot() then
        return XRobotManager.GetRobotCaptainSkillDesc(self.RawData.Id)
    else
        return XMVCA.XCharacter:GetCaptainSkillDesc(self.RawData.Id)
    end
end
--==================
--获取伙伴对象
--==================
function XBaseRole:GetPartner()
    local result
    if XRobotManager.CheckIsRobotId(self.RawData.Id) then
        result = self.RawData:GetPartner()
    else
        result = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(self.RawData.Id)
    end
    return result
end
--==================
--获取装备视图
--==================
function XBaseRole:GetEquipViewModels()
    local result = {}
    if XRobotManager.CheckIsRobotId(self.RawData.Id) then
        result = self.RawData:GetEquipViewModels()
    end
    return result
end
--==================
--获取职业图标
--==================
function XBaseRole:GetCareerIcon()
    return XMVCA.XCharacter:GetNpcTypeIcon(self:GetCareer())
end
--==================
--检查是否授格者
--==================
function XBaseRole:CheckIsIsomer()
    return XMVCA.XCharacter:GetIsIsomer(self:GetCharacterId())
end

function XBaseRole:GetFashionId()
    return self.RawData:GetCharacterViewModel():GetFashionId()
end
--==================
--获取角色正在装备的武器Id
--==================
function XBaseRole:GetUsingWeaponId()
    if self:GetIsRobot() then
        local robotCfg = XRobotManager.GetRobotTemplate(self.RawData.Id)
        return robotCfg and robotCfg.WeaponId
    else
        return XDataCenter.EquipManager.GetCharacterWearingWeaponId(self:GetCharacterId())
    end
end

function XBaseRole:GetWeaponEquipView()
    if self:GetIsRobot() then
        return self.RawData:GetWeaponViewModel()      
    else
        local weapon = XDataCenter.EquipManager.GetCharacterWearingWeapon(self:GetCharacterId())
        if not weapon then return end
        local equip = XDataCenter.EquipManager.GetEquip(weapon.Id)
        return equip and equip:GetEquipViewModel()
    end
end
--==================
--根据意识位置获取角色正在装备的意识
--==================
function XBaseRole:GetWearingAwarenessBySiteId(siteId)
    if self:GetIsRobot() then
        local robotCfg = XRobotManager.GetRobotTemplate(self.RawData.Id)
        return robotCfg and robotCfg.WaferId[siteId]
    else
        XDataCenter.EquipManager.GetWearingEquipIdBySite(self:GetCharacterId(), siteId)
    end
end

function XBaseRole:GetAwarenessEquipViewBySiteId(siteId)
    if self:GetIsRobot() then
        local dic = self.RawData:GetAwarenessViewModelDic()
        return dic[siteId]
    else
        local awareness = XDataCenter.EquipManager.GetWearingEquipBySite(self:GetCharacterId(), siteId)
        if not awareness then return end
        local equip = XDataCenter.EquipManager.GetEquip(awareness.Id)
        return equip and equip:GetEquipViewModel()
    end
end

return XBaseRole