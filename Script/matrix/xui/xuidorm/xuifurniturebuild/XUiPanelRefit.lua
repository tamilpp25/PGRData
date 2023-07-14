-- 家具改造子界面
XUiPanelRefit = XClass(nil, "XUiPanelRefit")

local DEFAULT_STRING1 = "？"
local DEFAULT_STRING2 = CS.XTextManager.GetText("None")
local DEFAULT_STRING3 = CS.XTextManager.GetText("SelectFurniture")
-- local DEFAULT_DATA = {[1] = DEFAULT_STRING1, [2] = DEFAULT_STRING1, [3] = DEFAULT_STRING1 }

local EnoughColor = CS.UnityEngine.Color(0, 0, 0)
local NotEnoughColor = CS.UnityEngine.Color(1, 0, 0)

-- local CFG = {
--     ConsumeCount = 3
-- }

function XUiPanelRefit:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.SelectedFurnitureIds = nil
    self.SelectedDrawingId = nil

    self.BtnSelectFurniture.CallBack = function() self:OnBtnSelectFurnitureClick() end
    self.BtnSelectDrawing.CallBack = function() self:OnBtnSelectDrawingClick() end
    self.BtnRefit.CallBack = function() self:OnBtnRefitClick() end
end

function XUiPanelRefit:Init(drawingId, furnitureTypeId)
    self:SelectFurniture()
    self:SelectDrawing()
    self.TxtConsume.text = CS.XTextManager.GetText("UiPanelRefitConsume")
    self.TxtSelectDrawing.text = CS.XTextManager.GetText("UiPanelRefitSelectDrawing")

    self.SelectedDrawingId = drawingId
    self.FrunitureTypeId = furnitureTypeId

    if self.SelectedDrawingId then
        self:SelectDrawing(self.SelectedDrawingId)
        self:OnBtnSelectFurnitureClick()
    end
end

function XUiPanelRefit:SetPanelActive(value)
    self.GameObject:SetActiveEx(value)
    if not value then
        if self.SelectedFurnitureIds then
            self:SelectFurniture()
        end

        if self.SelectedDrawingId then
            self:SelectDrawing()
        end
    else
        self.RootUi:PlayAnimRefitEnable()
    end
end

function XUiPanelRefit:CheckClearDrawing(furnitureIds)
    if self.SelectedDrawingId then
        local id = type(furnitureIds) == "table" and furnitureIds[1] or furnitureIds
        local selectedFurnitureDatas = XDataCenter.FurnitureManager.GetFurnitureById(id)
        local selectedFurnitureTemplate = XFurnitureConfigs.GetFurnitureTemplateById(selectedFurnitureDatas.ConfigId)

        local previewFurnitureId = XFurnitureConfigs.GetPreviewFurnitureByDrawingId(self.SelectedDrawingId)
        if not previewFurnitureId then
            self.SelectedDrawingId = nil
            self:SelectDrawing()
            return
        end

        local previewFurnitureTemplate = XFurnitureConfigs.GetFurnitureTemplateById(previewFurnitureId)
        if not previewFurnitureTemplate then
            self.SelectedDrawingId = nil
            self:SelectDrawing()
            return
        end

        if selectedFurnitureTemplate.TypeId ~= previewFurnitureTemplate.TypeId then
            self.SelectedDrawingId = nil
            self:SelectDrawing()
        end
    end
end

--显示选择的家具信息
function XUiPanelRefit:SelectFurniture(furnitureIds)
    if furnitureIds then
        local furnitureDatas = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIds)
        if not furnitureDatas then
            self:SelectFurniture()
            return
        end

        -- 新增一个处理，如果已经选择了图纸，并且该图纸不能匹配当前的家具，清空
        self:CheckClearDrawing(furnitureIds)
        self.SelectedFurnitureIds = furnitureIds

        -- 多选还是单选状态
        local isList = type(furnitureIds) == "table"

        local data = XDataCenter.FurnitureManager.GetFurnitureById(isList and furnitureIds[1] or furnitureIds)
        local cfg = XFurnitureConfigs.GetFurnitureTemplateById(data.ConfigId)
        self.FrunitureTypeId = cfg.TypeId

        if isList then
            local typeCfg = XFurnitureConfigs.GetFurnitureTypeById(cfg.TypeId)
            self.TxtSelectName.text = typeCfg.CategoryName
            self.TxtSelectNum.text = CS.XTextManager.GetText("DormRefitEnoughCount", #furnitureIds)
            self.ImgBtnSelectFurniture:SetRawImage(typeCfg.TypeIcon)
        else
            self.TxtSelectFurniture.text = ""
            local totalScore = 0
            for _, v in pairs(furnitureDatas.AttrList or {}) do
                totalScore = totalScore + v
            end

            local addition = furnitureDatas.Addition or 0
            local introduce = DEFAULT_STRING2
            if addition > 0 then
                totalScore = totalScore + XFurnitureConfigs.GetAdditionalAddScore(addition)
                local str = XFurnitureConfigs.GetAdditionalRandomEntry(addition)
                introduce = string.format("%s\n%s", str,XFurnitureConfigs.GetAdditionalRandomIntroduce(addition))
            end

            self.TxtSelectScore.text = CS.XTextManager.GetText("FurnitureRefitScore", totalScore)
            self.TxtSelectSpecial.text = introduce
            self.ImgBtnSelectFurniture:SetRawImage(XDataCenter.FurnitureManager.GetFurnitureIconById(furnitureIds, XDormConfig.DormDataType.Self))
        end

        self.PanelSelectFrunitureInfo.gameObject:SetActiveEx(not isList)
        self.PanelSelectFrunitureInfos.gameObject:SetActiveEx(isList)
        self.TxtSelectScore.gameObject:SetActiveEx(not isList)
        self.TxtSelectSpecial.gameObject:SetActiveEx(not isList)
        self.BtnSelectFurnitureCanvasGroup.alpha = 0
        self.ImgBtnSelectFurniture.gameObject:SetActiveEx(true)
    else
        self.SelectedFurnitureIds = nil
        self.FrunitureTypeId = nil
        self.TxtSelectFurniture.text = DEFAULT_STRING3
        self.TxtSelectScore.gameObject:SetActiveEx(false)
        self.TxtSelectSpecial.gameObject:SetActiveEx(false)
        self.PanelSelectFrunitureInfo.gameObject:SetActiveEx(false)
        self.PanelSelectFrunitureInfos.gameObject:SetActiveEx(false)
        self.ImgBtnSelectFurniture.gameObject:SetActiveEx(false)
        self.BtnSelectFurnitureCanvasGroup.alpha = 1
    end

    -- 计算消耗材料
    local ownFurnitureNum = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin)
    local needFurnitureNum = self:GetRefitNeedMoney(self.SelectedFurnitureIds)
    self.TxtConsumeCount.text = needFurnitureNum
    self.ImgDrawingIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.FurnitureCoin))
    if ownFurnitureNum >= needFurnitureNum then
        self.TxtConsumeCount.color = EnoughColor
        self.IsCoinEnough = true
    else
        self.TxtConsumeCount.color = NotEnoughColor
        self.IsCoinEnough = false
    end

    self:RefrshDrwaingCount()
    self:CheckPreview()
end

--显示选择的图纸信息
function XUiPanelRefit:SelectDrawing(DraftId)
    if DraftId then
        self.SelectedDrawingId = DraftId
        local icon = XDataCenter.ItemManager.GetItemIcon(DraftId)
        local name = XDataCenter.ItemManager.GetItemName(DraftId)
        self.PanelSelectDrawingInfo.gameObject:SetActiveEx(true)
        self.ImgSelectDrawing:SetRawImage(icon)
        self.TxtSelectDrawing.text = ""
        self.BtnSelectDrawingCanvasGroup.alpha = 0

        -- 检查是否批量建造
        self:RefrshDrwaingCount()
        self.TxtSelectDrawName.text = name
    else
        self.SelectedDrawingId = nil
        self.PanelSelectDrawingInfo.gameObject:SetActiveEx(false)
        self.TxtSelectDrawing.text = CS.XTextManager.GetText("UiPanelRefitSelectDrawing")
        self.BtnSelectDrawingCanvasGroup.alpha = 1
    end
    self:CheckPreview()
end

-- 刷新图纸数量
function XUiPanelRefit:RefrshDrwaingCount()
    if not self.SelectedDrawingId then
        self.TxtSelectDrawNum.text = CS.XTextManager.GetText("DormRefitEnoughCount", 0)
        return
    end

    local draftCount = XDataCenter.ItemManager.GetCount(self.SelectedDrawingId)
    local furnitrueCount = self:IsFurnitureTable() and #self.SelectedFurnitureIds or 1
    local content = furnitrueCount > draftCount and CS.XTextManager.GetText("DormRefitNoEnoughCount", furnitrueCount)
    or CS.XTextManager.GetText("DormRefitEnoughCount", furnitrueCount)
    self.TxtSelectDrawNum.text = content
end

--显示预览信息
function XUiPanelRefit:CheckPreview()

    self.TxtPreviewScore.text = CS.XTextManager.GetText("FurnitureRefitScore", DEFAULT_STRING1)
    self.BtnSelectDrawing:SetDisable(false, true)
    self.PreviewKuangDisable.gameObject:SetActiveEx(false)
    self.previewArrowDisable.gameObject:SetActiveEx(false)
    self.previewArrowEnable.gameObject:SetActiveEx(true)

    if self.SelectedFurnitureIds and self.SelectedDrawingId then
        -- 通过图纸拿到要生成的家具ID，通过判断类型是否一致决定是否显示
        local previewFurnitureId = XFurnitureConfigs.GetPreviewFurnitureByDrawingId(self.SelectedDrawingId)
        if not previewFurnitureId then
            self.ImgPreviewItemIcon.gameObject:SetActiveEx(false)
            return
        end

        -- -- 检查预览的家具，改装的家具类型是否一致
        local id = self:IsFurnitureTable() and self.SelectedFurnitureIds[1] or self.SelectedFurnitureIds
        local furnitureDatas = XDataCenter.FurnitureManager.GetFurnitureById(id)
        local furnitureTemplates = XFurnitureConfigs.GetFurnitureTemplateById(furnitureDatas.ConfigId)
        local previewDatas = XFurnitureConfigs.GetFurnitureTemplateById(previewFurnitureId)

        if furnitureTemplates.TypeId ~= previewDatas.TypeId then
            self.ImgPreviewItemIcon.gameObject:SetActiveEx(false)
            self.ImageAdd.gameObject:SetActiveEx(false)
        else
            local furnitureBaseTemplates = XFurnitureConfigs.GetFurnitureBaseTemplatesById(previewFurnitureId)
            self.ImgPreviewItemIcon.gameObject:SetActiveEx(true)
            self.ImgPreviewItemIcon:SetRawImage(furnitureBaseTemplates.Icon)
            self.ImageAdd.gameObject:SetActiveEx(true)
        end

        -- 查询组随机属性
        local hasRandomGroup = previewDatas.RandomGroupId > 0
        self.PanelIcon.gameObject:SetActiveEx(hasRandomGroup)
        if hasRandomGroup then
            local groupIntroduce = XFurnitureConfigs.GetGroupRandomIntroduce(previewDatas.RandomGroupId)
            local introduceBuffer = ""
            local a = {}
            for _, v in pairs(groupIntroduce) do
                for _,v1 in pairs(v) do
                    local key = XFurnitureConfigs.GetAdditionalRandomEntry(v1.Id,true)
                    if not a[key] then
                        a[key] = ""
                    end
                    a[key] = a[key] .. string.format("%s\n",v1.Introduce)
                end
            end
            for k,str in pairs(a)do
                local des = string.format("%s\n%s\n", k, str)
                introduceBuffer = introduceBuffer .. des
            end
            self.TxtPreviewSpecial.text = introduceBuffer
            self:ResizeRandomGroupContent()
        end

    else
        if self.SelectedFurnitureIds == nil then
            -- 未选中家具，不能选择图纸
            self.BtnSelectDrawing:SetDisable(true, false)
            self.PreviewKuangDisable.gameObject:SetActiveEx(true)
            self.previewArrowDisable.gameObject:SetActiveEx(true)
            self.previewArrowEnable.gameObject:SetActiveEx(false)
        end

        self.ImgPreviewItemIcon.gameObject:SetActiveEx(false)
        self.PanelIcon.gameObject:SetActiveEx(false)
        self.ImageAdd.gameObject:SetActiveEx(false)
    end
end

function XUiPanelRefit:ResizeRandomGroupContent()
    local rectTransform = self.TxtPreviewSpecial.transform:GetComponent("RectTransform")
    local adjustHeight = self.TxtPreviewSpecial.preferredHeight
    local sizeDelta = rectTransform.sizeDelta
    rectTransform.sizeDelta = CS.UnityEngine.Vector2(sizeDelta.x, adjustHeight)
end

function XUiPanelRefit:GetRefitNeedMoney(ids)
    if not ids then
        return 0
    end

    local func = function(id)
        local furnitureDatas = XDataCenter.FurnitureManager.GetFurnitureById(id)
        if not furnitureDatas then
            return 0
        else
            local configId = furnitureDatas.ConfigId
            local furnitureTemplates = XFurnitureConfigs.GetFurnitureTemplateById(configId)
            return furnitureTemplates.MoneyNum
        end
    end

    if type(ids) == "table" then
        local count = 0
        for _, id in pairs(ids) do
            local curCount = func(id)
            count = count + curCount
        end
        return count
    else
        return func(ids)
    end
end

function XUiPanelRefit:OnBtnSelectFurnitureClick()
    --TODO
    --跳转到仓库选择一个家具
    local pageRecord = XDormConfig.DORM_BAG_PANEL_INDEX.FURITURE
    local furnitureState = XFurnitureConfigs.FURNITURE_STATE.SELECT
    local func = function(furnitureIds)
        local ids = #furnitureIds > 1 and furnitureIds or furnitureIds[1]
        self:SelectFurniture(ids)
    end
    local filter = function(furnitureId)
        return not XDataCenter.FurnitureManager.GetFurnitureIsLocked(furnitureId)
    end
    XLuaUiManager.Open("UiDormBag", pageRecord, furnitureState, func, filter, nil, self.FrunitureTypeId)
end

function XUiPanelRefit:OnBtnSelectDrawingClick()
    --TODO
    --跳转到仓库选择一个图纸
    local pageRecord = XDormConfig.DORM_BAG_PANEL_INDEX.DRAFT
    local furnitureState = XFurnitureConfigs.FURNITURE_STATE.SELECTSINGLE
    local func = function(draftId)
        self:SelectDrawing(draftId)
    end
    local filter = function(drawingId)
        if self.SelectedFurnitureIds then
            local id = self:IsFurnitureTable() and self.SelectedFurnitureIds[1] or self.SelectedFurnitureIds
            local selectedFurnitureDatas = XDataCenter.FurnitureManager.GetFurnitureById(id)
            local selectedFurnitureTemplate = XFurnitureConfigs.GetFurnitureTemplateById(selectedFurnitureDatas.ConfigId)

            local typeDatas = XFurnitureConfigs.GetRefitTypeDatas(selectedFurnitureTemplate.TypeId) or {}
            for _, v in pairs(typeDatas) do
                if v.PicId == drawingId and v.GainType == XFurnitureConfigs.GainType.Refit then
                    return true
                end
            end
            return false

        end
        return true
    end
    local count = self:IsFurnitureTable() and #self.SelectedFurnitureIds or 1
    local fromRefit = true
    XLuaUiManager.Open("UiDormBag", pageRecord, furnitureState, func, filter, count, nil, nil, fromRefit)
end

function XUiPanelRefit:OnBtnRefitClick()
    if not self.SelectedFurnitureIds then
        XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureChooseFurniture"))
        return
    end

    if not self.SelectedDrawingId then
        XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureChooseDraft"))
        return
    end

    if not self.IsCoinEnough then
        XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureZeroCoin"))
        return
    end

    -- 检查图纸是否足够
    local draftCount = XDataCenter.ItemManager.GetCount(self.SelectedDrawingId)
    local furnitrueCount = self:IsFurnitureTable() and #self.SelectedFurnitureIds or 1
    if furnitrueCount > draftCount then
        -- local buyCount = furnitrueCount - draftCount
        -- local configId = self.SelectedDrawingId
        --TODO::: 进入快捷购买界面
        XUiManager.TipMsg(CS.XTextManager.GetText("DormNotEnoughDraft"), XUiManager.UiTipType.Tip)
        return
    end

    -- 图纸是否可以改装家具,通过图纸找到改装之后的家具，然后判断：改装之后生成的家具、用于改装的家具两者类型是否一致。
    local previewFurnitureId = XFurnitureConfigs.GetPreviewFurnitureByDrawingId(self.SelectedDrawingId)
    if not previewFurnitureId then
        XUiManager.TipMsg(CS.XTextManager.GetText("FunitureCannotCompound"))
        return
    end

    local check = function(id)
        local furnitureDatas = XDataCenter.FurnitureManager.GetFurnitureById(id)
        local previewTypeId = XFurnitureConfigs.GetFurnitureTemplateById(previewFurnitureId).TypeId
        local selectTypeId = XFurnitureConfigs.GetFurnitureTemplateById(furnitureDatas.ConfigId).TypeId
        if previewTypeId ~= selectTypeId then
            XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureNotMatchDraft"))
            return false
        end

        return true
    end

    -- 检查预览的家具，改装的家具类型是否一致
    if self:IsFurnitureTable() then
        for _, id in ipairs(self.SelectedFurnitureIds) do
            if not check(id) then
                return
            end
        end
    else
        if not check(self.SelectedFurnitureIds) then
            return
        end
    end

    local ids = self:IsFurnitureTable() and self.SelectedFurnitureIds or {self.SelectedFurnitureIds}
    XDataCenter.FurnitureManager.RemouldFurniture(ids, self.SelectedDrawingId, function(furnitureList)
        self:Init()
        if furnitureList then
            XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureRefitSuccess"), XUiManager.UiTipType.Tip, function()
                if #furnitureList > 1 then
                    local gainType = XFurnitureConfigs.GainType.Refit
                    XLuaUiManager.Open("UiFurnitureObtain", gainType, furnitureList, function(furnitureIds)
                        self:SelectFurniture(furnitureIds)
                        self:SelectDrawing()
                    end)

                    return
                end
                XLuaUiManager.Open("UiFurnitureDetail", furnitureList[1].Id, furnitureList[1].ConfigId)
            end)
        end
    end)
end

function XUiPanelRefit:IsFurnitureTable()
    return type(self.SelectedFurnitureIds) == "table"
end

return XUiPanelRefit