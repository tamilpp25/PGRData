
local XRestaurantData = require("XModule/XRestaurant/XData/XRestaurantData")

---@class XRestaurantStaffData : XRestaurantData 单个员工数据
---@field ViewModel XRestaurantStaffVM
local XRestaurantStaffData = XClass(XRestaurantData, "XRestaurantStaffData")

--[[ Properties
    CharacterId 员工Id
    CharacterLv 员工等级
    IsRecruit 是否招募
    WorkBenchId 工作台Id
    State 工作状态
    SkillIds 技能列表
]]

local Properties = {
    CharacterId = "CharacterId",
    CharacterLv = "CharacterLv",
    IsRecruit = "IsRecruit",
    WorkBenchId = "WorkBenchId",
    State = "State",
    AreaType = "AreaType",
    SkillIds = "SkillIds"
}

function XRestaurantStaffData:InitData(characterId)
    self.Data = {
        CharacterId = characterId,
        CharacterLv = XMVCA.XRestaurant.StaffLevelRange.Low,
        IsRecruit = false,
        WorkBenchId = 0,
        State = XMVCA.XRestaurant.WorkState.Free,
        AreaType = XMVCA.XRestaurant.AreaType.None,
        SkillIds = {}
    }
end

function XRestaurantStaffData:GetPropertyNameDict()
    return Properties
end

function XRestaurantStaffData:UpdateData(charId, level)
    self:SetProperty(Properties.CharacterId, charId)
    self:SetProperty(Properties.CharacterLv, level)
    self:Unlock()
    if self.ViewModel then
        self.ViewModel:UpdateViewModel()
    end
end

function XRestaurantStaffData:GetCharacterId()
    return self:GetProperty(Properties.CharacterId) or 0
end

function XRestaurantStaffData:GetLevel()
    return self:GetProperty(Properties.CharacterLv) or 0
end

function XRestaurantStaffData:UpdateLevel(level)
    local level = XMVCA.XRestaurant:GetSafeStaffLevel(level)
    self:SetProperty(Properties.CharacterLv, level)
end

function XRestaurantStaffData:IsRecruit()
    return self:GetProperty(Properties.IsRecruit) or false
end

function XRestaurantStaffData:Unlock()
    self:SetProperty(Properties.IsRecruit, true)
end

function XRestaurantStaffData:UpdateSkill(skillIds)
    self:SetProperty(Properties.SkillIds, skillIds)
end

function XRestaurantStaffData:GetSkillIds()
    return self:GetProperty(Properties.SkillIds)
end

function XRestaurantStaffData:UpdateWorkbench(workbenchId, areaType)
    self:SetProperty(Properties.WorkBenchId, workbenchId)
    self:SetProperty(Properties.AreaType, areaType)
end

function XRestaurantStaffData:GetWorkBenchId()
    return self:GetProperty(Properties.WorkBenchId) or 0
end

function XRestaurantStaffData:GetState()
    return self:GetProperty(Properties.State)
end

function XRestaurantStaffData:UpdateState(state)
    self:SetProperty(Properties.State, state)
end

function XRestaurantStaffData:GetAreaType()
    return self:GetProperty(Properties.AreaType)
end

---@class XRestaurantStaffMgt 员工管理数据
---@field StaffMap table<number, XRestaurantStaffData>
local XRestaurantStaffMgt = XClass(nil, "XRestaurantStaffMgt")

function XRestaurantStaffMgt:Ctor()
    self.StaffMap = {}
end

--- 更新已经解锁的员工信息
--------------------------
function XRestaurantStaffMgt:UpdateData(charList)
    if XTool.IsTableEmpty(charList) then
        return
    end
    for _, info in ipairs(charList) do
        local charId = info.CharacterId
        local staff = self:GetStaffData(charId)
        staff:UpdateData(charId, info.CharacterLv)
    end
end

--- 获取员工数据
---@param charId number 员工Id
---@return XRestaurantStaffData
--------------------------
function XRestaurantStaffMgt:GetStaffData(charId)
    local staff = self.StaffMap[charId]
    if not staff then
        staff = XRestaurantStaffData.New(charId)
        self.StaffMap[charId] = staff
    end
    return staff
end

--- 获取大于目标等级的员工人数
---@param level number 目标等级
---@return number
--------------------------
function XRestaurantStaffMgt:GetGreaterLevelCharacterCount(level)
    local count = 0
    for _, staff in pairs(self.StaffMap) do
        if staff:IsRecruit() and staff:GetLevel() >= level then
            count = count + 1
        end
    end
    return count
end

return XRestaurantStaffMgt