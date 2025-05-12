local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local ACTIVE_COLOR = "0E70BD"
local UNACTIVE_COLOR = "00000099"

-- 异构阵线2.0心智界面
local XUiMaverick2Talent = XLuaUiManager.Register(XLuaUi, "UiMaverick2Talent")

function XUiMaverick2Talent:OnAwake()
    self.RobotId = nil -- 机器人id
    self.StageId = nil -- 关卡id
    self.ChangeCharCb = nil -- 切换角色的回调
    self.TreeCfgs = nil -- 天赋树列表
    self.TalentLineGoList = { self.GridSkillLine } -- 天赋行预制体列表
    self.UnLockLineIndexDic = {} -- 记录解锁的行下标 
    self.IsEnoughLvUp = false -- 是否足够升级
    self.SelectGroupCfg = nil -- 选中的天赋
    self.LvUpTalentId = nil -- 记录刚升级完的天赋

    self:SetButtonCallBack()
    self:InitTimes()
    self:InitRoleModel()
    self:CloseTalentDetail()

    self.PanelSpecialTool.gameObject:SetActiveEx(false)
    local itemIcon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.Maverick2Unit)
    self.RImgIconUnit:SetRawImage(itemIcon)
end

function XUiMaverick2Talent:OnStart(robotId, stageId, changeCharCb)
    -- 无传具体机器人id，则用上次选中的机器人id
    if not robotId then
        robotId = XDataCenter.Maverick2Manager.GetLastSelRobotId()
    end
    self.RobotId = robotId
    self.StageId = stageId
    self.ChangeCharCb = changeCharCb
    self:UpdateCamera(XMaverick2Configs.CharacterCamera.Lv)
end

function XUiMaverick2Talent:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
end

function XUiMaverick2Talent:OnDisable()

end

function XUiMaverick2Talent:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnClickBtnBack)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnExchange, self.OnClickBtnExchange)
    XUiHelper.RegisterClickEvent(self, self.BtnReset, self.OnClickBtnReset)
    XUiHelper.RegisterClickEvent(self, self.BtnSummary, self.OnClickBtnSummary)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseSkillPopup, self.CloseTalentDetail)
    XUiHelper.RegisterClickEvent(self, self.BtnResetSkill, self.OnClickTalentReset)
    XUiHelper.RegisterClickEvent(self, self.BtnLvUpSkill, self.OnClickTalentLevelUp)
    XUiHelper.RegisterClickEvent(self, self.RImgIconUnit, self.OnClickIconUnit)
end

function XUiMaverick2Talent:OnClickBtnBack()
    if XLuaUiManager.IsUiShow("UiMaverick2CharacterExchange") then
        self:CloseChildUi("UiMaverick2CharacterExchange")
        self:UpdateCamera(XMaverick2Configs.CharacterCamera.Lv)
        self:ShowPanelTalent(true)
        self:Refresh()
        return
    end

    self:Close()
end

function XUiMaverick2Talent:OnClickBtnExchange()
    self:OpenOneChildUi("UiMaverick2CharacterExchange", self, self.StageId, function(robotId)
        self.RobotId = robotId
        if self.ChangeCharCb then
            self.ChangeCharCb(robotId)
        end
    end)
    
    -- 切换镜头
    self:UpdateCamera(XMaverick2Configs.CharacterCamera.EXCHANGE)
    self:ShowPanelTalent(false)
end

function XUiMaverick2Talent:OnClickBtnReset()
    XDataCenter.Maverick2Manager.RequestResetRobotAllTalent(self.RobotId, function()
        self:UpdateTalentLineList()
    end)
end

function XUiMaverick2Talent:OnClickBtnSummary()
    XLuaUiManager.Open("UiMaverick2Details", self.RobotId)
end

function XUiMaverick2Talent:Refresh()
    self.TreeCfgs = XMaverick2Configs.GetRobotTalentCfg(self.RobotId)
    self:InitTalentLineList()

    self:UpdateRoleModel(self.RobotId)
    self:UpdateTalentLineList()

    -- 心智等级
    local mentalLv = XDataCenter.Maverick2Manager.GetMentalLv()
    self.TxtTalentLv.text = tostring(mentalLv)

    -- 更新红点数据
    XDataCenter.Maverick2Manager.RefreshTalentRedUnlockGroupIds(self.RobotId)
end

function XUiMaverick2Talent:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.Maverick2Manager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

---------------------------------------- 3D模型 begin ----------------------------------------

-- 初始化3D模型
function XUiMaverick2Talent:InitRoleModel()
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
function XUiMaverick2Talent:UpdateRoleModel(robotId)
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
        local isOwen = XMVCA.XCharacter:IsOwnCharacter(robot2CharEntityId)
        if XRobotManager.CheckUseFashion(sourceEntityId) and isOwen then
            local character = XMVCA.XCharacter:GetCharacter(robot2CharEntityId)
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

function XUiMaverick2Talent:UpdateCamera(index)
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
---------------------------------------- 3D模型 end ----------------------------------------

---------------------------------------- 天赋列表 begin ----------------------------------------

function XUiMaverick2Talent:InitTalentLineList()
    -- 隐藏所有预置
    for _, go in ipairs(self.TalentLineGoList) do
        go.gameObject:SetActiveEx(false)
    end

    -- 创建/显示预置
    for i, _ in ipairs(self.TreeCfgs) do
        local go = self.TalentLineGoList[i]
        if not go then 
            go = CS.UnityEngine.Object.Instantiate(self.GridSkillLine.gameObject, self.PanelContent)
            self.TalentLineGoList[i] = go
        end
        go.gameObject:SetActiveEx(true)
    end
end

-- 刷新天赋行列表
function XUiMaverick2Talent:UpdateTalentLineList()
    self.UnLockLineIndexDic = {}

    for i, treeCfg in ipairs(self.TreeCfgs) do
        self:UpdateTalentLine(i)
    end

    self:UpdateRemainUnitCnt()
    self:UpdateUnlockProgress()
end

-- 刷新天赋组
function XUiMaverick2Talent:UpdateTalentLine(index)
    local treeCfg = self.TreeCfgs[index]
    local lineGo = self.TalentLineGoList[index]
    local uiObj = lineGo:GetComponent("UiObject")

    -- 天赋组解锁提示
    local assignUnit = XDataCenter.Maverick2Manager.GetAssignActiveUnitCnt(self.RobotId)
    local mentalLv = XDataCenter.Maverick2Manager.GetMentalLv()
    local isLock = false
    local desc = ""
    if assignUnit < treeCfg.NeedUnit then
        isLock = true
        desc = XUiHelper.GetText("Maverick2UnitCountUnlock", treeCfg.NeedUnit)
    end
    if mentalLv < treeCfg.NeedMentalLv then
        isLock = true
        desc = XUiHelper.GetText("Maverick2MentalLvUnlock", treeCfg.NeedMentalLv)
    end
    uiObj:GetObject("PanelUnlock").gameObject:SetActiveEx(isLock)
    uiObj:GetObject("TextUnlockTips").text = desc
    uiObj:GetObject("ImgNormal").gameObject:SetActiveEx(not isLock)
    uiObj:GetObject("ImgLock").gameObject:SetActiveEx(isLock)

    -- 记录解锁情况
    self.UnLockLineIndexDic[index] = not isLock

    -- 获取天赋和天赋预制体列表
    local talentGoList = {}
    local maxPos = 3
    for i = 1, maxPos do
        local isUse = treeCfg["UseUiPos" .. i] == 1
        local talentGo = uiObj:GetObject("Skill"..i)
        talentGo.gameObject:SetActiveEx(isUse)
        if isUse then
            table.insert(talentGoList, talentGo)
        end
    end

    -- 刷新单个天赋
    local groupCfgs = XMaverick2Configs.GetTalentGroupConfigs(treeCfg.TalentGroupId)
    for i, groupCfg in ipairs(groupCfgs) do
        local talentGo = talentGoList[i]
        if talentGo then
            self:UpdateTalent(talentGo, groupCfg)
        end
    end
end

-- 刷新单个天赋
function XUiMaverick2Talent:UpdateTalent(talentGo, groupCfg)
    local lvConfigs = XMaverick2Configs.GetTalentLvConfigs(groupCfg.TalentId)
    local lv = XDataCenter.Maverick2Manager.GetTalentLv(self.RobotId, groupCfg.TalentGroupId, groupCfg.TalentId)
    local isMax = lv == #lvConfigs
    local icon = lv == 0 and lvConfigs[1].Icon or lvConfigs[lv].Icon -- 无0级配置表，使用一级的图标配置

    local needUnit = 0
    local isTalentLock = false
    local desc = nil
    local isEnoughLvUp = false
    if not isMax then
        local nextLvCfg = lvConfigs[lv+1]
        needUnit = nextLvCfg.NeedUnit
        local unitCnt = XDataCenter.Maverick2Manager.GetRemainUnitCnt(self.RobotId)
        isEnoughLvUp = unitCnt >= needUnit
        if nextLvCfg.Condition ~= 0 then
            isTalentLock = XConditionManager.CheckCondition(nextLvCfg.Condition)
            desc = nextLvCfg.UnlockTips
        end
    end

    -- 刷新icon、锁
    local uiBtn = talentGo:GetComponent("XUiButton")
    uiBtn:SetDisable(isTalentLock)
    local uiObj = talentGo:GetComponent("UiObject")
    uiObj:GetObject("RImgIconNormal"):SetRawImage(icon)
    uiObj:GetObject("RImgIconPress"):SetRawImage(icon)
    uiObj:GetObject("RImgIconDisable"):SetRawImage(icon)

    -- 可升级特效
    local treeCfg = XMaverick2Configs.GetTalentTreeConfig(self.RobotId, groupCfg.TalentGroupId)
    local assignUnit = XDataCenter.Maverick2Manager.GetAssignActiveUnitCnt(self.RobotId)
    local mentalLv = XDataCenter.Maverick2Manager.GetMentalLv()
    local isGroupLock = mentalLv < treeCfg.NeedMentalLv or assignUnit < treeCfg.NeedUnit
    local showEffect = not isTalentLock and not isGroupLock and not isMax and isEnoughLvUp
    uiObj:GetObject("Effect").gameObject:SetActiveEx(showEffect)

    -- 升级成功特效
    local isLvUp = self.LvUpTalentId == groupCfg.TalentId
    local lvUpEffect = uiObj:GetObject("Efect2")
    if isLvUp then
        lvUpEffect.gameObject:SetActive(false)
        lvUpEffect.gameObject:SetActive(true)
    else
        lvUpEffect.gameObject:SetActiveEx(false)
    end

    -- 等级
    local showLvStr = ""
    if isMax then 
        showLvStr = "MAX" 
    end
    if lv > 0 then 
        showLvStr = XUiHelper.GetText("Maverick2TalentLv", lv) 
    end
    uiObj:GetObject("TxtSkillLv").text = showLvStr

    -- 升级消耗
    uiObj:GetObject("PanelCost").gameObject:SetActiveEx(not isMax)
    if not isMax then
        local itemIcon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.Maverick2Unit)
        uiObj:GetObject("RImgCostIcon"):SetRawImage(itemIcon)
        uiObj:GetObject("TxtCostCnt").text = isEnoughLvUp and tostring(needUnit) or string.format("<color=#C64141FF>%s</color>", needUnit)
    end

    -- 点击事件
    XUiHelper.RegisterClickEvent(self, talentGo, function()
        self:OpenTalentDetail(groupCfg)
    end)
end

-- 更新剩余点数
function XUiMaverick2Talent:UpdateRemainUnitCnt()
    local unitCnt = XDataCenter.Maverick2Manager.GetRemainUnitCnt(self.RobotId)
    self.TxtTalentUnit.text = XUiHelper.GetText("Maverick2RemainUnitCount", unitCnt)
end

-- 更新解锁进度
function XUiMaverick2Talent:UpdateUnlockProgress()
    local unlockCnt = 0
    for index, isUnlock in pairs(self.UnLockLineIndexDic) do
        if isUnlock then
            unlockCnt = unlockCnt + 1
        end
    end
    local allCnt = #self.TreeCfgs
    local lineHeight = self.GridSkillLine.rect.height
    local spacing = self.PanelContent:GetComponent("VerticalLayoutGroup").spacing

    local width = self.ProgressBg.rect.width
    local height = (allCnt - 1) * (lineHeight + spacing) + 0.5 * lineHeight
    local unlockHeight = (unlockCnt - 1) * (lineHeight + spacing) + 0.5 * lineHeight
    self.ProgressBg.sizeDelta = CS.UnityEngine.Vector2(width, height)
    self.Progress.fillAmount = unlockHeight / height
end

---------------------------------------- 天赋列表 end ----------------------------------------

-- 打开天赋详情
function XUiMaverick2Talent:OpenTalentDetail(groupCfg)
    self.BtnCloseSkillPopup.gameObject:SetActiveEx(true)
    self.PanelSkillPopup.gameObject:SetActiveEx(true)
    self.SelectGroupCfg = groupCfg
    self:UpdateTalentDetail()
end

-- 刷新天赋详情
function XUiMaverick2Talent:UpdateTalentDetail()
    local groupCfg = self.SelectGroupCfg
    local lvConfigs = XMaverick2Configs.GetTalentLvConfigs(groupCfg.TalentId)
    local lv = XDataCenter.Maverick2Manager.GetTalentLv(self.RobotId, groupCfg.TalentGroupId, groupCfg.TalentId)
    local isMax = lv == #lvConfigs
    local icon = lv == 0 and lvConfigs[1].Icon or lvConfigs[lv].Icon -- 无0级配置表，使用一级的图标配置
    self.IsEnoughLvUp = false

    -- 技能图标和名称
    self.RImgSkillIcon:SetRawImage(icon)
    self.TxtSkillName.text = groupCfg.Name

    -- 技能等级
    local isActive = lv > 0
    self.TxtSkillUnActive.gameObject:SetActiveEx(not isActive)
    self.TxtSkillLevel.gameObject:SetActiveEx(isActive)
    if isActive then
        self.TxtSkillLevel.text = tostring(lv)
    end

    -- 技能描述
    local descColor1 = lv == 1 and ACTIVE_COLOR or UNACTIVE_COLOR
    self.TxtSkillDes1.text = lvConfigs[1].Desc
    self.TxtSkillDes1.color = XUiHelper.Hexcolor2Color(descColor1)
    self.TxtPosA1.color = XUiHelper.Hexcolor2Color(descColor1)

    local showLv2 = lvConfigs[2] ~= nil
    self.TxtSkillDes2.gameObject:SetActiveEx(showLv2)
    if showLv2 then
        local descColor2 = lv == 2 and ACTIVE_COLOR or UNACTIVE_COLOR
        self.TxtSkillDes2.text = lvConfigs[2].Desc
        self.TxtSkillDes2.color = XUiHelper.Hexcolor2Color(descColor2)
        self.TxtPosA2.color = XUiHelper.Hexcolor2Color(descColor2)
    end

    local showLv3 = lvConfigs[3] ~= nil
    self.TxtSkillDes3.gameObject:SetActiveEx(showLv3)
    if showLv3 then
        local descColor3 = lv == 3 and ACTIVE_COLOR or UNACTIVE_COLOR
        self.TxtSkillDes3.text = lvConfigs[3].Desc
        self.TxtSkillDes3.color = XUiHelper.Hexcolor2Color(descColor3)
        self.TxtPosA3.color = XUiHelper.Hexcolor2Color(descColor3)
    end

    -- 是否可以升级下一级
    local needUnit = 0
    local isLock = false
    local desc = nil
    if not isMax then
        local nextLvCfg = lvConfigs[lv+1]
        needUnit = nextLvCfg.NeedUnit
        local unitCnt = XDataCenter.Maverick2Manager.GetRemainUnitCnt(self.RobotId)
        self.IsEnoughLvUp = unitCnt >= needUnit

        if nextLvCfg.Condition ~= 0 then
            isLock = XConditionManager.CheckCondition(nextLvCfg.Condition)
            if isLock then 
                desc = nextLvCfg.UnlockTips
            end
        end
    end

    -- 天赋组解锁提示
    local treeCfg = XMaverick2Configs.GetTalentTreeConfig(self.RobotId, groupCfg.TalentGroupId)
    local assignUnit = XDataCenter.Maverick2Manager.GetAssignActiveUnitCnt(self.RobotId)
    local mentalLv = XDataCenter.Maverick2Manager.GetMentalLv()
    if mentalLv < treeCfg.NeedMentalLv or assignUnit < treeCfg.NeedUnit then
        isLock = true
        if lv > 0 then
            desc = XUiHelper.GetText("Maverick2TalentUnEffect")
        else
            desc = XUiHelper.GetText("Maverick2TalentLock")
        end
    end

    -- 解锁提示
    self.TxtSkillUnlockTips.gameObject:SetActiveEx(isLock)
    if isLock then
        self.TxtSkillUnlockTips.text = desc
    end

    -- 重置按钮
    self.BtnResetSkill.gameObject:SetActiveEx(not isLock and isActive)

    -- 升级按钮
    local showLvUp = not isLock and not isMax
    self.BtnLvUpSkill.gameObject:SetActiveEx(showLvUp)
    if showLvUp then
        local itemIcon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.Maverick2Unit)
        self.RImgCostIcon:SetRawImage(itemIcon)
        self.TxtCostCnt.text = self.IsEnoughLvUp and tostring(needUnit) or string.format("<color=#C64141FF>%s</color>", needUnit)
        local btnName = lv > 0 and XUiHelper.GetText("Upgrade") or XUiHelper.GetText("Active")
        self.BtnLvUpSkill:SetName(btnName)
    end
end

-- 关闭天赋详情
function XUiMaverick2Talent:CloseTalentDetail()
    self.BtnCloseSkillPopup.gameObject:SetActiveEx(false)
    self.PanelSkillPopup.gameObject:SetActiveEx(false)
end

-- 点击升级单个天赋
function XUiMaverick2Talent:OnClickTalentLevelUp()
    if not self.IsEnoughLvUp then
        XUiManager.TipText("Maverick2TalentLvUpNoEnough")
        return
    end

    XDataCenter.Maverick2Manager.RequestUpgradeTalent(self.RobotId, self.SelectGroupCfg.TalentGroupId, self.SelectGroupCfg.TalentId, function()
        self.LvUpTalentId = self.SelectGroupCfg.TalentId
        self:UpdateTalentLineList()
        self:UpdateTalentDetail()
    end)
end

-- 点击重置单个天赋
function XUiMaverick2Talent:OnClickTalentReset()
    XDataCenter.Maverick2Manager.RequestResetSingleTalent(self.RobotId, self.SelectGroupCfg.TalentGroupId, self.SelectGroupCfg.TalentId, function()
        self:UpdateTalentLineList()
        self:UpdateTalentDetail()
    end)
end

-- 点击心智单元图标
function XUiMaverick2Talent:OnClickIconUnit()
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.ItemId.Maverick2Unit)
end

-- 显示天赋界面
function XUiMaverick2Talent:ShowPanelTalent(isShow)
    self.PanelDrag.gameObject:SetActiveEx(isShow)
    self.PanelAllTalent.gameObject:SetActiveEx(isShow)
    self.PanelSkillList.gameObject:SetActiveEx(isShow)
    self.PanelButton.gameObject:SetActiveEx(isShow)
    self.BtnExchange.gameObject:SetActiveEx(isShow)
end