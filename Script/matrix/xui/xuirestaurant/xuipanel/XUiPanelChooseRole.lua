local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiPanelWorkBase = require("XUi/XUiRestaurant/XUiPanel/XUiPanelWorkBase")
local XUiGridBenchStaff = require("XUi/XUiRestaurant/XUiGrid/XUiGridBenchStaff")
local XUiPanelWorkBuff = require("XUi/XUiRestaurant/XUiPanel/XUiPanelWorkBuff")

---@class XUiPanelChooseRole : XUiPanelWorkBase
---@field Staff XRestaurantStaffVM
local XUiPanelChooseRole = XClass(XUiPanelWorkBase, "XUiPanelChooseRole")

function XUiPanelChooseRole:InitUi()
    self:InitDynamicTable()
end

function XUiPanelChooseRole:InitDynamicTable()
    if XTool.UObjIsNil(self.PanelRoleList) then
        return
    end
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRoleList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridBenchStaff, self.Parent, handler(self, self.OnSelect))
    self.GridRole.gameObject:SetActiveEx(false)
end

function XUiPanelChooseRole:InitCb()
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
end

function XUiPanelChooseRole:RefreshView()
    self:SetupDynamicTable()
    self:RefreshChoose()
    self:RefreshBuff()
end

function XUiPanelChooseRole:ClearCache()
    self.LastGrid = nil
end

function XUiPanelChooseRole:SetupDynamicTable()
    if not self.DynamicTable then
        return
    end
    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    local startIndex = 1
    local productId = benchModel:GetProductId()
    local list = self:GetRecruitCharactersWithSort(self.AreaType, productId)
    local isEmpty = XTool.IsTableEmpty(list)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)
    if benchModel:IsRunning() then
        self.Staff = benchModel:GetCharacter()
        if not isEmpty then
            for index, staff in ipairs(list) do
                if staff:Equal(self.Staff) then
                    startIndex = index
                    break
                end
            end
        end
    end
    
    self.DataList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataSync(startIndex)
end

function XUiPanelChooseRole:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local selectId = self.Staff and self.Staff:GetCharacterId() or 0
        grid:Refresh(self.DataList[index], self.AreaType, self.Index, selectId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.Staff then
            return
        end
        local grids = self.DynamicTable:GetGrids()
        for _, item in pairs(grids or {}) do
            if item and item.Staff 
                    and self.Staff:Equal(item.Staff) then
                item:SetSelect(false)
                item:OnBtnClick()
                break
            end
        end
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:SetSelect(false)
        if grid:Equal(self.LastGrid) then   
            self.LastGrid = nil
        end
    end
end

function XUiPanelChooseRole:OnBtnConfirmClick()
    if not self.Staff then
        XUiManager.TipMsg(self._Control:GetProduceDesc(4))
        return
    end
    local characterId = self.Staff:GetCharacterId()
    if not XTool.IsNumberValid(characterId) then
        return
    end
    if not self.Staff:IsFree() then
        local title, content = self._Control:GetSwitchStaffContent(self.Staff:GetName(), self.Staff:GetAreaType())
        
        self._Control:OpenPopup(title, content, nil, nil, function()
            self:DoConfirm(characterId)
        end)
        return
    end
    self:DoConfirm(characterId)
end

function XUiPanelChooseRole:DoConfirm(characterId)
    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    --工作台已经启动了，走更换角色的流程
    if benchModel:IsRunning() then
        --当前工作台的产品
        local productId = benchModel:GetProductId()
        --当前工作台的员工
        local oldCharId = benchModel:GetCharacterId()
        self._Control:RequestAssignWork(self.AreaType, characterId, self.Index, productId, function()
            benchModel:SwitchStaffOrProduct(oldCharId, characterId, productId, productId)
        end)
        return
    end
    benchModel:AddStaff(characterId)
end

--- 点选回调
---@param grid XUiGridBenchStaff
--------------------------
function XUiPanelChooseRole:OnSelect(grid)
    if self.LastGrid then
        self.LastGrid:SetSelect(false)
    else
        local selectId = self.Staff and self.Staff:GetCharacterId() or 0
        local grids = self.DynamicTable:GetGrids()
        for _, g in ipairs(grids) do
            if g.GetCharacterId and g:GetCharacterId() == selectId then
                g:SetSelect(false)
                break
            end
        end
    end
    self.LastGrid = grid
    self.Staff = grid.Staff
    
    self:RefreshChoose()
end

function XUiPanelChooseRole:RefreshChoose()
    local select = self.Staff and true or false
    self.BtnConfirm:SetDisable(not select, select)
end

function XUiPanelChooseRole:RefreshBuff()
    if not self.PanelWorkBuff then
        self.PanelWorkBuff = XUiPanelWorkBuff.New(self.UiRestaurantBtnBuff, self.Parent, self.AreaType, true)
    end
    if self._Control:CheckAreaBuffUnlock(self.AreaType) then
        self.PanelWorkBuff:Open()
    else
        self.PanelWorkBuff:Close()
    end
end

--- 获取已招募角色并排序
---@param areaType number
---@param productId number
---@return XRestaurantStaffVM[]
--------------------------
function XUiPanelChooseRole:GetRecruitCharactersWithSort(areaType, productId)
    local list = self._Control:GetRecruitCharacters()
    if XTool.IsTableEmpty(list) then
        return list
    end

    local buff = self._Control:GetAreaBuff(areaType)
    table.sort(list, function(a, b)
        local isWorkingA = not a:IsFree()
        local isWorkingB = not b:IsFree()
        if isWorkingA ~= isWorkingB then
            return isWorkingB
        end

        local idA = a:GetCharacterId()
        local idB = b:GetCharacterId()

        local buffAddA = buff and buff:GetEffectAddition(areaType, idA, productId) or 0
        local buffAddB = buff and buff:GetEffectAddition(areaType, idB, productId) or 0

        local skillAddA = a:GetSkillAddition(areaType, productId)
        local skillAddB = b:GetSkillAddition(areaType, productId)

        local addA = buffAddA + skillAddA
        local addB = buffAddB + skillAddB

        if addA ~= addB then
            return addA > addB
        end

        if skillAddA ~= skillAddB then
            return skillAddA > skillAddB
        end

        if buffAddA ~= buffAddB then
            return buffAddA > buffAddB
        end

        local levelA = a:GetLevel()
        local levelB = b:GetLevel()

        if levelA ~= levelB then
            return levelA > levelB
        end

        return idA < idB
    end)

    return list
end

return XUiPanelChooseRole