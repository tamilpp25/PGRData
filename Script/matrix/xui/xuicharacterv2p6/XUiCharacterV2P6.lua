-- 2.6版本重构uicharacter界面
---@class XUiCharacterV2P6 XUiCharacterV2P6
---@field _Control XCharacterControl
local XUiCharacterV2P6 = XLuaUiManager.Register(XLuaUi, "UiCharacterV2P6")
local PanelCharacterOwnedInfoV2P6 = require("XUi/XUiCharacterV2P6/PanelChildUi/XPanelCharacterOwnedInfoV2P6")
local PanelCharacterUnOwnedInfoV2P6 = require("XUi/XUiCharacterV2P6/PanelChildUi/XPanelCharacterUnOwnedInfoV2P6")

function XUiCharacterV2P6:OnAwake()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    ag = XMVCA:GetAgency(ModuleId.XCommonCharacterFilt)
    ---@type XCommonCharacterFiltAgency
    self.FiltAgecy = ag

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
end

function XUiCharacterV2P6:InitFilter()
    self.PanelFilter = self.FiltAgecy:InitFilter(self.PanelCharacterFilter, self)
    local onSeleCb = function (character, index, grid, isFirstSelect)
        if not character then
            return
        end
        -- 记录角色新标签，默认选的也要消
        if self.CharacterAgency:IsOwnCharacter(character.Id) and XTool.IsNumberValid(character.NewFlag) then
            self.NewCharRecord[character.Id] = true
        end

        self:OnSelectCharacter(character)
    end

    local refreshFun = function (index, grid, char)
        grid:SetData(char)
        grid:UpdateRedPoint()
        grid:UpdateNew()
        grid:UpdateCollect()
        grid:UpdateIconEquipGuide()
    end

    self.PanelFilter:InitData(onSeleCb, nil, nil, refreshFun)

    -- 接入折叠功能
    local foldCb = function (isInitFoldState)
        if isInitFoldState then
            self:PlayAnimation("AnimFold")
        else
            self:PlayAnimation("AnimFold1F")
        end
        self.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.CharLeftMove)
    end

    local unFoldCb = function (isInitFoldState)
        if isInitFoldState then
            self:PlayAnimation("AnimUnFold")
        else
            self:PlayAnimation("AnimUnFold1F")
        end
        self.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.Main)
    end
    self.PanelFilter:SetFoldCallback(foldCb, unFoldCb)

    -- 先选中第一个
    local list = self.CharacterAgency:GetCharacterList()
    local sortTagList = self.CharacterAgency:GetModelCharacterFilterController()[self.Name].SortTagList
    list = self.FiltAgecy:DoSortFilterV2P6(list, sortTagList)
    local index = 1
    local targetChar = list[index]
    local initCharId = self.ParentUi.InitCharId
    if initCharId then
        targetChar = self.CharacterAgency:GetCharacter(initCharId)
        if not targetChar then
            targetChar = XMVCA.XCharacter:GetCharacterTemplate(initCharId)
        end
    end
    -- 提前选中时也要检测独域过滤
    if self.PanelFilter.HideIsomerTag and self.CharacterAgency:GetIsIsomer(targetChar.Id) then
        for k, char in ipairs(list) do
            if not self.CharacterAgency:GetIsIsomer(char.Id) then
                targetChar = char
                break
            end
        end
    end
    self:OnSelectCharacter(targetChar)

    self.NextNotRefreshCharInfoTrigger = true -- 提前刷新了 所以第一次onenable不刷新信息了
    self.FiltAgecy:SetNotSortTrigger()
    self.PanelFilter:ImportList(list)
end

function XUiCharacterV2P6:RefresFilter()
    -- 刷新时要重新获取源数据，因为角色data可能从碎片变成xCharacter。要重新获取
    local list = self.CharacterAgency:GetCharacterList()
    self.PanelFilter:ImportList(list)
    self.PanelFilter:RefreshList()
end

function XUiCharacterV2P6:OnEnable()
    self.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.Main)
    -- 重复刷新资源栏、因为进化界面会更改资源栏
    self.ParentUi:SetPanelAsset(XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.PanelFilter:InitFoldState()

    -- 同步其他子界面切换的角色
    local syncChar = self.ParentUi.CurCharacter
    local initCharId = self.ParentUi.InitCharId

    -- 只有第二次进入enbale才需要同步标签和角色，刷新角色信息。 因为第一次在init时刷新了
    self.PanelFilter:DoSelectTag("BtnAll", true, syncChar and syncChar.Id)
        
    if initCharId and not self.IsEnableFin then
        self.PanelFilter:DoSelectCharacter(initCharId)
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
        table.insert(allRecordClickedNewCharList, charId)
    end
    if not XTool.IsTableEmpty(allRecordClickedNewCharList) then
        self._Control:CharacterResetNewFlagRequest(allRecordClickedNewCharList)
    end
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
    self.ParentUi:SetCurCharacter(character)

    local cb = function(model)
        self.PanelDrag.Target = model.transform
    end
    self.ParentUi:RefreshRoleModel(cb)

    local isFragment = self.CharacterAgency:CheckIsFragment(self.CurCharacter.Id)
    local isFunctionOpen = XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Character, nil, true)
    self.BtnCollect.gameObject:SetActiveEx(not isFragment and isFunctionOpen)
    local collectState = character.CollectState and true or false
    self.BtnCollect:SetDisable(collectState)
    self:RefreshRightInfo()

    -- 刷新涂装等蓝点
    local isRed = XDataCenter.FashionManager.GetCurrCharHaveCanUnlockFashion(character.Id)
    self.BtnFashion:ShowReddot(isRed)
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
    local isFragment = self.CharacterAgency:CheckIsFragment(self.CurCharacter.Id)
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

function XUiCharacterV2P6:OnBtnCollectClick()
    if self.CollectLock then
        return
    end

    self.CollectLock = true

    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Character) then
        return
    end

    local character = self.CharacterAgency:GetCharacter(self.CurCharacter.Id)
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
end

function XUiCharacterV2P6:OnBtnTeachingClick()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self.CurCharacter.Id)
end

function XUiCharacterV2P6:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self.CurCharacter.Id)
end

function XUiCharacterV2P6:OnBtnOwnedDetailClick()
    XLuaUiManager.Open("UiCharacterDetail", self.CurCharacter.Id)
end

return XUiCharacterV2P6
