local XUiMaverick2CharacterRobot = require("XUi/XUiMaverick2/XUiMaverick2CharacterRobot")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

-- 异构阵线2.0成员界面
local XUiMaverick2Character = XLuaUiManager.Register(XLuaUi, "UiMaverick2Character")
local TabType = 
{
    HelpSkill = 1, -- 支援技能
    Info = 2, -- 角色信息
}
local Select = CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal

function XUiMaverick2Character:OnAwake()
    self.SelectRobotIndex = nil
    self.RobotCfgList = {}
    self.SelectTag = TabType.HelpSkill
    self.StageId = nil -- 挑战关卡id
    self.HelpSkillInfoList = {} -- 支援技列表
    self.SelHelpSkillIndex = nil -- 选中的支援技列表

    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:InitAssetPanel()
    self:InitTimes()
    self:InitRoleModel()
end

function XUiMaverick2Character:OnStart(stageId)
    self.StageId = stageId
    local isFight = self.StageId ~= nil
    self.SelectTag = isFight and TabType.HelpSkill or TabType.Info

    -- 挑战界面显示挑战按钮和支援技能
    self.PanelTabGroup.gameObject:SetActiveEx(isFight)
    self.TxtTitle.gameObject:SetActiveEx(not isFight)
    self.BtnFight.gameObject:SetActiveEx(isFight)
end

function XUiMaverick2Character:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()

    -- 战斗失败回到选角色界面重新播放BGM
    XDataCenter.Maverick2Manager.PlayBGM()
end

function XUiMaverick2Character:OnDisable()

end

function XUiMaverick2Character:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnClickBtnFight)
    XUiHelper.RegisterClickEvent(self, self.BtnHelpSkill, function() self:OnClickTab(TabType.HelpSkill) end)
    XUiHelper.RegisterClickEvent(self, self.BtnInfo, function() self:OnClickTab(TabType.Info) end)
    XUiHelper.RegisterClickEvent(self, self.BtnTalent, self.OnClickBtnTalent)
end

function XUiMaverick2Character:OnClickBtnFight()

    -- 进入战斗前需刷新支援技能信息，防止改动天赋导致之前选中的支援技能失效
    local talentGroupId = nil
    local talentId = nil
    self:RefreshDetailHelpSkill()
    if self.SelHelpSkillIndex then 
        local helpSkillCfg = self.HelpSkillInfoList[self.SelHelpSkillIndex].HelpSkillCfg
        talentGroupId = helpSkillCfg.TalentGroupId
        talentId = helpSkillCfg.TalentId
    end

    local robotId = self:GetSelectRobotId()
    XDataCenter.Maverick2Manager.EnterFight(self.StageId, robotId, talentGroupId, talentId)
end

function XUiMaverick2Character:OnClickBtnTalent()
    XLuaUiManager.Open("UiMaverick2Talent", self:GetSelectRobotId(), self.StageId, function(robotId)
        -- 设置最后选中的机器人
        XDataCenter.Maverick2Manager.SaveLastSelRobotId(robotId)
    end)
end

function XUiMaverick2Character:Refresh()
    self.RobotCfgList = XDataCenter.Maverick2Manager.GetRobotCfgList(self.StageId)
    self:RefreshDynamicTable()
    self:UpdateAssetPanel()
    self:UpdateCamera(XMaverick2Configs.CharacterCamera.Prepare)
end

function XUiMaverick2Character:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.Maverick2Manager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiMaverick2Character:GetSelectRobotId()
    return self.RobotCfgList[self.SelectRobotIndex].RobotId
end

-- 机器人是否被禁用
function XUiMaverick2Character:IsRobotForbid(robotId)
    return XDataCenter.Maverick2Manager.IsRobotForbid(robotId, self.StageId)
end

---------------------------------------- 机器人动态列表 begin ----------------------------------------
function XUiMaverick2Character:InitDynamicTable()
    self.GridCharacter.gameObject:SetActive(false)
    self.DynamicTable = XDynamicTableNormal.New(self.CharacterList)
    self.DynamicTable:SetProxy(XUiMaverick2CharacterRobot)
    self.DynamicTable:SetDelegate(self)
end

function XUiMaverick2Character:RefreshDynamicTable()
    -- 优先选中上次的机器人
    self.SelectRobotIndex = 1
    local robotId = XDataCenter.Maverick2Manager.GetLastSelRobotId()
    if not self:IsRobotForbid(robotId) then
        for i, robotCfg in ipairs(self.RobotCfgList) do
            if robotCfg.RobotId == robotId then 
                self.SelectRobotIndex = i
            end
        end
    end

    -- 刷新机器人列表
    self.DynamicTable:SetDataSource(self.RobotCfgList)
    self.DynamicTable:ReloadDataASync(self.SelectRobotIndex)
    self:UpdateRobotInfo()
end

function XUiMaverick2Character:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local robotCfg = self.RobotCfgList[index]
        local isSelect = self.SelectRobotIndex == index
        local isForbid = self:IsRobotForbid(robotCfg.RobotId)
        grid:Refresh(robotCfg, isForbid, isSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickRobot(index, grid)
    end
end

function XUiMaverick2Character:OnClickRobot(index, selectGrid)
    if self.SelectRobotIndex == index then
        return 
    end

    -- 禁用/未解锁，播放禁止音效
    if selectGrid.IsForbid or not selectGrid.IsUnlock then
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Intercept)
        return
    end

    -- 切换按钮状态
    self.SelectRobotIndex = index
    local grids = self.DynamicTable:GetGrids()
    for i, grid in pairs(grids) do
        local isSelect = i == self.SelectRobotIndex
        grid:ShowSelect(isSelect)
    end

    -- 选中回调
    selectGrid:OnClickRobot()

    -- 刷新角色
    self:UpdateRobotInfo()
end
---------------------------------------- 机器人动态列表 end ----------------------------------------

---------------------------------------- 机器人详情 begin ----------------------------------------
-- 刷新机器人信息
function XUiMaverick2Character:UpdateRobotInfo()
    -- 刷新模型旁边名字
    local robotId = self:GetSelectRobotId()
    local characterId = XEntityHelper.GetCharacterIdByEntityId(robotId)
    self.TxtName.text = XMVCA.XCharacter:GetCharacterName(characterId)
    self.TxtType.text = XMVCA.XCharacter:GetCharacterTradeName(characterId)
    self.TxtNumber.text = XMVCA.XCharacter:GetCharacterCodeStr(characterId)

    -- 刷新模型
    self:UpdateRoleModel(robotId)

    -- 刷新详细信息
    self:OnClickTab(self.SelectTag, true)
    
    -- 机器人天赋红点
    self:RefreshTalentRed()

    -- 设置最后选中的机器人
    XDataCenter.Maverick2Manager.SaveLastSelRobotId(self:GetSelectRobotId())
end

-- 初始化3D模型
function XUiMaverick2Character:InitRoleModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)

    self.CameraFar = {
        root:FindTransform("UiCamFarMaverick2Lv"),
        root:FindTransform("UiCamFarMaverick2Prepare"),
        root:FindTransform("UiCamFarMaverick2Exchange"),
    }
    self.CameraNear = {
        root:FindTransform("UiCamNearMaverick2Lv"),
        root:FindTransform("UiCamNearMaverick2Prepare"),
        root:FindTransform("UiCamNearMaverick2Exchange"),
    }
end

-- 刷新3D模型
function XUiMaverick2Character:UpdateRoleModel(robotId)
    local entity = XRobotManager.GetRobotById(robotId)
    if entity == nil then
        return
    end

    local finishedCallback = function(model)
        self.PanelDrag.Target = model.transform
    end
    local characterViewModel = entity:GetCharacterViewModel()
    local sourceEntityId = characterViewModel:GetSourceEntityId()
    if XRobotManager.CheckIsRobotId(sourceEntityId) then
        local robot2CharEntityId = XRobotManager.GetCharacterId(sourceEntityId)
        local isOwen = XDataCenter.CharacterManager.IsOwnCharacter(robot2CharEntityId)
        if XRobotManager.CheckUseFashion(sourceEntityId) and isOwen then
            local character = XDataCenter.CharacterManager.GetCharacter(robot2CharEntityId)
            local robot2CharViewModel = character:GetCharacterViewModel()
            self.UiPanelRoleModel:UpdateCharacterModel(robot2CharEntityId
            , self.PanelRoleModelGo
            , self.Name
            , finishedCallback
            , nil
            , robot2CharViewModel:GetFashionId())
        else
            local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
            self.UiPanelRoleModel:UpdateRobotModel(sourceEntityId
            , robotConfig.CharacterId
            , nil
            , robotConfig.FashionId
            , robotConfig.WeaponId
            , finishedCallback
            , nil
            , self.PanelRoleModelGo
            , self.Name)
        end
    else
        self.UiPanelRoleModel:UpdateCharacterModel(
        sourceEntityId,
        self.PanelRoleModelGo,
        self.Name,
        finishedCallback,
        nil,
        characterViewModel:GetFashionId()
        )
    end
end

function XUiMaverick2Character:UpdateCamera(index)
    if self.CurCameraIndex == index then 
        return
    end

    self.CurCameraIndex = index
    for i = 1, XMaverick2Configs.CAMERA_CNT do
        local isShow = self.CurCameraIndex == i
        if self.CameraFar[i] then
            self.CameraFar[i].gameObject:SetActiveEx(isShow)
        end
        if self.CameraNear[i] then
            self.CameraNear[i].gameObject:SetActiveEx(isShow)
        end
    end
end
---------------------------------------- 机器人详情 end ----------------------------------------

---------------------------------------- 页签 begin ----------------------------------------
function XUiMaverick2Character:OnClickTab(index, isForcedRefresh)
    if self.SelectTag == index and not isForcedRefresh then 
        return 
    end

    self.SelectTag = index
    local isSelectInfo = index == TabType.Info
    self.BtnHelpSkill:SetButtonState(isSelectInfo and Normal or Select)
    self.BtnInfo:SetButtonState(isSelectInfo and Select or Normal)

    if isSelectInfo then
        self:RefreshDetailInfo()
    else
        self:RefreshDetailHelpSkill()
    end
    self.PanelHelpSkill.gameObject:SetActiveEx(not isSelectInfo)
    self.PanelInfo.gameObject:SetActiveEx(isSelectInfo)
    self.BtnTalent.gameObject:SetActiveEx(isSelectInfo)
end

-- 刷新支援技能
function XUiMaverick2Character:RefreshDetailHelpSkill()
    self.SelHelpSkillIndex = nil
    self.HelpSkillInfoList = {}
    local robotId = self:GetSelectRobotId()
    local helpSkillList = XMaverick2Configs.GetRobotAssistSkillConfigs()
    table.sort(helpSkillList, function(a, b)
        local isUnlockA = XDataCenter.Maverick2Manager.IsAssistTalentUnlock(a.TalentId)
        local isUnlockB = XDataCenter.Maverick2Manager.IsAssistTalentUnlock(b.TalentId)
        local aValue = isUnlockA and 1 or 0
        local bValue = isUnlockB and 1 or 0
        if aValue ~= bValue then
            return aValue > bValue
        else
            return a.TalentId < b.TalentId
        end
    end)

    -- 刷新ui
    XUiHelper.RefreshCustomizedList(self.PanelContent, self.GridHelpSkill, #helpSkillList, function(index, go)
        self:RefreshHelpSkill(index, go, helpSkillList[index])
    end)

    -- 没有支援技
    self.TxtSelectHelpSkillTitle.text = ""
    self.TxtSelectHelpSkilDesc.text = ""
    if #self.HelpSkillInfoList == 0 then
        return
    end

    -- 优先选择上次选中的技能，没有则选第一个，都没解锁则不选中
    local selTalentId = XDataCenter.Maverick2Manager.GetRobotSelHelpSkill(robotId)
    local selectIndex = 1
    for i, skillInfo in ipairs(self.HelpSkillInfoList) do
        local skillCfg = skillInfo.HelpSkillCfg
        local isUnlock = XDataCenter.Maverick2Manager.IsAssistTalentUnlock(skillCfg.TalentId)
        if skillCfg.TalentId == selTalentId and isUnlock then
            selectIndex = i
        end
    end
    if self.HelpSkillInfoList[selectIndex].IsLock then
        self.TxtSelectHelpSkillTitle.text = ""
        self.TxtSelectHelpSkilDesc.text = ""
        for _, skillInfo in ipairs(self.HelpSkillInfoList) do
            skillInfo.ImgSelected.gameObject:SetActiveEx(false)
        end
    else
        self:OnClickBtnHelpSkill(selectIndex)
    end
end

-- 刷新支援技能
function XUiMaverick2Character:RefreshHelpSkill(index, go, helpSkillCfg)
    local robotId = self:GetSelectRobotId()
    local groupId = helpSkillCfg.TalentGroupId
    local talentId = helpSkillCfg.TalentId
    local lvConfigs = XMaverick2Configs.GetTalentLvConfigs(talentId)
    local lv = XDataCenter.Maverick2Manager.GetAssistTalentLv(talentId)
    local icon = lv == 0 and lvConfigs[1].Icon or lvConfigs[lv].Icon -- 无0级配置表，使用一级的图标配置

    local isLock = not XDataCenter.Maverick2Manager.IsAssistTalentUnlock(talentId)

    local uiObj = go:GetComponent("UiObject")
    local rImgIcon = uiObj:GetObject("RImgIcon")
    local imgLock = uiObj:GetObject("ImgLock")
    rImgIcon.gameObject:SetActiveEx(not isLock)
    imgLock.gameObject:SetActiveEx(isLock)
    if not isLock then
        rImgIcon:SetRawImage(icon)
    end
    XUiHelper.RegisterClickEvent(self, go, function()
        self:OnClickBtnHelpSkill(index)
    end)

    local imgSelected = uiObj:GetObject("ImgSelected")
    self.HelpSkillInfoList[index] = { Index = index, ImgSelected = imgSelected, HelpSkillCfg = helpSkillCfg, IsLock = isLock }
    if not isLock then
        self.HelpSkillInfoList[index].Name =  XUiHelper.GetText("Maverick2HelpSkillName", helpSkillCfg.Name, lv)
        self.HelpSkillInfoList[index].Desc = lvConfigs[lv].Desc
    end
end

-- 点击支援技能
function XUiMaverick2Character:OnClickBtnHelpSkill(index)
    local skillInfo = self.HelpSkillInfoList[index]
    if skillInfo.IsLock then
        return
    end

    -- 刷新ui
    for _, skillInfo in ipairs(self.HelpSkillInfoList) do
        local isSelect = skillInfo.Index == index
        skillInfo.ImgSelected.gameObject:SetActiveEx(isSelect)
    end
    self.TxtSelectHelpSkillTitle.text = skillInfo.Name
    self.TxtSelectHelpSkilDesc.text = skillInfo.Desc

    -- 更新数据
    self.SelHelpSkillIndex = index
    local robotId = self:GetSelectRobotId()
    local talentId = skillInfo.HelpSkillCfg.TalentId
    XDataCenter.Maverick2Manager.SaveRobotSelHelpSkill(robotId, talentId)
end

-- 刷新角色信息
function XUiMaverick2Character:RefreshDetailInfo()
    local robotId = self:GetSelectRobotId()

    -- 刷新属性
    local propertyList = XDataCenter.Maverick2Manager.GetRobotPropertyList(robotId)
    XUiHelper.RefreshCustomizedList(self.PropertyContent, self.PropertyItem, #propertyList, function(index, go)
        self:RefreshProperty(index, go, propertyList[index])
    end)
    local localPos = self.PropertyContent.localPosition
    localPos.y = 0
    self.PropertyContent.localPosition = localPos

    -- 刷新技能
    local skillCfgs = XMaverick2Configs.GetRobotSkillConfigs(robotId)
    XUiHelper.RefreshCustomizedList(self.PaneSkillContent, self.GridSkill, #skillCfgs, function(index, go)
        self:RefreshSkill(go, skillCfgs[index])
    end)
end

-- 刷新属性
function XUiMaverick2Character:RefreshProperty(index, go, property)
    local uiObj = go:GetComponent("UiObject")
    local config = XMaverick2Configs.GetMaverick2Attribute(property.AttrId, true)
    local showBg = index % 2 == 1
    local isPercent = config.ShowType == XMaverick2Configs.AttributeEffectType.Percent
    uiObj:GetObject("Bg").gameObject:SetActiveEx(showBg)
    uiObj:GetObject("Icon"):SetSprite(config.Icon)
    uiObj:GetObject("Name").text = config.Name
    uiObj:GetObject("NameEng").text = config.EnglishName
    uiObj:GetObject("TxtAttack").text = isPercent and (property.AttrValue / 100) .. "%" or property.AttrValue
end

-- 刷新角色技能
function XUiMaverick2Character:RefreshSkill(go, skillCfg)
    local uiObj = go:GetComponent("UiObject")
    uiObj:GetObject("Icon"):SetRawImage(skillCfg.Icon)
    uiObj:GetObject("Text").text = skillCfg.Name
    XUiHelper.RegisterClickEvent(self, go, function() self:OnClickBtnSkill(skillCfg) end)
end

-- 点击角色技能
function XUiMaverick2Character:OnClickBtnSkill(skillCfg)
    local data = { IsSkill = true }
    for k, v in pairs(skillCfg) do
        data[k] = v
    end
    XLuaUiManager.Open("UiFubenMaverickSkillTips", data)
end
---------------------------------------- 页签 end ----------------------------------------

---------------------------------------- 资源栏 begin ----------------------------------------

function XUiMaverick2Character:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.Maverick2Coin,
        },
        handler(self, self.UpdateAssetPanel),
        self.AssetActivityPanel
    )
end

function XUiMaverick2Character:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.Maverick2Coin,
        }
    )
end
---------------------------------------- 资源栏 end ----------------------------------------

-- 刷新天赋红点
function XUiMaverick2Character:RefreshTalentRed()
    local isRed = XDataCenter.Maverick2Manager.IsShowTalentRed(self:GetSelectRobotId())
    self.BtnInfo:ShowReddot(isRed)
    self.BtnTalent:ShowReddot(isRed)
end