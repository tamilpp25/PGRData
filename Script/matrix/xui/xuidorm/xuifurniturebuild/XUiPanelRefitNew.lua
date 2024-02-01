
---@class XUiPanelRefitNew
---@field TogCheck UnityEngine.UI.Toggle
---@field InputFunitueCount UnityEngine.UI.InputField
local XUiPanelRefitNew = XClass(nil, "XUiPanelRefitNew")

local EnoughColor = CS.UnityEngine.Color(0.0, 0.0, 0.0)
local NotEnoughColor = CS.UnityEngine.Color(1.0, 0.0, 0.0)

local InputEnoughColor = XUiHelper.Hexcolor2Color("0E70BDFF")
local InputNotEnoughColor = XUiHelper.Hexcolor2Color("FF0000FF")

local BlackColorStr = "000000CC"
local RedColorStr = "FF0000FF"

function XUiPanelRefitNew:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitUi()
    self:InitCb()
end

function XUiPanelRefitNew:InitUi()
    --允许自动使用非基础家具用于改装
    self.AllowNonBasic = false
    self.TogCheck.isOn = self.AllowNonBasic
    --改装数量
    self.RefitCount = 0
    self.InputFunitueCount.text = tostring(self.RefitCount)
    --预览家具
    self.PreviewFurnitureId = 0
    --选中套装
    self.SelectSuitId = nil
    --选中基础套装
    self.FurnitureIds = {}
    self.FurnitureIdsCache = {}
    --玩家手动选择
    self.ManualFurnitureIds = {}
    
    --图标固定
    self.ImgDrawingIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.FurnitureCoin))
    
    self.OnSelectPreviewCb = handler(self, self.OnSelectPreview)
    self.OnSelectFurnitureCb = handler(self, self.OnSelectFurnitureIds)
    self.OnSortFurnitureBaseCb = handler(self, self.OnSortFurnitureBase)
    self.OnSortFurnitureCb = handler(self, self.OnSortFurniture)
    self.OnRequestCb = handler(self, self.OnRequest)
    
    self.JiantouEnable = self.Transform:Find("Panel/JiantouEnable")
    self.JiantouDisable = self.Transform:Find("Panel/JiantouDisable")
    
end

function XUiPanelRefitNew:InitCb()
    self.TogCheck.onValueChanged:AddListener(function() 
        self:OnTogCheckClick()
    end)
    
    self.InputFunitueCount.onValueChanged:AddListener(function(text) 
        self:OnInputChanged(text)
    end)
    
    self.BtnAdd.CallBack = function() 
        self:OnBtnAddClick()
    end
    
    self.BtnReduce.CallBack = function() 
        self:OnBtnReduceClick()
    end
    
    self.BtnMax.CallBack = function() 
        self:OnBtnMaxClick()
    end
    
    self.BtnMin.CallBack = function() 
        self:OnBtnMinClick()
    end

    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
    
    self.BtnPreviewFurniture.CallBack = function() 
        self:OnBtnPreviewFurnitureClick()
    end

    self.BtnDrawing.CallBack = function()
        self:OnBtnDrawingClick()
    end

    self.BtnSelectFurnitureNo.CallBack = function()
        self:OnSelectFurnitureClick()
    end

    self.BtnChoice.CallBack = function()
        self:OnSelectFurnitureClick()
    end

    self.BtnSelectFurniture.CallBack = function()
        self:OnSelectFurnitureClick()
    end

    self.BtnChange.CallBack = function()
        self:OnBtnPreviewFurnitureClick()
    end
end

function XUiPanelRefitNew:Init()

end

function XUiPanelRefitNew:SetPanelActive(value)
    self.GameObject:SetActiveEx(value)
    if not value then
        return
    end
    
    self:RefreshView()
end

function XUiPanelRefitNew:RefreshView()
    --切换页签时，如果家具被消耗了，移除对应的Id
    local indexList = {}
    for index, id in ipairs(self.FurnitureIds) do
        if not XDataCenter.FurnitureManager.CheckFurnitureExist(id) then
            table.insert(indexList, index)
        end
    end
    --从后往前删除
    for index = #indexList, 1, -1 do
        local idx = indexList[index]
        table.remove(self.FurnitureIds, idx)
    end
    --家具制作改版前放在制作队列没有收集的家具列表
    local checkList = XDataCenter.FurnitureManager.GetFurnitureCreateList()
    if not XTool.IsTableEmpty(checkList) then
        XDataCenter.FurnitureManager.OnResponseCreateFurniture(checkList)
    end
    self:RefreshPreviewFurniture()
end

--- 刷新家具
--------------------------
function XUiPanelRefitNew:RefreshPreviewFurniture()
    local isSelect = self:IsSelectPreview()
    self.BtnPreviewFurniture.gameObject:SetActiveEx(not isSelect)
    self.PanelPreviewIcon.gameObject:SetActiveEx(isSelect)
    if isSelect then
        local template = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewFurnitureId)
        self.ImgPreviewItemIcon:SetRawImage(template.Icon)
        self.TxtPreviewScore.text = template.Name
    end
    self.PanelTxtresult.gameObject:SetActiveEx(isSelect)
    self:RefreshEdit()
end

--- 刷新材料
--------------------------
function XUiPanelRefitNew:RefreshMaterial()
    self:RefreshFurniture()
    self:RefreshDrawing()
end

--消耗家具
function XUiPanelRefitNew:RefreshFurniture()
    local isSelect = self:IsSelectPreview()
    --self:AutoSelectFurnitureIds()
    local selectCount = #self.FurnitureIds
    local isEmpty = not isSelect or selectCount <= 0
    self.BtnSelectFurnitureNo.gameObject:SetActiveEx(isEmpty)
    self.BtnSelectFurnitureNo:SetDisable(not isSelect, isSelect)
    self.BtnChoice.gameObject:SetActiveEx(not isEmpty)
    self.BtnSelectFurniture.gameObject:SetActiveEx(not isEmpty)

    if not isEmpty then
        local selectNonBasic = self:IsSelectNonBasicSuit()
        self.BtnSelectFurniture:ShowTag(selectNonBasic)
        if selectNonBasic then
            XUiManager.TipText("FurnitureContainNonBasic")
        end
        
        local colorStr = self.RefitCount > selectCount and RedColorStr or BlackColorStr
        local btnTxt = XUiHelper.GetText("DormSelectHint", colorStr, self.RefitCount)
        self.BtnSelectFurniture:SetNameByGroup(1, btnTxt)
        
        local scoreTxt = ""

        local icon
        if selectCount == 1 then
            local furniture = XDataCenter.FurnitureManager.GetFurnitureById(self.FurnitureIds[1])
            local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId())
            icon = template.Icon
            scoreTxt = XUiHelper.GetText("FurnitureRefitScore", furniture:GetScore())
        else
            icon = XFurnitureConfigs.DefaultIcon
        end
        self.BtnSelectFurniture:SetNameByGroup(0, scoreTxt)
        self.BtnSelectFurniture:SetRawImage(icon)
    end
end

--图纸
function XUiPanelRefitNew:RefreshDrawing()
    local isSelect = self:IsSelectPreview()

    self.BtnSelectDrawing:SetDisable(not isSelect, isSelect)
    self.BtnDrawing.gameObject:SetActiveEx(isSelect)

    if isSelect then
        local template = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewFurnitureId)
        local picId = template.PicId
        local validPicId = XTool.IsNumberValid(picId)
        local needCount, ownCount = 0, 0
        self.BtnSelectDrawing.gameObject:SetActiveEx(validPicId)
        self.BtnDrawing.gameObject:SetActiveEx(validPicId)
        if validPicId then
            needCount = template.PicNum * self.RefitCount
            ownCount = XDataCenter.ItemManager.GetCount(picId)
            self.BtnSelectDrawing:SetRawImage(XDataCenter.ItemManager.GetItemIcon(picId))
        end
        self.BtnSelectDrawing:SetNameAndColorByGroup(0, "X"..needCount, ownCount >= needCount and EnoughColor or NotEnoughColor)
    end
end

--编辑栏
function XUiPanelRefitNew:RefreshEdit()
    self:RefreshMaterial()
    self:RefreshCount()
end

--数量
function XUiPanelRefitNew:RefreshCount()
    local isSelect = self:IsSelectPreview()
    
    local cost = self:GetCostMoney()
    
    local own = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin)
    local enough = own >= cost
    self.TxtConsumeCount.text = cost
    self.TxtConsumeCount.color = enough and EnoughColor or NotEnoughColor

    self.MaxRefit = self:GetMaxRefit()
    local materialEnough = self.RefitCount <= self.MaxRefit

    self.InputFunitueCount.interactable = isSelect
    self.InputFunitueCount.text = tostring(self.RefitCount)
    self.InputFunitueCount.textComponent.color = (enough and materialEnough) and InputEnoughColor or InputNotEnoughColor
    
    self.CostEnough = enough
    self.MaterialEnough = materialEnough
    local add = not (isSelect and enough)
    local reduce = not (isSelect and self.RefitCount > 1)
    self.BtnAdd:SetDisable(add)
    self.BtnReduce:SetDisable(reduce)
    self.BtnMax:SetDisable(add)
    self.BtnMin:SetDisable(reduce)
    
    local disable = add or self.RefitCount < 1
    self.BtnConfirm:SetDisable(disable, not disable)
    
    local enable = isSelect and enough and materialEnough
    
    self.JiantouEnable.gameObject:SetActiveEx(enable)
    self.JiantouDisable.gameObject:SetActiveEx(not enable)
end

---改装效果
function XUiPanelRefitNew:RefreshRandomEffect()
    local valid = XTool.IsNumberValid(self.PreviewFurnitureId)
    self.PanelTxtresult.gameObject:SetActiveEx(valid)
    if not valid then
        return
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewFurnitureId)
    local hasRandom = template.RandomGroupId > 0
    self.PanelTxtresult.gameObject:SetActiveEx(hasRandom)
    if hasRandom then
        local groupIntroduce = XFurnitureConfigs.GetGroupRandomIntroduce(template.RandomGroupId)
        local minLevel = self:GetMinFurnitureLevel()
        self.TxtResult.text = XFurnitureConfigs.FurnitureAttrLevel[minLevel]
        local buffer = ""
        local introduce = {}
        local desc, level = nil, nil
        for _, v in pairs(groupIntroduce) do
            for _, v1 in pairs(v) do
                if minLevel > v1.QualityType then
                    break
                end
                if not desc then
                    desc = XFurnitureConfigs.GetAdditionalRandomEntry(v1.Id, true) .. "\n"
                end
                desc = desc .. string.format("%s\n", v1.Introduce)
                level = v1.QualityType
            end
            if level then
                table.insert(introduce, {
                    Level = level,
                    Desc = desc
                })
            end
            desc, level = nil, nil
        end
        
        table.sort(introduce, function(a, b) 
            return a.Level < b.Level
        end)
       
        for _, v in ipairs(introduce) do
            buffer = string.format("%s%s\n",buffer, v.Desc)
        end
        self.TxtPreviewSpecial.text = buffer
    end
end

function XUiPanelRefitNew:OnTogCheckClick()
    self.AllowNonBasic = self.TogCheck.isOn
    
    self:RefreshEdit()
end

function XUiPanelRefitNew:OnInputChanged(text)
    if not self:IsSelectPreview() then
        return
    end
    if string.IsNilOrEmpty(self.InputFunitueCount.text) then
        self.InputFunitueCount.text = tostring(self.RefitCount)
        return
    end
    
    self.RefitCount = tonumber(self.InputFunitueCount.text)
    self:AutoSelectFurnitureIds()
    self:RefreshEdit()
end

function XUiPanelRefitNew:OnBtnAddClick()
    if not self:IsSelectPreview() then
        return
    end
    
    self.RefitCount = self.RefitCount + 1
    self:AutoSelectFurnitureIds()
    self:RefreshEdit()
end

function XUiPanelRefitNew:OnBtnReduceClick()
    if not self:IsSelectPreview() then
        return
    end
    if self.RefitCount < 1 then
        return
    end

    self.RefitCount = self.RefitCount - 1
    self:AutoSelectFurnitureIds()
    self:RefreshEdit()
end

function XUiPanelRefitNew:OnBtnMaxClick()
    if not self:IsSelectPreview() then
        return
    end
    
    self.RefitCount = self.MaxRefit < 0 and 1 or self.MaxRefit
    self:AutoSelectFurnitureIds()
    self:RefreshEdit()
end

function XUiPanelRefitNew:OnBtnMinClick()
    if not self:IsSelectPreview() then
        return
    end

    if self.RefitCount == 1 then
        return
    end
    
    self.RefitCount = 1
    self:AutoSelectFurnitureIds()
    self:RefreshEdit()
end

function XUiPanelRefitNew:OnBtnConfirmClick()
    if not self:IsSelectPreview() then
        XUiManager.TipText("FurnitureChooseFurniture")
        return
    end

    if not self.CostEnough then
        XUiManager.TipText("FurnitureZeroCoin")
        return
    end

    if not self.MaterialEnough then
        XUiManager.TipText("FurnitureOrDrawingNotEnough")
        return
    end
    
    local request = function()
        local template = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewFurnitureId)
        local map = {
            [template.PicId] = self.FurnitureIds
        }
        local tempPreviewId = self.PreviewFurnitureId
        XUiHelper.LimitContinuousClick(self.BtnConfirm)
        XDataCenter.FurnitureManager.RemouldFurniture(map, self.OnRequestCb, function(ids)
            self.PreviewFurnitureId = tempPreviewId
            self.FurnitureIds = ids
            self:RefreshPreviewFurniture()
            self:OnBtnConfirmClick()
        end)
    end
    if self:IsSelectNonBasicSuit() then
        local title = XUiHelper.GetText("TipTitle")
        local content = XUiHelper.GetText("FurnitureContainNonBasicTip")
        XUiManager.DialogTip(title, content, nil, nil, request)
    else
        request()
    end
   
end

function XUiPanelRefitNew:OnBtnPreviewFurnitureClick()
    XLuaUiManager.Open("UiDormFieldGuide", self.SelectSuitId, true, self.PreviewFurnitureId, self.OnSelectPreviewCb)
end

function XUiPanelRefitNew:OnBtnDrawingClick()
    if not self:IsSelectPreview() then
        XUiManager.TipText("FurnitureChooseFurniture")
        return
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewFurnitureId)
    local itemId = template.PicId
    local own = XDataCenter.ItemManager.GetCount(itemId)
    local buyCount = own >= self.RefitCount and 1 or self.RefitCount - own
    
    XDataCenter.FurnitureManager.JumpToBuyDrawing(self.PreviewFurnitureId, buyCount, function()
        self:RefreshEdit()
    end)
end

function XUiPanelRefitNew:OnSelectFurnitureClick()
    if not XTool.IsNumberValid(self.PreviewFurnitureId) then
        return
    end

    local typeId = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewFurnitureId).TypeId
    -- 策划需要玩家手动选择时也能选中目标类型的家具
    --XLuaUiManager.Open("UiDormBagChoice", self.FurnitureIds, typeId, 0, self.OnSelectFurnitureCb, { [self.PreviewFurnitureId] = true })
    XLuaUiManager.Open("UiDormBagChoice", self.FurnitureIds, typeId, 0, self.OnSelectFurnitureCb)
end

--- 选中预览家具回调
---@param suitCfg XTable.XTableFurnitureSuit
---@param furnitureCfg XTable.XTableFurniture
--------------------------
function XUiPanelRefitNew:OnSelectPreview(suitCfg, furnitureCfg)
    self.SelectSuitId = suitCfg and suitCfg.Id or XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID
    local previewId = furnitureCfg and furnitureCfg.Id or 0
    if self.PreviewFurnitureId ~= previewId then
        self.ManualFurnitureIds = {}
    end
    self.PreviewFurnitureId = previewId

    self.RefitCount = XTool.IsNumberValid(self.PreviewFurnitureId) and 1 or 0
    self:AutoSelectFurnitureIds()
    self:RefreshPreviewFurniture()
    self:RefreshRandomEffect()
end

--- 选中材料家具回调
---@param furnitureIds number[] 家具Id列表
--------------------------
function XUiPanelRefitNew:OnSelectFurnitureIds(furnitureIds)
    self.FurnitureIds = furnitureIds
    self.FurnitureIdsCache = furnitureIds
    self.ManualFurnitureIds = furnitureIds
    self.RefitCount = #furnitureIds
    self.TogCheck.isOn = self:IsSelectNonBasicSuit()
    self:RefreshEdit()
    self:RefreshRandomEffect()
end

--自动填充
function XUiPanelRefitNew:AutoSelectFurnitureIds()
    if not XTool.IsNumberValid(self.PreviewFurnitureId) then
        return
    end

    --置空选中
    self.FurnitureIds = XTool.Clone(self.ManualFurnitureIds)
    self.FurnitureIdsCache = XTool.Clone(self.ManualFurnitureIds)
    
    -- 玩家选中大于需要制作数量
    local count = #self.FurnitureIds
    if count >= self.RefitCount then
        for i = count, self.RefitCount + 1, -1 do
            table.remove(self.FurnitureIds, i)
        end
        return
    end
    
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewFurnitureId)
    local typeIds = { template.TypeId }
    --自动填充时过滤目标家具
    local furnitureIds = XDataCenter.FurnitureManager.GetFurnitureCategoryIdsNoSort(typeIds,
            nil, nil, true, false, true, (not self.AllowNonBasic), { [self.PreviewFurnitureId] = true })
    
    if not XTool.IsTableEmpty(furnitureIds) then
        local sortFunc = self.AllowNonBasic and self.OnSortFurnitureCb or self.OnSortFurnitureBaseCb
        table.sort(furnitureIds, sortFunc)
    end
    self.FurnitureIdsCache = appendArray(self.FurnitureIdsCache, furnitureIds)

    for i = count + 1, self.RefitCount do
        table.insert(self.FurnitureIds, furnitureIds[i])
    end
end

--材料家具排序-任意套装
function XUiPanelRefitNew:OnSortFurniture(furnitureIdA, furnitureIdB)
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
function XUiPanelRefitNew:OnSortFurnitureBase(furnitureIdA, furnitureIdB)
    local furnitureA = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIdA)
    local furnitureB = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIdB)

    local scoreA = furnitureA and furnitureA:GetScore() or 0
    local scoreB = furnitureB and furnitureB:GetScore() or 0

    if scoreA ~= scoreB then
        return scoreA > scoreB
    end

    return furnitureIdA < furnitureIdB
end

function XUiPanelRefitNew:OnRequest(furnitureIds)
    self.PreviewFurnitureId = 0
    self.RefitCount = 0
    self.ManualFurnitureIds = {}
    self:RefreshPreviewFurniture()
end

function XUiPanelRefitNew:IsSelectPreview()
    return XTool.IsNumberValid(self.PreviewFurnitureId)
end

function XUiPanelRefitNew:IsSelectFurniture()
    return not XTool.IsTableEmpty(self.FurnitureIds)
end

function XUiPanelRefitNew:IsSelectNonBasicSuit()
    for _, furnitureId in pairs(self.FurnitureIds) do
        if XTool.IsNumberValid(furnitureId) then
            local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
            if furniture and furniture:GetSuitId() ~= XFurnitureConfigs.BASE_SUIT_ID then
                return true
            end
        end
    end
    
    return false
end

function XUiPanelRefitNew:GetCostMoney()
    local cost = 0

    for _, furnitureId in pairs(self.FurnitureIds) do
        local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
        local price = 0
        if furniture then
            local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId())
            price = template.MoneyNum
        end
        cost = cost + price
    end
    
    return cost
end

function XUiPanelRefitNew:GetMinFurnitureLevel()
    local min = XFurnitureConfigs.FurnitureAttrLevelId.LevelS
    for _, furnitureId in pairs(self.FurnitureIds) do
        local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
        if furniture then
            min = math.min(furniture:GetFurnitureTotalAttrLevel(), min)
        end
    end
    
    return min
end

--最大改造个数
function XUiPanelRefitNew:GetMaxRefit()
    if not self:IsSelectPreview() then
        return 0
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.PreviewFurnitureId)
    local picId = template.PicId
    local ownCount = XDataCenter.ItemManager.GetCount(picId)
    --现在拥有的图纸能制作的个数
    local createCount = math.floor(ownCount / template.PicNum)
    
    local freeCount = 0
    for _, furnitureId in ipairs(self.FurnitureIdsCache) do
        local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
        if not furniture then
            goto continue
        end
        --允许使用非基础家具
        if self.AllowNonBasic then
            freeCount = freeCount + 1
        else
            if furniture:CheckIsBaseFurniture() then
                freeCount = freeCount + 1
            end
        end

        if freeCount >= createCount then
            break
        end
        
        :: continue ::
    end
    return math.min(freeCount, createCount)
end

return XUiPanelRefitNew