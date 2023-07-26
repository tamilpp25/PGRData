
---@class XUiGridBenchStaff
local XUiGridBenchStaff = XClass(nil, "XUiGridBenchStaff")

function XUiGridBenchStaff:Ctor(ui, onClick)
    XTool.InitUiObjectByUi(self, ui)
    self.OnClick = onClick
    
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
    self.GridSkill = {}
    self.TxtOne.gameObject:SetActiveEx(false)
end

--- 刷新显示
---@param staff XRestaurantStaff
---@return void
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
    
    self:SetSelect(staff:GetProperty("_Id") == selectId)
    self.ImgWorking.gameObject:SetActiveEx(not staff:IsFree())
    self.PanelDisable.gameObject:SetActiveEx(not staff:GetProperty("_IsRecruit"))
    self:RefreshAddition()
end

function XUiGridBenchStaff:RefreshAddition()
    for _, grid in pairs(self.GridSkill) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local bench = viewModel:GetWorkBenchViewModel(self.AreaType, self.Index)
    local handleProductId = bench:GetProperty("_ProductId")
    
    local index = 1
    index = self:RefreshSkill(index, handleProductId)
    
    local buff = viewModel:GetAreaBuff(self.AreaType)
    local buffAddition = buff and buff:GetEffectAddition(self.AreaType, self.Staff:GetProperty("_Id"), handleProductId) or 0
    
    if buffAddition > 0 then
        local grid = self:GetGridSkill(index)
        grid.TxtSkill.text = buff:GetProperty("_Name")
        grid.TxtPercent.text = XRestaurantConfigs.GetCharacterSkillPercentAddition(buffAddition, self.AreaType, handleProductId)
        grid.ImgIcon:SetSprite(XRestaurantConfigs.GetBuffAdditionIcon())

    end
    
    local addition = self.Staff:GetSkillAddition(self.AreaType, handleProductId)
    self.ImgUpgrade.gameObject:SetActiveEx(addition > 0 or buffAddition > 0)
end

function XUiGridBenchStaff:RefreshSkill(index, handleProductId)
    local skillIds = self.Staff:GetProperty("_SkillIds")
    for _, skillId in ipairs(skillIds or {}) do
        local skillMap = XRestaurantConfigs.GetCharacterSkillAddition(skillId)
        local areaType = XRestaurantConfigs.GetCharacterSkillAreaType(skillId)
        --仅显示对当前区域有加成的技能
        if areaType ~= self.AreaType then
            goto ContinueOutSide
        end
        --local skillDesc = XRestaurantConfigs.GetSkillAdditionDesc(areaType)
        for productId, addition in pairs(skillMap or {}) do
            --仅显示对当前产品有加成的技能
            if handleProductId ~= productId then
                goto ContinueInSide
            end
            local grid = self:GetGridSkill(index)
            --local product = viewModel:GetProduct(areaType, productId)
            --grid.TxtSkill.text = string.format("%s%s", product:GetProperty("_Name"), skillDesc)
            grid.TxtSkill.text = XRestaurantConfigs.GetCharacterSkillName(skillId)
            grid.TxtPercent.text = XRestaurantConfigs.GetCharacterSkillPercentAddition(addition, areaType, productId)
            grid.ImgIcon:SetSprite(XRestaurantConfigs.GetSkillAdditionIcon())
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
    self.ImgNormal.gameObject:SetActiveEx(not select)
    self.ImgSelect.gameObject:SetActiveEx(select)
end

function XUiGridBenchStaff:OnBtnClick()
    if self.IsSelect then
        return
    end
    self:SetSelect(true)
    if self.OnClick then self.OnClick(self) end
end


return XUiGridBenchStaff