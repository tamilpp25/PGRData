

---@class XUiDormDormitoryFormWork : XLuaUi
---@field BtnContent XUiButtonGroup
---@field TabList XTable.XTableDormTemplateGroup[]
---@field SViewTemplatePanel XUiPanelSViewReform
local XUiDormDormitoryFormWork = XLuaUiManager.Register(XLuaUi, "UiDormDormitoryFormWork")
local XUiPanelSViewReform = require("XUi/XUiDorm/XUiFurnitureReform/XUiPanelSViewReform")

local DefaultSelectTabIndex = 1 --默认选中下标
local DormTemplateCache = {} --宿舍模板缓存

function XUiDormDormitoryFormWork:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiDormDormitoryFormWork:OnStart(dormDataType, roomId)
    self.DefaultDormType = dormDataType
    self.RoomId = roomId
    self:InitView()
end

function XUiDormDormitoryFormWork:OnEnable()
    self:SetupDynamicTable()
    self:RefreshControlBtnState()
    self:RefreshTabCount()
end

function XUiDormDormitoryFormWork:OnDisable()
    self:ClearTemplateDormitoryCache()
end

function XUiDormDormitoryFormWork:OnDestroy()
    self:DestroyView()
end

function XUiDormDormitoryFormWork:InitUi()
    --页签
    self.TabList = XDormConfig.GetDormTemplateGroupList()
    local tab = {}
    for i, template in ipairs(self.TabList) do
        local btn = i == 1 and self.BtnFirst or XUiHelper.Instantiate(self.BtnFirst, self.BtnContent.transform)
        btn:SetNameByGroup(0, template.Name .. XDataCenter.DormManager.GetTemplateDormitoryCount(template.DormType))
        btn:SetSprite(template.BtnIcon)
        table.insert(tab, btn)
    end
    self.BtnContent:Init(tab, function(tabIndex) self:OnSelectTab(tabIndex) end)
    self.TabButton = tab
    --动态列表
    self.SViewTemplatePanel = XUiPanelSViewReform.New(self.PanelSViewFurniture, self, require("XUi/XUiDorm/XUiFurnitureReform/XUiGridTemplateItem"))
    self.SViewTemplatePanel:RegisterClickGrid(function(homeData) 
        self:OnSelectTemplate(homeData)
    end)
    
    self.OnPutTemplateCb = handler(self, self.PutTemplateFurniture)
end 

function XUiDormDormitoryFormWork:RefreshTabCount()
    for i, template in ipairs(self.TabList) do
        local btn = self.TabButton[i]
        if btn then
            btn:SetNameByGroup(0, string.format("%s %d", template.Name, XDataCenter.DormManager.GetTemplateDormitoryCount(template.DormType)))
        end
    end
end

function XUiDormDormitoryFormWork:InitCb()
    self.BtnBack.CallBack = function() 
        self:OnBtnBackClick()
    end
    
    self.BtnPut.CallBack = function() 
        self:OnBtnPutClick()
    end
    
    self.BtnTarget.CallBack = function() 
        self:OnBtnTargetClick()
    end
    
    self.BtnUnbind.CallBack = function() 
        self:OnBtnUnbindClick()
    end

    self.BtnEditRoom.CallBack = function()
        self:OnBtnEditRoomClick()
    end

    self.BtnFabrication.CallBack = function()
        self:OnBtnFabricationClick()
    end
end 

function XUiDormDormitoryFormWork:InitView()
    self.BtnContent:SelectIndex(self:GetTabIndexByDormType(self.DefaultDormType))
    --角色
    XHomeCharManager.HideAllCharacter()
    XHomeCharManager.ReleaseAllCharLongPressTrigger()
    --不会选中任何模板
    self:RefreshControlBtnState()
end

function XUiDormDormitoryFormWork:DestroyView()

    --显示角色
    XHomeCharManager.ShowAllCharacter(true)
end

function XUiDormDormitoryFormWork:OnSelectTab(tabIndex)
    if self.TabIndex == tabIndex then
        return
    end
    self:PlayAnimation("QieHuan")
    self.TabIndex = tabIndex
    self:SetupDynamicTable()
end 

function XUiDormDormitoryFormWork:SetupDynamicTable(ignoreSort)
    if not self.TabIndex or not self.TabList then
        return
    end

    --local startIndex = self:GetStartIndexByTemplateId()
    if ignoreSort then
        --self.SViewTemplatePanel:ClearCache()
        self.SViewTemplatePanel:Show(self.DataList, nil, self.RoomId)
        return
    end
    local dataList = self:GetTemplateDormitoryCache(self:GetDormTypeByIndex(self.TabIndex))
    self.DataList = self:SortTempDormData(dataList)
    --self.SViewTemplatePanel:ClearCache()
    self.SViewTemplatePanel:Show(self.DataList, nil, self.RoomId)
end

function XUiDormDormitoryFormWork:GetStartIndexByTemplateId()
    if not XTool.IsNumberValid(self.SelectTemplateId) then
        return nil
    end
    
    local startIndex
    for index, data in ipairs(self.DataList) do
        if data.GetRoomId and data:GetRoomId() == self.SelectTemplateId then
            startIndex = index
            break
        end
    end
    return startIndex
end

--- 选中模板
---@param templateHomeData XHomeRoomData
--------------------------
function XUiDormDormitoryFormWork:OnSelectTemplate(templateHomeData)
    self.SelectTemplateId = (not XTool.IsTableEmpty(templateHomeData)) and templateHomeData:GetRoomId() or 0
    self:RefreshControlBtnState()
end

function XUiDormDormitoryFormWork:GetTabIndexByDormType(dormType)
    if not dormType then
        return DefaultSelectTabIndex 
    end

    for index, template in ipairs(self.TabList) do
        if template.DormType == dormType then
            return index
        end
    end
    
    return DefaultSelectTabIndex
end

function XUiDormDormitoryFormWork:GetDormTypeByIndex(tabIndex)
    if not tabIndex or not self.TabList then
        return XDormConfig.DormDataType.Template
    end
    local template = self.TabList[tabIndex]
    if not template then
        return XDormConfig.DormDataType.Template
    end
    
    return template.DormType
end

-- 宿舍模板缓存
function XUiDormDormitoryFormWork:GetTemplateDormitoryCache(dormDataType)
    if DormTemplateCache[dormDataType] then
        return DormTemplateCache[dormDataType]
    end
    local data = XDataCenter.DormManager.GetTemplateDormitoryData(dormDataType)
    if dormDataType == XDormConfig.DormDataType.Collect then
        local newData = {}
        local collectTemplates = XDormConfig.GetDormTemplateCollectList()
        for i = 1, #collectTemplates do
            local tempData = data[i] or {}
            table.insert(newData, tempData)
        end
        data = newData
    end
    DormTemplateCache[dormDataType] = data

    return data
end

-- 清除宿舍模板缓存
function XUiDormDormitoryFormWork:ClearTemplateDormitoryCache()
    DormTemplateCache = {}
end

---@param dataList XHomeRoomData[]
function XUiDormDormitoryFormWork:SortTempDormData(dataList)
    if XTool.IsTableEmpty(dataList) then
        return
    end
    local homeData = XDataCenter.DormManager.GetRoomDataByRoomId(self.RoomId)
    local curConnectId = homeData:GetConnectDormId()
    table.sort(dataList, function(a, b)
        local roomIdA = a.GetRoomId and a:GetRoomId() or XMath.IntMax()
        local roomIdB = b.GetRoomId and b:GetRoomId() or XMath.IntMax()

        local isConnectA, isConnectB = roomIdA == curConnectId, roomIdB == curConnectId

        if isConnectA ~= isConnectB then
            return isConnectA
        end

        return roomIdA < roomIdB
    end)
    
    return dataList
end 

function XUiDormDormitoryFormWork:OnBtnBackClick()
    XHomeDormManager.SetSelectedRoom(self.RoomId, true)
    self:Close()
end 

function XUiDormDormitoryFormWork:RefreshControlBtnState()
    if not XTool.IsNumberValid(self.SelectTemplateId) then
        self.BtnTarget.gameObject:SetActiveEx(false)
        self.BtnPut.gameObject:SetActiveEx(false)
        self.BtnUnbind.gameObject:SetActiveEx(false)
        self.BtnFabrication.gameObject:SetActiveEx(false)
        self.BtnEditRoom.gameObject:SetActiveEx(false)
        return
    end
    local homeData = XDataCenter.DormManager.GetRoomDataByRoomId(self.RoomId)
    local isTarget = self.SelectTemplateId == homeData:GetConnectDormId()
    self.BtnTarget.gameObject:SetActiveEx(not isTarget)
    self.BtnPut.gameObject:SetActiveEx(isTarget)
    self.BtnUnbind.gameObject:SetActiveEx(isTarget)
    self.BtnFabrication.gameObject:SetActiveEx(isTarget)
    
    local template = self.TabList[self.TabIndex]
    self.BtnEditRoom.gameObject:SetActiveEx(template.DormType == XDormConfig.DormDataType.Collect)
end

function XUiDormDormitoryFormWork:PutTemplateFurniture()
    if not XTool.IsNumberValid(self.SelectTemplateId) then
        return
    end
    
    local template = XDataCenter.DormManager.GetRoomDataByRoomId(self.SelectTemplateId, XDormConfig.DormDataType.Template)
    XDataCenter.DormManager.CopyTemplateDorm(self.RoomId, self.SelectTemplateId, template:GetRoomDataType(), function()
        XUiManager.TipText("DormTemplateOneKeySuccesss")
        --self:SetupDynamicTable()
        self:OnBtnBackClick()
    end)
end

function XUiDormDormitoryFormWork:OnBtnPutClick()
    if not XTool.IsNumberValid(self.SelectTemplateId) then
        XUiManager.TipText("DormTemplateSelectNoneTip")
        return
    end
    
    local putCb = function()
        local homeData = XDataCenter.DormManager.GetRoomDataByRoomId(self.RoomId)
        
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), 
                XUiHelper.GetText("DormTemplateOneKeyTip", homeData:GetRoomName()), 
                nil, nil, self.OnPutTemplateCb)
    end

    local saveCb = function()
        if XTool.IsNumberValid(self.SelectTemplateId) then
            local homeRoomData = XDataCenter.DormManager.GetRoomDataByRoomId(self.RoomId)
            homeRoomData:SetHideCharacter(true)
            XHomeDormManager.SetSelectedRoom(self.RoomId, true)
        end
        XLuaUiManager.Open("UiDormTemplateScene", self.RoomId, XDormConfig.DormDataType.Self, nil, self.SelectTemplateId)
    end

    XDataCenter.DormManager.OpenNotification(XUiHelper.GetText("DormPutTemplateTitle"),
            XUiHelper.GetText("DormPutTemplateContent"), saveCb, putCb,
            XUiHelper.GetText("DormPutTemplatePositiveTxt"),
            XUiHelper.GetText("DormPutTemplateNegativeTxt"), true)
end 

function XUiDormDormitoryFormWork:OnBtnTargetClick()
    if not XTool.IsNumberValid(self.SelectTemplateId) then
        XUiManager.TipText("DormTemplateSelectNoneTip")
        return
    end

    local homeData = XDataCenter.DormManager.GetRoomDataByRoomId(self.RoomId)
    local connectId = homeData:GetConnectDormId()
    if connectId == self.SelectTemplateId then
        XUiManager.TipText("DormTemplateSelectTip")
        return
    end
    
    local newTemplate = XDataCenter.DormManager.GetRoomDataByRoomId(self.SelectTemplateId, XDormConfig.DormDataType.Template)
    local oldTemplate

    local request = function()
        XDataCenter.DormManager.DormBindLayoutReq(self.RoomId, self.SelectTemplateId, function()
            local txtTip = XUiHelper.GetText("DormSetTemplateTxt", homeData:GetRoomName(), newTemplate:GetRoomName())
            XUiManager.TipMsg(txtTip)
            homeData:SetConnectDormId(self.SelectTemplateId)
            newTemplate:SetConnectDormId(self.RoomId)
            if oldTemplate then
                oldTemplate:SetConnectDormId(0)
            end
            self:SetupDynamicTable(true)
            self:RefreshControlBtnState()
        end)
    end
    
    if connectId ~= 0 then
        oldTemplate = XDataCenter.DormManager.GetRoomDataByRoomId(connectId, XDormConfig.DormDataType.Template)
        
        local desc = XUiHelper.GetText("DormChangeTemplateTxt", oldTemplate:GetRoomName(), newTemplate:GetRoomName()) 
        
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), desc, nil, nil, request)
    else
        request()
    end
    
    
end 

function XUiDormDormitoryFormWork:OnBtnUnbindClick()
    if not XTool.IsNumberValid(self.SelectTemplateId) then
        XUiManager.TipText("DormTemplateSelectNoneTip")
        return
    end
    
    local homeData = XDataCenter.DormManager.GetRoomDataByRoomId(self.RoomId)
    local connectId = homeData:GetConnectDormId()

    --目标模板与选中不一致
    if connectId ~= self.SelectTemplateId then
        return
    end
    local requestCb = function()
        homeData:SetConnectDormId(0)
        local oldTemplate = XDataCenter.DormManager.GetRoomDataByRoomId(self.SelectTemplateId, XDormConfig.DormDataType.Template)
        oldTemplate:SetConnectDormId(0)
        self:SetupDynamicTable(true)
        self:RefreshControlBtnState()
    end
    
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("DormTemplateSelectCancelTip"), 
            nil, nil, function() 
        XDataCenter.DormManager.DormUnBindLayoutReq(self.RoomId, requestCb)
    end)
end

function XUiDormDormitoryFormWork:OnBtnFabricationClick()
    if not XTool.IsNumberValid(self.SelectTemplateId) then
        XUiManager.TipText("DormTemplateSelectNoneTip")
        return
    end
    local template = self.TabList[self.TabIndex]
    local selectRoomData = XDataCenter.DormManager.GetRoomDataByRoomId(self.SelectTemplateId, template.DormType)
    XDataCenter.FurnitureManager.OpenFurnitureOrderBuild(self.RoomId, self.SelectTemplateId, template.DormType, selectRoomData:GetRoomName(), " ")
end

function XUiDormDormitoryFormWork:OnBtnEditRoomClick()
    if not XTool.IsNumberValid(self.SelectTemplateId) then
        XUiManager.TipText("DormTemplateSelectNoneTip")
        return
    end
    
    local template = self.TabList[self.TabIndex]
    XDataCenter.DormManager.EnterTemplateDormitory(self.SelectTemplateId, template.DormType, self.RoomId)
end