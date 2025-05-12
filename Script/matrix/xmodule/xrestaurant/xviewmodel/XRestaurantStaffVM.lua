local XRestaurantViewModel = require("XModule/XRestaurant/XViewModel/XRestaurantViewModel")

---@class XRestaurantStaffVM : XRestaurantViewModel 员工视图数据
---@field Data XRestaurantStaffData
---@field _Model XRestaurantModel
---@field _OwnControl XRestaurantControl
local XRestaurantStaffVM = XClass(XRestaurantViewModel, "XRestaurantStaffVM")

--- 招募
--------------------------
function XRestaurantStaffVM:Recruit()
    --已经招募
    if self.Data:IsRecruit() then
        return
    end
    self:InitSkill()
    self.Data:Unlock()
end

--- 生产
---@param workbenchId number 工作台id
---@param areaType number 工作区域
--------------------------
function XRestaurantStaffVM:Produce(workbenchId, areaType)
    local room = self._OwnControl:GetRoom()
    self.Data:UpdateWorkbench(workbenchId, areaType)
    room:AssignWork(self:GetCharacterId(), areaType, workbenchId)
end

--- 暂停
--------------------------
function XRestaurantStaffVM:Pause()
    if self:IsPause() then
        return
    end
    self.Data:UpdateState(XMVCA.XRestaurant.WorkState.Pause)
    self:DoStateChanged()
end

--- 恢复工作
--------------------------
function XRestaurantStaffVM:ReWork()
    if self:IsWorking() then
        return
    end
    self.Data:UpdateState(XMVCA.XRestaurant.WorkState.Working)
    self:DoStateChanged()
end

--- 停工
--------------------------
function XRestaurantStaffVM:Stop()
    self.Data:UpdateWorkbench(0, XMVCA.XRestaurant.AreaType.None)
    self.Data:UpdateState(XMVCA.XRestaurant.WorkState.Free)
    self._OwnControl:GetRoom():UnAssignWork(self:GetCharacterId())
end

--- 状态更改
--------------------------
function XRestaurantStaffVM:DoStateChanged()
    self._OwnControl:GetRoom():ChangeStaffState(self:GetCharacterId(), self:GetState())
end

function XRestaurantStaffVM:UpdateSkill()
    local skillIds = self._Model:GetCharacterSkillIds(self:GetCharacterId(), self:GetLevel())
    self.Data:UpdateSkill(skillIds)
end

function XRestaurantStaffVM:UpdateViewModel()
    self:UpdateSkill()
end

--- 是否相等
---@param staff XRestaurantStaffVM 员工视图数据
---@return boolean
--------------------------
function XRestaurantStaffVM:Equal(staff)
    if not staff then
        return false
    end
    
    return staff:GetCharacterId() == self:GetCharacterId()
end

--region   ------------------getter start-------------------

function XRestaurantStaffVM:GetCharacterId()
    return self.Data:GetCharacterId()
end

function XRestaurantStaffVM:GetLevel()
    return self.Data:GetLevel()
end

function XRestaurantStaffVM:GetState()
    return self.Data:GetState()
end

function XRestaurantStaffVM:GetWorkBenchId()
    return self.Data:GetWorkBenchId()
end

function XRestaurantStaffVM:GetAreaType()
    return self.Data:GetAreaType()
end

function XRestaurantStaffVM:IsInWorkBench(areaType, workbenchId)
    if not XTool.IsNumberValid(areaType) then
        return false
    end
    if not XTool.IsNumberValid(workbenchId) then
        return false
    end
    return self:GetWorkBenchId() == workbenchId and self:GetAreaType() == areaType
end

function XRestaurantStaffVM:GetPriority()
    local template = self._Model:GetCharacterTemplate(self:GetCharacterId())
    return template and template.Priority or 0
end

--- 玩家技能id
---@return number[]
--------------------------
function XRestaurantStaffVM:GetSkillIds()
    return self.Data:GetSkillIds()
end

--- 预览某个等级的技能列表
---@param level number
---@return number[]
--------------------------
function XRestaurantStaffVM:GetSkillIdsInPreview(level)
    local template = self._Model:GetCharacterLevelTemplate(self:GetCharacterId(), level)
    return template and template.SkillId or {}
end

function XRestaurantStaffVM:GetName()
    local template = self._Model:GetCharacterTemplate(self:GetCharacterId())
    return template and template.Name or ""
end

function XRestaurantStaffVM:GetAffiliated()
    local template = self._Model:GetCharacterTemplate(self:GetCharacterId())
    return template and template.Affiliated or ""
end

function XRestaurantStaffVM:GetIcon()
    return XDormConfig.GetCharacterStyleConfigQSIconById(self:GetCharacterId())
end

function XRestaurantStaffVM:GetCharacterLevelLabelIcon()
    return self._Model:GetClientConfigValue("StaffLevelLabelIcon", self:GetLevel())
end

function XRestaurantStaffVM:GetLevelStr(level)
    if not level then
        level = self:GetLevel()
    end
    return self._Model:GetCharacterLevelStr(level)
end

function XRestaurantStaffVM:IsFree()
    return self:GetState() == XMVCA.XRestaurant.WorkState.Free
end

function XRestaurantStaffVM:IsPause()
    return self:GetState() == XMVCA.XRestaurant.WorkState.Pause
end

function XRestaurantStaffVM:IsWorking()
    return self:GetState() == XMVCA.XRestaurant.WorkState.Working
end

function XRestaurantStaffVM:IsRecruit()
    return self.Data:IsRecruit()
end

--- 获取技能加成值
---@param areaType number
---@param productId number
---@return number
--------------------------
function XRestaurantStaffVM:GetSkillAddition(areaType, productId)
    if not XTool.IsNumberValid(productId) then
        return 0
    end
    local add = 0
    local skillIds = self:GetSkillIds()
    for _, skillId in ipairs(skillIds) do
        local targetType = self:GetCharacterSkillAreaType(skillId)
        if targetType == areaType then
            local dict = self:GetCharacterSkillAddition(skillId)
            if dict and dict[productId] then
                add = add + dict[productId]
            end
        end
    end
    return add
end

function XRestaurantStaffVM:GetCharacterSkillAddition(skillId)
    return self._Model:GetCharacterSkillAddition(skillId)
end

function XRestaurantStaffVM:GetCharacterSkillAreaType(skillId)
    return self._Model:GetCharacterSkillAreaType(skillId)
end

function XRestaurantStaffVM:GetCharacterSkillName(skillId)
    local template = self._Model:GetCharacterSkillTemplate(skillId)
    return template and template.Name or ""
end

function XRestaurantStaffVM:GetCharacterSkillDesc(skillId)
    local template = self._Model:GetCharacterSkillTemplate(skillId)
    return template and template.Desc or ""
end

function XRestaurantStaffVM:GetCharacterSkillLabelIcon(areaType, isSmall)
    if not self._CharacterSkillTypeLabelIcon then
        self._CharacterSkillTypeLabelIcon = {}
    end
    if not self._CharacterSkillTypeLabelIcon[areaType] then
        local template = self._Model:GetCharacterSkillTypeTemplate(areaType)
        local icons = string.Split(template.LabelIcon, "|") or {}
        self._CharacterSkillTypeLabelIcon[areaType] = {
            Big = icons[1],
            Small = icons[2],
        }
    end
    return isSmall and self._CharacterSkillTypeLabelIcon[areaType].Small or self._CharacterSkillTypeLabelIcon[areaType].Big
end

function XRestaurantStaffVM:GetCharacterSkillTypeName(areaType)
    local template = self._Model:GetCharacterSkillTypeTemplate(areaType)
    return template and template.Name or ""
end

--- 对此产品是否有增益效果
---@param areaType number 工作区域
---@param productId number 产品Id
---@return boolean
--------------------------
function XRestaurantStaffVM:IsAddition(areaType, productId)
    local skillIds = self:GetSkillIds()
    if XTool.IsTableEmpty(skillIds) then
        return false
    end

    for _, skillId in ipairs(skillIds) do
        local targetType = self:GetCharacterSkillAreaType(skillId)
        if targetType == areaType then
            local dict = self._Model:GetCharacterSkillAddition(skillId)
            if dict and dict[productId] then
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
function XRestaurantStaffVM:IsAdditionByAreaTypeWithMaxLevel(areaType)
    return self:IsAdditionByAreaTypeWithLevel(areaType, XMVCA.XRestaurant.StaffLevelRange.Max)
end

--- 初级时是否对区域有加成效果
---@param areaType number
---@return boolean
--------------------------
function XRestaurantStaffVM:IsAdditionByAreaTypeWithLowLevel(areaType)
    return self:IsAdditionByAreaTypeWithLevel(areaType, XMVCA.XRestaurant.StaffLevelRange.Low)
end

--- 当前等级对区域是否有加成效果
---@param areaType number 
---@param level number 
---@return boolean
--------------------------
function XRestaurantStaffVM:IsAdditionByAreaTypeWithLevel(areaType, level)
    if areaType == XMVCA.XRestaurant.AreaType.None then
        return true
    end

    if not level then
        level = self:GetLevel()
    end
    
    local skillIds = self._Model:GetCharacterSkillIds(self:GetCharacterId(), level)
    return self._Model:IsAdditionByAreaType(areaType, skillIds)
end

--- 获取多个技能对某个区域的产品加成
---@param areaType number 工作区域
---@param productId number 产品Id
---@return number
--------------------------
function XRestaurantStaffVM:GetCharacterSkillTotalAddition(areaType, productId)
    return self._Model:GetCharacterSkillTotalAddition(self:GetSkillIds(), areaType, productId)
end

function XRestaurantStaffVM:GetCharacterSkillAdditionList(skillId)
    local template = self._Model:GetCharacterSkillTemplate(skillId)
    local list = {}
    if XTool.IsTableEmpty(template.ProductId) then
        return list
    end
    for idx, productId in ipairs(template.ProductId) do

        table.insert(list, {
            Id = productId,
            Addition = template.SkillAddition[idx] or 0,
            AreaType = template.SectionType
        })
    end

    return list
end

--- 当前等级升级到下级所需材料
---@param level number 角色当前等级
--------------------------
function XRestaurantStaffVM:GetCharacterLevelUpConsume(level)
    local template = self._Model:GetCharacterLevelTemplate(self:GetCharacterId(), level)
    local consume = {}
    if XTool.IsTableEmpty(template.UpgradeNeedItemId) then
        return consume
    end
    for idx, itemId in ipairs(template.UpgradeNeedItemId) do
        local item = {
            ItemId = itemId,
            Count = template.UpgradeNeedItemCount and template.UpgradeNeedItemCount[idx] or 0
        }
        table.insert(consume, item)
    end
    return consume
end

--- 获取角色招募消耗
--------------------------
function XRestaurantStaffVM:GetCharacterEmployConsume()
    local consume = {}
    local template = self._Model:GetCharacterTemplate(self:GetCharacterId())
    if XTool.IsTableEmpty(template.EmployNeedItemId) then
        return consume
    end
    for idx, itemId in ipairs(template.EmployNeedItemId) do

        local item = {
            ItemId = itemId,
            Count = template.EmployNeedItemCount and template.EmployNeedItemCount[idx] or 0
        }
        table.insert(consume, item)
    end
    return consume
end

--endregion------------------getter finish------------------

return XRestaurantStaffVM