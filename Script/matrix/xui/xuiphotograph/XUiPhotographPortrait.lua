local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBattery = require("XUi/XUiBuyAsset/XUiBattery")
local XUiGridPhotographSceneBtn = require("XUi/XUiPhotograph/XUiGridPhotographSceneBtn")
local XUiGridPhotographCharacterBtn = require("XUi/XUiPhotograph/XUiGridPhotographCharacterBtn")
local XUiGridPhotographOtherBtn = require("XUi/XUiPhotograph/XUiGridPhotographOtherBtn")
local XUiGridPhotographFashionBtn = require("XUi/XUiPhotograph/XUiGridPhotographFashionBtn")
local XUiPhotographActionPanel = require("XUi/XUiPhotograph/XUiPhotographActionPanel")
local XUiPhotographSDKPanel = require("XUi/XUiPhotograph/XUiPhotographSDKPanel")

local XUiPhotographPortrait = XLuaUiManager.Register(XLuaUi, "UiPhotographPortrait")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local OffsetX, OffsetY = 60, 60

local MAX_FASHION_MEMBER_LINE = 3 --涂装表每行个数

local CsXUiBattery = CS.XUiBattery
local CsXQualityManager = CS.XQualityManager
local LowPowerValue = CS.XGame.ClientConfig:GetFloat("UiMainLowPowerValue")
local DateStartTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeStr")
local DateEndTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeEnd")

local CSDestroy = CS.UnityEngine.Object.Destroy
local Vector2 = CS.UnityEngine.Vector2

local SceneMode = 1
local CGMode = 2

local DynamicTableType = {
    Scene = 1,
    Character = 2,
    Fashion = 3,
    Action = 4
}

function XUiPhotographPortrait:OnAwake()
    self:InitCb()
    self:InitUi()
end

function XUiPhotographPortrait:OnStart(orientation, charId, fashionId, uiPhotograph, sceneId)
    self.Orientation = orientation
    self.SetData = XDataCenter.PhotographManager.GetSetData()
    self.OldCharacterId = charId
    self.CharacterId = charId
    self.FashionId = fashionId
    self.UiPhotograph = uiPhotograph
    self.CurrSeleSceneId = sceneId
    self:InitView()
end

function XUiPhotographPortrait:OnEnable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    self.Timer = XScheduleManager.ScheduleForever(function() 
        self:Update()
    end, 0)
    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnEnable()
    end
    
    self:UpdateView()
    XMVCA.XFavorability:AddRoleActionUiAnimListener(self)

    -- 开启时钟
    self.ClockTimer = XUiHelper.SetClockTimeTempFun(self)
end

function XUiPhotographPortrait:Update()

    local dt = CS.UnityEngine.Time.deltaTime
    if self.SignBoardPlayer then
        self.SignBoardPlayer:Update(dt)
    end
    local width, height = CS.UnityEngine.Screen.width, CS.UnityEngine.Screen.height
    if width ~= self.StartWidth or height ~= self.StartHeight then
        self:InitProportionImage()
        self.StartWidth  = width
        self.StartHeight = height
    end
end

function XUiPhotographPortrait:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnDisable()
    end
    XMVCA.XFavorability:RemoveRoleActionUiAnimListener(self)

    -- 关闭时钟
    if self.ClockTimer then
        XUiHelper.StopClockTimeTempFun(self, self.ClockTimer)
        self.ClockTimer = nil
    end
end

function XUiPhotographPortrait:OnDestroy()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnDestroy()
    end
    CS.XResolutionManager.SetIsLandscape(true) 
    -- CS.UnityEngine.Screen.orientation = self.Orientation
    -- 这里不能还原成原来的值，会变成锁死方向。必须改成可自动旋转
    -- 如果该值设置为 ScreenOrientation.AutoRotation，则随着设备方向的改变，屏幕将自动从任意选项（由 autorotateToPortrait 等启用）中进行选择
    -- 集成到CS.XResolutionManager.SetIsLandscape中设置了
    -- 安卓有bug，需要先切回原来的横屏方向，再下一帧设置成Auto
    if XUserManager.Platform == XUserManager.PLATFORM.Android then 
        CS.UnityEngine.Screen.orientation = self.Orientation
        XScheduleManager.ScheduleNextFrame(function()
            CS.UnityEngine.Screen.orientation = CS.UnityEngine.ScreenOrientation.AutoRotation
        end)
    end

    XDataCenter.PhotographManager.ClearTextureCache()
end

function XUiPhotographPortrait:Close()
    self:EmitSignal("Refresh", self.CharacterId, self.FashionId, self.OldCharacterId)
    self.Super.Close(self)
end

function XUiPhotographPortrait:InitView()
    self.TxtUserName.text = XPlayer.Name
    self.TxtLevel.text = XPlayer.GetLevelOrHonorLevel()
    self.TxtID.text = string.format("ID: %s", XPlayer.Id)
    self.TxtRank.text = XPhotographConfigs.GetRankLevelText()
    self.ImgGlory.gameObject:SetActiveEx(XPlayer.IsHonorLevelOpen())
    
    self:SwitchMenuPanel(false)
    self:SwitchActionPanel(false)
    
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
    local scenePath, modelPath = XSceneModelConfigs.GetSceneAndModelPathById(sceneTemplate.SceneModelId)
    self:LoadUiScene(scenePath, modelPath, handler(self, self.OnUiSceneLoaded), false)
    
    self:RefreshBtnSynchronous()
end

function XUiPhotographPortrait:OnGetEvents()
    return {
        XEventId.EVENT_PHOTO_CHANGE_SCENE,
        XEventId.EVENT_PHOTO_CHANGE_MODEL,
        XEventId.EVENT_PHOTO_PLAY_ACTION,   
        XEventId.EVENT_PHOTO_CHANGE_ANIMATION_STATE,
        XEventId.EVENT_PHOTO_REPLAY_ANIMATION,
        CS.XEventId.EVENT_VIDEO_PLAYER_STATUS_PLAYING,
        CS.XEventId.EVENT_VIDEO_PLAYER_STATUS_PLAYEND,
    }
end

function XUiPhotographPortrait:OnNotify(evt, ...)
    if evt == XEventId.EVENT_PHOTO_CHANGE_SCENE then
        self.SignBoardPlayer:Stop(nil, true)
        self:UpdateScene(...)
        self:RefreshBtnSynchronous()
        self:RefreshActionView()
    elseif evt == XEventId.EVENT_PHOTO_CHANGE_MODEL then
        self.SignBoardPlayer:Stop(nil, true)
        self:UpdateRoleModel(...)
        self:PlayChangeActionEffect()
        self:RefreshBtnSynchronous()
    elseif evt == XEventId.EVENT_PHOTO_PLAY_ACTION then
        self:ForcePlay(...)
    elseif evt == XEventId.EVENT_PHOTO_CHANGE_ANIMATION_STATE then
        self:UpdateAnimation(...)
    elseif evt == XEventId.EVENT_PHOTO_REPLAY_ANIMATION then
        self:Replay()
    elseif evt == CS.XEventId.EVENT_VIDEO_PLAYER_STATUS_PLAYING then
        if not self.CG:IsLanguagePreparing() then
            self:OnCGPlay()
        end
    elseif evt == CS.XEventId.EVENT_VIDEO_PLAYER_STATUS_PLAYEND then
        self:OnCGStop()
    end
end

function XUiPhotographPortrait:OnCGPlay()
    self.ActionCtrlPanel:Refresh(true, self.SignBoardActionId ~= nil)
    self.CG:OnCGPlay()
end

function XUiPhotographPortrait:OnCGStop()
    self.ActionCtrlPanel:Refresh(false, self.SignBoardActionId ~= nil)
    self.CG:OnCGStop()
end

function XUiPhotographPortrait:UpdateView()
    self:BindViewModelPropertyToObj(self.SetData, function(logo)
        local show = logo.Value ~= 0
        self.ImgLogo.gameObject:SetActiveEx(show)
        if show then
            XPhotographConfigs.SetLogoOrInfoPos(self.ImgLogo.transform, logo, false, OffsetX, OffsetY)
        end
        XDataCenter.PhotographManager.SaveSetData()
    end, "_LogoAlignment")

    self:BindViewModelPropertyToObj(self.SetData, function(info)
        local show = info.Value ~= 0
        self.PanelName.gameObject:SetActiveEx(show)
        if show then
            XPhotographConfigs.SetLogoOrInfoPos(self.PanelName, info, true, OffsetX, OffsetY, self.PanelAutoLayout)
        end
        XDataCenter.PhotographManager.SaveSetData()
    end, "_InfoAlignment")

    self:BindViewModelPropertyToObj(self.SetData, function(openLevel)
        self.TxtLevel.transform.parent.gameObject:SetActiveEx(XTool.IsNumberValid(openLevel))
        XDataCenter.PhotographManager.SaveSetData()
    end, "_OpenLevel")

    self:BindViewModelPropertyToObj(self.SetData, function(openUId)
        self.TxtID.gameObject:SetActiveEx(XTool.IsNumberValid(openUId))
        XDataCenter.PhotographManager.SaveSetData()
    end, "_OpenUId")
end

function XUiPhotographPortrait:InitCb()
    self.BtnBack.CallBack = function()
       self:OnBtnBackClick()
    end
    self.BtnHide.CallBack = function() 
        self:OnBtnHideClick()
    end
    self.BtnSet.CallBack = function() 
        self:OnBtnSetClick()
    end
    self.BtnSynchronous.CallBack = function() 
        self:OnBtnSynchronousClick()
    end
    self.BtnPhotograph.CallBack = function() 
        self:OnBtnPhotographClick()
    end
    self.BtnMenu.CallBack = function() 
        self:OnBtnMenuClick()
    end
    self.BtnAction.CallBack = function() 
        self:OnBtnActionClick()
    end
    self.BtnCaptureClose.CallBack = function() 
        self:SwitchCapturePanel(false)
    end
    self.Btn.CallBack = function() 
        self:OnBtnClick()
    end
    if self.BtnBreakActionAnim then
        self.BtnBreakActionAnim.CallBack = function () self:PlayRoleActionUiBreakAnim() end
    end
end 

function XUiPhotographPortrait:InitUi()
    --场景列表
    self.DynamicSceneTable = XDynamicTableNormal.New(self.PanelSceneList)
    self.DynamicSceneTable:SetProxy(XUiGridPhotographSceneBtn)
    self.DynamicSceneTable:SetDelegate(self)
    --角色列表
    self.DynamicCharTable = XDynamicTableNormal.New(self.PanelCharacterList)
    self.DynamicCharTable:SetProxy(XUiGridPhotographCharacterBtn)
    self.DynamicCharTable:SetDelegate(self)
    --涂装列表
    self.DynamicFashionTable = XDynamicTableNormal.New(self.PanelFashionList)
    self.DynamicFashionTable:SetProxy(XUiGridPhotographFashionBtn)
    self.DynamicFashionTable:SetDelegate(self)
    --动作列表
    self.DynamicActionTable = XDynamicTableNormal.New(self.PanelActionList)
    self.DynamicActionTable:SetProxy(XUiGridPhotographOtherBtn)
    self.DynamicActionTable:SetDelegate(self)
    
    --ButtonGroup
    local tabBtn = {
        self.BtnScene,
        self.BtnCharacter,
        self.BtnFashion
    }
    
    self.TabBtnIndex = {
        BtnScene = 1,
        BtnCharacter = 2,
        BtnFashion = 3
    }
    
    self.ImgPicture.transform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
    self.ImgPicture.transform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)

    self.SafeAdapter = self.Transform:Find("SafeAreaContentPane"):GetComponent("XUiSafeAreaAdapter")
    self.PanelBtn:Init(tabBtn, function(index) self:OnSelectMenu(index) end)
    
    self.PanelAutoLayout = self.PanelName:GetComponent("XAutoLayoutGroup")

    self.TxtRank = self.TxtLevel.transform.parent:Find("TxtLv"):GetComponent("Text")
    self.ImgGlory = self.TxtLevel.transform.parent:Find("Icon")

    self.StartWidth = CS.UnityEngine.Screen.width
    self.StartHeight = CS.UnityEngine.Screen.height
    self.ContainerSize = self.ImageContainer.sizeDelta
    self:InitProportionImage()
    --Player
    self.Parent = self --奇怪的操作
    local signBoardPlayer = require("XCommon/XSignBoardPlayer").New(self, CS.XGame.ClientConfig:GetInt("SignBoardPlayInterval"), CS.XGame.ClientConfig:GetFloat("SignBoardDelayInterval"))
    local playerData = XMVCA.XFavorability:GetSignBoardPlayerData()
    signBoardPlayer:SetPlayerData(playerData)
    self.SignBoardPlayer = signBoardPlayer
    --ActionPanel
    ---@type XUiPhotographActionPanel
    self.ActionCtrlPanel = XUiPhotographActionPanel.New(self.PanelAction)
    self.ActionCtrlPanel:SetViewState(true)
    self.ActionCtrlPanel:Refresh(false, false)
    --SDKPanel
    self.SDKPanel = XUiPhotographSDKPanel.New(self, self.PanelSDK)
    ---@type XUiPanelCharacterCG
    self.CG = require("XUi/XUiCharacterCG/XUiPanelCharacterCG").New(self.PanelVideo, self)
end

--region   ------------------动态列表 start-------------------

function XUiPhotographPortrait:SetupDynamicTable(tableType)
    if self.CurTableType == tableType then
        return
    end
    self.CurTableType = tableType
    
    self.PanelSceneList.gameObject:SetActiveEx(false)
    self.PanelCharacterList.gameObject:SetActiveEx(false)
    self.PanelFashionList.gameObject:SetActiveEx(false)
    self.PanelActionList.gameObject:SetActiveEx(false)
    
    if self.CurTableType == DynamicTableType.Scene then
        self.PanelSceneList.gameObject:SetActiveEx(true)
        local list = XDataCenter.PhotographManager.GetSceneIdList()
        table.sort(list, function(idA, idB) 
            --已拥有的排在未拥有的前面
            local hasA = XDataCenter.PhotographManager.CheckSceneIsHaveById(idA)
            local hasB = XDataCenter.PhotographManager.CheckSceneIsHaveById(idB)
            if hasA ~= hasB then
                return hasA
            end

            return idA > idB
        end)
        local _, index = table.contains(list, XDataCenter.PhotographManager.GetCurSelectSceneId())
        self.CurSceneIndex = index or 1
        self.DynamicSceneTable:SetDataSource(list)
        self.DynamicSceneTable:ReloadDataASync(self.CurSceneIndex)
    elseif self.CurTableType == DynamicTableType.Character then
        self.PanelCharacterList.gameObject:SetActiveEx(true)
        self.CurCharIndex = XDataCenter.PhotographManager.GetCharIndexById(self.CharacterId)
        self.DynamicCharTable:SetDataSource(XDataCenter.PhotographManager.GetCharacterList())
        self.DynamicCharTable:ReloadDataASync(self.CurCharIndex)
    elseif self.CurTableType == DynamicTableType.Fashion then
        self.PanelFashionList.gameObject:SetActiveEx(true)
        self.FashionList = XDataCenter.FashionManager.GetCurrentTimeFashionByCharId(self.CharacterId)
        self.CurFashionIndex = self.CurFashionIndex and self.CurFashionIndex 
                or XDataCenter.PhotographManager.GetFashionIndexByFashionList(self.FashionId, self.FashionList)
        self.DynamicFashionTable:SetDataSource(self.FashionList)
        --动态列表的算法会屏蔽掉应该显示的格子
        self.DynamicFashionTable:ReloadDataASync(self.CurFashionIndex - MAX_FASHION_MEMBER_LINE)
    elseif self.CurTableType == DynamicTableType.Action then
        self.PanelActionList.gameObject:SetActiveEx(true)
        self.ActionList = XMVCA.XFavorability:GetCharacterActionById(self.CharacterId) or {}
        self.DynamicActionTable:SetDataSource(self.ActionList)
        self.DynamicActionTable:ReloadDataASync()
    end
end

function XUiPhotographPortrait:OnDynamicTableEvent(evt, index, grid)
    if self.CurTableType == DynamicTableType.Scene then
        self:OnDynamicSceneTableEvent(evt, index, grid)
    elseif self.CurTableType == DynamicTableType.Character then
        self:OnDynamicCharTableEvent(evt, index, grid)
    elseif self.CurTableType == DynamicTableType.Fashion then
        self:OnDynamicFashionTableEvent(evt, index, grid)
    elseif self.CurTableType == DynamicTableType.Action then
        self:OnDynamicActionTableEvent(evt, index, grid)
    end
end

function XUiPhotographPortrait:OnDynamicSceneTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local sceneId = XDataCenter.PhotographManager.GetSceneIdByIndex(index)
        local data = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
        grid:Reset()
        grid:Refrash(data)
        if self.CurSceneIndex and self.CurSceneIndex == index then
            self.CurSceneGrid = grid
            grid:SetSelect(true)
        end
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local sceneId = XDataCenter.PhotographManager.GetSceneIdByIndex(index)
        local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
        local isHas = XDataCenter.PhotographManager.CheckSceneIsHaveById(sceneId)
        if not isHas then
            XUiManager.TipPortraitMsg(sceneTemplate.LockDec)
            return
        end
        if self.CurSceneIndex and self.CurSceneIndex == index then
            return
        end
        if self.CurSceneGrid ~= nil then
            self.CurSceneGrid:SetSelect(false)
        end
        self.CurSceneGrid = grid
        self.CurSceneIndex = index
        sceneId = XDataCenter.PhotographManager.GetSceneIdByIndex(index)
        local data = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
        XDataCenter.PhotographManager.RemoveNewSceneTempData(sceneId) -- 消除场景蓝点(随机场景界面的)
        grid:OnTouched(data)
        XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnScene, {
            scene_id = sceneId
        })
    end
end

function XUiPhotographPortrait:OnDynamicCharTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = XDataCenter.PhotographManager.GetCharacterDataByIndex(index)
        grid:Reset()
        grid:Refrash(data)
        if self.CurCharIndex and self.CurCharIndex == index then
            self.CurCharGrid = grid
            grid:SetSelect(true)
        end
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurCharIndex and self.CurCharIndex == index then
            return
        end
        if self.CurCharGrid ~= nil then
            self.CurCharGrid:SetSelect(false)
        end
        self.CurCharGrid = grid
        local data = XDataCenter.PhotographManager.GetCharacterDataByIndex(index)
        self:ClearAnimationCache(data.Id)
        self.CharacterId = data.Id
        self.CurCharIndex = index
        self.CurFashionIndex = nil -- 切换角色清空涂装index 再次点击涂装会重新获取index
        grid:OnTouched(self.CharacterId)
        XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnCharacter, {
            character_id = self.CharacterId
        })
    end
end

function XUiPhotographPortrait:OnDynamicFashionTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.FashionList[index], self.CurFashionIndex == index)
        if self.CurFashionIndex and self.CurFashionIndex == index then
            self.CurFashionGrid = grid
            grid:SetSelect(true)
        end
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local fashionId = self.FashionList[index]
        local isHas = XDataCenter.FashionManager.CheckHasFashion(fashionId)
        if not isHas then
            XUiManager.TipPortraitMsg(CS.XTextManager.GetText("PhotoModeNoFashion"))
            return
        end
        local status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
        if status == XDataCenter.FashionManager.FashionStatus.Lock then
            XUiManager.TipPortraitText("FashionNoGet")
            return
        end
        if self.CurFashionIndex and self.CurFashionIndex == index then
            return
        end
        if self.CurFashionGrid ~= nil then
            self.CurFashionGrid:SetSelect(false)
        end
        self.CurFashionGrid = grid
        self.CurFashionIndex = index
        grid:OnTouched(self.CharacterId)
        XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnFashion, {
            fashion_id = fashionId,
            character_id = self.CharacterId
        })
    end
end

function XUiPhotographPortrait:OnDynamicActionTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ActionList[index]
        local charData = XDataCenter.PhotographManager.GetCharacterDataById(self.CharacterId)
        grid:Reset()
        grid:RefrashAction(data, charData)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local tryFashionId = self.FashionId
        local trySceneId = self.CurrSeleSceneId
        local isHas = XMVCA.XFavorability:CheckTryCharacterActionUnlock(self.ActionList[index], XDataCenter.PhotographManager.GetCharacterDataById(self.CharacterId).TrustLv, tryFashionId, trySceneId)
        if not isHas then
            XUiManager.TipPortraitMsg(XMVCA.XFavorability:GetCharacterActionMapText(self.ActionList[index].config.ConditionDescript))
            return
        end
        self:PlayAnimation("PanelActionEnable")
        if self.CurActionGrid ~= nil then
            self.CurActionGrid:SetSelect(false)
            if self.CurActionGrid ~= grid then
                self.SignBoardPlayer:Stop(true, true)
            end
        end
        self.CurActionGrid = grid
        self.ActionCtrlPanel:SetTxtTitle(XMVCA.XFavorability:GetCharacterActionMapText(self.ActionList[index].config.Name))
        grid:OnActionTouched(self.ActionList[index])
        self:SwitchActionPanel(false)
        XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnAction, {
            action_id = self.ActionList[index].config.Id,
            character_id = self.CharacterId
        })
        if XMVCA.XFavorability:CheckCGBoardAct(self.FashionId, self.ActionList[index].config.SignBoardActionId) then
            if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.Android then
                self.CG:PlayCG(1015301) -- 临时处理 安卓播1k视频
            else
                self.CG:PlayCG(10153)  -- ios和pc播2k视频
            end
            self.ShotMode = CGMode
        else
            self.ShotMode = SceneMode
            self.CG:HideCG()
        end
    end
end

--endregion------------------动态列表 finish------------------

function XUiPhotographPortrait:OnUiSceneLoaded()
    self:PlayAnimation("Loading2")
    
    --self:SetGameObject()
    
    local root = self.UiModelGo.transform
    self.CameraFar = self:FindVirtualCamera("CamFarMain")
    self.CameraNear = self:FindVirtualCamera("CamNearMain")
    self.CameraComponentFar = root:FindTransform("UiFarCamera"):GetComponent("Camera")
    self.CameraComponentNear = root:FindTransform("UiNearCamera"):GetComponent("Camera")
    self.UiModelParent = root:FindTransform("UiModelParent")
    self.ChangeActionEffect = root:FindTransform("ChangeActionEffect")
    ---@type XUiPanelRoleModel
    self.RoleModel = XUiPanelRoleModel.New(self.UiModelParent, self.Name, true, false, false, true, nil, nil, true)
    self:UpdateRoleModel(self.CharacterId, self.FashionId)
    
    self.CameraFar.gameObject:SetActiveEx(true)
    self.CameraNear.gameObject:SetActiveEx(true)
    
    self:UpdateBatteryMode()
end

function XUiPhotographPortrait:UpdateScene(sceneId)
    XDataCenter.PhotographManager.SetCurSelectSceneId(sceneId)
    local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
    local scenePath, modelPath = XSceneModelConfigs.GetSceneAndModelPathById(sceneTemplate.SceneModelId)
    self:LoadUiScene(scenePath, modelPath, handler(self, self.OnUiSceneLoaded), false)
    self.CurrSeleSceneId = sceneId

    -- 开启时钟
    self.ClockTimer = XUiHelper.SetClockTimeTempFun(self)
end

function XUiPhotographPortrait:ForcePlay(signBoardActionId, actionId)
    self.SignBoardActionId = signBoardActionId
    self.ActionId = actionId or self.ActionId -- characterAction表的主键
    local config = XMVCA.XFavorability:GetSignBoardConfigById(signBoardActionId)
    local PlayingElement = self.SignBoardPlayer.PlayerData.PlayingElement -- 同步主界面时 PlayingElement会被清掉 下面执行到ForcePlayCross时会被重新创建 所以这里得判空
    if self.SignBoardPlayer:GetInterruptDetection() and PlayingElement and PlayingElement.Id ~= config.Id then
        self:PlayChangeActionEffect()
    end
    self:UpdateAnimation(false)
    self.ActionCtrlPanel:SetBtnPlayState(false)
    XScheduleManager.ScheduleNextFrame(function()
        self.SignBoardPlayer:ForcePlayCross(config)
    end)
    self.SignBoardPlayer:SetInterruptDetection(true)
end

function XUiPhotographPortrait:Play(element)
    if not element then
        return
    end
    if self.ShotMode == SceneMode then
        self:RefreshActionView()
    end
    if element.SignBoardConfig.CvId and element.SignBoardConfig.CvId > 0 then
        if element.CvType then
            self.PlayingCv = XLuaAudioManager.PlayCvWithCvType(element.SignBoardConfig.CvId, element.CvType)
        else
            self.PlayingCv = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, element.SignBoardConfig.CvId)
        end
    end
    local actionId = element.SignBoardConfig.ActionId
    if actionId then
        self.RoleModel:PlayAnima(actionId, true)
        self.RoleModel:LoadCharacterUiEffect(tonumber(element.SignBoardConfig.RoleId), actionId)
    end

    -- 关闭角色头部跟随
    self.RoleModel:SetXPostFaicalControllerActive(false)
end

function XUiPhotographPortrait:PlayCross(element)
    if not element then
        return
    end
    self:RefreshActionView()
    if element.SignBoardConfig.CvId and element.SignBoardConfig.CvId > 0 then
        if element.CvType then
            self.PlayingCv = XLuaAudioManager.PlayCvWithCvType(element.SignBoardConfig.CvId, element.CvType)
        else
            self.PlayingCv = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, element.SignBoardConfig.CvId)
        end
    end
    local actionId = element.SignBoardConfig.ActionId
    if actionId then
        self.RoleModel:PlayAnimaCross(actionId, true)
        self.RoleModel:LoadCharacterUiEffect(tonumber(element.SignBoardConfig.RoleId), actionId)
        self:CheckToLoadPanelCharacterMappingPrefab(actionId)
    end

    -- 关闭角色头部跟随
    self.RoleModel:SetXPostFaicalControllerActive(false)
end

function XUiPhotographPortrait:CheckToLoadPanelCharacterMappingPrefab(actionId)
    local xCharacter = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    if not xCharacter then
        return
    end
    local fashionId = XMVCA.XCharacter:GetShowFashionId(self.CharacterId)
    local pid = string.format("%s%s", fashionId, actionId)
    local targetNodeEffectMappingConfig = XMVCA.XCharacter:GetModelCharacterModelNodeEffectMapping()[pid]
    if not targetNodeEffectMappingConfig then
        return
    end
    self.RoleModel:SetCharacterModelNodeEffectMappingPrefab(targetNodeEffectMappingConfig)
end

function XUiPhotographPortrait:OnStop(playingElement, force)
    if self.PlayingCv then
        self.PlayingCv:Stop()
        self.PlayingCv = nil
    end
    
    if playingElement then
        self.RoleAnimator.speed = 1
        self:ChangeUiEffectAnimationSpeed(1)
        self.RoleModel:StopAnima(playingElement.SignBoardConfig.ActionId, force)
        self.RoleModel:LoadCurrentCharacterDefaultUiEffect()
        self.RoleModel:DisposeCharacterModelNodeEffectMappingPrefab()
    end
    self.SignBoardPlayer:SetInterruptDetection(false)
    if self.ShotMode == SceneMode then
        self:RefreshActionView()
    end

    -- 开启角色头部跟随
    self.RoleModel:SetXPostFaicalControllerActive(true)
end

function XUiPhotographPortrait:ClearAnimationCache(charId)
    if charId ~= self.CharacterId then
        self.SignBoardActionId = nil
    end
end

function XUiPhotographPortrait:PlayChangeActionEffect()
    if self.ChangeActionEffect then
        self.ChangeActionEffect.gameObject:SetActive(false)
        self.ChangeActionEffect.gameObject:SetActive(true)
    end
end

function XUiPhotographPortrait:UpdateAnimation(pause)
    if not self.RoleAnimator then
        return
    end
    local speed
    if pause then
        speed = 0
        self.SignBoardPlayer:Pause()
        if self.PlayingCv then
            self.PlayingCv:Pause()
        end
    else
        speed = 1
        self.SignBoardPlayer:Resume()
        if self.PlayingCv then
            self.PlayingCv:Resume()
        end
    end
    self.RoleAnimator.speed = speed
    self:ChangeUiEffectAnimationSpeed(speed)
    self.CG:ChangeCGState(pause)
end


function XUiPhotographPortrait:ChangeUiEffectAnimationSpeed(speed)
    local roleUiEffectAnimators = self.RoleModel:GetUiEffectAnimators()
    if not XTool.IsTableEmpty(roleUiEffectAnimators) then
        for _, animator in pairs(roleUiEffectAnimators) do
            animator.speed = speed
        end
    end
end

function XUiPhotographPortrait:Replay()
    if not XTool.IsNumberValid(self.SignBoardActionId) then
        return
    end

    local configs = XMVCA.XFavorability:GetCharacterActionById(self.CharacterId)
    local data = nil
    for k, v in pairs(configs) do
        if v.config.Id == self.ActionId then
            data = v
        end
    end
    if XTool.IsTableEmpty(data) then
        return
    end
    local tryFashionId = self.FashionId
    local trySceneId = self.CurrSeleSceneId
    local isHas = XMVCA.XFavorability:CheckTryCharacterActionUnlock(data, XDataCenter.PhotographManager.GetCharacterDataById(self.CharacterId).TrustLv, tryFashionId, trySceneId)
    if not isHas then
        XUiManager.TipError(XMVCA.XFavorability:GetCharacterActionMapText(data.config.ConditionDescript))
        return
    end
    self:UpdateAnimation(false)
    self.SignBoardPlayer:Stop(nil, true)
    self:ForcePlay(self.SignBoardActionId)
    self.CG:ReplayCG()
end

function XUiPhotographPortrait:UpdateRoleModel(charId, fashionId)
    self:ClearAnimationCache(charId)
    self.CharacterId = charId
    self.FashionId = fashionId
    XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModel, charId, nil, fashionId)
    self.RoleAnimator = self.RoleModel:GetAnimator()

    self.RoleModel:SetXPostFaicalControllerActive(true)
end

--region   ------------------点击事件 start-------------------

function XUiPhotographPortrait:OnSelectMenu(index)
    self:PlayAnimation("Qiehuan")
    self.SelectIndex = index
    if index == self.TabBtnIndex.BtnScene then
        XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnScene)
    elseif index == self.TabBtnIndex.BtnCharacter then
        XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnCharacter)
    elseif index == self.TabBtnIndex.BtnFashion then
        XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnFashion)
    end
    self:SetupDynamicTable(index)
end

--编辑
function XUiPhotographPortrait:OnBtnMenuClick()
    if self:IsShowActionPanel() then
        self:SwitchActionPanel(false)
    end
    self:SwitchMenuPanel(true)
    local type = self.SelectIndex and self.SelectIndex or DynamicTableType.Scene
    self.PanelBtn:SelectIndex(type)
end

--动作
function XUiPhotographPortrait:OnBtnActionClick()
    XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnAction)
    if self:IsShowMenuPanel() then
        self:SwitchMenuPanel(false)
    end
    self:SwitchActionPanel(true)
    self:SetupDynamicTable(DynamicTableType.Action)
end

--同步主界面
function XUiPhotographPortrait:OnBtnSynchronousClick()
    if not self:CheckChanged() then
        XUiManager.TipPortraitText("PhotoModeCannotSyncTips")
        return
    end
    XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnSynchronous, {
        character_id = self.CharacterId,
        fashion_id = self.FashionId,
        scene_id = XDataCenter.PhotographManager.GetCurSelectSceneId()
    })
    XDataCenter.PhotographManager.ChangeDisplay(XDataCenter.PhotographManager.GetCurSelectSceneId(), 
            self.CharacterId, self.FashionId, function ()
                self.OldCharacterId = self.CharacterId
                self:RefreshBtnSynchronous() 
                XUiManager.TipPortraitText("PhotoModeChangeSuccess")
    end)
end

--返回
function XUiPhotographPortrait:OnBtnBackClick()
    if self:IsShowMenuPanel() then
        self:SwitchMenuPanel(false)
        return
    end
    if self:IsShowActionPanel() then
        self:SwitchActionPanel(false)
        return
    end
    self:Close()
end

--设置
function XUiPhotographPortrait:OnBtnSetClick()
    XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnSet)
    XLuaUiManager.Open("UiPhotographPortraitSet", self.SetData)
end

--隐藏UI
function XUiPhotographPortrait:OnBtnHideClick()
    XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnHide)
    self:RefreshViewActive(not self.BtnHide:GetToggleState())
end

function XUiPhotographPortrait:OnBtnClick()
    if self:IsShowMenuPanel() then
        self:SwitchMenuPanel(false)
    elseif self:IsShowActionPanel() then
        self:SwitchActionPanel(false)
    elseif self.BtnHide:GetToggleState() then
        self.BtnHide:SetButtonState(CS.UiButtonState.Normal)
        self:OnBtnHideClick()
    end
end

--拍照
function XUiPhotographPortrait:OnBtnPhotographClick()
    XPhotographConfigs.CsRecord(XGlobalVar.BtnPhotograph.BtnUiPhotographPortraitBtnPhotograph, {
        character_id = self.CharacterId,
        fashion_id = self.FashionId,
        scene_id = XDataCenter.PhotographManager.GetCurSelectSceneId()
    })
    -- 将人物渲染到ImgPicture内
    local shotCamera
    self.ShotMode = self.ShotMode or SceneMode
    if self.ShotMode == SceneMode then
        shotCamera = self.CameraComponentNear
        self.CameraCupture.depth = 0
    elseif self.ShotMode == CGMode then
        shotCamera = CS.XUiManager.Instance.UiCamera
        self.PanelPhotograph.gameObject:SetActiveEx(false)
        if self.CG:IsCGPlaying() then
            self.CameraCupture.depth = CS.XUiManager.Instance.UiCamera.depth - 1
        else
            self.CameraCupture.depth = 0
        end
    end
    XCameraHelper.ScreenShotNew(self.ImgPicture, shotCamera, function()
        -- 将最终图案渲染到ImagePhoto中
        XCameraHelper.ScreenShotNew(self.ImagePhoto, self.CameraCupture, function(screenShot)
            CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CS.XUiManager.Instance.UiCamera)
            self.ShareTexture = screenShot
            self.PhotoName = string.format("[%s]_Portrait_%s", tostring(XPlayer.Id), XTime.GetServerNowTimestamp())

            self:PlayAnimation("Shanguang", function()
                if not XTool.UObjIsNil(self.ImgPicture.mainTexture) 
                        and self.ImgPicture.mainTexture ~= "UnityWhite" 
                then
                    CSDestroy(self.ImgPicture.mainTexture)
                end
            end)

            self:PlayAnimation("Photo", function() 
                self.BtnCaptureClose.gameObject:SetActiveEx(true) 
            end, function()
                self.BtnCaptureClose.gameObject:SetActiveEx(false)
                self:SwitchCapturePanel(true)
            end
            )
            if self.ShotMode == CGMode then
                self.PanelPhotograph.gameObject:SetActiveEx(true)
            end
        end, function() CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, self.CameraCupture) end)
    end)
    XDataCenter.PhotographManager.SendPhotoGraphRequest()
end

--endregion------------------点击事件 finish------------------

--region   ------------------界面显隐 start-------------------

function XUiPhotographPortrait:RefreshViewActive(show)
    local animName = show and "UiEnable" or "UiDisable"
    self:PlayAnimation(animName)
    local select = self.BtnHide:GetToggleState()
    show = show and not select
    if not show then
        self:SwitchMenuPanel(show)
        self:SwitchActionPanel(show)
    end
    self.BtnBack.gameObject:SetActiveEx(show)
    self.BtnSet.gameObject:SetActiveEx(show)
    self:RefreshBottom(show)
    self:RefreshBtnSynchronous()
end

function XUiPhotographPortrait:RefreshBottom(show, ctrlPhotograph)
    local select = self.BtnHide:GetToggleState()
    self.BtnAction.gameObject:SetActiveEx(show and not select)
    self.BtnMenu.gameObject:SetActiveEx(show and not select)
    self.Btn.gameObject:SetActiveEx(not show and select)
    if ctrlPhotograph then
        self.BtnPhotograph.gameObject:SetActiveEx(show)
    end
end

function XUiPhotographPortrait:SwitchMenuPanel(show)
    self.PanelMenu.gameObject:SetActiveEx(show)
    self:RefreshBottom(not show, true)
    self:RefreshActionView()
end

function XUiPhotographPortrait:IsShowMenuPanel()
    return self.PanelMenu.gameObject.activeInHierarchy 
end

function XUiPhotographPortrait:SwitchActionPanel(show)
    self.PanelActionView.gameObject:SetActiveEx(show)
    self:RefreshBottom(not show, true)
end

function XUiPhotographPortrait:IsShowActionPanel()
    return self.PanelActionView.gameObject.activeInHierarchy
end

function XUiPhotographPortrait:SwitchCapturePanel(show)
    self.PanelCapture.gameObject:SetActiveEx(show)
    if show then
        self.SDKPanel:Show()
    else
        self.SDKPanel:Hide()
    end
    self:RefreshActionView()
    self.BtnHide.gameObject:SetActiveEx(not show)
    self:RefreshViewActive(not show)
    self.Btn.gameObject:SetActiveEx(not show)
    self.BtnPhotograph.gameObject:SetActiveEx(not show)
end

function XUiPhotographPortrait:IsShowCapturePanel()
    return self.PanelCapture.gameObject.activeInHierarchy
end

function XUiPhotographPortrait:RefreshActionView()
    local showOtherPanel = self:IsShowMenuPanel() or self:IsShowCapturePanel()
    local showPause = (self.SignBoardPlayer.Status == 1 or self.SignBoardPlayer.Status == 3) 
            and not showOtherPanel
    local showReplay = self.SignBoardActionId ~= nil and not showOtherPanel
    self.ActionCtrlPanel:Refresh(showPause, showReplay)
    self.ActionCtrlPanel:SetBtnPlayState(self.SignBoardPlayer.Status == 3)
end

function XUiPhotographPortrait:RefreshBtnSynchronous()
    local changed = self:CheckChanged()
    self.BtnSynchronous.gameObject:SetActiveEx(changed and not self.BtnHide:GetToggleState() and not self:IsShowCapturePanel())
end

function XUiPhotographPortrait:CheckChanged()
    local sceneId = XDataCenter.PhotographManager.GetCurSceneId()
    local selectSceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    if self.CharacterId ~= self.OldCharacterId or sceneId ~= selectSceneId then
        return true
    end
    local fashionId = XMVCA.XCharacter:GetShowFashionId(self.CharacterId)
    return self.FashionId ~= fashionId
end

function XUiPhotographPortrait:InitProportionImage()
    --切换横竖屏后，获取到的宽高不一定正确，会在延后几帧更新
    local width, height = CS.UnityEngine.Screen.width, CS.UnityEngine.Screen.height
    local defaultSize = self.ContainerSize
    local ratio = width / height
    local screenH
    --竖屏以宽度为基准进行等比缩放
    if ratio < 1 then
        screenH = 1 / ratio * defaultSize.x
    else
        screenH = ratio * defaultSize.x
    end
    self.ImageContainer.sizeDelta = Vector2(defaultSize.x, screenH)
    self.ImgPicture.rectTransform.sizeDelta = Vector2(CsXUiManager.RealScreenWidth, CsXUiManager.RealScreenHeight)
    self.SafeAdapter:UpdateSpecialScreenOff()
end

function XUiPhotographPortrait:UpdateBatteryMode()
    if CsXQualityManager.Instance.IsSimulator and not CsXUiBattery.DebugMode then
        return
    end

    local animationRoot = self.UiSceneInfo.Transform:Find("Animations")
    if XTool.UObjIsNil(animationRoot) then return end

    local toChargeTimeLine = animationRoot:Find("ToChargeTimeLine")
    local toFullTimeLine = animationRoot:Find("ToFullTimeLine")
    local fullTimeLine = animationRoot:Find("FullTimeLine")
    local chargeTimeLine = animationRoot:Find("ChargeTimeLine")

    toChargeTimeLine.gameObject:SetActiveEx(false)
    toFullTimeLine.gameObject:SetActiveEx(false)
    fullTimeLine.gameObject:SetActiveEx(false)
    chargeTimeLine.gameObject:SetActiveEx(false)
    
    local curSelectSceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    local particleGroupName = XDataCenter.PhotographManager.GetSceneTemplateById(curSelectSceneId).ParticleGroupName

    local chargeAnimator

    if not string.IsNilOrEmpty(particleGroupName) then
        local chargeAnimatorTrans = self.UiSceneInfo.Transform:FindTransform(particleGroupName)
        if chargeAnimatorTrans then
            chargeAnimator = chargeAnimatorTrans:GetComponent("Animator")
        else
            XLog.Error("Can't Find \"" .. particleGroupName .. "\", Please Check \"ParticleGroupName\" In Share/PhotoMode/Background.tab")
        end
    end

    local type = XPhotographConfigs.GetBackgroundTypeById(curSelectSceneId)
    if type == XPhotographConfigs.BackGroundType.PowerSaved then
        if CsXUiBattery.IsCharging then --充电状态
            if chargeAnimator then chargeAnimator:Play("Full") end
            fullTimeLine.gameObject:SetActiveEx(true)
        else
            if CsXUiBattery.BatteryLevel > LowPowerValue then -- 比较电量
                if chargeAnimator then chargeAnimator:Play("Full") end
                fullTimeLine.gameObject:SetActiveEx(true)
            else
                if chargeAnimator then chargeAnimator:Play("Low") end
                chargeTimeLine.gameObject:SetActiveEx(true)
            end
        end
    else
        local startTime = XTime.ParseToTimestamp(DateStartTime)
        local endTime = XTime.ParseToTimestamp(DateEndTime)
        local nowTime = XTime.ParseToTimestamp(CS.System.DateTime.Now:ToLocalTime():ToString())
        if startTime > nowTime and nowTime > endTime then   -- 比较时间
            if chargeAnimator then chargeAnimator:Play("Full") end
            fullTimeLine.gameObject:SetActiveEx(true)
        else
            if chargeAnimator then chargeAnimator:Play("Low") end
            chargeTimeLine.gameObject:SetActiveEx(true)
        end
    end
end

--endregion------------------界面显隐 finish------------------


-- v1.32 播放角色特殊动作Ui动画
-- ===================================================

-- 播放场景动画
function XUiPhotographPortrait:PlaySceneAnim(element)
    if not element then
        return
    end
    local animRoot = self.UiModelGo.transform
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    local sighBoardId = element.SignBoardConfig.Id
    XMVCA.XFavorability:LoadSceneAnim(animRoot, self.CameraFar, self.CameraNear, sceneId, sighBoardId, self)
    XMVCA.XFavorability:SceneAnimPlay()
end

function XUiPhotographPortrait:PlayRoleActionUiDisableAnim(signBoardid)
    self:SetActionMask(true)
    if XMVCA.XFavorability:CheckCurSceneAnimIsGachaLamiya() then
        self:PlayAnimation("UiDisableLamiya")
    elseif XMVCA.XFavorability:CheckIsUseNormalUiAnim(signBoardid, self.Name) then
        self:PlayAnimation("UiDisable")
    end
end

function XUiPhotographPortrait:PlayRoleActionUiEnableAnim(signBoardid)
    self:SetActionMask(false)
    if XMVCA.XFavorability:CheckCurSceneAnimIsGachaLamiya() then
        self:PlayAnimation("UiEnableLamiya")
    elseif XMVCA.XFavorability:CheckIsUseNormalUiAnim(signBoardid, self.Name) then
        self:PlayAnimationWithMask("UiEnable")
    end
end

function XUiPhotographPortrait:PlayRoleActionUiBreakAnim()
    self:SetActionMask(false)

    if self.CG:IsCGExist() then
        self:OnStop(self.SignBoardPlayer.PlayerData.PlayingElement, true) -- 先结束动作 否则CG结束时有一瞬间能看到动作在切换
        self.CG:StopCG(true, function()
            self.ActionCtrlPanel:Refresh(false, self.SignBoardActionId ~= nil)
            self:PlayRoleActionUiBreakAnimCb(false)
        end)
    else
        self:PlayRoleActionUiBreakAnimCb(true)
    end
end

function XUiPhotographPortrait:PlayRoleActionUiBreakAnimCb(isCheckAnimCross)
    if XMVCA.XFavorability:CheckCurSceneAnimIsGachaLamiya() then
        self:PlayAnimationWithMask("DarkEnableLamiya", function()
            self.SignBoardPlayer:Stop(true, true)
            self:PlayAnimationWithMask("DarkDisableLamiya")
        end)
    else
        if isCheckAnimCross then
            local playingElement = self.SignBoardPlayer.PlayerData.PlayingElement
            if playingElement then
                local actionId = playingElement.SignBoardConfig.ActionId
                local _, animator = self.RoleModel:CheckAnimaCanPlay(actionId)
                local clips = animator:GetCurrentAnimatorClipInfo(0)
                local clip
                if clips and clips.Length > 0 then
                    clip = clips[0].clip
                end
                if clip and clip.name ~= actionId then
                    -- 动作还在过渡中 不能打断
                    self:SetActionMask(true)
                    return
                end
            end
        end
        self:UpdateAnimation(false)
        self.SignBoardPlayer:Stop(nil, true)
    end
end

function XUiPhotographPortrait:SetActionMask(active)
    if self.BtnBreakActionAnim then
        self.BtnBreakActionAnim.gameObject:SetActiveEx(active)
    end
end

---@return XUiPanelRoleModel
function XUiPhotographPortrait:GetRoleModel()
    return self.RoleModel
end

-- ===================================================