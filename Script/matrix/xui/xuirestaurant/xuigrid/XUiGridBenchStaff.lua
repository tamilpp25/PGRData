
---@class XUiGridBenchStaff : XUiNode
---@field _Control XRestaurantControl
local XUiGridBenchStaff = XClass(XUiNode, "XUiGridBenchStaff")

function XUiGridBenchStaff:OnStart(onClick)
    self.OnClick = onClick

    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
    self.GridSkill = {}
    self.TxtOne.gameObject:SetActiveEx(false)
end

--- 刷新显示
---@param staff XRestaurantStaffVM
--------------------------
function XUiGridBenchStaff:Refresh(staff, areaType, index, selectId)
    if not staff then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.Staff = staff
    self.AreaType = areaType
    self.Index = index
    self.TxtName.text = string.format("%s(%s)", staff:GetName(), staff:GetLevelStr())
    self.RImgIcon:SetRawImage(staff:GetIcon())
    
    self:SetSelect(staff:GetCharacterId() == selectId)
    self.ImgWorking.gameObject:SetActiveEx(not staff:IsFree())
    self.PanelDisable.gameObject:SetActiveEx(not staff:IsRecruit())
    self:RefreshAddition()
end

function XUiGridBenchStaff:RefreshAddition()
    for _, grid in pairs(self.GridSkill) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
    local bench = self._Control:GetWorkbench(self.AreaType, self.Index)
    local handleProductId = bench:GetProductId()
    
    local index = 1
    index = self:RefreshSkill(index, handleProductId)
    
    local buff = self._Control:GetAreaBuff(self.AreaType)
    local buffAddition = buff and buff:GetEffectAddition(self.AreaType, self.Staff:GetCharacterId(), handleProductId) or 0
    
    if buffAddition > 0 then
        local grid = self:GetGridSkill(index)
        grid.TxtSkill.text = buff:GetName()
        grid.TxtPercent.text = self._Control:GetCharacterSkillPercentAddition(buffAddition, self.AreaType, 
                handleProductId)
        grid.ImgIcon:SetSprite( self._Control:GetAdditionIcon(true))

    end
    
    local addition = self.Staff:GetSkillAddition(self.AreaType, handleProductId)
    self.ImgUpgrade.gameObject:SetActiveEx(addition > 0 or buffAddition > 0)
end

function XUiGridBenchStaff:RefreshSkill(index, handleProductId)
    local skillIds = self.Staff:GetSkillIds()
    for _, skillId in ipairs(skillIds or {}) do
        local skillMap = self.Staff:GetCharacterSkillAddition(skillId)
        local areaType = self.Staff:GetCharacterSkillAreaType(skillId)
        --仅显示对当前区域有加成的技能
        if areaType ~= self.AreaType then
            goto ContinueOutSide
        end
        for productId, addition in pairs(skillMap or {}) do
            --仅显示对当前产品有加成的技能
            if handleProductId ~= productId then
                goto ContinueInSide
            end
            local grid = self:GetGridSkill(index)
            grid.TxtSkill.text = self.Staff:GetCharacterSkillName(skillId)
            grid.TxtPercent.text = self._Control:GetCharacterSkillPercentAddition(addition, areaType, productId)
            grid.ImgIcon:SetSprite(self._Control:GetAdditionIcon(false))
            index = index + 1

            ::ContinueInSide::
        end
        ::ContinueOutSide::
    end
    return index
end

function XUiGridBenchStaff:GetGridSkill(index)
    local grid = self.GridSkill[index]
    if not grid then
        local ui = index == 1 and self.TxtOne or XUiHelper.Instantiate(self.TxtOne, self.PanelYield)
        grid = {}
        XTool.InitUiObjectByUi(grid, ui)
        self.GridSkill[index] = grid
    end
    grid.GameObject.name = "GridAddition"..index
    grid.GameObject:SetActiveEx(true)
    return grid
end

function XUiGridBenchStaff:SetSelect(select)
    self.IsSelect = select
    if self.ImgNormal then
        self.ImgNormal.gameObject:SetActiveEx(not select)
    end
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(select)
    end
end

function XUiGridBenchStaff:OnBtnClick()
    if self.IsSelect then
        return
    end
    self:SetSelect(true)
    if self.OnClick then self.OnClick(self) end
end

function XUiGridBenchStaff:GetCharacterId()
    if not self.Staff then
        return 0
    end
    return self.Staff:GetCharacterId()
end

function XUiGridBenchStaff:Equal(other)
    if not other then
        return false
    end
    local id = self:GetCharacterId()
    if id <= 0 then
        return false
    end
    return id == other:GetCharacterId()
end

return XUiGridBenchStaff