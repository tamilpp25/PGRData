local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---场景设置切换界面的管理器
local XUiSceneSettingMain = XLuaUiManager.Register(XLuaUi,"UiSceneSettingMain")
local BatteryComponent = CS.XUiBattery
local DateStartTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeStr")
local DateEndTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeEnd")
local LowPowerValue = CS.XGame.ClientConfig:GetFloat("UiMainLowPowerValue")

function XUiSceneSettingMain:OnAwake()
    self.FirstLoad = true
    self.ModeTagPool = {}

    self:InitButton()
    self:InitDynamicTable()

    -- 助理刷新
    XEventManager.AddEventListener(XEventId.EVENT_FAVORABILITY_ASSISTLIST_CHANGE, self.RefreshPanelAssistantByServerSync, self)
    -- 场景刷新
    XEventManager.AddEventListener(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN, self.RefreshPanelSceneByServerSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN, self.RefreshSyncBtnState, self)
end

function XUiSceneSettingMain:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.ToggleRandomScene, self.OnToggleRandomSceneClick)

    -- 打开助理面板
    self.BtnAssistant.CallBack = function()
        self:OnBtnAssistantClick()
    end

    -- 打开场景面板
    self.BtnScene.CallBack = function()
        self:OnBtnSceneClick()
    end

    -- 设为首席助理
    self.BtnSetFav.CallBack = function()
        self:OnBtnSetFavClick()
    end
    
    self.BtnSetFav2.CallBack = function()
        self:OnBtnSetFavClick()
    end

    -- 更换助理
    self.BtnExchange.CallBack = function()
        self:OnBtnExchangeClick()
    end

    self.BtnFashion.CallBack = function()
        self:OnBtnFashionClick()
    end

    self.BtnSceneSetting1.CallBack = function()
        self:OnBtnSceneSettingClick(self.BtnSceneSetting1)
    end

    self.BtnSceneSetting2.CallBack = function()
        self:OnBtnSceneSettingClick(self.BtnSceneSetting2)
    end

    self.BtnEffectPreview.CallBack = function()
        self:PlayAnimationWithMask("DarkEnable", function ()
            XDataCenter.PhotographManager.OpenScenePreview(self.CurSelectedBackgroundId)
        end)
    end

    self.BtnAdd.CallBack = function()
        self:OnBtnAddClick()
    end

    self.BtnRemove.CallBack = function()
        self:OnBtnRemoveClick()
    end

    self.BtnGet.CallBack = function()
        self:OnBtnGetClick()
    end

    self.BtnSyncMainScene.CallBack = function() 
        self:OnBtnSyncMainSceneClick()
    end

    -- 红点
    self.ScreenPointId = self:AddRedPointEvent(self.BtnScene, self.CheckBtnScreenRedPoint, self, {XRedPointConditions.Types.CONDITION_SCENE_SETTING})

    ---@type XUiTaikoMasterFlowText
    local XUiTextScrolling = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")
    self.NameTextScrolling = XUiTextScrolling.New(self.TxtName ,self.TxtNameMask)
    self.NameTextScrolling:Stop()
end

function XUiSceneSettingMain:CheckBtnScreenRedPoint(count)
    self.BtnScene:ShowReddot(count>=0)
end

function XUiSceneSettingMain:OnBtnAssistantClick()
    if self.PanelAssistant.gameObject.activeSelf then
        return
    end

    self:PlayAnimation("DarkDisable")
    self.BtnGroup:DoSelectIndex(0)
    self:RefreshPanelAssistant()
    self.DynamicTableScene:SetActive(false)
    self.UiModelParent.gameObject:SetActiveEx(self.PanelAssistant.gameObject.activeSelf) --场景列表不显示助理
end

function XUiSceneSettingMain:OnBtnSceneClick()
    if self.PanelScene.gameObject.activeSelf then
        return
    end

    self:PlayAnimation("DarkDisable")
    self.BtnGroup:DoSelectIndex(1)
    self:RefreshPanelScene()
    self.DynamicTableAssistant:SetActive(false)
    self.ChiefAssistantGrid:Close()
    self.UiModelParent.gameObject:SetActiveEx(self.PanelAssistant.gameObject.activeSelf)
end

function XUiSceneSettingMain:OnBtnSetFavClick()
    -- 避免重复设置
    local isSelecetChiefAssistant = self.AssistantSelectIndex == 0
    if isSelecetChiefAssistant then
        --打开首席选择界面
        XLuaUiManager.Open("UiFavorabilityLineRoomCharacterMainSelect", self:GetCurrSelectChar())
    else
        local charId = self:GetCurrSelectChar().Id
        XDataCenter.DisplayManager.SetDisplayCharIdFirstRequest(charId, function (res)
            self.AssistantSelectIndex = 0 -- 设置首席后重新选定默认下标为0
            local charConfig = XMVCA.XCharacter:GetCharacterTemplate(charId)
            local name = charConfig.Name.. "·" ..charConfig.TradeName
            XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilitySetChiefAssistSucc", name))
        end)
    end
end

function XUiSceneSettingMain:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self:GetCurrSelectChar().Id)
end

-- 点击首席助理
function XUiSceneSettingMain:OnSelectChiefAssistant()
    if self.CurSelectedAssistantGrid then
        self.CurSelectedAssistantGrid:OnSelect(false)
    end

    self.AssistantSelectIndex = 0
    self.CurSelectedAssistantGrid = self.ChiefAssistantGrid
    self.ChiefAssistantGrid:OnSelect(true)
    self.BtnExchange.gameObject:SetActiveEx(false)
    self.BtnSetFav.gameObject:SetActiveEx(false) --普通助理设置首席的按钮
    self.BtnSetFav2.gameObject:SetActiveEx(true) --首席助理设置首席的按钮
    self:RefreshAssistantInfo()
end

function XUiSceneSettingMain:OnBtnAddAssistListClick()
    -- 打开添加助理队列ui
    XLuaUiManager.Open("UiFavorabilityLineRoomCharacterSelect")
end

function XUiSceneSettingMain:OnBtnExchangeClick()
    XLuaUiManager.Open("UiFavorabilityLineRoomCharacterSelect", self:GetCurrSelectChar())
end

function XUiSceneSettingMain:OnBtnSceneSettingClick(btn)
    if btn.ButtonState == CS.UiButtonState.Disable then
        local content = CS.XTextManager.GetText("UiSceneRandomUnlock")
        XLuaUiManager.Open("UiDialog", nil, content, XUiManager.DialogType.Normal, nil, function ()
            self:OnToggleRandomSceneClick(function ()
                XLuaUiManager.Open("UiSceneRandomSetting")
            end)
        end)
        return
    end

    XLuaUiManager.Open("UiSceneRandomSetting")
end

function XUiSceneSettingMain:OnBtnAddClick()
    XDataCenter.PhotographManager.AddRandomBackgroundRequest(self.CurSelectedBackgroundId)
end

function XUiSceneSettingMain:OnBtnRemoveClick()
    XDataCenter.PhotographManager.RemoveRandomBackgroundRequest(self.CurSelectedBackgroundId)
end

function XUiSceneSettingMain:OnBtnGetClick()
    local currentSceneId = self.CurSelectedBackgroundId
    local skipId = XDataCenter.PhotographManager.GetSceneSkipIdById(currentSceneId)

    if XTool.IsNumberValid(skipId) then
        XFunctionManager.SkipInterface(skipId)
    end
end

function XUiSceneSettingMain:OnBtnSyncMainSceneClick()
    --判断按钮是否可交互
    local stateEnum = XEnumConst.Ui_MAIN.UiSceneSettingMainBtnSyncState
    if self.BtnTongBlackState == stateEnum.Enable then
        --执行同步
        local curSelectSceneId = self.CurSelectedBackgroundId
        local curChara = XDataCenter.DisplayManager.GetDisplayChar()

        XDataCenter.PhotographManager.ChangeDisplay(curSelectSceneId, curChara.Id, curChara.FashionId, function ()
            self:RefreshSyncBtnState()
            XUiManager.TipText("PhotoModeChangeSuccess")
        end)
    elseif self.BtnTongBlackState == stateEnum.Lock then
        --提示其解锁方式
        local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(self.CurSelectedBackgroundId)
        XUiManager.TipError(sceneTemplate.LockDec)
    end
end

function XUiSceneSettingMain:OnToggleRandomSceneClick(fun)
    if self.SwitchLock then
        return
    end
    self.SwitchLock = true

    local targetFlag = not XDataCenter.PhotographManager.GetIsRandomBackground()
    XDataCenter.PhotographManager.SwitchRandomBackgroundRequest(targetFlag, XDataCenter.PhotographManager.GetCurSceneId(), function (res)
        self.ToggleRandomScene.isOn = targetFlag
        self.SwitchLock = false

        -- 每次打开开关后进行一次场景随机，确保在随机场景模式下, LastRandomBackgroundId是有值的
        XDataCenter.PhotographManager.GetNextRandomSceneId()

        if fun and type(fun) == "function" then
            fun()
        end
    end)
end

function XUiSceneSettingMain:InitDynamicTable()
    local XFavorabilityAssistantGrid = require('XUi/XUiSceneSettingMain/Grid/XFavorabilityAssistantGrid')
    self.DynamicTableAssistant = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTableAssistant:SetProxy(XFavorabilityAssistantGrid,self)
    self.DynamicTableAssistant:SetDelegate(self)
    self.DynamicTableAssistant:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEventAssistant(event, index, grid)
    end)

    local XDynamicBackgroundGrid = require('XUi/XUiSceneSettingMain/Grid/XDynamicBackgroundGrid')
    self.DynamicTableScene = XDynamicTableNormal.New(self.PanelSceneList)
    self.DynamicTableScene:SetProxy(XDynamicBackgroundGrid, self)
    self.DynamicTableScene:SetDelegate(self)
    self.DynamicTableScene:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEventScene(event, index, grid)
    end)
end

-- 刷新首席助理
function XUiSceneSettingMain:RefreshChiefAssistant()
    -- 首席助理专用格子
    if not self.ChiefAssistantGrid then
        local XFavorabilityAssistantGrid = require('XUi/XUiSceneSettingMain/Grid/XFavorabilityAssistantGrid')
        self.ChiefAssistantGrid = XFavorabilityAssistantGrid.New(self.PanelChiefAssistant, self)
        XUiHelper.RegisterClickEvent(self.ChiefAssistantGrid, self.ChiefAssistantGrid.Button, function() self:OnSelectChiefAssistant() end)
    end
    self.ChiefAssistantGrid:RefreshAssist(XPlayer.DisplayCharIdList[1])

    if self.AssistantSelectIndex == 0 then
        self:OnSelectChiefAssistant()
    end
end

-- 刷新普通助理
function XUiSceneSettingMain:RefreshDynamicTableAssistant()
    self.Characters = self:GetCharaterList()
    self.DynamicTableAssistant:SetDataSource(self.Characters)
    self.DynamicTableAssistant:ReloadDataASync()
end

function XUiSceneSettingMain:OnDynamicTableEventAssistant(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local charId = self.Characters[index]
        grid:RefreshAssist(charId)
        local selected = index == self.AssistantSelectIndex
        grid:OnSelect(selected)
        if selected then
            self.CurSelectedAssistantGrid = grid
            self:RefreshAssistantInfo()
        end

        if charId == XDataCenter.DisplayManager.GetDisplayChar().Id then
            self.CurAssist = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if grid.Value == CS.XTextManager.GetText("AddButton") then
            return
        end

        if not self.Characters[index] then return end
        if self.CurSelectedAssistantGrid then
            self.CurSelectedAssistantGrid:OnSelect(false)
        end
        grid:OnSelect(true)

        self.AssistantSelectIndex = index
        self.CurSelectedAssistantGrid = grid
        self.BtnExchange.gameObject:SetActiveEx(true)
        self.BtnSetFav.gameObject:SetActiveEx(true) --普通助理设置首席的按钮
        self.BtnSetFav2.gameObject:SetActiveEx(false) --首席助理设置首席的按钮
        self:RefreshAssistantInfo()
    end
end

function XUiSceneSettingMain:RefreshAssistantInfo()
    local characterId = self:GetCurrSelectChar().Id
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtTradeName.text = charConfig.TradeName
    self.TxtNameVocal.text = XMVCA.XFavorability:GetCharacterCvById(characterId)

    local character = XMVCA.XCharacter:GetCharacter(characterId)
    self.RImgTypeIcon:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(character.Type))

    self:RefreshRoleModelPanel()

    self.UiModelParent.gameObject:SetActiveEx(self.PanelAssistant.gameObject.activeSelf)
end

function XUiSceneSettingMain:RefreshRoleModelPanel()
    -- 场景未加载完成时，不刷新角色模型
    if self.FirstLoad  then
        return
    end

    if not self.RoleModelPanel then
        local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
        self.RoleModelPanel = XUiPanelRoleModel.New(self.UiModelParent, self.Name, true, false, false, nil, nil, nil, true)
    end

    if not self.ChangeActionEffect then
        local uiModelRoot = self.UiModelGo.transform
        self.ChangeActionEffect = uiModelRoot:FindTransform("ChangeActionEffect")
    end

    if self:GetCurrSelectChar().Id ~= self.LastChangeCharacterId then
        self.ChangeActionEffect.gameObject:SetActiveEx(false)
        self.ChangeActionEffect.gameObject:SetActiveEx(true)
    end

    local ranfomBackgroundCharFashionId = nil
    if XDataCenter.PhotographManager.GetIsBackgroundRandomFashion() then
        ranfomBackgroundCharFashionId = XDataCenter.PhotographManager.GetCharRandomBackgroundFashionDic(self.DisplayCharacterId)
    end
    XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModelPanel, self:GetCurrSelectChar().Id, nil, ranfomBackgroundCharFashionId)
    self.LastChangeCharacterId = self:GetCurrSelectChar().Id
end

function XUiSceneSettingMain:GetCurrSelectChar()
    if not self.Characters then
        self.Characters = self:GetCharaterList()
    end
    local charId = nil
    if self.AssistantSelectIndex == 0 then
        charId = XPlayer.DisplayCharIdList[1]
    else
        charId = self.Characters[self.AssistantSelectIndex]
    end

    return XMVCA.XCharacter:GetCharacter(charId)
end

function XUiSceneSettingMain:GetCharaterList()
    local charList = XPlayer.DisplayCharIdList
    local res = {}
    for i = 2, #charList, 1 do
        table.insert(res, charList[i])
    end

    local maxAssistantNum = CS.XGame.Config:GetInt("AssistantNum") - 1
    if #res < maxAssistantNum then
        table.insert(res, CS.XTextManager.GetText("AddButton"))
    end

    return res
end

function XUiSceneSettingMain:RefreshPanelSceneByServerSync()
    if not self.PanelScene.gameObject.activeSelf then
        return
    end
    self:RefreshPanelScene()
end

function XUiSceneSettingMain:RefreshPanelAssistantByServerSync()
    if not self.PanelAssistant.gameObject.activeSelf then
       return 
    end

    local charList = self:GetCharaterList()
    if self.AssistantSelectIndex  > (#charList - 1) then
        self.AssistantSelectIndex = #charList - 1 -- 如果是移除助理，要考虑到当前选中的是最后一个助理的情况
    end
    self:RefreshPanelAssistant()
end

function XUiSceneSettingMain:RefreshPanelAssistant()
    if self.DynamicTableAssistant then
        self.DynamicTableAssistant:SetActive(true)
    end

    if self.ChiefAssistantGrid then
        self.ChiefAssistantGrid:Open()
    end

    self:RefreshDynamicTableAssistant() -- 普通列表
    self:RefreshChiefAssistant() -- 首席助理列表
    self:RefreshAssistantInfo() -- 右边信息
end

function XUiSceneSettingMain:RefreshDynamicTableScene()
    local dataList = self:SortSceneIdList(XDataCenter.PhotographManager.GetSceneIdList())
    self.SceneIdList = dataList
    self.DynamicTableScene:SetDataSource(dataList)
    if not self.CurSelectedBackgroundIndex then
        self.CurSelectedBackgroundIndex = 1
    end

    if self.CurSelectedBackgroundId then
        local _, index = table.contains(dataList, self.CurSelectedBackgroundId)
        self.CurSelectedBackgroundIndex = index
    end

    self.DynamicTableScene:ReloadDataASync(self.CurSelectedBackgroundIndex)
end

function XUiSceneSettingMain:OnDynamicTableEventScene(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        --根据索引获取指定的场景数据
        local sceneId = self.SceneIdList[index]
        --更新当前元素
        grid:RefreshDisplay(sceneId)

        local isSelect = index == self.CurSelectedBackgroundIndex
        grid:SetSelect(isSelect)
        if isSelect then
            XDataCenter.PhotographManager.RemoveNewSceneTempData(sceneId)
            grid:RefreshRedPoint()
            self.CurSelectedBackgroundGrid = grid
            local sceneId = self.SceneIdList[index]
            self.CurSelectedBackgroundId = sceneId
            self.CurSelectedBackgroundIndex = index
            local template = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
            local scenePath, modelPath = XSceneModelConfigs.GetSceneAndModelPathById(template.SceneModelId)
            if self.LastScenePath == scenePath then return end -- 相同场景不切换
            self:LoadUiScene(scenePath, modelPath, function() self:OnUiSceneLoaded(self.FirstLoad, scenePath) end, false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurSelectedBackgroundGrid == grid then return end

        grid:SetSelect(true)
        if self.CurSelectedBackgroundGrid then
            self.CurSelectedBackgroundGrid:SetSelect(false)
        end
        self.CurSelectedBackgroundGrid = grid

        local sceneId = self.SceneIdList[index]
        XDataCenter.PhotographManager.RemoveNewSceneTempData(sceneId)
        grid:RefreshRedPoint()

        self.CurSelectedBackgroundId = sceneId
        self.CurSelectedBackgroundIndex = index
        local template = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
        local scenePath, modelPath = XSceneModelConfigs.GetSceneAndModelPathById(template.SceneModelId)
        self:LoadUiScene(scenePath, modelPath, function() self:OnUiSceneLoaded(self.FirstLoad, scenePath) end, false)
    end
end

function XUiSceneSettingMain:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.CameraFar = self:FindVirtualCamera("CamFarMain")
    self.CameraNear = self:FindVirtualCamera("CamNearMain")
    self.CameraComponentFar = root:FindTransform("UiFarCamera"):GetComponent("Camera")
    self.CameraComponentNear = root:FindTransform("UiNearCamera"):GetComponent("Camera")
    self.UiModelParent = root:FindTransform("UiModelParent")
    self.ChangeActionEffect = root:FindTransform("ChangeActionEffect")
end

function XUiSceneSettingMain:OnUiSceneLoaded(firstload, scenePath)
    if not firstload then
        --执行淡出动画
        self:PlayAnimation('Loading2')
    end

    --加载新场景要刷新电池模式
    self.CurBatteryMode = nil
    self:InitSceneRoot()
    if self:InitBatteryUi() then
        self:UpdateBatteryMode()
    end

    self:RefreshSyncBtnState() -- 右下角按钮
    --刷新右上角信息栏显示
    self:RefreshSceneInfo()
    -- self.Parent:RefreshRightTagPanel()

    -- 恢复相机
    self.CameraFar.gameObject:SetActiveEx(true)
    self.CameraNear.gameObject:SetActiveEx(true)

    -- 开启时钟
    self:ReStartClockTime()

    -- 刷新角色模型
    self.RoleModelPanel = nil
    self:RefreshRoleModelPanel()

    self.FirstLoad = false
    self.LastScenePath = scenePath
end

-- [场景电池相关]
function XUiSceneSettingMain:InitBatteryUi()
    self.animationRoot = self.UiSceneInfo.Transform:Find("Animations")
    if XTool.UObjIsNil(self.animationRoot) then return false end
    
    self.toChargeTimeLine = self.animationRoot:Find("ToChargeTimeLine")
    self.toFullTimeLine = self.animationRoot:Find("ToFullTimeLine")
    self.fullTimeLine = self.animationRoot:Find("FullTimeLine")
    self.chargeTimeLine = self.animationRoot:Find("ChargeTimeLine")

    self.toChargeTimeLine.gameObject:SetActiveEx(false)
    self.toFullTimeLine.gameObject:SetActiveEx(false)
    self.fullTimeLine.gameObject:SetActiveEx(false)
    self.chargeTimeLine.gameObject:SetActiveEx(false)
    
    return true
end

-- [场景电池相关]
function XUiSceneSettingMain:UpdateBatteryMode()
    if XTool.UObjIsNil(self.animationRoot) then return end

    --先还原状态
    self.toChargeTimeLine.gameObject:SetActiveEx(false)
    self.toFullTimeLine.gameObject:SetActiveEx(false)
    self.fullTimeLine.gameObject:SetActiveEx(false)
    self.chargeTimeLine.gameObject:SetActiveEx(false)
    
    local particleGroupName = XDataCenter.PhotographManager.GetSceneTemplateById(self.CurSelectedBackgroundId).ParticleGroupName
    local chargeAnimator = nil
    if particleGroupName and particleGroupName ~= "" then
        local chargeAnimatorTrans = self.UiSceneInfo.Transform:FindTransform(particleGroupName)
        if chargeAnimatorTrans then
            chargeAnimator = chargeAnimatorTrans:GetComponent("Animator")
        else
            XLog.Error("Can't Find \"" .. particleGroupName .. "\", Plase Check \"ParticleGroupName\" In Share/PhotoMode/Background.tab")
        end
    end

    local type = XPhotographConfigs.GetBackgroundTypeById(self.CurSelectedBackgroundId)
    if type == XPhotographConfigs.BackGroundType.PowerSaved then
        if BatteryComponent.IsCharging then --充电状态
            self:PlayBatteryModeAnimation(false,chargeAnimator)
            XDataCenter.PhotographManager.UpdatePreviewState(true, true)
        else
            if BatteryComponent.BatteryLevel > LowPowerValue then -- 比较电量
                self:PlayBatteryModeAnimation(false,chargeAnimator)
                XDataCenter.PhotographManager.UpdatePreviewState(true, true)
            else
                self:PlayBatteryModeAnimation(true,chargeAnimator)
                XDataCenter.PhotographManager.UpdatePreviewState(false, true)
            end
        end
    else
        --时间模式判断
        local startTime = XTime.ParseToTimestamp(DateStartTime)
        local endTime = XTime.ParseToTimestamp(DateEndTime)
        local nowTime = XTime.ParseToTimestamp(CS.System.DateTime.Now:ToLocalTime():ToString())
        if startTime > nowTime and nowTime > endTime then   -- 比较时间
            self:PlayBatteryModeAnimation(false,chargeAnimator)
            XDataCenter.PhotographManager.UpdatePreviewState(true, true)
        else
            self:PlayBatteryModeAnimation(true,chargeAnimator)
            XDataCenter.PhotographManager.UpdatePreviewState(false, true)
        end
    end
end

-- [场景电池相关]
function XUiSceneSettingMain:PlayBatteryModeAnimation(IsSetLow,chargeAnimator)
    if self.CurBatteryMode==XPhotographConfigs.BackGroundState.Full then
        if IsSetLow then
            if chargeAnimator then chargeAnimator:Play("FullToLow") end
            self.CurBatteryMode=XPhotographConfigs.BackGroundState.Low
            self.toChargeTimeLine.gameObject:SetActiveEx(true)
        else
            if chargeAnimator then chargeAnimator:Play("Full") end
            self.fullTimeLine.gameObject:SetActiveEx(true)
        end
    elseif self.CurBatteryMode==XPhotographConfigs.BackGroundState.Low then
        if IsSetLow then
            if chargeAnimator then chargeAnimator:Play("Low") end
            self.chargeTimeLine.gameObject:SetActiveEx(true)
        else
            if chargeAnimator then chargeAnimator:Play("LowToFull") end
            self.CurBatteryMode=XPhotographConfigs.BackGroundState.Full
            self.toFullTimeLine.gameObject:SetActiveEx(true)
        end
    else    --如果没有有效值，说明是第一次打开该场景，直接设置状态
        if IsSetLow then
            if chargeAnimator then chargeAnimator:Play("Low") end
            self.CurBatteryMode=XPhotographConfigs.BackGroundState.Low
            self.chargeTimeLine.gameObject:SetActiveEx(true)
        else
            if chargeAnimator then chargeAnimator:Play("Full") end
            self.CurBatteryMode=XPhotographConfigs.BackGroundState.Full
            self.fullTimeLine.gameObject:SetActiveEx(true)
        end
    end
end

-- 刷新场景同步按钮状态 (这个如果只靠切换场景触发是不行的)
function XUiSceneSettingMain:RefreshSyncBtnState()
    local stateEnum = XEnumConst.Ui_MAIN.UiSceneSettingMainBtnSyncState
    local selectedId = self.CurSelectedBackgroundId
    if selectedId == XDataCenter.PhotographManager.GetCurSceneId() then
        --禁用，并显示“使用中”
        self.BtnGet.gameObject:SetActiveEx(false)
        self.BtnSyncMainScene.gameObject:SetActiveEx(true)
        self.BtnSyncMainScene:SetName(XUiHelper.GetText('SceneSettingUsing'))
        self.BtnSyncMainScene:SetButtonState(3)
        self.BtnTongBlackState = stateEnum.Using
    elseif not XDataCenter.PhotographManager.CheckSceneIsHaveById(selectedId) then
        if XDataCenter.PhotographManager.CheckSceneCanSkipById(selectedId) then
            self.BtnSyncMainScene.gameObject:SetActiveEx(false)
            self.BtnGet.gameObject:SetActiveEx(true)
        else
            self.BtnSyncMainScene.gameObject:SetActiveEx(true)
            self.BtnGet.gameObject:SetActiveEx(false)
            --禁用,并显示"未解锁"
            self.BtnSyncMainScene:SetName(XUiHelper.GetText('SceneSettingLock'))
            self.BtnSyncMainScene:SetButtonState(3)
            self.BtnTongBlackState = stateEnum.Lock
        end
    else
        --开启
        self.BtnGet.gameObject:SetActiveEx(false)
        self.BtnSyncMainScene.gameObject:SetActiveEx(true)
        self.BtnSyncMainScene:SetName(XUiHelper.GetText('SceneSettingNormal'))

        self.BtnSyncMainScene:SetButtonState(0)
        self.BtnTongBlackState = stateEnum.Enable
    end

    local isRandomBackground = XDataCenter.PhotographManager.GetIsRandomBackground()
    self.ToggleRandomScene.isOn = isRandomBackground
    
    if isRandomBackground then
        self.BtnSceneSetting1:SetButtonState(CS.UiButtonState.Normal)
        self.BtnSceneSetting2:SetButtonState(CS.UiButtonState.Normal)

        local isCurBackgroundRandom = XDataCenter.PhotographManager.GetRandomBackgroundDataInRandomPoolById(self.CurSelectedBackgroundId)
        local isHave = XDataCenter.PhotographManager.CheckSceneIsHaveById(self.CurSelectedBackgroundId)
        self.BtnAdd.gameObject:SetActiveEx(not isCurBackgroundRandom and isHave)
        self.BtnRemove.gameObject:SetActiveEx(isCurBackgroundRandom)
    else
        self.BtnSceneSetting1:SetButtonState(CS.UiButtonState.Disable)
        self.BtnSceneSetting2:SetButtonState(CS.UiButtonState.Disable)

        self.BtnAdd.gameObject:SetActiveEx(false)
        self.BtnRemove.gameObject:SetActiveEx(false)
    end

    local poolList = XDataCenter.PhotographManager.GetRandomBackgroundPool()
    local limitNum = CS.XGame.Config:GetInt("RandomBackgroundCountLimit")
    self.TxtRandomSceneNum.text = #poolList .. "/" .. limitNum

    XRedPointManager.Check(self.ScreenPointId)
end

-- 刷新场景右边数据
function XUiSceneSettingMain:RefreshSceneInfo()
    local template = XDataCenter.PhotographManager.GetSceneTemplateById(self.CurSelectedBackgroundId)

    --显示场景名称
    self.TxtSceneName.text = template.Name
    --显示场景模式
    for index = 1, #template.Tag do
        local item=self:GetTagItem(index)
        item.GameObject:SetActiveEx(true)
        item:SetContent(template.Tag[index])
    end

    for index = #template.Tag+1, #self.ModeTagPool do
        local item=self:GetTagItem(index)
        item.GameObject:SetActiveEx(false)
    end

    self.UiModelParent.gameObject:SetActiveEx(self.PanelAssistant.gameObject.activeSelf)
end

-- [场景Tag相关]
function XUiSceneSettingMain:GetTagItem(index)
    local XRightTagItem = require('XUi/XUiSceneSettingMain/XRightTagItem')
    if index >= 1 and index <= #self.ModeTagPool then
        return self.ModeTagPool[index]
    else
        local ui = CS.UnityEngine.GameObject.Instantiate(self.Function1, self.PanelLbItem.transform)
        self.ModeTagPool[index]= XRightTagItem.New(ui)
        return self.ModeTagPool[index]
    end
end

function XUiSceneSettingMain:RefreshPanelScene()
    if self.DynamicTableScene then
        self.DynamicTableScene:SetActive(true)
    end
    self:RefreshDynamicTableScene()
end

---对场景显示进行排序
---1.优先显示使用中的场景
---2.优先显示已解锁场景
---3.其他按照表中优先级值进行排序
function XUiSceneSettingMain:SortSceneIdList(list)
    local curShowSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    table.sort(list,function(sceneIdA, sceneIdB)
        --正在使用的排在其他的前面
        local isACur = sceneIdA == curShowSceneId
        local isBCur = sceneIdB == curShowSceneId
        if isACur ~= isBCur then
            return isACur
        end

        local randomPool = XDataCenter.PhotographManager.GetRandomBackgroundPool()
        local isARandom = table.containsKey(randomPool, "BackgroundId", sceneIdA)
        local isBRandom = table.containsKey(randomPool, "BackgroundId", sceneIdB)
        if isARandom ~= isBRandom then
            return isARandom
        end
        
        --已拥有的排在未拥有的前面
        local hasA = XDataCenter.PhotographManager.CheckSceneIsHaveById(sceneIdA)
        local hasB = XDataCenter.PhotographManager.CheckSceneIsHaveById(sceneIdB)
        if hasA ~= hasB then
            return hasA
        end

        --其他情况按优先级排序
        return sceneIdA > sceneIdB
    end)
    return list
end

function XUiSceneSettingMain:OnStart()
    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    self.CurSelectedBackgroundId = curSceneId    
    local curSceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(curSceneId)
    local curSceneUrl, modelUrl = XSceneModelConfigs.GetSceneAndModelPathById(curSceneTemplate.SceneModelId)
    self:LoadUiScene(curSceneUrl, modelUrl, function() self:OnUiSceneLoaded(self.FirstLoad, curSceneUrl) end, false)
end

function XUiSceneSettingMain:OnEnable()
    self:PlayAnimationWithMask("DarkDisable")

    local curId = XDataCenter.DisplayManager.GetDisplayChar().Id
    local _, index = table.contains(XPlayer.DisplayCharIdList, curId)
    self.AssistantSelectIndex = index - 1

    if self.PanelAssistant.gameObject.activeSelf then
        self:RefreshPanelAssistant()
    end
    if self.PanelScene.gameObject.activeSelf then
        self:RefreshPanelScene()
    end

    XRedPointManager.Check(self.ScreenPointId)

    -- 开启时钟
    self:ReStartClockTime()
end

function XUiSceneSettingMain:OnDisable()
    -- 关闭时钟
    if self.ClockTimer then
        XUiHelper.StopClockTimeTempFun(self, self.ClockTimer)
        self.ClockTimer = nil
    end
    self.LastScenePath = nil
end

function XUiSceneSettingMain:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FAVORABILITY_ASSISTLIST_CHANGE, self.RefreshPanelAssistantByServerSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN, self.RefreshPanelSceneByServerSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN, self.RefreshSyncBtnState, self)
end

function XUiSceneSettingMain:ReStartClockTime()
    self:StopClockTime()
    -- 开启时钟
    self.ClockTimer = XUiHelper.SetClockTimeTempFun(self)
end

function XUiSceneSettingMain:StopClockTime()
    -- 关闭时钟
    if self.ClockTimer then
        XUiHelper.StopClockTimeTempFun(self, self.ClockTimer)
        self.ClockTimer = nil
    end
end

return XUiSceneSettingMain