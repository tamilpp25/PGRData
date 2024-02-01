
local FilterMap

local function GetFilterMap(selectIds)
    if XTool.IsTableEmpty(FilterMap) then
        return
    end
    local map = XTool.Clone(FilterMap)
    for _, id in pairs(selectIds) do
        map[id] = nil
    end
    return map
end

local function AddFilterList(selectIds)
    FilterMap = FilterMap or {}
    for _, id in pairs(selectIds) do
        FilterMap[id] = true
    end
end


---@class XUiGridOrderBuild
---@field InputFurniture UnityEngine.UI.InputField
---@field ParentUi XUiFurnitureOrderBuild
local XUiGridOrderBuild = XClass(nil, "XUiGridOrderBuild")

local InputEnoughColor = XUiHelper.Hexcolor2Color("0E70BDFF")
local InputNotEnoughColor = XUiHelper.Hexcolor2Color("FF0000FF")

local EnoughColor = CS.UnityEngine.Color(0.0, 0.0, 0.0)
local NotEnoughColor = CS.UnityEngine.Color(1.0, 0.0, 0.0)

function XUiGridOrderBuild:Ctor(ui, parentUi)
    XTool.InitUiObjectByUi(self, ui)
    self.ParentUi = parentUi
    self.IsValid = false

    self.OnSelectFurnitureCb = handler(self, self.OnSelectFurniture)
    self.OnBtnSelectFurnitureClickCb = handler(self, self.OnBtnSelectFurnitureClick)
    self:InitCb()
end

function XUiGridOrderBuild:InitCb()
    self.InputFurniture.onValueChanged:AddListener(function(txt) 
        self:OnInputChanged(txt)
    end)
    
    self.BtnAdd.CallBack = function() 
        self:OnBtnAddClick()
    end

    self.BtnReduce.CallBack = function()
        self:OnBtnReduceClick()
    end

    self.BtnTip.CallBack = function()
        self:OnBtnTipClick()
    end
    
    self.BtnFurniture.CallBack = self.OnBtnSelectFurnitureClickCb
    self.BtnFurnitureNo.CallBack = self.OnBtnSelectFurnitureClickCb
    
    self.BtnDrawing.CallBack = function() 
        self:OnBtnBuyDrawingClick()
    end
end

function XUiGridOrderBuild:Refresh(furniture, index)
    self.TxtOrder.text = string.format("%02d", index)
    self.TargetCount = furniture.Count
    self.EditCount = self.TargetCount
    self.PreviewId = furniture.ConfigId
    local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture.ConfigId)
    local furnitureIds = self.ParentUi:GetFurnitureIdsByTypeId(template.TypeId, self.TargetCount)
    self:UpdateFurnitureIds(furnitureIds)
    self:SetValid(true)
    self:RefreshFurniture()
    self:RefreshCount()
end

function XUiGridOrderBuild:RefreshFurniture()
    local previewId = self.PreviewId
    local template = XFurnitureConfigs.GetFurnitureTemplateById(previewId)
    if not template then
        return
    end
    self.ImgPreviewItemIcon:SetRawImage(template.Icon)
    self.TxtPreviewScore.text = template.Name
    local drawId = template.PicId
    local drawName = ""
    local isValidDrawId = XTool.IsNumberValid(drawId)
    self.ImgSelectDrawing.gameObject:SetActiveEx(isValidDrawId)
    self.PanelDrawing.gameObject:SetActiveEx(isValidDrawId)
    self.ImgAdd.gameObject:SetActiveEx(isValidDrawId)
    if isValidDrawId then
        self.ImgSelectDrawing:SetRawImage(XDataCenter.ItemManager.GetItemIcon(drawId))
        drawName = XDataCenter.ItemManager.GetItemName(drawId)
    end
    self.TxtDrawing.text = drawName
    local furnitureIds = self.FurnitureIds
    self.FurnitureCount = #furnitureIds
    local hasFurniture = self.FurnitureCount > 0
    self.PanelFurnitureSelect.gameObject:SetActiveEx(hasFurniture)
    self.PanelFurnitureNone.gameObject:SetActiveEx(not hasFurniture)
    if hasFurniture then
        local furnitureName, icon = "", ""
        if self.FurnitureCount == 1 then
            local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIds[1])
            if furniture then
                local furnitureTemplate = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId())
                furnitureName, icon = furnitureTemplate.Name, furnitureTemplate.Icon
            end
        else
            furnitureName, icon = XFurnitureConfigs.DefaultCreateName, XFurnitureConfigs.DefaultIcon
        end
        self.TxtFurnitureName.text = furnitureName
        self.ImgSelectFurniture:SetRawImage(icon)
    end
    self.BtnTip.gameObject:SetActiveEx(self:IsSelectNonBasicSuit())
end

--是否选中了非基础家具
function XUiGridOrderBuild:IsSelectNonBasicSuit()
    if XTool.IsTableEmpty(self.FurnitureIds) then
        return false
    end
    for _, furnitureId in pairs(self.FurnitureIds) do
        local furnitureData = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
        if furnitureData and furnitureData:GetSuitId() ~= XFurnitureConfigs.BASE_SUIT_ID then
            return true
        end
    end
    return false
end

function XUiGridOrderBuild:OnSelectFurniture(furnitureIds)
    self:UpdateFurnitureIds(furnitureIds)
    self:RefreshEdit()
end

function XUiGridOrderBuild:UpdateFurnitureIds(furnitureIds)
    self.FurnitureIds = furnitureIds
    AddFilterList(furnitureIds or {})
end

function XUiGridOrderBuild:RefreshCount()
    local count = self.EditCount
    local missingFurniture, missingDrawing = self:GetMissingMaterial(self.EditCount)
    local isMissingFurniture, isMissDrawing = missingDrawing > 0, missingFurniture > 0
    local enoughKey, notEnoughKey = "DormTemplateCountEnough", "DormTemplateCountNotEnough"
    local drawingKey = isMissingFurniture and notEnoughKey or enoughKey
    local furnitureKey = isMissDrawing and notEnoughKey or enoughKey
    self.TxtDrawingNum.text = XUiHelper.GetText(drawingKey, count - missingDrawing, self.TargetCount)
    self.TxtFurnitureCount.text = XUiHelper.GetText(furnitureKey, count - missingFurniture, self.TargetCount)
    
    local materialEnough = not (isMissDrawing or isMissingFurniture)
    self.InputFurniture.text = tostring(count)
    self.InputFurniture.textComponent.color = materialEnough and InputEnoughColor or InputNotEnoughColor
    local targetKey = materialEnough and enoughKey or notEnoughKey
    self.TxtTarget.text = XUiHelper.GetText(targetKey, count, self.TargetCount)
    
    local disableReduce = self.EditCount <= 0
    self.BtnReduce:SetDisable(disableReduce, not disableReduce)
    local disableAdd = self.EditCount > XFurnitureConfigs.MaxRemouldCount or self.EditCount >= self.TargetCount
    self.BtnAdd:SetDisable(disableAdd, not disableAdd)

end

function XUiGridOrderBuild:OnInputChanged(txt)
    local count = 0
    count = string.IsNilOrEmpty(txt) and 0 or tonumber(txt)
    if self.EditCount == count then
        return
    end
    count = math.min(self.TargetCount, count)
    self.EditCount = count
    self:RefreshEdit()
end

function XUiGridOrderBuild:OnBtnAddClick()
    if self.EditCount > XFurnitureConfigs.MaxRemouldCount then
        return
    end
    self.EditCount = self.EditCount + 1
    self:RefreshEdit()
end

function XUiGridOrderBuild:OnBtnReduceClick()
    if self.EditCount <= 0 then
        return
    end
    self.EditCount = self.EditCount - 1
    self:RefreshEdit()
end

function XUiGridOrderBuild:OnBtnTipClick()
    XUiManager.TipText("FurnitureContainNonBasic")
end

function XUiGridOrderBuild:RefreshEdit()
    self:RefreshFurniture()
    self:RefreshCount()
    self.ParentUi:RefreshCost()
    self.ParentUi:RefreshMissingView()
end

function XUiGridOrderBuild:OnBtnSelectFurnitureClick()
    if not self:CheckIsValid() then
        return
    end
    local typeId = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewId).TypeId
    --策划不需要过滤当前套装
    --XLuaUiManager.Open("UiDormBagChoice", self.FurnitureIds, typeId, self.TargetCount, self.OnSelectFurnitureCb, GetFilterMap(self.FurnitureIds), self.ParentUi.FilterSuitMap)
    XLuaUiManager.Open("UiDormBagChoice", self.FurnitureIds, typeId, self.TargetCount, self.OnSelectFurnitureCb, GetFilterMap(self.FurnitureIds))
end

function XUiGridOrderBuild:OnBtnBuyDrawingClick()
    if not XTool.IsNumberValid(self.PreviewId) or not self:CheckIsValid() then
        return
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewId)
    local itemId = template.PicId
    local own = XDataCenter.ItemManager.GetCount(itemId)
    local buyCount = own >= self.TargetCount and 1 or self.TargetCount - own
    XDataCenter.FurnitureManager.JumpToBuyDrawing(self.PreviewId, buyCount, function()
        self:RefreshEdit()
    end)
end

function XUiGridOrderBuild:SetValid(valid)
    self.IsValid = valid and XTool.IsNumberValid(self.PreviewId)
    self.GameObject:SetActiveEx(valid)
end

function XUiGridOrderBuild:CheckIsValid()
    return self.IsValid
end

--- 获取缺失材料数量, return1:家具缺失数, return2:图纸缺失数
---@return number,number
--------------------------
function XUiGridOrderBuild:GetMissingMaterial(targetCount)
    if not XTool.IsNumberValid(self.PreviewId) or not self:CheckIsValid() then
        return 0, 0
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewId)
    local drawCount, furnitureCount
    if not XTool.IsNumberValid(template.PicId) then
        drawCount = 0
    else
        local cost = template.PicNum * targetCount
        local own = XDataCenter.ItemManager.GetCount(template.PicId)
        drawCount = math.max(cost - own, 0)
    end
    furnitureCount = math.max(targetCount - self.FurnitureCount, 0)
    
    return furnitureCount, drawCount 
end

function XUiGridOrderBuild:GetCost()
    if not XTool.IsNumberValid(self.PreviewId) or not self:CheckIsValid() then
        return 0
    end
    local maxBuild = self.EditCount - math.max(self:GetMissingMaterial(self.EditCount))
    if maxBuild <= 0 then
        return 0
    end
    local price, build = 0, 0
    local previewConfig = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewId)
    local isBase = previewConfig.SuitId == XFurnitureConfigs.BASE_SUIT_ID
    for _, furnitureId in pairs(self.FurnitureIds) do
        local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
        if furniture then
            local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId())
            price = price + (isBase and 0 or template.MoneyNum)
            build = build + 1
        end
        if build >= maxBuild then
            break
        end
    end
    
    return price
end

function XUiGridOrderBuild:GetBuildAndTargetCount()
    if not XTool.IsNumberValid(self.PreviewId) or not self:CheckIsValid() then
        return 0, 0
    end
    local missF, missD = self:GetMissingMaterial(self.EditCount)
    local miss = math.max(missD, missF)
    return math.max(self.EditCount - miss, 0), self.TargetCount
end

function XUiGridOrderBuild:GetReformData()
    if not self:CheckIsValid() or self.TargetCount <= 0 then
        return
    end
    local missingFurniture, missingDrawing = self:GetMissingMaterial(self.EditCount)
    --能够改造个数
    local validCount = math.min(self.EditCount - missingDrawing, self.EditCount - missingFurniture)
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewId)
    local reform, unReform
    
    if validCount > 0 then
        
        local reformFurniture, reformDraw = {}, {}
        reformDraw[template.PicId] = validCount
        for i = 1, validCount do
            local furnitureId = self.FurnitureIds[i]
            local configId = XDataCenter.FurnitureManager.GetFurnitureConfigId(furnitureId)
            reformFurniture[configId] = reformFurniture[configId] or {}
            table.insert(reformFurniture[configId], furnitureId)
        end
        reform = {
            TargetId = self.PreviewId,
            Furniture = reformFurniture,
            Draw = reformDraw,
            Count = validCount
        }
    end

    local unReformFurniture
    local leftCount = self.TargetCount - self.EditCount
    if missingFurniture > 0 or leftCount > 0 then
        unReformFurniture = {}
        unReformFurniture[template.TypeId] = math.max(leftCount, missingFurniture)
    end

    local unReformDraw
    if missingDrawing > 0 or leftCount > 0 then
        unReformDraw = {}
        unReformDraw[template.PicId] = math.max(leftCount, missingDrawing)
    end

    if unReformFurniture or unReformDraw then
        unReform = {
            TargetId = self.PreviewId,
            Furniture = unReformFurniture,
            Draw = unReformDraw,
            Count = self.TargetCount - validCount
        }
    end
    return reform, unReform
end

function XUiGridOrderBuild:PlayTimelineAnimation(name, finish, begin, wrapMode)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
   
    if not self.GameObject.activeInHierarchy then
        return
    end
    if not self[name] then
        self[name] = self.Transform:Find("Animation/" .. name)
    end

    if XTool.UObjIsNil(self[name]) or not self[name].gameObject.activeInHierarchy then
        XLog.Warning("动画播放异常!!!", name)
        return
    end

    wrapMode = wrapMode or CS.UnityEngine.Playables.DirectorWrapMode.Hold
    self[name]:PlayTimelineAnimation(finish, begin, wrapMode)
end

--=========================================类分界线=========================================--

---@class XUiFurnitureOrderBuild : XLuaUi
---@field TogCheck UnityEngine.UI.Toggle
---@field PanelOrderList UnityEngine.UI.ScrollRect
local XUiFurnitureOrderBuild = XLuaUiManager.Register(XLuaUi, "UiFurnitureOrderBuild")

function XUiFurnitureOrderBuild:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiFurnitureOrderBuild:OnStart(roomId, templateRoomId, templateRoomType, title, subTitle)
    self.RoomId = roomId
    self.TemplateId = templateRoomId
    self.TemplateRoomType = templateRoomType
    self:InitView(title, subTitle)
end 

function XUiFurnitureOrderBuild:OnDestroy()
    FilterMap = nil
end

function XUiFurnitureOrderBuild:InitUi()
    --允许自动使用非基础家具用于改装
    self.AllowNonBasic = false
    self.TogCheck.isOn = self.AllowNonBasic
    --可用家具
    self.EditFurnitureMap = {}
    ---@type table<number,XUiGridOrderBuild>
    self.EditGridPool = {}
    
    self.AllSuitIdMap = {}
    local suitList = XFurnitureConfigs.GetFurnitureSuitTemplates()
    for _, suit in pairs(suitList) do
        if suit.Id ~= XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID and not self.AllSuitIdMap[suit.Id] then
            self.AllSuitIdMap[suit.Id] = true
        end
    end
    self.OnSortFurnitureCb = handler(self, self.OnSortFurniture)
    self.OnSortFurnitureBaseCb = handler(self, self.OnSortFurnitureBase)
    self.OnRefitRequestCb = handler(self, self.OnRefitRequest)
    
    FilterMap = {}
end

function XUiFurnitureOrderBuild:InitCb()
    self:BindExitBtns()
    self:BindHelpBtn()
    
    self.TogCheck.onValueChanged:AddListener(function() 
        self:OnTogCheckClick()
    end)
    
    self.BtnDrawingLess.CallBack = function() 
        self:OnBtnDrawingLessClick()
    end
    
    self.BtnFurnitureLess.CallBack = function() 
        self:OnBtnFurnitureLessClick()
    end
    
    self.BtnConfirm.CallBack = function() 
        self:OnBtnConfirmClick()
    end
end

function XUiFurnitureOrderBuild:InitView(title, subTitle)
    
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.DormCoin, 
            XDataCenter.ItemManager.ItemId.FurnitureCoin)
    
    self.ImgDrawingIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.FurnitureCoin))

    if not string.IsNilOrEmpty(title) then
        self.TxtName.text = title
    end
    
    if not string.IsNilOrEmpty(subTitle) then
        self.TxtExplain.text = subTitle
    end
    
    self:RefreshView()
end

function XUiFurnitureOrderBuild:RefreshView()
    self.FurnitureList = XDataCenter.DormManager.GetNotOwnedFurniture(self.RoomId, self.TemplateId, self.TemplateRoomType)
    if XTool.IsTableEmpty(self.FurnitureList) then
        self:Close()
        return
    end
    --需要剔除套装Id
    self.FilterSuitMap = {}
    --获取可改造的家具
    local typeMap, typeIds = {}, {}
    local suitMap, suitIds = XTool.Clone(self.AllSuitIdMap), {}
    for _, furniture in pairs(self.FurnitureList) do
        local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture.ConfigId)
        if template and template.TypeId and not typeMap[template.TypeId] then
            table.insert(typeIds, template.TypeId)
            typeMap[template.TypeId] = true
        end
        
        suitMap[template.SuitId] = false
    end
    for id, value in pairs(suitMap) do
        if value then
            table.insert(suitIds, id)
        else
            self.FilterSuitMap[id] = true
        end
        
    end
    local furnitureIds = XDataCenter.FurnitureManager.GetFurnitureCategoryIdsNoSort(typeIds, suitIds, nil,
            true, false, true, (not self.AllowNonBasic))
    
    self:UpdateFurnitureId(furnitureIds)
    self:RefreshList()
    self:RefreshMissingView()
    self:RefreshCost()
end

function XUiFurnitureOrderBuild:OnTogCheckClick()
    self.AllowNonBasic = self.TogCheck.isOn
    self:RefreshView()
end

function XUiFurnitureOrderBuild:UpdateFurnitureId(furnitureIds)
    self.EditFurnitureMap = {}
    if XTool.IsTableEmpty(furnitureIds) then
        return
    end
    for _, furnitureId in pairs(furnitureIds) do
        local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
        if furniture then
            local typeId = furniture:GetTypeId()
            self.EditFurnitureMap[typeId] = self.EditFurnitureMap[typeId] or {}
            table.insert(self.EditFurnitureMap[typeId], furnitureId)
        end
    end
    local sortFunc = self.AllowNonBasic and self.OnSortFurnitureCb or self.OnSortFurnitureBaseCb
    for typeId, _ in pairs(self.EditFurnitureMap) do
        table.sort(self.EditFurnitureMap[typeId], sortFunc)
    end
end

function XUiFurnitureOrderBuild:GetFurnitureIdsByTypeId(typeId, count)
    local list = XTool.Clone(self.EditFurnitureMap[typeId])
    if XTool.IsTableEmpty(list) then
        return {}
    end
    local length = #list
    if length <= count then
        self.EditFurnitureMap[typeId] = nil
        return list
    end
    local temp = {}
    for i = 1, count do
        table.insert(temp, list[i])
    end
    for i = count, 1, -1 do
        table.remove(self.EditFurnitureMap[typeId], i)
    end
    return temp
end

function XUiFurnitureOrderBuild:RefreshList()
    for _, grid in pairs(self.EditGridPool) do
        grid:SetValid(false)
    end

    for i, furniture in pairs(self.FurnitureList) do
        local grid = self.EditGridPool[i]
        if not grid then
            local ui = i == 1 and self.GridTask or XUiHelper.Instantiate(self.GridTask, self.PanelTaskContainer)
            grid = XUiGridOrderBuild.New(ui, self)
            self.EditGridPool[i] = grid
        end
        grid:Refresh(furniture, i)
    end
end

function XUiFurnitureOrderBuild:RefreshMissingView()
    local missingFurniture, missingDrawing = 0, 0
    self.MissingFurnitureList = {}
    self.MissingDrawingList = {}
    for index, grid in pairs(self.EditGridPool) do
        if grid:CheckIsValid() then
            local temp1, temp2 = grid:GetMissingMaterial(grid.TargetCount)
            missingFurniture = missingFurniture + temp1
            missingDrawing = missingDrawing + temp2
            
            if temp1 > 0 then
                table.insert(self.MissingFurnitureList, index)
                self.LastJumpFurniture = self.LastJumpFurniture or 1
            end

            if temp2 > 0 then
                table.insert(self.MissingDrawingList, index)
                self.LastJumpDrawing = self.LastJumpDrawing or 1
            end
        end
    end
    self.BtnDrawingLess.gameObject:SetActiveEx(missingDrawing > 0)
    self.BtnFurnitureLess.gameObject:SetActiveEx(missingFurniture > 0)
    self.BtnFurnitureLess:SetNameByGroup(1, missingFurniture)
    self.BtnDrawingLess:SetNameByGroup(1, missingDrawing)
end 

function XUiFurnitureOrderBuild:RefreshCost()
    local price = 0
    local build, target = 0, 0
    for _, grid in pairs(self.EditGridPool) do
        if grid:CheckIsValid() then
            price = price + grid:GetCost()
            local tb, tt = grid:GetBuildAndTargetCount()
            build = build + tb
            target = target + tt
        end
    end
    local enough = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin) >= price
    self.TxtCount.text = price
    self.TxtCount.color = enough and EnoughColor or NotEnoughColor
    local disable = not enough or build <= 0
    local key = disable and "DormRefitCountNotEnough" or "DormRefitCountEnough"
    self.TxtQuantity.text = XUiHelper.GetText(key, build, target)
    self.BtnConfirm:SetDisable(disable, not disable)
    self.CostCount = price
    self.CoinEnough = enough
end

--材料家具排序-任意套装
function XUiFurnitureOrderBuild:OnSortFurniture(furnitureIdA, furnitureIdB)
    local furnitureA = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIdA)
    local furnitureB = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIdB)

    local isBaseA = furnitureA and furnitureA:CheckIsBaseFurniture() or false
    local isBaseB = furnitureB and furnitureB:CheckIsBaseFurniture() or false

    --基础套优先
    if isBaseA ~= isBaseB then
        return isBaseA
    end

    local scoreA = furnitureA and furnitureA:GetScore() or 0
    local scoreB = furnitureB and furnitureB:GetScore() or 0

    if scoreA ~= scoreB then
        if isBaseA then --都是基础套时，分数大的优先
            return scoreA > scoreB
        else            --否则分数小的优先
            return scoreA < scoreB
        end
    end

    return furnitureIdA < furnitureIdB
end

--材料家具排序-基础套装
function XUiFurnitureOrderBuild:OnSortFurnitureBase(furnitureIdA, furnitureIdB)
    local furnitureA = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIdA)
    local furnitureB = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIdB)

    local scoreA = furnitureA and furnitureA:GetScore() or 0
    local scoreB = furnitureB and furnitureB:GetScore() or 0

    if scoreA ~= scoreB then
        return scoreA > scoreB
    end

    return furnitureIdA < furnitureIdB
end

--region   ------------------Ui事件 start-------------------
function XUiFurnitureOrderBuild:OnBtnDrawingLessClick()
    local count = #self.MissingDrawingList
    if count <= 0 then
        return
    end

    local index = self.MissingDrawingList[self.LastJumpDrawing]
    if count == 1 and XTool.GetTableCount(self.EditGridPool) == 1 then
        local grid = self.EditGridPool[index]
        if grid then
            grid:PlayTimelineAnimation("GridTaskEnable")
        end
        return
    end
    self:ScrollTo(index - 1)
    if self.LastJumpDrawing >= #self.MissingDrawingList then
        self.LastJumpDrawing = 0
    end
    self.LastJumpDrawing = self.LastJumpDrawing + 1
    
end

function XUiFurnitureOrderBuild:OnBtnFurnitureLessClick()
    local count = #self.MissingFurnitureList
    if count <= 0 then
        return
    end
    local index = self.MissingFurnitureList[self.LastJumpFurniture]
    if count == 1 and XTool.GetTableCount(self.EditGridPool) == 1 then
        local grid = self.EditGridPool[index]
        if grid then
            grid:PlayTimelineAnimation("GridTaskEnable")
        end
        return
    end
    self:ScrollTo(index - 1)
    if self.LastJumpFurniture >= #self.MissingFurnitureList then
        self.LastJumpFurniture = 0
    end
    self.LastJumpFurniture = self.LastJumpFurniture + 1
end

function XUiFurnitureOrderBuild:ScrollTo(index)
    local total = #self.FurnitureList
    if total <= 0 then
        return
    end
    local grid = self.EditGridPool[index + 1]
    if grid then
        grid:PlayTimelineAnimation("GridTaskEnable")
    end
    local percent = 1 / (1 - total) * index + 1
    self.PanelOrderList.verticalNormalizedPosition = percent
end

function XUiFurnitureOrderBuild:OnBtnConfirmClick()
    if not self.CoinEnough then
        XUiManager.TipText("FurnitureZeroCoin")
        return
    end
    local reformList, unReformList = {}, {}
    for _, grid in pairs(self.EditGridPool) do
        local reform, unReform = grid:GetReformData()
        if reform then
            table.insert(reformList, reform)
        end

        if unReform then
            table.insert(unReformList, unReform)
        end
    end
    XLuaUiManager.Open("UiFurnitureOrderTips", reformList, unReformList, self.CostCount, self.OnRefitRequestCb)
end

function XUiFurnitureOrderBuild:OnRefitRequest()
    XUiManager.TipText("FurnitureRefitSuccess")
    self:Close()
end
--endregion------------------Ui事件 finish------------------