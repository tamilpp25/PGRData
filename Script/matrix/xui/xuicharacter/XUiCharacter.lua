local XUiGridCharacterNew = require("XUi/XUiCharacter/XUiGridCharacterNew")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")

local CSXTextManagerGetText = CS.XTextManager.GetText

local CAMERA_NUM = 6
local TabBtnIndex = {
    Normal = 1,
    Isomer = 2,
}
local CharacterTypeConvert = {
    [TabBtnIndex.Normal] = XCharacterConfigs.CharacterType.Normal,
    [TabBtnIndex.Isomer] = XCharacterConfigs.CharacterType.Isomer,
}
local LastSelectTabBtnIndex

local XUiCharacter = XLuaUiManager.Register(XLuaUi, "UiCharacter")

function XUiCharacter:OnAwake()
    self:InitDynamicTable()
    self:AutoAddListener()
    self.FiltSortListTypeDic = {} --记录筛选排序缓存列表(根据独域和泛用机体类型储存)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.GridCharacterNew.gameObject:SetActiveEx(false)
    self.PanelTeamBtn.gameObject:SetActiveEx(false)

    self.LogoCharacterGouzaoti.gameObject:SetActiveEx(false)
    self.LogoCharacterShougezhe.gameObject:SetActiveEx(false)

    local tempGo = self.Transform:Find("SafeAreaContentPane/BtnLensOut")
    if not XTool.UObjIsNil(tempGo) then
        tempGo.gameObject:SetActiveEx(false)
    end
    self.OnUiSceneLoadedCB = function(lastSceneUrl) self:OnUiSceneLoaded(lastSceneUrl) end

    XDataCenter.RoomCharFilterTipsManager.Reset()   -- 旧筛选器的清除也加上，有些界面的旧筛选器还没有替换成新的
    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据

    self:SetBtnTeachingActive(true)
    self:SetBtnFashionActive(true)
    if XUiManager.IsHideFunc then
        self.BthPaixu.gameObject:SetActiveEx(false)
        self.BtnShaixuan.gameObject:SetActiveEx(false)
        self.BtnSort.gameObject:SetActiveEx(false)
    end
end

function XUiCharacter:OnStart(characterId, _, openFromTeamInfo, forbidGotoEquip, skipToProperty, isSupport, supportData, propertyIndex)
    self:InitSceneRoot()

    if openFromTeamInfo then
        self.TeamCharIdMap = openFromTeamInfo.TeamCharIdMap
        self.TeamSelectPos = openFromTeamInfo.TeamSelectPos
        self.TeamResultCb = openFromTeamInfo.TeamResultCb
    end

    if forbidGotoEquip then
        self.BtnOwnedDetail.gameObject:SetActiveEx(false)
        self:SetBtnFashionActive(false)
        self.ForbidGotoEquip = true
    end

    if isSupport then
        self.BtnOwnedDetail.gameObject:SetActiveEx(false)
        self:SetBtnFashionActive(false)
        self.IsSupport = true
    end

    if not XTool.IsTableEmpty(supportData) then
        self.BtnShaixuan.gameObject:SetActiveEx(false)
        self.BtnShengxu.gameObject:SetActiveEx(false)
        self.BtnJiangxu.gameObject:SetActiveEx(false)
    end

    self.SkipToProperty = skipToProperty
    self.SupportData = supportData
    self.PropertyIndex = propertyIndex

    if characterId then
        self.CharacterId = characterId
        local isIsomer = XCharacterConfigs.IsIsomer(characterId)
        --如果从外部打开界面，LastSelectIsomerCharacterId与LastSelectNormalCharacterId未能赋值，会拿到默认的（显示在列表第一的）角色ID
        if isIsomer then
            self.LastSelectIsomerCharacterId = characterId
            self.SelectTabBtnIndex = TabBtnIndex.Isomer
        else
            self.LastSelectNormalCharacterId = characterId
            self.SelectTabBtnIndex = TabBtnIndex.Normal
        end
        -- self.SelectTabBtnIndex = XCharacterConfigs.IsIsomer(characterId) and TabBtnIndex.Isomer or TabBtnIndex.Normal
    else
        -- 切换账号后不满足感染体解锁条件将上次记录强转成构造体
        if LastSelectTabBtnIndex and LastSelectTabBtnIndex == TabBtnIndex.Isomer then
            if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
            or XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Isomer) then
                LastSelectTabBtnIndex = TabBtnIndex.Normal
            end
        end

        self.SelectTabBtnIndex = LastSelectTabBtnIndex or TabBtnIndex.Normal
    end

    self.IsAscendOrder = false   --初始降序
    self:CheckBtnFilterActive()

    self.BtnTabShougezhe.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Isomer))
    self.BtnTabShougezhe:SetDisable(not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer))
    local tabBtns = { self.BtnTabGouzaoti, self.BtnTabShougezhe }
    self.PanelCharacterTypeBtns:Init(tabBtns, function(index) self:OnSelectCharacterType(index) end)
    self.LastChacaterFashionSceneUrl = nil

    self.ReddotGouzaoti = XRedPointManager.AddRedPointEvent(self.BtnTabGouzaoti, self.CheckGouzaoti, self, { XRedPointConditions.Types.CONDITION_CHARACTER_TYPE }, XCharacterConfigs.CharacterType.Normal)
    self.ReddotShougezhe = XRedPointManager.AddRedPointEvent(self.BtnTabShougezhe, self.CheckShougezhe, self, { XRedPointConditions.Types.CONDITION_CHARACTER_TYPE }, XCharacterConfigs.CharacterType.Isomer)
end

function XUiCharacter:CheckGouzaoti(count)
    self.BtnTabGouzaoti:ShowReddot(count >= 0)
end

function XUiCharacter:CheckShougezhe(count)
    self.BtnTabShougezhe:ShowReddot(count >= 0 and XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer))
end

function XUiCharacter:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    -- 父UI的OnEnable中无法正确检测子UI的打开关闭状态，故需自己维护一个变量
    if not self.ChildOpen then
        self.PanelCharacterTypeBtns:SelectIndex(self.SelectTabBtnIndex)
    else
        self:UpdateCurCharacterInfo(self.CharacterId)
    end
    if self.ReddotGouzaoti then
        XRedPointManager.Check(self.ReddotGouzaoti)
    end
    if self.ReddotShougezhe then
        XRedPointManager.Check(self.ReddotShougezhe)
    end
end

function XUiCharacter:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiCharacter:OnDestroy()
    LastSelectTabBtnIndex = self.SelectTabBtnIndex
    -- XDataCenter.RoomCharFilterTipsManager.Reset()
    self.FiltSortListTypeDic = nil
    XDataCenter.CommonCharacterFiltManager.ClearCacheData() --清除筛选缓存数据
    --界面销毁如果有正在播放的角色语音，则停止播放
    XDataCenter.FavorabilityManager.StopCv()

    if self.CuteRandomController then
        self.CuteRandomController:Stop()
    end
end

function XUiCharacter:OnGetEvents()
    return { XEventId.EVENT_CHARACTER_SYN }
end

function XUiCharacter:OnNotify(evt, ...)
    local args = { ... }
    local characterId = args[1]

    if evt == XEventId.EVENT_CHARACTER_SYN then
        self:UpdateCharacterList(characterId)
    end
end

function XUiCharacter:InitSceneRoot()
    local root = self.UiModelGo.transform

    -- if self.PanelRoleModel then
    --     self.PanelRoleModel:DestroyChildren()
    -- end
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectLogoGouzao = root:FindTransform("ImgEffectLogoGouzao")
    self.ImgEffectLogoGanran = root:FindTransform("ImgEffectLogoGanran")
    self.CameraFar = {
        root:FindTransform("UiCamFarLv"),
        root:FindTransform("UiCamFarGrade"),
        root:FindTransform("UiCamFarQuality"),
        root:FindTransform("UiCamFarSkill"),
        root:FindTransform("UiCamFarrExchange"),
        root:FindTransform("UiCamFarEnhanceSkill"),
    }
    self.CameraNear = {
        root:FindTransform("UiCamNearLv"),
        root:FindTransform("UiCamNearGrade"),
        root:FindTransform("UiCamNearQuality"),
        root:FindTransform("UiCamNearSkill"),
        root:FindTransform("UiCamNearrExchange"),
        root:FindTransform("UiCamNearEnhanceSkill"),
    }
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
    self.CuteRandomController = XSpecialTrainActionRandom.New()
end

function XUiCharacter:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGridCharacterNew)
    self.DynamicTable:SetDelegate(self)
end

-- doNotSort 默认不传，传true 则不会排序再刷新
function XUiCharacter:OnSelectCharacterType(index, doNotSort)
    if index == TabBtnIndex.Isomer and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then
        return
    end

    self.SelectTabBtnIndex = index
    if index == TabBtnIndex.Normal then
        self.ImgEffectLogoGouzao.gameObject:SetActiveEx(true)
        self.ImgEffectLogoGanran.gameObject:SetActiveEx(false)
        self:UpdateCharacterList(self.LastSelectNormalCharacterId, doNotSort)
    elseif index == TabBtnIndex.Isomer then
        self.ImgEffectLogoGouzao.gameObject:SetActiveEx(false)
        self.ImgEffectLogoGanran.gameObject:SetActiveEx(true)
        self:UpdateCharacterList(self.LastSelectIsomerCharacterId, doNotSort)
    end
end

function XUiCharacter:UpdateCharacterList(characterId, doNotSort)
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    if characterId then
        --选中角色与当前类型页签不符时，强制选中对应角色类型页签
        self.CharacterId = characterId
        local paramCharacterType = XMVCA.XCharacter:GetCharacterType(characterId)
        if paramCharacterType ~= characterType then
            if XCharacterConfigs.IsIsomer(characterId) then
                self.LastSelectIsomerCharacterId = characterId
                self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndex.Isomer)
            else
                self.LastSelectNormalCharacterId = characterId
                self.PanelCharacterTypeBtns:SelectIndex(TabBtnIndex.Normal)
            end
            return
        end
    end

    local index = 1
    local characterList = self.FiltSortListTypeDic[characterType] or
    (self.SupportData and self.SupportData.GetCharacters and self.SupportData.GetCharacters(characterType) or
    XDataCenter.CharacterManager.GetCharacterList(characterType, false, self.IsAscendOrder, true)) 

    -- 排序器回调后 这里不再排序(拿到列表后 在更新前进行一次排序)
    if not doNotSort then
        local selectTagType = XDataCenter.CommonCharacterFiltManager.GetSortData(characterType)
        characterList = XDataCenter.CommonCharacterFiltManager.DoSort(characterList, selectTagType, self.IsAscendOrder) 
    end

    local isSetCharacterId = true
    if characterId then
        for k, v in pairs(characterList) do
            if v.Id == characterId then
                index = k
                isSetCharacterId = false
                break
            end
        end
    else
        characterId = characterList[1].Id
    end
    if isSetCharacterId then
        characterId = characterList[1].Id
        self.CharacterId = characterId
    end

    if self.SelectTabBtnIndex == TabBtnIndex.Normal then
        self.LastSelectNormalCharacterId = characterId
    elseif self.SelectTabBtnIndex == TabBtnIndex.Isomer then
        self.LastSelectIsomerCharacterId = characterId
    end

    self:UpdateCurCharacterInfo(characterId)

  

    self.CharacterList = characterList
    self.InTeamCheckTable = XDataCenter.TeamManager.GetInTeamCheckTable()
    self.DynamicTable:SetDataSource(characterList)
    self.DynamicTable:ReloadDataASync(index)
end

function XUiCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.CharacterList[index]
        grid:Reset()
        grid:UpdateGrid(data)
        grid:SetInTeam(self.InTeamCheckTable[data.Id] ~= nil)
        grid:UpdateSupport(self.SupportData)
        if self.CharacterId == data.Id then
            self.CurSelectGrid = grid
        end
        grid:SetSelect(self.CharacterId == data.Id)

        if self.SupportData then
            grid:HideRedPoint()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local characterId = self.CharacterList[index].Id
        if XMVCA.XCharacter:IsCharacterForeShow(characterId) then
            if self.CharacterId ~= characterId then
                if self.CurSelectGrid then
                    self.CurSelectGrid:SetSelect(false)
                end
                grid:SetSelect(true)
                self.CurSelectGrid = grid
                self:UpdateCurCharacterInfo(characterId)
            end
        else
            XUiManager.TipMsg(CSXTextManagerGetText("ComingSoon"), XUiManager.UiTipType.Tip)
        end
    end
end

function XUiCharacter:UpdateCurCharacterInfo(characterId)
    self.CharacterId = characterId

    if XCharacterConfigs.IsIsomer(characterId) then
        self.LastSelectIsomerCharacterId = characterId
    else
        self.LastSelectNormalCharacterId = characterId
    end

    self:UpdateSceneAndModel()

    if self.SkipToProperty and not self.ChildOpen then
        self:OpenOneChildUi("UiPanelCharProperty", self, self.PropertyIndex)
        self.ChildOpen = true
        self.SkipToProperty = false
        self.PropertyIndex = nil
        return
    end

    if not self.ChildOpen then
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(characterId)
        if isOwn then
            local childUi = self:FindChildUiObj("UiCharacterOwnedInfo")
            childUi:PreSetCharacterId(characterId)
            if not XLuaUiManager.IsUiShow("UiCharacterOwnedInfo") then
                self:OpenOneChildUi("UiCharacterOwnedInfo", self.ForbidGotoEquip, function()
                    self:OpenOneChildUi("UiPanelCharProperty", self)
                    self.ChildOpen = true
                end, self.IsSupport, self.SupportData, self)
            else
                childUi:UpdateView(characterId)
                childUi:PlayAnimation("AnimEnable")
            end
        else
            local childUi = self:FindChildUiObj("UiCharacterUnOwnedInfo")
            childUi:PreSetCharacterId(characterId)
            if not XLuaUiManager.IsUiShow("UiCharacterUnOwnedInfo") then
                self:OpenOneChildUi("UiCharacterUnOwnedInfo", characterId)
            else
                childUi:UpdateView(characterId)
                childUi:PlayAnimation("AnimEnable")
            end
        end
    end

    if self.TeamCharIdMap then
        self:UpdateTeamBtn()
    end
end

function XUiCharacter:UpdateCamera(index)
    self.CurCameraIndex = index
    for i = 1, CAMERA_NUM do
        if self.CurCameraIndex ~= i then
            self.CameraFar[i].gameObject:SetActiveEx(false)
            self.CameraNear[i].gameObject:SetActiveEx(false)
        end
    end

    if self.CameraFar[self.CurCameraIndex] then
        self.CameraFar[self.CurCameraIndex].gameObject:SetActiveEx(true)
    end
    if self.CameraNear[self.CurCameraIndex] then
        self.CameraNear[self.CurCameraIndex].gameObject:SetActiveEx(true)
    end
end

function XUiCharacter:LoadModelScene()
    local sceneUrl = self:GetSceneUrl()
    local modelUrl = self:GetDefaultUiModelUrl()
    self:LoadUiScene(sceneUrl, modelUrl, self.OnUiSceneLoadedCB, false)
end

function XUiCharacter:GetSceneUrl()
    local sceneUrl = XDataCenter.CharacterManager.GetCharShowFashionSceneUrl(self.CharacterId)
    if sceneUrl and sceneUrl ~= "" then
        return sceneUrl
    else
        return self:GetDefaultSceneUrl()
    end
end

function XUiCharacter:OnUiSceneLoaded(lastSceneUrl)
    if lastSceneUrl ~= self.LastChacaterFashionSceneUrl then
        --self:SetGameObject()
        self:InitSceneRoot()
        self.LastChacaterFashionSceneUrl = lastSceneUrl
    end
end

function XUiCharacter:UpdateSceneAndModel()
    self:LoadModelScene()
    self:UpdateRoleModel()
end

--更新模型
function XUiCharacter:UpdateRoleModel()
    if self.CuteRandomController then
        self.CuteRandomController:Stop()
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)

    -- 愚人节检测
    if XDataCenter.AprilFoolDayManager.IsInCuteModelTime() and XCharacterCuteConfig.CheckHasCuteModel(self.CharacterId) then
        self.RoleModelPanel:UpdateCuteModel(nil, self.CharacterId, nil, nil, nil, nil, true, nil, self.Name)
        
        self.CuteRandomController:SetAnimator(self.RoleModelPanel:GetAnimator(), {}, self.RoleModelPanel)
        self.CuteRandomController:Play()
    else
        self.RoleModelPanel:UpdateCharacterModel(self.CharacterId, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiCharacter, function(model)
            self.PanelDrag.Target = model.transform
            if self.SelectTabBtnIndex == TabBtnIndex.Normal then
                self.ImgEffectHuanren.gameObject:SetActiveEx(true)
            elseif self.SelectTabBtnIndex == TabBtnIndex.Isomer then
                self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
            end
        end)

    end
end

function XUiCharacter:UpdateTeamBtn()
    if not next(self.TeamCharIdMap) then
        return
    end

    local isInTeam = false
    local characterId = self.CharacterId
    for _, v in pairs(self.TeamCharIdMap) do
        if characterId == v then
            isInTeam = true
            break
        end
    end
    self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInTeam)
    self.ImgEnjoinTeam.gameObject:SetActiveEx(false)
end

function XUiCharacter:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, "Character")
    self:RegisterClickEvent(self.BtnJoinTeam, self.OnBtnJoinTeamClick)
    self:RegisterClickEvent(self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    self:RegisterClickEvent(self.BtnFashion, self.OnBtnFashionClick)
    self:RegisterClickEvent(self.BtnOwnedDetail, self.OnBtnOwnedDetailClick)
    self:RegisterClickEvent(self.BtnShaixuan, self.OnBtnShaixuanClick)
    self:RegisterClickEvent(self.BtnSort, self.OnBtnSortClick)
    self:RegisterClickEvent(self.BtnShengxu, self.OnBtnOrderClick)
    self:RegisterClickEvent(self.BtnJiangxu, self.OnBtnOrderClick)
    self:RegisterClickEvent(self.BtnTeaching, self.OnBtnTeachingClick)
end

function XUiCharacter:OnBtnBackClick()
    if XLuaUiManager.IsUiShow("UiPanelCharacterExchange") then
        self:CloseChildUi("UiPanelCharacterExchange")
        return
    end

    if XLuaUiManager.IsUiShow("UiPanelCharProperty") then
        local propertyChildUi = self:FindChildUiObj("UiPanelCharProperty")
        if not propertyChildUi:RecoveryPanel() then
            self:CloseChildUi("UiPanelCharProperty")
            self.ChildOpen = false
            self:UpdateCharacterList(self.CharacterId)
            self:UpdateCamera(XCharacterConfigs.XUiCharacter_Camera.MAIN)
        end
        return
    end

    self:Close()
end

function XUiCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiCharacter:OnBtnJoinTeamClick()
    local id = self.CharacterId
    for k, v in pairs(self.TeamCharIdMap) do
        if v == id then
            self.TeamCharIdMap[k] = 0
            break
        end
    end

    self.TeamCharIdMap[self.TeamSelectPos] = id
    if self.TeamResultCb then
        self.TeamResultCb(self.TeamCharIdMap)
    end

    self:Close()
end

function XUiCharacter:OnBtnQuitTeamClick()
    local count = 0
    for _, v in pairs(self.TeamCharIdMap) do
        if v > 0 then
            count = count + 1
        end
    end

    local id = self.CharacterId
    for k, v in pairs(self.TeamCharIdMap) do
        if v == id then
            self.TeamCharIdMap[k] = 0
            break
        end
    end

    if self.TeamResultCb then
        self.TeamResultCb(self.TeamCharIdMap)
    end

    self:Close()
end

function XUiCharacter:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self.CharacterId)
end

function XUiCharacter:OnBtnOwnedDetailClick()
    XLuaUiManager.Open("UiCharacterDetail", self.CharacterId)
end

-- 筛选要用导入该界面的源列表，排序要用当前界面的展示列表(self.CharacterList)
function XUiCharacter:OnBtnShaixuanClick()
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    -- XLuaUiManager.Open("UiRoomCharacterFilterTips",
    -- self,
    -- XRoomCharFilterTipsConfigs.EnumFilterType.Common,
    -- XRoomCharFilterTipsConfigs.EnumSortType.Common,
    -- characterType)
    
    -- 打开筛选器(v1.30新筛选器)
    local characterList = self.SupportData and self.SupportData.GetCharacters and self.SupportData.GetCharacters(characterType) or
    XDataCenter.CharacterManager.GetCharacterList(characterType, false, self.IsAscendOrder, true)

    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", characterList, characterType, function (afterFiltList)
        self.FiltSortListTypeDic[characterType] = afterFiltList
        self:OnSelectCharacterType(self.SelectTabBtnIndex)
    end, characterType)
end

-- 排序
function XUiCharacter:OnBtnSortClick()
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]

    XLuaUiManager.Open("UiCommonCharacterFilterTipsSort", self.CharacterList, characterType, self.IsAscendOrder, function (afterSortList)
        self.FiltSortListTypeDic[characterType] = afterSortList -- 这里本可不记录，但是拆开了和 UpdateCharacterList 里的排序，所以要把这里的值传给 UpdateCharacterList 方法刷新列表
        self:OnSelectCharacterType(self.SelectTabBtnIndex, true) -- 这边已经排序过一次了，所以刷新就不排了
    end)
end

function XUiCharacter:OpenChangeCharacterView()
    self:OpenOneChildUi("UiPanelCharacterExchange", self, function(characterId)
        self:UpdateCharacterList(characterId)
        self:OpenOneChildUi("UiPanelCharProperty", self)
        self.ChildOpen = true
    end)

    self:UpdateCamera(XCharacterConfigs.XUiCharacter_Camera.EXCHANGE)
    self.SViewCharacterList.gameObject:SetActiveEx(false)
    self.PanelCharacterTypeBtns.gameObject:SetActiveEx(false)
    self:SetBtnFashionActive(false)
    self.BtnOwnedDetail.gameObject:SetActiveEx(false)
    self:SetBtnTeachingActive(false)
end

function XUiCharacter:Filter(selectTagGroupDic, sortTagId, isThereFilterData)
    local characterType = CharacterTypeConvert[self.SelectTabBtnIndex]
    local characterList = XDataCenter.CharacterManager.GetCharacterList(characterType, true, nil, true)
    if isThereFilterData and isThereFilterData(characterList) then
        self:OnSelectCharacterType(self.SelectTabBtnIndex)
    end
end

function XUiCharacter:OnBtnOrderClick()
    self.IsAscendOrder = not self.IsAscendOrder
    self:CheckBtnFilterActive()
    self:OnSelectCharacterType(self.SelectTabBtnIndex)
end

function XUiCharacter:OnBtnTeachingClick()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self.CharacterId)
end

function XUiCharacter:CheckBtnFilterActive()
    if not XTool.IsTableEmpty(self.SupportData) then return end

    self.BtnShengxu.gameObject:SetActiveEx(self.IsAscendOrder)
    self.BtnJiangxu.gameObject:SetActiveEx(not self.IsAscendOrder)
end

function XUiCharacter:SetBtnTeachingActive(isActive)
    if XUiManager.IsHideFunc then
        isActive = false
    end
    self.BtnTeaching.gameObject:SetActiveEx(isActive)
end

function XUiCharacter:SetBtnFashionActive(isActive)
    if XUiManager.IsHideFunc then
        isActive = false
    end
    self.BtnFashion.gameObject:SetActiveEx(isActive)
end

--===========================================================================
--v1.28【角色】升阶拆分 - 打开品质预览
--===========================================================================
function XUiCharacter:OpenQualityPreview(characterId, star)
    if not XLuaUiManager.IsUiShow("UiPanelQualityPreview")then
        self:OpenChildUi("UiPanelQualityPreview", self, characterId)
        self.ChildUiPanelQualityPreview:UpdateDynamicTableData(characterId, star)
        -- 层级调整,避免特效残留和点击穿透
        self.ChildUiPanelQualityPreview.Ui:SetCanvasOrder(999)
    end
end