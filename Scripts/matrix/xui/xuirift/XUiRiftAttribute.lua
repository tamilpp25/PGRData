local XUiRiftAttributeSlider = require("XUi/XUiRift/Grid/XUiRiftAttributeSlider")
local XUiRiftAttributeEffectGrid = require("XUi/XUiRift/Grid/XUiRiftAttributeEffectGrid")
local XRiftAttributeTemplate = require("XEntity/XRift/XRiftAttributeTemplate")

--大秘境队伍加点界面
local XUiRiftAttribute = XLuaUiManager.Register(XLuaUi, "UiRiftAttribute")
local MEMBER_CNT = 3
local Color = {
    red = XUiHelper.Hexcolor2Color("d11227"),
    blue = XUiHelper.Hexcolor2Color("0f70bc"),
}

function XUiRiftAttribute:OnAwake()
    self.AttrTemplate = nil -- 当前应用的加点模板
    self.AttrSliderList = {}
    self.IsPropertyShow = false

    self.CanEditorTeam = true
    self.TeamData = nil -- 当前队伍信息
    self.SelectIndex = 1 -- 当前选中的角色下标
    
    self:RegisterEvent()
    self:InitSliders()
    self:InitPropertyPanel()
    self:InitDynamicTable()
    self:InitAssetPanel()
    self:InitTimes()

    local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.RiftGold)
    self.RImgExpend:SetRawImage(icon)
end

function XUiRiftAttribute:OnStart(canEditorTeam)
    if canEditorTeam == nil then canEditorTeam = true end
    self.CanEditorTeam = canEditorTeam
end

function XUiRiftAttribute:OnEnable()
    self.Super.OnEnable(self)
    local attrTemplateId = self.AttrTemplate and self.AttrTemplate.Id or XRiftConfig.DefaultAttrTemplateId
    self:Refresh(attrTemplateId)
end

function XUiRiftAttribute:OnDisable()
    self.Super.OnDisable(self)
    XDataCenter.RiftManager.CloseBuyAttrRed()
end

function XUiRiftAttribute:RegisterEvent()
    self.BtnMainUi.CallBack = handler(self, function() XLuaUiManager.RunMain() end)
    self.BtnBack.CallBack = handler(self, self.Close)
    self:BindHelpBtn(self.BtnHelp, "RiftAttributeHelp")
    self:RegisterClickEvent(self.BtnSave, self.OnClickSave)
    self:RegisterClickEvent(self.BtnTemplate, self.OnClickBtnTemplate)
    self:RegisterClickEvent(self.BtnProperty, self.OnClickBtnProperty)
    self:RegisterClickEvent(self.TogPlugin, self.OnClickTogPlugin)
    self:RegisterClickEvent(self.TogDot, self.OnClickTogDot)

    self:RegisterClickEvent(self.TogEditorTeam, self.OnClickTogEditorTeam)
    self:RegisterClickEvent(self.GridDeployMember1, function() self:OnClickMember(1) end)
    self:RegisterClickEvent(self.GridDeployMember2, function() self:OnClickMember(2) end)
    self:RegisterClickEvent(self.GridDeployMember3, function() self:OnClickMember(3) end)
    self:RegisterClickEvent(self.GridDeployMember1:GetObject("ImgChange"), function() self:OnClickChangeMember(1) end)
    self:RegisterClickEvent(self.GridDeployMember2:GetObject("ImgChange"), function() self:OnClickChangeMember(2) end)
    self:RegisterClickEvent(self.GridDeployMember3:GetObject("ImgChange"), function() self:OnClickChangeMember(3) end)
end

function XUiRiftAttribute:OnClickChangeMember(index)
    if self.TogEditorTeam.isOn then
        local team = XDataCenter.RiftManager.GetSingleTeamData()
        XLuaUiManager.Open("UiRiftCharacter", false, team, index, true)
    end
end

function XUiRiftAttribute:OnClickSave()
    if self.BtnSave.ButtonState == CS.UiButtonState.Disable then
        return
    end

    if self.GoldNoEnough then
        XUiManager.TipText("RogueLikeBuyNotEnough")
    else
        local curAttrTemplate = self:GetCurAttrTemplate()
        XDataCenter.RiftManager.RequestSetAttrSet(curAttrTemplate, function()
            self:Refresh(XRiftConfig.DefaultAttrTemplateId)
        end)
    end
end

function XUiRiftAttribute:OnClickBtnTemplate()
    if self.BtnTemplate.ButtonState == CS.UiButtonState.Disable then
        return
    end
    local changeCb = function(id)
        self:OnAttrTemplateChange(id)
    end
    XLuaUiManager.Open("UiRiftTemplate", self.AttrTemplate.Id, changeCb)
end

function XUiRiftAttribute:OnClickBtnProperty()
    self.IsPropertyShow = not self.IsPropertyShow
    if self.IsPropertyShow then
        self.PropertyEnable:Stop()
        self.PropertyEnable:Play()
    else
        self.PropertyDisable:Stop()
        self.PropertyDisable:Play()
    end
    self.ImagePropertyShow.gameObject:SetActiveEx(self.IsPropertyShow)
    self.ImagePropertyHide.gameObject:SetActiveEx(not self.IsPropertyShow)
    self.PanelContent.gameObject:SetActiveEx(not self.IsPropertyShow)

    self:RefreshDynamicTable()
end

function XUiRiftAttribute:OnClickTogPlugin()
    self:RefreshDynamicTable()
end

function XUiRiftAttribute:OnClickTogDot()
    self:RefreshDynamicTable()
end

function XUiRiftAttribute:OnClickTogEditorTeam()
    self:RefreshChangeMemberBtn()
end

function XUiRiftAttribute:OnClickMember(index)
    if not self.TeamData:CheckIsPosEmpty(index) then
        self.SelectIndex = index
        self:RefreshMemberSelect()
    else
        if self.TogEditorTeam.isOn then
            local team = XDataCenter.RiftManager.GetSingleTeamData()
            XLuaUiManager.Open("UiRiftCharacter", false, team, index, true)
        end 
    end
end

function XUiRiftAttribute:OnAttrLevelChange()
    self:RefreshAttrLevelAndConst()
    self:RefreshAttrBtnState()

    self:RefreshMemberAbilityChange()
    self:RefreshDynamicTable()
end

function XUiRiftAttribute:OnAttrTemplateChange(id)
    self:Refresh(id)
end

function XUiRiftAttribute:Refresh(attrTemplateId)
    -- 设置属性加点模板
    local attrTemplate = XDataCenter.RiftManager.GetAttrTemplate(attrTemplateId)
    self.AttrTemplate = XRiftAttributeTemplate.New(XRiftConfig.DefaultAttrTemplateId, attrTemplate.AttrList)

    -- 设置队伍数据
    self.TeamData = XDataCenter.RiftManager.GetSingleTeamData()
    self.SelectIndex = 1
    for pos = 1, MEMBER_CNT do
        if not self.TeamData:CheckIsPosEmpty(pos) then 
            self.SelectIndex = pos
            break
        end
    end

    self:RefreshAttrPanel()
    self:RefreshEditorTeamTog()
    self:RefreshMembers()
    self:RefreshChangeMemberBtn()
    self:RefreshMemberSelect()
    self:RefreshMemberAbilityChange()
    self:RefreshDynamicTable()
    self:UpdateAssetPanel()
end

---------------------------------------- 加点 start ----------------------------------------

function XUiRiftAttribute:InitSliders()
    self.AttrSliderList = {}
    for i = 1, XRiftConfig.AttrCnt do
        local tran = self["Attr" .. i]
        local slider = XUiRiftAttributeSlider.New(tran, self, i)
        table.insert(self.AttrSliderList, slider)
    end
end

function XUiRiftAttribute:RefreshAttrPanel()
    self:RefreshSlider()
    self:RefreshAttrLevelAndConst()
    self:RefreshAttrBtnState()
end

function XUiRiftAttribute:RefreshSlider()
    local attrLevelMax = XDataCenter.RiftManager.GetAttrLevelMax()
    for i, attrSlider in ipairs(self.AttrSliderList) do
        local level = self.AttrTemplate:GetAttrLevel(i)
        attrSlider:Refresh(level, attrLevelMax)
    end
end

function XUiRiftAttribute:RefreshAttrLevelAndConst()
    local totalLevel = 0
    for _, attrSlider in ipairs(self.AttrSliderList) do
        totalLevel = totalLevel + attrSlider:GetLevel()
    end
    self.TxtTotalLv.text = totalLevel

    -- 右上角的+/-标志
    local originLevel = self.AttrTemplate:GetAllLevel()
    local isAdd = totalLevel > originLevel
    self.TxtTotalLvAdd.gameObject:SetActiveEx(isAdd)
    if isAdd then
        self.TxtTotalLvAdd.text = "+" .. (totalLevel - originLevel)
    end
    local isSub = originLevel > totalLevel
    self.TxtTotalLvSubtract.gameObject:SetActiveEx(isSub)
    if isSub then
        self.TxtTotalLvSubtract.text = "-" .. (originLevel - totalLevel)
    end

    -- 购买点数消耗
    self.PanelExpend.gameObject:SetActiveEx(false)
    self.GoldNoEnough = false
    local const = XDataCenter.RiftManager.GetAttributeCost(totalLevel)
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
    local showConst = const > 0
    if showConst then 
        self.TxtExpendTitle.text = XUiHelper.GetText("RiftBuyAttrConst")
        self.TxtExpend.text = const
        self.GoldNoEnough = ownCnt < const
        self.TxtExpend.color = self.GoldNoEnough and Color.red or Color.blue
        self.PanelExpend.gameObject:SetActiveEx(true)
    end

    -- 无点数变化 且 当前加点=已购买点数，显示购买下一点数需要的金币
    local isChange = self:IsAttrChange()
    local buyAttrLevel = XDataCenter.RiftManager.GetTotalAttrLevel()
    if not isChange and totalLevel == buyAttrLevel then
        local nextLvCost = XDataCenter.RiftManager.GetAttributeCost(buyAttrLevel + 1)
        if nextLvCost > 0 then
            self.TxtExpendTitle.text = XUiHelper.GetText("RiftNextAttrConst")
            self.TxtExpend.text = nextLvCost
            local canBuyNext = ownCnt >= nextLvCost
            self.TxtExpend.color = canBuyNext and Color.blue or Color.red
            self.PanelExpend.gameObject:SetActiveEx(true)
        end
    end
end

function XUiRiftAttribute:RefreshAttrBtnState()
    for i = 1, XRiftConfig.AttrCnt do
        self.AttrSliderList[i]:RefreshButton()
    end

    local isChange = self:IsAttrChange()
    self.BtnSave:SetDisable(not isChange, false)
    self.BtnTemplate:SetDisable(isChange, false)
end

function XUiRiftAttribute:IsAttrChange()
    local attrTemplate = XDataCenter.RiftManager.GetAttrTemplate(XRiftConfig.DefaultAttrTemplateId)
    for i = 1, XRiftConfig.AttrCnt do
        if self.AttrSliderList[i]:GetLevel() ~= attrTemplate:GetAttrLevel(i) then
            return true
        end
    end
    return false
end

function XUiRiftAttribute:GetCurAttrTemplate()
    if self.CurAttrTemplate == nil then
        self.CurAttrTemplate = XRiftAttributeTemplate.New(XRiftConfig.DefaultAttrTemplateId)
    end

    self.CurAttrTemplate:SetAttrLevel(1, self.AttrSliderList[1]:GetLevel())
    self.CurAttrTemplate:SetAttrLevel(2, self.AttrSliderList[2]:GetLevel())
    self.CurAttrTemplate:SetAttrLevel(3, self.AttrSliderList[3]:GetLevel())
    self.CurAttrTemplate:SetAttrLevel(4, self.AttrSliderList[4]:GetLevel())
    return self.CurAttrTemplate
end

---------------------------------------- 加点 end ----------------------------------------

---------------------------------------- 效果面板 start ----------------------------------------
function XUiRiftAttribute:InitPropertyPanel()
    self.IsPropertyShow = false
    local select = CS.UiButtonState.Select
    self.TogPlugin:SetButtonState(select)
    self.TogDot:SetButtonState(select)
end

function XUiRiftAttribute:InitDynamicTable()
    self.EffectGrid.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEffectList)
    self.DynamicTable:SetProxy(XUiRiftAttributeEffectGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftAttribute:RefreshDynamicTable()
    self.DataList = self:GetEffectDataList()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    
    self.PanelNoProperty.gameObject:SetActiveEx(#self.DataList == 0)
end

function XUiRiftAttribute:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local effectData = self.DataList[index]
        grid:Refresh(index, effectData)
    end
end

function XUiRiftAttribute:GetEffectDataList()
    local originEffectList = self:GetEffectList(self.AttrTemplate)

    local curAttrTemplate = self:GetCurAttrTemplate()
    local curEffectList = self:GetEffectList(curAttrTemplate)

    local showEffectDic = {}
    for _, effect in ipairs(originEffectList) do
        local showEffect = showEffectDic[effect.EffectType]
        if showEffect == nil then
            showEffectDic[effect.EffectType] = {}
            showEffect = showEffectDic[effect.EffectType]
            showEffect.EffectType = effect.EffectType
            showEffect.OriginValue = 0
            showEffect.CurValue = 0
        end
        showEffect.OriginValue = showEffect.OriginValue + effect.EffectValue
    end

    for _, effect in ipairs(curEffectList) do
        local showEffect = showEffectDic[effect.EffectType]
        if showEffect == nil then
            showEffectDic[effect.EffectType] = {}
            showEffect = showEffectDic[effect.EffectType]
            showEffect.EffectType = effect.EffectType
            showEffect.OriginValue = 0
            showEffect.CurValue = 0
        end
        showEffect.CurValue = showEffect.CurValue + effect.EffectValue
    end

    local showEffectList = {}
    for _, effect in pairs(showEffectDic) do
        table.insert(showEffectList, effect)
    end
    local effectTypeConfigs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTeamAttributeEffectType)
    table.sort(showEffectList,  function(a, b)
        return effectTypeConfigs[a.EffectType].Order < effectTypeConfigs[b.EffectType].Order
    end)

    return showEffectList
end

function XUiRiftAttribute:GetEffectList(attrTemplate)
    local allEffectList = {}

    -- 插件页签
    if self.TogPlugin:GetToggleState() then
        if not self.TeamData:CheckIsPosEmpty(self.SelectIndex) then
            local entityId = self.TeamData:GetEntityIdByTeamPos(self.SelectIndex)
            local xRole = XDataCenter.RiftManager.GetEntityRoleById(entityId)
            local xPluginList = xRole:GetPlugIns()
            for _, plugin in ipairs(xPluginList) do
                local pluginEffectList = plugin:GetEffectList(attrTemplate)
                for _, effect in ipairs(pluginEffectList) do
                    table.insert(allEffectList, effect)
                end
            end
        end
    end

    -- 加点页签
    if self.TogDot:GetToggleState() then 
        local attrEffectList = attrTemplate:GetEffectList()
        for _, effect in ipairs(attrEffectList) do
            table.insert(allEffectList, effect)
        end
    end

    return allEffectList
end
---------------------------------------- 效果面板 end ----------------------------------------

---------------------------------------- 成员 start ----------------------------------------
function XUiRiftAttribute:RefreshEditorTeamTog()
    self.TxtEditorTeamOn.gameObject:SetActiveEx(self.CanEditorTeam)
    self.TxtEditorTeamOff.gameObject:SetActiveEx(not self.CanEditorTeam)
    self.TogEditorTeam.isOn = self.CanEditorTeam
    self.TogEditorTeam.interactable = self.CanEditorTeam
end

function XUiRiftAttribute:RefreshMembers()
    for pos = 1, MEMBER_CNT do
        local haveMember = not self.TeamData:CheckIsPosEmpty(pos)
        local go = self["GridDeployMember"..pos]
        go:GetObject("PanelNotEmpty").gameObject:SetActiveEx(haveMember)
        if haveMember then
            local entityId = self.TeamData:GetEntityIdByTeamPos(pos)
            local characterId
            if XRobotManager.CheckIsRobotId(entityId) then
                local robotConfig = XRobotManager.GetRobotTemplate(entityId)
                characterId = robotConfig.CharacterId
            else
                characterId = entityId
            end
            local image = XDataCenter.CharacterManager.GetCharHalfBodyImage(characterId)
            go:GetObject("RawImage"):SetRawImage(image)
        end
    end
end

function XUiRiftAttribute:RefreshChangeMemberBtn()
    local showChangeBtn = self.TogEditorTeam.isOn
    for i = 1, MEMBER_CNT do
        local go = self["GridDeployMember"..i]
        go:GetObject("ImgChange").gameObject:SetActiveEx(showChangeBtn)
        go:GetObject("ImageEmpty").gameObject:SetActiveEx(showChangeBtn)
        go:GetObject("ImageEmptyDisable").gameObject:SetActiveEx(not showChangeBtn)
    end
end

function XUiRiftAttribute:RefreshMemberSelect()
    for i = 1, MEMBER_CNT do
        local isSelect = self.SelectIndex == i
        local go = self["GridDeployMember"..i]
        go:GetObject("GridNow").gameObject:SetActiveEx(isSelect)
    end
end

function XUiRiftAttribute:RefreshMemberAbilityChange()
    local curAttrTemplate = self:GetCurAttrTemplate()
    for pos = 1, MEMBER_CNT do
        local oldAbility = 0
        local curAbility = 0
        if not self.TeamData:CheckIsPosEmpty(pos) then 
            local entityId = self.TeamData:GetEntityIdByTeamPos(pos)
            local xRole = XDataCenter.RiftManager.GetEntityRoleById(entityId)
            local xPluginList = xRole:GetPlugIns()
            for _, plugin in ipairs(xPluginList) do
                oldAbility = oldAbility + plugin:GetAbility(self.AttrTemplate)
                curAbility = curAbility + plugin:GetAbility(curAttrTemplate)
            end
        end
        oldAbility = oldAbility + self.AttrTemplate:GetAbility()
        curAbility = curAbility + curAttrTemplate:GetAbility()

        local go = self["GridDeployMember"..pos]
        go:GetObject("ImgAdd").gameObject:SetActiveEx(curAbility > oldAbility)
        go:GetObject("TextAdd").text = "+"..(curAbility - oldAbility)
        go:GetObject("ImgReduce").gameObject:SetActiveEx(oldAbility > curAbility)
        go:GetObject("TextReduce").text = tostring(curAbility - oldAbility)
    end
end

---------------------------------------- 成员 end ----------------------------------------

function XUiRiftAttribute:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.RiftGold,
        },
        handler(self, self.UpdateAssetPanel),
        self.AssetActivityPanel
    )
end

function XUiRiftAttribute:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.RiftGold,
        }
    )
end

function XUiRiftAttribute:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.RiftManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end
