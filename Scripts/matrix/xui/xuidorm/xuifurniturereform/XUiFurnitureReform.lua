
---@class XUiFurnitureReform : XLuaUi
---@field BtnDrdSort UnityEngine.UI.Dropdown
---@field IsEntrance boolean 是否首次进入
---@field ChildViewTab XUiComponent.XUiButton[] 子页面按钮列表
---@field BtnContent XUiButtonGroup
---@field CurFurniture XHomeFurnitureObj 是否需要刷新数量
local XUiFurnitureReform = XLuaUiManager.Register(XLuaUi, "UiFurnitureReform")

local XUiGridFurnitureScore = require("XUi/XUiDorm/XUiFurnitureReform/XUiGridFurnitureScore")
local XUiPanelSViewReform = require("XUi/XUiDorm/XUiFurnitureReform/XUiPanelSViewReform")

local TargetCameraDistance = 13

local BtnType = {
    Primary     = 1, --一级按钮
    Secondary   = 2, --二级按钮
}

local FurnitureCache = {} --家具数据缓存
local DormTemplateCache = {} --宿舍模板数据缓存

local DefaultSuitId= 0

function XUiFurnitureReform:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiFurnitureReform:OnStart(roomId, roomType)
    self.RoomId = roomId
    self.RoomType = roomType
    self.IsOwnRoom = roomType == XDormConfig.DormDataType.Self
    self.IsEntrance = self.IsOwnRoom
    self.SuitId = DefaultSuitId
    self:InitData()
    self:InitView()
end 

function XUiFurnitureReform:OnEnable()
    self:RefreshChildView()
    XDataCenter.FurnitureManager.SetInReform(true)
end

function XUiFurnitureReform:OnDisable()
    self:ClearTemplateDormitoryCache()
    XDataCenter.FurnitureManager.SetInReform(false)
end

function XUiFurnitureReform:OnDestroy()
    --清除点击事件
    XHomeDormManager.SetClickFurnitureCallback(nil)
    --显示角色
    XHomeCharManager.ShowAllCharacter(true)
    --清空按钮缓存
    self.ChildViewTab = {}
    --清空家具缓存
    self:ResetCache()
    --模板缓存
    self:ClearTemplateDormitoryCache()
    if self:IsInFurniture() then
        self:RestoreCamera()
    end

    XHomeDormManager.AttachSurfaceToRoom()
    XHomeDormManager.ReformRoom(self.RoomId, false)

    XEventManager.RemoveEventListener(XEventId.EVENT_FURNITURE_GET_FURNITURE, self.RefreshFurnitureReform, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FURNITURE_ON_MODIFY, self.RefreshFurnitureReform, self)
    
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_FURNITURE_HIDE_ALL_ATTR_TAG_DETAIL)
end

function XUiFurnitureReform:OnGetEvents()
    return {
        XEventId.EVENT_FURNITURE_ONDRAG_ITEM_CHANGED,
        XEventId.EVENT_FURNITURE_CLEAN_ROOM,
        XEventId.EVENT_FURNITURE_REFRESH,
        XEventId.EVENT_CLICK_FURNITURE_ON_ROOM
    }
end

function XUiFurnitureReform:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FURNITURE_ONDRAG_ITEM_CHANGED then
        self:UpdateCacheFurniture(...)
        self:RefreshChildView()
        self:RefreshRoomScore()
        
    elseif evt == XEventId.EVENT_FURNITURE_CLEAN_ROOM then
        self:RefreshRoomScore()
        
    elseif evt == XEventId.EVENT_FURNITURE_REFRESH then
        self:RefreshFurnitureReform()
        
    elseif evt == XEventId.EVENT_CLICK_FURNITURE_ON_ROOM then
        self:OnSelectTabByFurniture(...)
    end
end

function XUiFurnitureReform:Close()
    if self:IsInFurniture() then
        local targetAngle = CS.XGame.ClientConfig:GetInt("DefaultDormTargetAngle")
        local allowYAxis = CS.XGame.ClientConfig:GetInt("DefaultAllowYAxis")
        XHomeSceneManager.ChangeAngleYAndYAxis(targetAngle, allowYAxis == 1)
    end
    self.Super.Close(self)
end

function XUiFurnitureReform:InitUi()
    --隐藏菜单按钮
    self.PanelMenu.gameObject:SetActive(false)
    self.MenuPanel = require("XUi/XUiDorm/XUiFurnitureReform/XUiPanelMenu").New(self, self.PanelMenu)
    
    --分数下拉框
    local scoreTag = XFurnitureConfigs.GetFurnitureTagTypeTemplates() or {}
    self.ScoreIndex2TagId = {}
    local index = 0
    self.BtnDrdSort:ClearOptions()
    for id, template in pairs(scoreTag) do
        local dOp = CS.UnityEngine.UI.Dropdown.OptionData()
        dOp.text = template.TagName
        self.BtnDrdSort.options:Add(dOp)
        self.ScoreIndex2TagId[index] = id
        index = index + 1
    end
    self.BtnDrdSort.value = 0 --默认选中[隐藏数值]选项
   
    --总分控件
    self.ScorePanels = {}
    
    self:RefreshTabActive(false)
    
    --动态列表
    self.SViewFurniturePanel = XUiPanelSViewReform.New(self.PanelSViewFurniture, self, require("XUi/XUiDorm/XUiFurnitureReform/XUiGridFurnitureItem"))
    self.SViewTemplatePanel = XUiPanelSViewReform.New(self.PanelSViewTemplate, self, require("XUi/XUiDorm/XUiFurnitureReform/XUiGridTemplateItem"))
    self.SViewTemplatePanel:RegisterClickGrid(handler(self, self.OnSelectTemplate))
    
    self.OnSelectSuitCb = handler(self, self.OnSelectSuit)
    self.OnSaveTemplateCb = handler(self, self.DoSaveRoom)
    self.OnJumpToQuickBuildCb = handler(self, self.OnJumpToQuickBuild)
    self.OnSortFurnitureCb = handler(self, self.SortFurniture)
end 

function XUiFurnitureReform:InitCb()
    self.BtnBack.CallBack = function() 
        self:OnBtnBackClick()
    end
    --下拉框
    self.BtnDrdSort.onValueChanged:AddListener(function(index) 
        self:OnBtnDrdSortChanged(index)
    end)
    --模板预设
    self.BtnPreset.CallBack = function()
        self:OnJumpToChildView(XDormConfig.ReformPanelIndex.Template)
    end
    --宿舍家具
    self.BtnFurniture.CallBack = function() 
        self:OnJumpToChildView(XDormConfig.ReformPanelIndex.Furniture)
    end
    --子界面关闭
    self.BtnReturn.CallBack = function() 
        self:OnBtnReturnClick()
    end
    --回收
    self.BtnRecover.CallBack = function() 
        self:OnBtnRecoverClick()
    end
    --撤销
    self.BtnUndo.CallBack = function()
        self:OnBtnUndoClick()
    end
    --保存
    self.BtnSaveAndQuit.CallBack = function()
        self:OnBtnSaveAndQuitClick()
    end
    --预览模板
    self.BtnOverview.CallBack = function() 
        self:OnBtnOverviewClick()
    end
end 

function XUiFurnitureReform:InitData()
    self:RestoreCache()
    
    XEventManager.AddEventListener(XEventId.EVENT_FURNITURE_GET_FURNITURE, self.RefreshFurnitureReform, self)
    XEventManager.AddEventListener(XEventId.EVENT_FURNITURE_ON_MODIFY, self.RefreshFurnitureReform, self)
end

function XUiFurnitureReform:InitView()
    --子界面页签
    self:InitChildTab()
    --宿舍场景
    XHomeDormManager.SetClickFurnitureCallback(function(furniture) self:ShowFurnitureMenu(furniture, false, false) end)
    XHomeDormManager.ReformRoom(self.RoomId, true)
    XHomeDormManager.ClearFurnitureAnimation(self.RoomId)
    --隐藏角色
    XHomeCharManager.HideAllCharacter()
    XHomeCharManager.ReleaseAllCharLongPressTrigger()
    --分数显示
    self.PanelTool.gameObject:SetActiveEx(self.IsOwnRoom)
    self:RefreshRoomScore()
    --下拉框
    self.BtnDrdSort.gameObject:SetActiveEx(self.IsOwnRoom)
    --如果不是自己房间，直接跳往家具编辑
    if not self.IsOwnRoom then
        self:OnJumpToChildView(XDormConfig.ReformPanelIndex.Furniture)
    end
    self.BtnReturn.gameObject:SetActiveEx(self.IsOwnRoom)
end

function XUiFurnitureReform:InitCamera()
    self.CameraCtrl = XHomeSceneManager.GetSceneCameraController()
    if XTool.UObjIsNil(self.CameraCtrl) then
        return
    end
    self.LastDistance = self.CameraCtrl.Distance
    self.LastTarget = self.CameraCtrl.TargetObj
    self.TargetAngleX = self.CameraCtrl.TargetAngleX
    self.TargetAngleY = self.CameraCtrl.TargetAngleY
    
    XCameraHelper.SetCameraTarget(self.CameraCtrl, self.LastTarget, TargetCameraDistance)
end

function XUiFurnitureReform:RestoreCamera()
    if XTool.UObjIsNil(self.CameraCtrl) then
        return
    end
    
    self.CameraCtrl:SetTartAngle(CS.UnityEngine.Vector2(self.TargetAngleX, self.TargetAngleY))
    XCameraHelper.SetCameraTarget(self.CameraCtrl, self.LastTarget, self.LastDistance)
    self.CameraCtrl = nil
end

--初始化子界面页签
function XUiFurnitureReform:InitChildTab()
    --一级/二级页签按钮
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    local tabConfig = XDataCenter.DormManager.GetReformTabConfig()
    self.TabIndex2Config = {}
    self.ChildViewTab = {}
    local btnIndex = 0
    for _, config in ipairs(tabConfig) do
        local hasChild = config.HasChild
        local btn = self:CreateButton(BtnType.Primary)
        btn:SetSprite(config.Icon)
        btn:SetNameByGroup(0,  config.Name)
        btnIndex = btnIndex + 1
        table.insert(self.ChildViewTab, btn)
        self.TabIndex2Config[btnIndex] = config
        if hasChild then
            local firstIndex = btnIndex
            for _, child in ipairs(config.Children) do
                local childBtn = self:CreateButton(BtnType.Secondary)
                childBtn.SubGroupIndex = firstIndex
                childBtn:SetNameByGroup(0,  child.Name)
                table.insert(self.ChildViewTab, childBtn)
                btnIndex = btnIndex + 1
                self.TabIndex2Config[btnIndex] = child
            end
        end
    end
    self.BtnContent:SetIsXScale(true)
    self.BtnContent:Init(self.ChildViewTab, function(tabIndex) self:OnSelectTab(tabIndex) end)
    
    ---@type UnityEngine.RectTransform
    local container = self.ScrollTitleTab.transform.parent
    --安全区域
    local sizeX = CS.XUiManager.RealScreenWidth - (CS.XAppPlatBridge.GetNotchSize() + CS.XUiSafeAreaAdapter.SpecialScreenOff) * 2
    for i = 0, container.childCount - 1 do
        local child = container:GetChild(i)
        if child.name == self.ScrollTitleTab.name then
            break
        elseif child.gameObject.activeInHierarchy then
            sizeX = sizeX - child.rect.size.x
        end
    end
    self.ScrollTitleTab.sizeDelta = CS.UnityEngine.Vector2(sizeX, self.ScrollTitleTab.rect.size.y)
end

--region   ------------------UI刷新 start-------------------

--刷新房间分数
function XUiFurnitureReform:RefreshRoomScore()
    if not XTool.IsNumberValid(self.RoomId) or XDormConfig.IsTemplateRoom(self.RoomType) then
        return
    end
    
    local newAttrs = XHomeDormManager.GetFurnitureScoresByRoomId(self.RoomId)
    local oldAttrs = XHomeDormManager.GetFurnitureScoresByUnSaveRoom(self.RoomId)
    self.ScoreTotalPanel = self.ScoreTotalPanel or XUiGridFurnitureScore.New(self.PanelTotal)
    self.ScoreTotalPanel:RefreshTotal(newAttrs, oldAttrs)
    for i = 1, #newAttrs.AttrList do
        local panel = self.ScorePanels[i]
        if not panel then
            panel = XUiGridFurnitureScore.New(self["PanelTool"..i])
            self.ScorePanels[i] = panel
        end
        local typeData = XFurnitureConfigs.GetDormFurnitureType(i)
        panel:Refresh(newAttrs.AttrList[i], oldAttrs.AttrList[i], typeData.TypeIcon, i)
    end
end

function XUiFurnitureReform:RefreshFurnitureReform()
    self:ResetCache()
    self:RestoreCache()
    self:RefreshTabCount()
    self:RefreshRoomScore()
    if self:IsInTemplate() and self.SelectRoomData then
        local roomData = XDataCenter.DormManager.GetRoomDataByRoomId(self.SelectRoomData:GetRoomId(), self.SelectRoomData:GetRoomDataType())
        local room = XHomeDormManager.GetRoom(self.RoomId)
        if room then
            room:ReplaceFurniture(roomData)
        end
        self.TemplateIndex = self.SViewTemplatePanel:GetStartIndex()
        self:SetupDynamicTable()
    end
end

function XUiFurnitureReform:RefreshChildView()
    self.PanelEntrance.gameObject:SetActiveEx(self.IsEntrance)
    self.PanelReform.gameObject:SetActiveEx(not self.IsEntrance)

    if self.IsEntrance then
        self.BtnPreset:SetNameByGroup(0, XDataCenter.DormManager.GetTemplateDormitoryCount())
        self.BtnFurniture:SetNameByGroup(0, self:GetFurnitureNumsBySuitId(0))
    else
        self:RefreshTabCount()
    end

    if self:IsInFurniture() then
        self.BtnOverview.gameObject:SetActiveEx(true)
        self:InitCamera()
    else
        self.BtnOverview.gameObject:SetActiveEx(false)
        self:RestoreCamera()
    end
end

--刷新页签按钮显示
function XUiFurnitureReform:RefreshTabBtn()
    for tabIndex, btn in pairs(self.ChildViewTab) do
        if btn and not XTool.UObjIsNil(btn) and btn.SubGroupIndex <= 0 then
            local cfg = self.TabIndex2Config[tabIndex]
            self.BtnContent:ShowButtonGroup(btn, false)
            btn.gameObject:SetActiveEx(cfg.TabIndex == self.ChildType)
        end
    end
end

--设置动态列表数据
function XUiFurnitureReform:SetupDynamicTable()
    if not self.TabIndex then
        return
    end
    self.SViewTemplatePanel:ClearCache()
    self.SViewFurniturePanel:ClearCache()
    local config = self.TabIndex2Config[self.TabIndex]
    if self.ChildType == XDormConfig.ReformPanelIndex.Template then --模板
        self.SViewFurniturePanel:Hide()
        local template = XDormConfig.GetDormTemplateGroupCfg(config.Param)
        local dormType = template and template.DormType or XDormConfig.DormDataType.Template
        local data = self:GetTemplateDormitoryCache(dormType)
        data = self:SortTempDormData(data)
        self.SViewTemplatePanel:Show(data, self.TemplateIndex, self.RoomId, self.RoomType)
    else --家具
        self.SViewTemplatePanel:Hide()
        local template = XFurnitureConfigs.GetFurnitureTypeById(config.Param)
        local cacheKey = self:GetCacheKey(template.MinorType, template.Category)
        self:SwitchViewAngle(template.MinorType)
        self.LastMinorType = template.MinorType 
        self:SortFurnitureCache(FurnitureCache[cacheKey])
        local filterCache
        if self.IsOwnRoom then
            filterCache = self:FilterCacheBySuitId(FurnitureCache[cacheKey] or {})
        else
            filterCache = XFurnitureConfigs.GetFurnitureCfgList(template.MinorType, template.Category, self.SuitId)
        end
        if self.IsExpand then
            local temp
            for _, list in pairs(filterCache or {}) do
                local furniture = list[1]
                if furniture.ConfigId == self.ExpandFurnitureConfigId then
                    temp = list
                    break
                end
            end
            filterCache = temp
        end
        self.SViewFurniturePanel:Show(filterCache, self.OpenIndex, self.RoomId, self.RoomType)
    end
end

--展开家具
function XUiFurnitureReform:ExpandFurniture(furnitureList)
    if XTool.IsTableEmpty(furnitureList) then
        return
    end
    self.IsExpand = true
    local furniture = furnitureList[1]
    self.ExpandFurnitureConfigId = furniture.ConfigId
    self.BtnExpand:SetNameByGroup(0, furniture:GetFurnitureName())
    self:RefreshTabActive(true)
    self.SViewTemplatePanel:Hide()
    self.OpenIndex = self.SViewFurniturePanel:GetStartIndex()
    self.SViewFurniturePanel:Show(furnitureList, nil, self.RoomId, self.RoomType)
end

--- 显示家具菜单
---@param furniture XHomeFurnitureObj
---@param isFollowMouse boolean
---@param isNew boolean
---@return
--------------------------
function XUiFurnitureReform:ShowFurnitureMenu(furniture, isFollowMouse, isNew)
    self.SafeAreaContentPane.gameObject:SetActiveEx(not furniture)
    local isOutOfLimit = false
    if furniture and (not XDataCenter.FurnitureManager.CheckFurnitureUsing(furniture.Data.Id)) then
        local minorType = XFurnitureConfigs.GetFurnitureTypeCfgByConfigId(furniture.Data.CfgId).MinorType
        local curLength = XHomeDormManager.GetFurnitureNumsByRoomAndMinor(self.RoomId, minorType)
        local curCapacity = XHomeDormManager.GetFurnitureCapacityByRoomANdMinor(self.RoomId, minorType, self.RoomType)
        isOutOfLimit = (curCapacity > 0) and (curLength >= curCapacity) or false
    end
    self.MenuPanel:SetFurniture(furniture, isFollowMouse, isNew, isOutOfLimit)
    
    self.CurFurniture = furniture
    self:OnShowBlockGrids()
end

function XUiFurnitureReform:OnShowBlockGrids()
    if not self.CurFurniture then
        return
    end
    XHomeDormManager.OnShowBlockGrids(self.CurFurniture.HomePlatType, self.CurFurniture.GridOffset, self.CurFurniture.RotateAngle)
end

function XUiFurnitureReform:OnHideBlockGrids()
    if not self.CurFurniture then
        return
    end
    XHomeDormManager.OnHideBlockGrids(self.CurFurniture.HomePlatType, self.CurFurniture.RotateAngle)
end

--刷新按钮上的数量显示
function XUiFurnitureReform:RefreshTabCount()
    for index, btn in pairs(self.ChildViewTab) do
        local cfg = self.TabIndex2Config[index]
        if self.ChildType == cfg.TabIndex then
            btn:SetNameByGroup(1,  " " .. self:GetItemCount(cfg.Param))
            btn:ShowReddot(self:CheckRedPoint(cfg.Param))
        end
    end
end

function XUiFurnitureReform:SwitchViewAngle(minorType)
    local viewAngle = XFurnitureConfigs.GetFurnitureViewAngleByMinor(minorType)
    if not viewAngle then
        return
    end

    if self.LastMinorType then
        local lastViewAngle = XFurnitureConfigs.GetFurnitureViewAngleByMinor(self.LastMinorType)
        if lastViewAngle and lastViewAngle.GroupId == viewAngle.GroupId then
            return
        end
    end

    XHomeSceneManager.ChangeAngleYAndYAxis(viewAngle.TargetAngleY, viewAngle.AllowYAxis == 1)
end

function XUiFurnitureReform:RefreshTabActive(isExpand)
    self.ScrollTitleTab.gameObject:SetActiveEx(not isExpand)
    self.ScrollTitleTabOpen.gameObject:SetActiveEx(isExpand)
end

--endregion------------------UI刷新 finish------------------

--region   ------------------UI回调 start-------------------

--分数设置回调
function XUiFurnitureReform:OnBtnDrdSortChanged(index)
    if self.ScoreTagIndex == index then
        return
    end
    self.ScoreTagIndex = index
    local scoreTag = XFurnitureConfigs.GetFurnitureTagTypeTemplates() or {}
    local template = scoreTag[self.ScoreIndex2TagId[index]]
    if template then
        XHomeDormManager.FurnitureShowAttrType = template.AttrIndex
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_FURNITURE_ATTR_TAG, template.AttrIndex)
    end
end

--跳转到子界面
function XUiFurnitureReform:OnJumpToChildView(childType)
    self.IsEntrance = false
    self.ChildType = childType
    self:RefreshTabBtn()
    self.BtnContent:SelectIndex(self:GetValidTabIndex(self.ChildType))
    self:RefreshChildView()
end

--关闭子界面
function XUiFurnitureReform:OnBtnReturnClick()
    if self.IsExpand then --关闭展开
        self.IsExpand = false
        self:RefreshTabActive(false)
        self:SetupDynamicTable()
        self.OpenIndex = nil
    else --关闭子界面
        local function onClose()
            self.IsEntrance = true
            self.ChildType = nil
            self.SelectRoomData = nil
            self.SViewTemplatePanel:ClearCache()
            self.SViewFurniturePanel:ClearCache()
            self:RefreshChildView()
        end
        if XHomeDormManager.IsNeedSave(self.RoomId, self.RoomType) then
            self:BackOnFurnitureChanged(onClose)
            return
        end
        onClose()
    end
end

--选中页签
function XUiFurnitureReform:OnSelectTab(tabIndex)
    if self.TabIndex == tabIndex then
        return
    end
    self:PlayAnimation("QieHuan")
    self.TabIndex = tabIndex
    self:SetupDynamicTable()

    local btn = self.ChildViewTab[self.TabIndex]
    btn:ShowReddot(false)
    if btn.SubGroupIndex > 0 then
        local subBtn = self.ChildViewTab[btn.SubGroupIndex]
        local cfg = self.TabIndex2Config[btn.SubGroupIndex]
        subBtn:ShowReddot(self:CheckRedPoint(cfg.Param))
    end
end

--关闭界面
function XUiFurnitureReform:OnBtnBackClick()
    if not XTool.IsNumberValid(self.RoomId) then
        self:Close()
        return
    end
    if XHomeDormManager.IsNeedSave(self.RoomId, self.RoomType) then
        self:BackOnFurnitureChanged(function() 
            self:Close()
        end)
    else
        self:Close()
    end
end

function XUiFurnitureReform:BackOnFurnitureChanged(closeCb)
    XUiManager.DialogTip(XUiHelper.GetText("FurnitureTips"), XUiHelper.GetText("FurnitureIsSave"),
            nil, function()
                XHomeDormManager.RevertRoom(self.RoomId)
                if closeCb then closeCb() end
            end, function()
                self:DoSaveRoom(false, closeCb)
            end)
end

function XUiFurnitureReform:OnBtnRecoverClick()
    if not XTool.IsNumberValid(self.RoomId) then
        return
    end
    
    if not self.OnRecoverCb then
        self.OnRecoverCb = function() 
            XHomeDormManager.CleanRoom(self.RoomId)
        end
    end
    
    XUiManager.DialogTip(XUiHelper.GetText("FurnitureTips"), XUiHelper.GetText("FurnitureCleanRoom"), nil, nil, self.OnRecoverCb)
end

function XUiFurnitureReform:OnBtnUndoClick()
    if not XTool.IsNumberValid(self.RoomId) then
        return
    end

    if not self.OnUndoCb then
        self.OnUndoCb = function()
            XHomeDormManager.RevertRoom(self.RoomId)
            local index = self.ScoreTagIndex
            local scoreTag = XFurnitureConfigs.GetFurnitureTagTypeTemplates() or {}
            local template = scoreTag[self.ScoreIndex2TagId[index]]
            if template then
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_FURNITURE_ATTR_TAG, template.AttrIndex)
            end
        end
    end

    XUiManager.DialogTip(XUiHelper.GetText("FurnitureTips"), XUiHelper.GetText("FurnitureRevertRoom"), nil, nil, self.OnUndoCb)
end

function XUiFurnitureReform:OnBtnSaveAndQuitClick()
    if not XTool.IsNumberValid(self.RoomId) then
        return
    end
    --家具装修
    if self:IsInTemplate() and self.SelectRoomData then
        local unOwnFurniture = XDataCenter.DormManager.GetNotOwnedFurniture(self.RoomId,
                self.SelectRoomData:GetRoomId(), self.SelectRoomData:GetRoomDataType())
        if not XTool.IsTableEmpty(unOwnFurniture) then
            XDataCenter.DormManager.OpenNotification(XUiHelper.GetText("DormSaveDressUp"), XUiHelper.GetText("DormNoFurnitureOnPut"),
                    self.OnSaveTemplateCb, self.OnJumpToQuickBuildCb, XUiHelper.GetText("DormSaveDirectly"), XUiHelper.GetText("DormQuickBuild"))
        else
            self:DoSaveRoom()
        end
    else
        self:DoSaveRoom()
    end
end

function XUiFurnitureReform:DoSaveRoom(isBehaviour, cb)
    if not XTool.IsNumberValid(self.RoomId) then
        return
    end
    if self.SelectRoomData and self:IsInTemplate() then
        self.SViewTemplatePanel:ClearCache()
    end
    self.SelectRoomData = nil
    XHomeDormManager.SaveRoomModification(self.RoomId, isBehaviour, cb)
end

function XUiFurnitureReform:OnSelectTabByFurniture(furnitureId)
    if not XTool.IsNumberValid(furnitureId) or 
            self.ChildType ~= XDormConfig.ReformPanelIndex.Furniture then
        return
    end
    local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
    if not furniture then
        return
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId())
    if not template then
        return
    end
    local tabIndex
    for index, config in ipairs(self.TabIndex2Config) do
        if config.Param == template.TypeId then
            tabIndex = index
            break
        end
    end
    self.BtnContent:SelectIndex(tabIndex)
end

function XUiFurnitureReform:OnSelectSuit(suitId)
    self.SuitId = suitId or XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID
    if self:IsInFurniture() then
        self:RefreshTabCount()
        self:SetupDynamicTable()
    end
end

--- 选中模板回调
---@param homeData XHomeRoomData 模板数据
---@return
--------------------------
function XUiFurnitureReform:OnSelectTemplate(homeData)
    self.SelectRoomData = homeData
end

function XUiFurnitureReform:OnBtnOverviewClick()
    XLuaUiManager.Open("UiDormDressingOverview", self.SuitId, self.RoomType, FurnitureCache, self.OnSelectSuitCb)
end

--- 快捷制造
---@return
--------------------------
function XUiFurnitureReform:OnJumpToQuickBuild()
    XDataCenter.FurnitureManager.OpenFurnitureOrderBuild(self.RoomId, self.SelectRoomData:GetRoomId(), 
            self.SelectRoomData:GetRoomDataType(), self.SelectRoomData:GetRoomName(), " ")
end

--endregion------------------UI回调 finish------------------

--- 获取按钮
---@param btnType number 按钮类型
---@return XUiComponent.XUiButton
--------------------------
function XUiFurnitureReform:CreateButton(btnType)
    local prefab = btnType == BtnType.Primary and self.BtnFirst or self.BtnSecond
    local btn = XUiHelper.Instantiate(prefab, self.BtnContent.transform)
    return btn
end

--- 家具缓存Key
---@param baseType number
---@param subType number
---@return string
--------------------------
function XUiFurnitureReform:GetCacheKey(baseType, subType)
    return XDataCenter.FurnitureManager.GenerateCacheKey(baseType, subType)
end

--- 根据页签类型获取有效的页签下标
---@param panelIndex number
---@return number
--------------------------
function XUiFurnitureReform:GetValidTabIndex(panelIndex)
    if not XTool.IsNumberValid(panelIndex) then
        return 1
    end
    if XTool.IsNumberValid(self.TabIndex) then
        local config = self.TabIndex2Config[self.TabIndex]
        --当前选中的TabIndex符合选项
        if config.TabIndex == panelIndex then
            return self.TabIndex
        end
    end
    for index, config in pairs(self.TabIndex2Config) do
        if config.TabIndex == panelIndex then
            return index
        end
    end
    return 1
end

-- 清除家具数据缓存
function XUiFurnitureReform:ResetCache()
    FurnitureCache = {}
end

-- 重新计算家具缓存
function XUiFurnitureReform:RestoreCache()
    local allTypeTemplate = XFurnitureConfigs.GetAllFurnitureTypes()
    for _, data in pairs(allTypeTemplate) do
        local cacheKey = self:GetCacheKey(data.MinorType, data.Category)
        FurnitureCache[cacheKey] = XDataCenter.FurnitureManager.FilterAndMergeDisplayFurnitureList(
                XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID, data.MinorType, data.Category)
    end
end

function XUiFurnitureReform:UpdateCacheFurniture(isRemove, furnitureId)
    if not XTool.IsNumberValid(furnitureId) or not self:IsInFurniture() then
        return
    end
    
    local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
    if not furniture then
        return
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId())
    if not template then
        return
    end
    local typeTemplate = XFurnitureConfigs.GetFurnitureTypeById(template.TypeId)
    if not typeTemplate then
        return
    end
    
    local cacheKey = self:GetCacheKey(typeTemplate.MinorType, typeTemplate.Category)

    if isRemove then
        self:AddCacheToList(FurnitureCache[cacheKey], furniture)
    else
        self:RemoveCacheFromList(FurnitureCache[cacheKey], furniture)
    end
    self.OpenIndex = self.SViewFurniturePanel:GetStartIndex()
    self:SetupDynamicTable()
end

function XUiFurnitureReform:AddCacheToList(cache, furniture)
    local isNewList = false
    if not furniture or not cache then
        return isNewList
    end
    if #cache <= 0 then
        isNewList = true
        table.insert(cache, { furniture })
        return isNewList
    end
    local configId = furniture:GetConfigId()
    local furnitureId = furniture.Id
    local index
    for idx, list in pairs(cache) do
        for _, data in pairs(list) do
            if furnitureId == data.Id then
                return isNewList
            end
        end
        local temp = list[1]
        if temp and temp:GetConfigId() == configId then
            index = idx
            break
        end
    end

    if XTool.IsNumberValid(index) then
        table.insert(cache[index], furniture)
        isNewList = false
    else
        table.insert(cache, { furniture })
        isNewList = true
    end
    self:SortFurnitureCache(cache)
    return isNewList
end

function XUiFurnitureReform:RemoveCacheFromList(cache, furniture)
    if XTool.IsTableEmpty(cache) or not furniture then
        return false
    end
    local furnitureId = furniture.Id
    local i, j
    for idx, list in pairs(cache) do
        for jIdx, data in pairs(list) do
            if furnitureId == data.Id then
                i = idx
                j = jIdx
                break
            end
        end
    end
    local isDelList = false

    if XTool.IsNumberValid(i) and XTool.IsNumberValid(j) then
        isDelList = #cache[i] <= 1
        table.remove(cache[i], j)
        if #cache[i] <= 0 then
            table.remove(cache, i)
        end
    end 
    
    return isDelList
end

-- 重新排序家具缓存
function XUiFurnitureReform:SortFurnitureCache(cache)
    if XTool.IsTableEmpty(cache) then
        return
    end
    --先对堆叠的家具排序
    for i, cacheList in pairs(cache) do
        if #cacheList > 1 then
            table.sort(cache[i], self.OnSortFurnitureCb)
        end
    end
    --再对整体进行排序
    table.sort(cache, function(a, b) 
        return self:SortFurniture(a[1], b[1])
    end)
end

function XUiFurnitureReform:SortFurniture(furnitureA, furnitureB)
    local configIdA, configIdB = furnitureA:GetConfigId(), furnitureB:GetConfigId()
    
    local isMaxA = XDataCenter.FurnitureManager.CheckIsMaxScore(configIdA) 
    local isMaxB = XDataCenter.FurnitureManager.CheckIsMaxScore(configIdB)
    
    if isMaxA ~= isMaxB then
        return isMaxA
    end
    
    local idA, idB = furnitureA:GetInstanceID(), furnitureB:GetInstanceID()
    
    local scoreA = furnitureA.GetScore and furnitureA:GetScore() or 0
    local scoreB = furnitureB.GetScore and furnitureB:GetScore() or 0

    if scoreA ~= scoreB then
        return scoreA > scoreB
    end
    return idA < idB
end

-- 过滤套装
function XUiFurnitureReform:FilterCacheBySuitId(cache)

    --if not self.SuitId or self.SuitId == DefaultSuitId then
    if XFurnitureConfigs.IsAllSuit(self.SuitId) then
        return cache
    end
    
    local suitCache = {}
    local result = {}
    for _, list in ipairs(cache) do
        suitCache = {}
        for _, v in ipairs(list) do
            local template = XFurnitureConfigs.GetFurnitureTemplateById(v.ConfigId)
            if template.SuitId == self.SuitId then
                table.insert(suitCache, v)
            end
        end
        if #suitCache > 0 then
            table.insert(result, suitCache)
        end
    end

    return result
end

-- 宿舍模板缓存
function XUiFurnitureReform:GetTemplateDormitoryCache(dormDataType)
    if DormTemplateCache[dormDataType] then
        return DormTemplateCache[dormDataType]
    end
    local data = XDataCenter.DormManager.GetTemplateDormitoryData(dormDataType)
    DormTemplateCache[dormDataType] = data
    
    return data
end

---@param dataList XHomeRoomData[]
function XUiFurnitureReform:SortTempDormData(dataList)
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

-- 清除宿舍模板缓存
function XUiFurnitureReform:ClearTemplateDormitoryCache()
    DormTemplateCache = {}
end

--获取Tab对应的Item数量
function XUiFurnitureReform:GetItemCount(param)
    if self.ChildType == XDormConfig.ReformPanelIndex.Template then
        local template = XDormConfig.GetDormTemplateGroupCfg(param)
        return XDataCenter.DormManager.GetTemplateDormitoryCount(template.DormType)
    elseif self.ChildType == XDormConfig.ReformPanelIndex.Furniture  then
        if type(param) == "number" then
            return self:GetFurnitureCountByMinorAndCategoryAndSuitId(param)
        else
            local total = 0
            for _, typeId in pairs(param) do
                total = total + self:GetFurnitureCountByMinorAndCategoryAndSuitId(typeId)
            end
            return total
        end
    end
    return 0
end

function XUiFurnitureReform:CheckRedPoint(param)
    if not self.IsOwnRoom then
        return false
    end
    if self.ChildType == XDormConfig.ReformPanelIndex.Template then
        return false
    end
    local getCfgList = function(typeId)
        local typeTemplate = XFurnitureConfigs.GetFurnitureTypeById(typeId)
        local list = XFurnitureConfigs.GetFurnitureConfigIdList(typeTemplate.MinorType, typeTemplate.Category, self.SuitId)
        return list
    end

    if type(param) == "number" then
        return XDataCenter.FurnitureManager.CheckIsMaxScoreByConfigIds(getCfgList(param))
    else
        for _, typeId in pairs(param) do
            if XDataCenter.FurnitureManager.CheckIsMaxScoreByConfigIds(getCfgList(typeId)) then
                return true
            end
        end
    end
    
    return false
end

function XUiFurnitureReform:GetFurnitureCountByMinorAndCategoryAndSuitId(typeId)
    local template = XFurnitureConfigs.GetFurnitureTypeById(typeId)
    if not self.IsOwnRoom then
        return XFurnitureConfigs.GetCountByCategory(template.MinorType, template.Category, self.SuitId)
    end
    local cacheKey = self:GetCacheKey(template.MinorType, template.Category)
    local count = XDataCenter.FurnitureManager.GetFurnitureCountByMinorAndCategoryAndSuitId(self.RoomId, 
            FurnitureCache[cacheKey], self.SuitId, template.MinorType, template.Category)
    return count
end

function XUiFurnitureReform:GetFurnitureNumsBySuitId(suitId)
    if not XTool.IsNumberValid(self.RoomId) then
        return 0
    end

    if self.IsOwnRoom then
        return XDataCenter.FurnitureManager.GetFurnitureCountBySuitId(FurnitureCache, suitId)
    end
    return XFurnitureConfigs.GetSuitCount(suitId)
end

function XUiFurnitureReform:IsInFurniture()
    return self.ChildType == XDormConfig.ReformPanelIndex.Furniture
end

function XUiFurnitureReform:IsInTemplate()
    return self.ChildType == XDormConfig.ReformPanelIndex.Template
end

function XUiFurnitureReform:CheckNeedSaveTemplate()
    if not self.SelectRoomData then
        return false
    end
    return XHomeDormManager.IsNeedSaveByTemplate(self.SelectRoomData:GetRoomId(), self.SelectRoomData:GetRoomDataType(), self.RoomId)
end