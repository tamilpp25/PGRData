local XUiCharacterPropertyV2P6 = XLuaUiManager.Register(XLuaUi, "UiCharacterPropertyV2P6")

function XUiCharacterPropertyV2P6:OnAwake()
    self:InitPanelInfo()
    self:InitButton()
    self:InitFilter()
end

function XUiCharacterPropertyV2P6:InitPanelInfo()
    -- 顺序要合Ui上的按钮顺序一致s
    self.PanelProxyDatas = 
    {
        {Name = "XPanelCharacterLevelV2P6", ParentTrans = "PanelCharLevel", AssetPath = CS.XGame.ClientConfig:GetString("PanelCharLevelV2P6")},
        {Name = "XPanelCharacterGradeV2P6", ParentTrans = "PanelCharGrade", AssetPath = CS.XGame.ClientConfig:GetString("PanelCharGradeV2P6"),
            CheckOpenFun = function ()
                return XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterGrade)
            end
        },
        {Name = "XPanelCharacterSkillV2P6", ParentTrans = "PanelCharSkill", AssetPath = CS.XGame.ClientConfig:GetString("PanelCharSkillV2P6"),
            CheckOpenFun = function ()
                return XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterSkill)
            end
        },
    }

    -- require("XUi/XUiCharacterV2P6/Grid/XPanelCharacterLevelV2P6")
    -- require("XUi/XUiCharacterV2P6/Grid/XPanelCharacterGradeV2P6")
    -- require("XUi/XUiCharacterV2P6/Grid/XPanelCharacterSkillV2P6")
    -- for k, panelInfo in pairs(self.PanelProxyDatas) do
    --     local proxy = require("XUi/XUiCharacterV2P6/PanelChildUi/"..panelInfo.Name)
    --     local path = panelInfo.AssetPath
    --     local ui = self[panelInfo.ParentTrans]:LoadPrefab(path)
    --     ui.gameObject:SetActiveEx(false)
    --     self[panelInfo.Name] = proxy.New(ui, self)
    -- end
end

function XUiCharacterPropertyV2P6:InitFilter()
    self.PanelFilter = XMVCA.XCommonCharacterFilter:InitFilter(self.PanelCharacterFilter, self)
    self.PanelCharacterFilter.gameObject:SetActiveEx(false)
    local onSeleCb = function (character, index, grid, isFirstSelect)
        if not character then
            return
        end
        self:OnSelectCharacter(character)
    end

    local onTagClickCb = function (targetBtn)
        self.ParentUi.FilterCurSelectTagBtnName = targetBtn.gameObject.name

        local enumId = XGlobalVar.BtnUiCharacterSystemV2P6[self.ParentUi.FilterCurSelectTagBtnName]
        XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, enumId, self.ParentUi.CurCharacter and self.ParentUi.CurCharacter.Id)
    end
    
    self.PanelFilter:InitData(onSeleCb, onTagClickCb)
    local list = XMVCA.XCharacter:GetOwnCharacterList()
    self.DataSource = list
    self.PanelFilter:ImportList(list)
    self.PanelFilter:RefreshList()
    self.PanelFilter:Close()
end

function XUiCharacterPropertyV2P6:InitButton()
    local btns = {self.BtnTabLevel, self.BtnTabGrade, self.BtnTabSkill}
    self.PanelPropertyButtons:Init(btns, function(index)
        self:OnSelectTab(index)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnExchange, self.OnBtnExchangeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseFilter, self.HideFilter)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiCharacterPropertyV2P6:OnStart(openIndex)
    self.OpenIndex = openIndex
end

function XUiCharacterPropertyV2P6:OnEnable()
    local initCharId = self.ParentUi.InitCharId
    local skipArgs = self.ParentUi.SkipArgs
    if initCharId and skipArgs and not self.ParentUi.IsUiInit then -- 跳转进入属性培养界面  同步更改父界面模型
        local char = XMVCA.XCharacter:GetCharacter(initCharId)
        self.ParentUi:SetCurCharacter(char) -- 如果玩家未拥有该角色 跳转进来，这一步的代码是无效的，父界面不会被设置一个有效角色
        self.ParentUi:RefreshRoleModel()
    end

    if self.ParentUi.CurCharacter then
        -- self.PanelFilter:DoSelectCharacter(self.ParentUi.CurCharacter.Id)
    else
        -- 一个判空保底 如果父界面没有角色  选中第一个就好.可能出现的情况：跳转到培养的角色，玩家未拥有
        local char = self.DataSource[1]
        self.ParentUi:SetCurCharacter(char)
        self.ParentUi:RefreshRoleModel()
    end
    self.PanelPropertyButtons:SelectIndex(self.OpenIndex or self.CurSelectIndex or 1)
    self.OpenIndex = nil -- 用完就丢弃
    self:RefreshCurShowUi()
    self.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.Train)

    --顺便附加拖拽模型
    self.PanelDrag.Target = self.ParentUi.RoleModelPanel:GetTransform()
end

function XUiCharacterPropertyV2P6:OnDisable()
    XMVCA.XFavorability:StopCv()
end

-- 刷新当前展示的内容
function XUiCharacterPropertyV2P6:RefreshCurShowUi()
    self:RefreshCurPanel()
    self:RefreshTabBtns()
end

function XUiCharacterPropertyV2P6:RefreshCurPanel()
    local panelInfo = self.PanelProxyDatas[self.CurSelectIndex]
    if not panelInfo then
        return
    end
    self:GetPanel(self.CurSelectIndex):RefreshUiShow()
end

function XUiCharacterPropertyV2P6:RefreshTabBtns()
    local charId = self.ParentUi.CurCharacter.Id
    local character = self.ParentUi.CurCharacter

    -- 最大等级
    local isMaxLevel = XMVCA.XCharacter:IsMaxLevel(charId)
    self.BtnTabLevel:ShowTag(isMaxLevel)
    
    local isMaxGrade = XMVCA.XCharacter:IsMaxCharGrade(character)
    self.BtnTabGrade:ShowTag(isMaxGrade)
    
    local isCharAllSkillMax = XMVCA.XCharacter:CheckCharacterAllSkillMax(charId)
    self.BtnTabSkill:ShowTag(isCharAllSkillMax)

    -- 判断是否解锁
    -- 不要直接调用SetDisable接口 会覆盖buttonGroup的选中状态，即使setDisable为false
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterGrade, nil, true) then
        self.BtnTabGrade:SetDisable(true)
    else -- 后面这段逻辑是预计会出现在当前界面刷新的时候，button的状态由disable转为normal
        if self.BtnTabGrade.ButtonState == CS.UiButtonState.Disable then
            self.BtnTabGrade.ButtonState = CS.UiButtonState.Normal
        end
    end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterSkill, nil, true)then
        self.BtnTabSkill:SetDisable(true)
    else
        if self.BtnTabSkill.ButtonState == CS.UiButtonState.Disable then
            self.BtnTabSkill.ButtonState = CS.UiButtonState.Normal
        end
    end

    -- 红点
    self.BtnTabLevel:ShowReddot(XRedPointManager.CheckConditions({XRedPointConditions.Types.CONDITION_CHARACTER_LEVEL}, charId))
    self.BtnTabGrade:ShowReddot(XRedPointManager.CheckConditions({XRedPointConditions.Types.CONDITION_CHARACTER_GRADE}, charId))
    self.BtnTabSkill:ShowReddot(XRedPointManager.CheckConditions({XRedPointConditions.Types.CONDITION_CHARACTER_SKILL, XRedPointConditions.Types.CONDITION_CHARACTER_NEW_ENHANCESKILL_TIPS}, charId))
end

function XUiCharacterPropertyV2P6:OnSelectCharacter(character)
    if self.ParentUi.CurCharacter == character then
        return
    end

    local tagName = self.PanelFilter:GetCurSelectTagName()
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_CHANGE_SYNC_SYSTEM, character, tagName)
    local cb = function (model)
        self.PanelDrag.Target = model.transform
    end
    self.ParentUi:RefreshRoleModel(cb)
    
    self:RefreshCurShowUi()
    self:HideFilter()
end

function XUiCharacterPropertyV2P6:CheckPanelExsit(index)
    local panelInfo = self.PanelProxyDatas[index]
    if not self[panelInfo.Name] then
        return false
    end
    return true
end

function XUiCharacterPropertyV2P6:GetPanel(index)
    local panelInfo = self.PanelProxyDatas[index]
    if not self[panelInfo.Name] then
        local proxy = require("XUi/XUiCharacterV2P6/PanelChildUi/"..panelInfo.Name)
        local path = panelInfo.AssetPath
        local ui = self[panelInfo.ParentTrans]:LoadPrefab(path)
        ui.gameObject:SetActiveEx(false)
        self[panelInfo.Name] = proxy.New(ui, self)
    end
    return self[panelInfo.Name]
end

function XUiCharacterPropertyV2P6:OnSelectTab(index)
    local checkOpenFun = self.PanelProxyDatas[index].CheckOpenFun
    if checkOpenFun and not checkOpenFun() then
        return
    end

    for k, panelInfo in pairs(self.PanelProxyDatas) do
        if k == index then
            self:GetPanel(k):Open()
        else -- 减少耗时 如果面板还没生成 不需要调用关闭接口
            if self:CheckPanelExsit(k) then
                self:GetPanel(k):Close()
            end
        end
    end

    self.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.Train)
    self.ParentUi:SetBackTrigger(nil)
    self.CurSelectIndex = index
    self:RefreshCurShowUi()
end

function XUiCharacterPropertyV2P6:HideFilter()
    self.PanelCharacterFilter.gameObject:SetActiveEx(false)
    self.PanelPropertyButtons.gameObject:SetActiveEx(true)
    self.PanelFilter:Close()
end

function XUiCharacterPropertyV2P6:OnBtnExchangeClick()
    self:ShowOrHideFilter()
end

function XUiCharacterPropertyV2P6:ShowOrHideFilter()
    local activeSelf = nil
    activeSelf = self.PanelCharacterFilter.gameObject.activeSelf
    self.PanelCharacterFilter.gameObject:SetActiveEx(not activeSelf)
    -- 打开的时候刷新
    local charId = self.ParentUi.CurCharacter.Id
    local syncTag = self.ParentUi.CurSyncTagName -- 可以每次都同步  因为该界面筛选器本身也会发送同步信息
    if not activeSelf then
        self.PanelFilter:Open()
        self.PanelFilter:DoSelectTag(syncTag or "BtnAll", nil, charId)
        XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnExchange, charId)
    else
        XMVCA.XCharacter:BuryingUiCharacterAction(self.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnCloseFilter, charId)
        self.PanelFilter:Close()
    end

    activeSelf = self.PanelPropertyButtons.gameObject.activeSelf
    self.PanelPropertyButtons.gameObject:SetActiveEx(not activeSelf)
end

return XUiCharacterPropertyV2P6
