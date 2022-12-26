-- 家具建造节点
XUiGridCreate = XClass(nil, "XUiGridCreate")

local CREATE_STATE = {
    AVALIABLE = 0,
    CREATING = 1,
    COMPLETE = 2,
}

function XUiGridCreate:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    self.CurrentState = nil
    self.WorkingTimer = nil
    self.CreateState = CREATE_STATE.AVALIABLE
    self.RemainingTime = 0

    XTool.InitUiObject(self)

    self:AddBtnsListeners()
    self.BtnStart.CallBack = function()
        if not self.Cfg then return end

        XLuaUiManager.Open("UiFurnitureCreate", nil, nil, self.Cfg.Pos, function(pos)
            self.Parent:UpdateCreateGridByPos(pos)
        end)

    end
end

function XUiGridCreate:Rename(index)
    self.GameObject.name = string.format("GridCreate%d", index)
end

function XUiGridCreate:AddBtnsListeners()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnCheck, self.OnBtnCheckClick)
end

function XUiGridCreate:RegisterListener(uiNode, eventName, func)
    if not uiNode then return end
    local key = eventName .. uiNode:GetHashCode()
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiBtnTab:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiGridCreate:Init(cfg, parent)
    self.Parent = parent
    self.Cfg = cfg

    self:UpdateCreate()
end

function XUiGridCreate:OnClose()
    self:RemoveWorkingTimer()
end

function XUiGridCreate:UpdateCreate()
    if not self.Cfg then return end
    local createDatas = XDataCenter.FurnitureManager.GetFurnitureCreateItemByPos(self.Cfg.Pos)
    local now = XTime.GetServerNowTimestamp()

    if createDatas then
        --这个坑位正在创造或者已经创造完成
        local furnitureTemplates, furnitureBaseTemplates
        if createDatas.Count <= 1 then
            local configId = createDatas.Furniture.ConfigId
            furnitureTemplates = XFurnitureConfigs.GetFurnitureTemplateById(configId)
            furnitureBaseTemplates = XFurnitureConfigs.GetFurnitureBaseTemplatesById(configId)
            if (not furnitureTemplates) or (not furnitureBaseTemplates) then
                return
            end
        end

        local finishTime = createDatas.EndTime
        self.RemainingTime = finishTime - now
        self.RemainingTime = (self.RemainingTime < 0) and 0 or self.RemainingTime
        if finishTime > now then
            --坑位正在制作家具
            self.PanelAttris.gameObject:SetActive(createDatas.Count <= 1)
            self.PanelMany.gameObject:SetActive(createDatas.Count > 1)

            if createDatas.Count > 1 then
                self.TxtWorkingFurnitureName.text = XFurnitureConfigs.DefaultName
                self.ImgWorkingItemIcon:SetRawImage(XFurnitureConfigs.DefaultIcon)
                self.TxtWorkKey.text = XFurnitureConfigs.DefaultName .. CS.XTextManager.GetText("DormBuildCountDesc")
                self.TxtWorkValue.text = "x" .. tostring(createDatas.Count)
            else
                local typeDatas = XFurnitureConfigs.GetFurnitureTypeById(furnitureTemplates.TypeId)
                if not typeDatas then return end
                self.ImgWorkingItemIcon:SetRawImage(typeDatas.TypeIcon)
                self.TxtWorkingFurnitureName.text = typeDatas.CategoryName
            end

            self.CreateState = CREATE_STATE.CREATING
        else
            --坑位家具制作完成，可以领取
            self.PanelComAttris.gameObject:SetActive(createDatas.Count <= 1)
            self.PanelComMany.gameObject:SetActive(createDatas.Count > 1)

            if createDatas.Count > 1 then
                self.TxtCompleteFurnitureName.text = XFurnitureConfigs.DefaultName
                self.ImgCompleteItemIcon:SetRawImage(XFurnitureConfigs.DefaultIcon)
                self.TxtCompleteKey.text = XFurnitureConfigs.DefaultName .. CS.XTextManager.GetText("DormBuildCountDesc")
                self.TxtCompleteValue.text = "x" .. tostring(createDatas.Count)
            else
                self.ImgCompleteItemIcon:SetRawImage(XDataCenter.FurnitureManager.GetIconByFurniture(createDatas.Furniture))
                self.TxtCompleteFurnitureName.text = furnitureBaseTemplates.Name
                self:UpdateFurnitureCompleteAttris(createDatas.Furniture, furnitureTemplates)
            end

            self.CreateState = CREATE_STATE.COMPLETE
        end
    else
        --这个坑位空闲
        self.CreateState = CREATE_STATE.AVALIABLE
    end

    local serialNumber = string.format("0%d", self.Cfg.Pos + 1)
    self.TxtStartLabel.text = serialNumber
    self.TxtWorkingLabel.text = serialNumber
    self.TxtCompleteLabel.text = serialNumber

    if self.CreateState == CREATE_STATE.CREATING then--剩余时间
        self:AddWorkingTimer()
    end

    self:UpdateCreateView(self.CreateState)
end

function XUiGridCreate:UpdateCreateView(currentState)
    self.PanelStart.gameObject:SetActive(currentState == CREATE_STATE.AVALIABLE)
    self.PanelWorking.gameObject:SetActive(currentState == CREATE_STATE.CREATING)
    self.PanelComplete.gameObject:SetActive(currentState == CREATE_STATE.COMPLETE)
end

function XUiGridCreate:UpdateFurnitureWorkingAttris(furniture, furnitureTemplates)
    if not furniture then return end
    for i = 1, #furniture.AttrList do
        local attrScore = furniture.AttrList[i] or 0
        self[string.format("TxtWorkingValue%d", i)].text = XFurnitureConfigs.GetFurnitureAttrLevelDescription(furnitureTemplates.TypeId, i, attrScore)
    end
end
function XUiGridCreate:UpdateFurnitureCompleteAttris(furniture, furnitureTemplates)
    if not furniture then return end
    for i = 1, #furniture.AttrList do
        local attrScore = furniture.AttrList[i] or 0
        self[string.format("TxtCompleteValue%d", i)].text = XFurnitureConfigs.GetFurnitureAttrLevelDescription(furnitureTemplates.TypeId, i, attrScore)
    end
end

function XUiGridCreate:AddWorkingTimer()
    self:RemoveWorkingTimer()
    local dataTime = XUiHelper.GetTime(self.RemainingTime, XUiHelper.TimeFormatType.HOSTEL)
    self.TxtRemaining.text = dataTime
    self.WorkingTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.Transform) then
            self:RemoveWorkingTimer()
            return
        end
        local dataTimeNew
        self.RemainingTime = self.RemainingTime - 1
        if self.RemainingTime <= 0 then
            dataTimeNew = XUiHelper.GetTime(0, XUiHelper.TimeFormatType.HOSTEL)
            self.TxtRemaining.text = dataTimeNew
            self:RemoveWorkingTimer()
            self:UpdateCreate()
        else
            dataTimeNew = XUiHelper.GetTime(self.RemainingTime, XUiHelper.TimeFormatType.HOSTEL)
            self.TxtRemaining.text = dataTimeNew
        end
    end, 1000)
end

function XUiGridCreate:GetProgress()
    if not self.Cfg then return 0 end
    local createDatas = XDataCenter.FurnitureManager.GetFurnitureCreateItemByPos(self.Cfg.Pos)
    local now = XTime.GetServerNowTimestamp()
    if not createDatas then return 0 end

    local configId = createDatas.Furniture.ConfigId
    local furnitureTemplates = XFurnitureConfigs.GetFurnitureTemplateById(configId)
    local progress = (now - createDatas.EndTime + furnitureTemplates.CreateTime) / furnitureTemplates.CreateTime
    return (progress > 1) and 1 or progress
end

function XUiGridCreate:RemoveWorkingTimer()
    if self.WorkingTimer then
        XScheduleManager.UnSchedule(self.WorkingTimer)
        self.WorkingTimer = nil
    end
end

function XUiGridCreate:OnBtnStartClick()
    self.Parent:ShowPanelCreationDetail(self.Cfg.Pos)
end

function XUiGridCreate:OnBtnCheckClick()
    -- 领取
    if self.CreateState and self.CreateState == CREATE_STATE.COMPLETE and self.Cfg then
        XDataCenter.FurnitureManager.CheckCreateFurniture(self.Cfg.Pos, function(furnitureList, createCoinCount)
            self:RemoveWorkingTimer()
            self:UpdateCreate()

            if #furnitureList > 1 then
                local gainType = XFurnitureConfigs.GainType.Create
                XLuaUiManager.Open("UiFurnitureObtain", gainType, furnitureList, nil, createCoinCount, self.Cfg.Pos, function(pos)
                    self.Parent:UpdateCreateGridByPos(pos)
                end)

                return
            end
            XLuaUiManager.Open("UiFurnitureDetail", furnitureList[1].Id, furnitureList[1].ConfigId)

        end)
    end
end

return XUiGridCreate