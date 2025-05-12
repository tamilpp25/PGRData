local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridDormArchive = XClass(nil, "XUiGridDormArchive")

function XUiGridDormArchive:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridDormArchive:Refresh(furnitureConfigId, isNew, unlock)
    self.FurnitureIdConfigId = furnitureConfigId
    self.IsNew = isNew
    local template = XFurnitureConfigs.GetFurnitureTemplateById(furnitureConfigId)
    self.Lock.gameObject:SetActiveEx(not unlock)
    self.UnLock.gameObject:SetActiveEx(unlock)
    local icon = unlock and self.RImgIconUnlock or self.RImgIconLock
    icon:SetRawImage(template.Icon)
    self.NEW.gameObject:SetActiveEx(isNew and true or false)
end

function XUiGridDormArchive:GetId()
    return self.FurnitureIdConfigId
end

function XUiGridDormArchive:PlayEffect()
    if not self.IsNew then
        return
    end
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        -- 播放特效
        self.NEW.gameObject:SetActiveEx(false)
        self.NEW.gameObject:SetActiveEx(true)
    end, 200)
end


--=========================================类分界线=========================================--


local XUiDormArchiveUnlock = XLuaUiManager.Register(XLuaUi, "UiDormArchiveUnlock")
local Duration = 2

function XUiDormArchiveUnlock:OnAwake()
    self:InitUi()
    self:InitCb()
end

--- 
---@param suitId number @套装id
---@param configId2IdMap table<number,number> configId -> furnitureId
---@param cb function
---@return
--------------------------
function XUiDormArchiveUnlock:OnStart(suitId, configId2IdMap, cb)
    self.SuitId = suitId
    self.ConfigId2IdMap = configId2IdMap or {}
    self.CloseCb = cb
    
    self:InitView()
end

function XUiDormArchiveUnlock:InitUi()
    self.ObtainGrid.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamic)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridDormArchive)
    
    self.OnSortCb = handler(self, self.SortFunc)
end

function XUiDormArchiveUnlock:InitCb()
    local closeHandler = function()
        self:Close()
        if self.CloseCb then self.CloseCb() end
    end
    self.BtnClose.CallBack = closeHandler
    self.BtnWndClose.CallBack = closeHandler
    
    self.BtnShowTemplate.CallBack = function() 
        self:OnBtnShowTemplateClick()
    end
end

function XUiDormArchiveUnlock:InitView()
    local template = XFurnitureConfigs.GetFurnitureSuitTemplatesById(self.SuitId)
    self.BtnShowTemplate.gameObject:SetActiveEx(true)
    self.TxtOption.text = template.SuitName
    self.RImgArchive:SetRawImage(template.SuitIcon)
    local newCount = 0
    for configId, _ in pairs(self.ConfigId2IdMap) do
        XDataCenter.FurnitureManager.MarkFirstObtain(configId)
        newCount = newCount + 1
    end
    local list = XFurnitureConfigs.GetFurnitureConfigIdsBySuitId(self.SuitId)
    table.sort(list, self.OnSortCb)
    local total = #list
    local unlockCount = 0
    for _, id in ipairs(list) do
        if self:CheckUnlock(id) then
            unlockCount = unlockCount + 1
        end
    end
    local curCount = unlockCount - newCount

    self.DataList = list
    self:SetupDynamicTable()
    
    XUiHelper.Tween(Duration, function(delta)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        
        local add = curCount + math.floor(newCount * delta)
        self.TxtOptionNum.text = string.format("%d/%d", add, total)
        self.ImgProgress.fillAmount = (curCount + newCount * delta) / total
    end)
end

function XUiDormArchiveUnlock:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local configId = self.DataList[index]
        grid:Refresh(configId, self.ConfigId2IdMap[configId] ~= nil, self:CheckUnlock(configId))
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        --local configId = self.ConfigId2IdMap[grid:GetId()]
        --if XTool.IsNumberValid(furnitureId) then
        --    XLuaUiManager.Open("UiFurnitureDetail", furnitureId, grid:GetId(), nil, nil, true, true)
        --end
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self.DynamicTable:GetGrids()
        for _, temp in pairs(grids) do
            temp:PlayEffect()
        end
    end
end

function XUiDormArchiveUnlock:SetupDynamicTable()
    
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync()
end

function XUiDormArchiveUnlock:SortFunc(idA, idB)
    local isNewA = self.ConfigId2IdMap[idA] ~= nil
    local isNewB = self.ConfigId2IdMap[idB] ~= nil

    if isNewA ~= isNewB then
        return isNewA
    end
    
    local unlockA = self:CheckUnlock(idA)
    local unlockB = self:CheckUnlock(idB)

    if unlockA ~= unlockB then
        return unlockA
    end
    
    local tempA = XFurnitureConfigs.GetFurnitureTemplateById(idA)
    local tempB = XFurnitureConfigs.GetFurnitureTemplateById(idB)

    if tempA.TypeId ~= tempB.TypeId then
        local typeA = XFurnitureConfigs.GetFurnitureTypeById(tempA.TypeId)
        local typeB = XFurnitureConfigs.GetFurnitureTypeById(tempB.TypeId)
        return typeA.Priority < typeB.Priority
    end
    
    return tempA.Id < tempB.Id
end

function XUiDormArchiveUnlock:CheckUnlock(id)
    if not id then
        return false
    end
    
    return XDataCenter.DormManager.FurnitureUnlockList and 
            XDataCenter.DormManager.FurnitureUnlockList[id] ~= nil or false
end 

function XUiDormArchiveUnlock:OnBtnShowTemplateClick()
    if not XTool.IsNumberValid(self.SuitId) then
        return
    end
    
    XLuaUiManager.Open("UiDormFieldGuide", self.SuitId)
end