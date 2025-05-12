-- 2.6版本重构uicharacter界面
---@class XUiCharacterV2P6 XUiCharacterV2P6
---@field _Control XCharacterControl
local XUiCharacterV2P6 = XLuaUiManager.Register(XLuaUi, "UiCharacterV2P6")
local PanelCharacterOwnedInfoV2P6 = require("XUi/XUiCharacterV2P6/PanelChildUi/XPanelCharacterOwnedInfoV2P6")
local PanelCharacterUnOwnedInfoV2P6 = require("XUi/XUiCharacterV2P6/PanelChildUi/XPanelCharacterUnOwnedInfoV2P6")

function XUiCharacterV2P6:OnAwake()
    self.NewCharRecord = {}
    self.PanelProxyDatas = 
    {
        PanelCharacterOwnedInfoV2P6 = {Proxy = PanelCharacterOwnedInfoV2P6, Ui = "PanelOwned"},
        PanelCharacterUnOwnedInfoV2P6 = {Proxy = PanelCharacterUnOwnedInfoV2P6, Ui = "PanelUnOwned"},
    }

    self:InitButton()
    self:InitFilter()
end

function XUiCharacterV2P6:InitButton()
    self:BindHelpBtn(self.BtnHelp, "Character")
    XUiHelper.RegisterClickEvent(self, self.BtnCollect, self.OnBtnCollectClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTeaching, self.OnBtnTeachingClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFashion, self.OnBtnFashionClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOwnedDetail, self.OnBtnOwnedDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFiles, self.OnBtnFileClick)
    self.PanelDrag:AddPointerDownListener(function ()
        self:OnDragPointerDown()
    end)
end

function XUiCharacterV2P6:InitFilter()
    self.PanelFilter = XMVCA.XCommonCharacterFilter:InitFilter(self.PanelCharacterFilter, self)
    local onSeleCb = function (character, index, grid, isFirstSelect)
        if not character then
            return
        end
        -- 记录角色新标签，默认选的也要消
        self.NewCharRecord[character.Id] = true
        self:OnSelectCharacter(character)

        -- 记录最后一次点击选择的角色和标签
        local curTagName = self.PanelFilter.CurSelectTagBtn.gameObject.name
        XMVCA.XCommonCharacterFilter:RecordLastTag(self.Name, curTagName, character.Id)
    end

    local refreshFun = function (index, grid, char)
        grid:SetData(char)
        grid:UpdateRedPoint()
        grid:UpdateNew()
        grid:UpdateCollect()
        grid:UpdateIconEquipGuide()
        -- grid:AprilFoolShowHandle()
    end

    local onTagClickCb = function (targetBtn)
        local tagName = targetBtn.gameObject.name
        local enumId = XGlobalVar.BtnUiCharacterSystemV2P6[tagName]
        local charId = self.CurCharacter and self.CurCharacter.Id
        XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, enumId, charId)
        XMVCA.XCommonCharacterFilter:RecordLastTag(self.Name, tagName, charId)
    end

    self.PanelFilter:InitData(onSeleCb, onTagClickCb, nil, refreshFun)

    -- 接入折叠功能
    local foldCb = function (isInitFoldState)
        if isInitFoldState then
            self:PlayAnimation("AnimFold")
        else
            self:PlayAnimation("AnimFold1F")
        end
        self.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.CharLeftMove)
        XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnFilterFold, self.CurCharacter and self.CurCharacter.Id)
    end

    local unFoldCb = function (isInitFoldState)
        if isInitFoldState then
            self:PlayAnimation("AnimUnFold")
        else
            self:PlayAnimation("AnimUnFold1F")
        end
        self.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.Main)
        XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnFilterUnFold, self.CurCharacter and self.CurCharacter.Id)
    end
    self.PanelFilter:SetFoldCallback(foldCb, unFoldCb)

    local list = XMVCA.XCharacter:GetCharacterList()
    self.PanelFilter:ImportList(list)
end

function XUiCharacterV2P6:RefresFilter()
    -- 刷新时要重新获取源数据，因为角色data可能从碎片变成xCharacter。要重新获取
    local list = XMVCA.XCharacter:GetCharacterList()
    self.PanelFilter:ImportList(list)
    self.PanelFilter:RefreshList()
    self.PanelFilter:UpdateElementStateByGeneralSkill()
end

function XUiCharacterV2P6:RefreshButtonShow()
    local isOpenTeachingActivity = XDataCenter.FubenNewCharActivityManager.CheckActivityIsOpenByCharacterId(self.CurCharacter.Id)

    self.BtnFiles.gameObject:SetActiveEx(isOpenTeachingActivity)
    self.BtnTeaching.gameObject:SetActiveEx(false)
    self.BtnOwnedDetail.gameObject:SetActiveEx(not isOpenTeachingActivity)
end

function XUiCharacterV2P6:OnEnable()
    self.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.Main)
    -- 重复刷新资源栏、因为进化界面会更改资源栏
    self.ParentUi:SetPanelAsset(XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.PanelFilter:InitFoldState()

    -- 同步其他子界面切换的角色
    local syncChar = self.ParentUi.CurCharacter
    local syncTag = self.ParentUi.CurSyncTagName
    local initCharId = self.ParentUi.InitCharId

    -- 只有第二次进入enbale才需要同步标签和角色，刷新角色信息。 因为第一次在init时刷新了
    -- self.PanelFilter:DoSelectTag(XEnumConst.Filter.TagName.BtnAll, true, syncChar and syncChar.Id)
    -- if initCharId and not self.IsEnableFin then
    --     self.PanelFilter:DoSelectCharacter(initCharId)
    -- end
    
    -- 跳转进入不触发自动选择缓存内容，默认选中全选即可
    if initCharId and not self.IsEnableFin then
        self.PanelFilter:DoSelectTag(XEnumConst.Filter.TagName.BtnAll, true, initCharId)
    else
        -- 没有记录的角色就默认同步其他界面的角色
        local recordData = XMVCA.XCommonCharacterFilter:GetRecordLastTag(self.Name)
        if self.SyncCharTrigger then
            -- 有同步信息
            self.SyncCharTrigger = nil
            self.PanelFilter:DoSelectTag(syncTag or XEnumConst.Filter.TagName.BtnAll, true, syncChar and syncChar.Id)
        elseif recordData then
            -- 有数据记录
            
            -- 就算红点按钮消失也无需处理，因为筛选器内部会自己处理【选择无法使用的的标签的逻辑】
            self.PanelFilter:DoSelectTag(recordData.TagName, true, recordData.CharacterId)
        else
            -- 默认
            self.PanelFilter:DoSelectTag(XEnumConst.Filter.TagName.BtnAll, true, syncChar and syncChar.Id)
        end
    end

    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_SYN, self.RefresFilter, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_FIRST_GET, self.RefresFilter, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_CHARACTER_EQUIP_CHANGE, self.RefreshRightInfo, self) -- 穿、卸装备意识
    
    self.IsEnableFin = true
end

function XUiCharacterV2P6:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_SYN, self.RefresFilter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_FIRST_GET, self.RefresFilter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_CHARACTER_EQUIP_CHANGE, self.RefreshRightInfo, self)
end

function XUiCharacterV2P6:OnDestroy()
    local allRecordClickedNewCharList = {}
    for charId, v in pairs(self.NewCharRecord) do
        if XMVCA.XCharacter:IsOwnCharacter(charId) and XTool.IsNumberValid(XMVCA.XCharacter:GetCharacter(charId).NewFlag)then
            table.insert(allRecordClickedNewCharList, charId)
        end
    end

    if XTool.IsTableEmpty(allRecordClickedNewCharList) then
        return
    end

    -- 取消新标签
    self._Control:CharacterResetNewFlagRequest(allRecordClickedNewCharList)
end

-- 只有角色Id进行切换时该方法才会被调用
function XUiCharacterV2P6:OnSelectCharacter(character)
    if self.NextNotRefreshCharInfoTrigger then
        self.NextNotRefreshCharInfoTrigger = false
        return
    end

    if not character then
        return
    end
    self.CurCharacter = character
    local tagName = self.PanelFilter:GetCurSelectTagName()
    self.ParentUi:SetCurCharacter(character, tagName)
    XMVCA.XCharacter:RecordUiCharacterV2P6LastTag(tagName)

    local cb = function(model)
        self.PanelDrag.Target = model.transform
    end

    -- 愚人节模型处理
    local isAprilHide = XMVCA.XAprilFoolDay:IsMainCharacterHide(character.Id)
    self.ParentUi:SetRoleModelPanelActive(not isAprilHide)
    local isSubShowCharId = XMVCA.XAprilFoolDay:GetCharIsSubCharacterShow(character.Id)
    if isSubShowCharId then
        self.ParentUi:RefreshRoleModel2(isSubShowCharId)
    end
    self.ParentUi:SetRoleModelPanel2Active(XTool.IsNumberValid(isSubShowCharId))
    -- 愚人节模型处理 结束

    self.ParentUi:RefreshRoleModel(cb)
    local isFragment = XMVCA.XCharacter:CheckIsFragment(self.CurCharacter.Id)
    local isFunctionOpen = XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Character, nil, true)
    self.BtnCollect.gameObject:SetActiveEx(not isFragment and isFunctionOpen)
    local collectState = character.CollectState and true or false
    self.BtnCollect:SetDisable(collectState)
    self:RefreshRightInfo()

    -- 刷新涂装等蓝点
    local isFashionRed = XDataCenter.FashionManager.GetCurrCharHaveNewFashion(character.Id)
    local isWeaponFashionRed = XDataCenter.WeaponFashionManager.GetCurrCharHaveNewWeaponFashion(character.Id)
    local isHeadPortraitRed = XDataCenter.FashionManager.GetCurrCharHaveNewHeadPortrait(character.Id)
    local isRed = isFashionRed or isWeaponFashionRed or isHeadPortraitRed
    self.BtnFashion:ShowReddot(isRed)
    
    self:RefreshButtonShow()
end

function XUiCharacterV2P6:CheckPanelExsit(panelName)
    if not self[panelName] then
        return false
    end
    return true
end

function XUiCharacterV2P6:GetCharPanel(panelName)
    if not self[panelName] then
        local data = self.PanelProxyDatas[panelName]
        local proxy = data.Proxy
        self[panelName] = proxy.New(self[data.Ui], self)
    end
    return self[panelName]
end

-- 角色切换、onenbale刷新都会调用
function XUiCharacterV2P6:RefreshRightInfo()
    local isFragment = XMVCA.XCharacter:CheckIsFragment(self.CurCharacter.Id)
    if isFragment then
        self:GetCharPanel("PanelCharacterUnOwnedInfoV2P6"):Open()
        self:GetCharPanel("PanelCharacterUnOwnedInfoV2P6"):RefreshUiShow()
        if self:CheckPanelExsit("PanelCharacterOwnedInfoV2P6") then
            self:GetCharPanel("PanelCharacterOwnedInfoV2P6"):Close()
        end
    else
        self:GetCharPanel("PanelCharacterOwnedInfoV2P6"):Open()
        self:GetCharPanel("PanelCharacterOwnedInfoV2P6"):RefreshUiShow()
        if self:CheckPanelExsit("PanelCharacterUnOwnedInfoV2P6") then
            self:GetCharPanel("PanelCharacterUnOwnedInfoV2P6"):Close()
        end
    end
end

-- 其他界面的筛选器同步信息
function XUiCharacterV2P6:SetSyncCharFlag()
    self.SyncCharTrigger = true
end

function XUiCharacterV2P6:OnBtnCollectClick()
    if self.CollectLock then
        return
    end

    self.CollectLock = true

    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Character) then
        return
    end

    local character = XMVCA.XCharacter:GetCharacter(self.CurCharacter.Id)
    if not character then
        return
    end
    local targetState = nil
    if character.CollectState then
        targetState = false
    else
        targetState = true
        XUiHelper.PlayAllChildParticleSystem(self.BtnCollect.TagObj.transform)
    end
    self.PanelFilter:SetForceSeleCbTrigger()
    self._Control:CharacterSetCollectStateRequest(character.Id, targetState, function ()
        self.CollectLock = false

        if not targetState then
            return
        end
        local grid = self.PanelFilter:GetGridByCharId(character.Id)
        if not grid then
            return
        end

        grid:PlayPanelCollectEffect()
    end)

    XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnCollect, self.CurCharacter.Id)
end

function XUiCharacterV2P6:OnBtnTeachingClick()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnTeaching, self.CurCharacter.Id)
    XDataCenter.PracticeManager.OpenUiFubenPractice(self.CurCharacter.Id)
end

function XUiCharacterV2P6:OnBtnFashionClick()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnFashion, self.CurCharacter.Id)
    XLuaUiManager.Open("UiFashion", self.CurCharacter.Id)
end

function XUiCharacterV2P6:OnBtnOwnedDetailClick()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnOwnedDetail, self.CurCharacter.Id)
    XLuaUiManager.Open("UiCharacterDetail", self.CurCharacter.Id)
end

function XUiCharacterV2P6:OnBtnFileClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewCharAct) then
        if XDataCenter.FubenNewCharActivityManager.CheckActivityIsOpenByCharacterId(self.CurCharacter.Id) then
            local actId = XFubenNewCharConfig.GetActivityIdByCharacterId(self.CurCharacter.Id)
            if XTool.IsNumberValid(actId) then
                XDataCenter.FubenNewCharActivityManager.SkipToActivityMain(actId)
            else
                XLog.Error('角色:'..tostring(self.CurCharacter.Id)..' 对应的活动Id无效:'..tostring(actId))
            end
        end
    end
end

function XUiCharacterV2P6:OnDragPointerDown()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, XGlobalVar.BtnUiCharacterSystemV2P6.CharacterPanelDrag, self.CurCharacter.Id)
end

return XUiCharacterV2P6
