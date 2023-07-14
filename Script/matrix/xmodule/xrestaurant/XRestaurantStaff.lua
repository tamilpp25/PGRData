

local default = {
    _Id = 0,
    _Level = 0,
    _IsRecruit = false,
    _WorkBenchId = 0,
    _State = XRestaurantConfigs.WorkState.Free,
    _SkillIds = {},
}

---@class XRestaurantStaff : XDataEntityBase 餐厅员工类
---@field _Id number 员工Id
---@field _Level number 等级
---@field _IsRecruit boolean 是否招募
---@field _WorkBenchId number 工作台id
---@field _AreaType number 工作区域
---@field _SkillIds number[] 技能列表
---@field _State number 工作状态
local XRestaurantStaff = XClass(XDataEntityBase, "XRestaurantStaff")

function XRestaurantStaff:Ctor(id)
    self:Init(default, id)
end

function XRestaurantStaff:InitData(id)
    self:SetProperty("_Id", id)
end

--- 更新员工信息
---@param isRecruit boolean 是否招募
---@param level number 等级
---@return void
--------------------------
function XRestaurantStaff:UpdateInfo(isRecruit, level)
    self:SetProperty("_IsRecruit", isRecruit)
    self:SetProperty("_Level", level)
    self:_UpdateSkill()
end

--- 招募 
---@return boolean 是否招募成功
--------------------------
function XRestaurantStaff:Recruit()
    local recruit = self._IsRecruit
    if recruit then
        return false
    end
    self:SetProperty("_IsRecruit", true)
    self:SetProperty("_Level", XRestaurantConfigs.StaffLevel.Low)
    
    self:_UpdateSkill()
    
    return true
end

--- 生产
---@param workBenchId number 工作台id
---@param areaType number 工作区域
---@return void
--------------------------
function XRestaurantStaff:Produce(workBenchId, areaType)
    self:SetProperty("_WorkBenchId", workBenchId)
    self:SetProperty("_AreaType", areaType)
    local room = XDataCenter.RestaurantManager.GetRoom()
    room:AssignWork(self._Id, areaType, workBenchId)
end

--- 暂停
---@return void
--------------------------
function XRestaurantStaff:Pause()
    if self._State == XRestaurantConfigs.WorkState.Pause then
        return
    end
    self:SetProperty("_State", XRestaurantConfigs.WorkState.Pause)
    self:ChangeState()
end

--- 恢复工作
---@param 
---@return
--------------------------
function XRestaurantStaff:ReWork()
    if self._State == XRestaurantConfigs.WorkState.Working then
        return
    end
    self:SetProperty("_State", XRestaurantConfigs.WorkState.Working)
    self:ChangeState()
end

--- 停工
---@return void
--------------------------
function XRestaurantStaff:Stop()
    self:SetProperty("_WorkBenchId", 0)
    self:SetProperty("_State", XRestaurantConfigs.WorkState.Free)
    local room = XDataCenter.RestaurantManager.GetRoom()
    room:UnAssignWork(self._Id)
end

function XRestaurantStaff:ChangeState(state)
    local room = XDataCenter.RestaurantManager.GetRoom()
    room:ChangeStaffState(self._Id, state)
end

function XRestaurantStaff:GetName()
    return XRestaurantConfigs.GetCharacterName(self._Id)
end

function XRestaurantStaff:GetIcon()
    return XDormConfig.GetCharacterStyleConfigQSIconById(self._Id)
end

function XRestaurantStaff:IsWorking()
    return XTool.IsNumberValid(self._WorkBenchId) 
            and self._State == XRestaurantConfigs.WorkState.Working
end

function XRestaurantStaff:IsFree()
    return not XTool.IsNumberValid(self._WorkBenchId) or self._State == XRestaurantConfigs.WorkState.Free
end

--- 对以解锁产品是否有加成效果
---@return boolean
--------------------------
function XRestaurantStaff:IsAdditionOnUnlockProduct()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local unlockFoodMap = viewModel:GetProperty("_UnlockFood")
    for productId, _ in pairs(unlockFoodMap or {}) do
        if self:IsAddition(XRestaurantConfigs.AreaType.FoodArea, productId) 
                or self:IsAddition(XRestaurantConfigs.AreaType.SaleArea, productId) then
            return  true
        end
    end
    
    local unlockIngredientMap = viewModel:GetProperty("_UnlockIngredient")
    for productId, _ in pairs(unlockIngredientMap or {}) do
        if self:IsAddition(XRestaurantConfigs.AreaType.IngredientArea, productId) then
            return  true
        end
    end
    return false
end

--- 是否拥有加成效果
---@param areaType number
---@return boolean
--------------------------
function XRestaurantStaff:IsAddition(areaType, productId)
    for _, skillId in pairs(self._SkillIds or {}) do
        local type = XRestaurantConfigs.GetCharacterSkillAreaType(skillId)
        if type == areaType then
            local addition = XRestaurantConfigs.GetCharacterSkillAddition(skillId)
            if addition[productId] then
                return true
            end
        end
    end
    return false
end

--- 顶级时是否对区域加成
---@param areaType number
---@return boolean
--------------------------
function XRestaurantStaff:IsAdditionByAreaTypeWithMaxLevel(areaType)
    local skillIds = XRestaurantConfigs.GetCharacterSkillIds(self._Id, XRestaurantConfigs.StaffLevel.Max)
    return self:_IsAdditionByAreaType(areaType, skillIds)
end

--- 初级时是否对区域有加成效果
---@param areaType number
---@return boolean
--------------------------
function XRestaurantStaff:IsAdditionByAreaTypeWithLowLevel(areaType)
    local skillIds = XRestaurantConfigs.GetCharacterSkillIds(self._Id, XRestaurantConfigs.StaffLevel.Low)
    return self:_IsAdditionByAreaType(areaType, skillIds)
end

--- 当前等级对区域是否有加成效果
---@param areaType number
---@return boolean
--------------------------
function XRestaurantStaff:IsAdditionByAreaType(areaType)
    return self:_IsAdditionByAreaType(areaType, self._SkillIds)
end

function XRestaurantStaff:IsAdditionByAreaTypeWithLevel(areaType, level)
    if areaType == 0 then
        return true
    end
    local skillIds = XRestaurantConfigs.GetCharacterSkillIds(self._Id, level)
    return self:_IsAdditionByAreaType(areaType, skillIds)
end

function XRestaurantStaff:_IsAdditionByAreaType(areaType, skillIds)
    for _, skillId in pairs(skillIds or {}) do
        local type = XRestaurantConfigs.GetCharacterSkillAreaType(skillId)
        if type == areaType then
            return true
        end
    end
    return false
end

--- 获取技能加成值
---@param productId number
---@return number
--------------------------
function XRestaurantStaff:GetSkillAddition(areaType, productId)
    if not XTool.IsNumberValid(productId) then
        return 0
    end
    local add = 0
    for _, skillId in pairs(self._SkillIds or {}) do
        local type = XRestaurantConfigs.GetCharacterSkillAreaType(skillId)
        if type == areaType then
            local addition = XRestaurantConfigs.GetCharacterSkillAddition(skillId)
            if addition[productId] then
                add = add + addition[productId]
            end
        end
    end
    return add
end

--- 更新员工技能
---@return void
--------------------------
function XRestaurantStaff:_UpdateSkill()
    local skillIds = XRestaurantConfigs.GetCharacterSkillIds(self._Id, self._Level)
    self:SetProperty("_SkillIds", skillIds)
end

--- 等级描述
---@return string
--------------------------
function XRestaurantStaff:GetLevelStr()
    return XRestaurantConfigs.GetCharacterLevelStr(self._Level)
end

---@param staff XRestaurantStaff
---@return boolean
--------------------------
function XRestaurantStaff:Equal(staff)
    if not staff then
        return false
    end
    return self._Id == staff:GetProperty("_Id")
end

return XRestaurantStaff