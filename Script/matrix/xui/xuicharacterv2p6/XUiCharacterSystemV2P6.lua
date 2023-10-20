local XUiCharacterSystemV2P6 = XLuaUiManager.Register(XLuaUi, "UiCharacterSystemV2P6")
local XUiPanelModelV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiPanelModelV2P6")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiCharacterSystemV2P6:OnAwake()
    self.OpenChildStack = XStack.New()
    self.CurCharacter = nil --所有的子界面都通过该字段同步、获取角色
    self.FilterCurSelectTagBtnName = nil --同步子界面的筛选器标签。子界面切换了标签后，成员界面的标签也要切换
    self:SetPanelAsset(XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    
    self:InitModel()
    self:InitButton()

    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_CHANGE_SYNC_SYSTEM, self.SetCurCharacter, self)
end

function XUiCharacterSystemV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "UiCharacterSystemV2P6")
end

function XUiCharacterSystemV2P6:InitModel()
    -- 公用的model
    ---@type XUiPanelModelV2P6
    self.PanelModel = XUiPanelModelV2P6.New(self.UiModelGo, self) -- 3d镜头
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelModel.PanelRoleModel, self.Name, nil, true, nil, true)
end

-- 子界面通过该接口同步资源栏物品
function XUiCharacterSystemV2P6:SetPanelAsset(...)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, ...)
end

-- 子界面通过该接口设置相机
function XUiCharacterSystemV2P6:SetCamera(targetIndex)
    self.PanelModel:SetCamera(targetIndex)
end

-- 子界面通过该接口同步角色
function XUiCharacterSystemV2P6:SetCurCharacter(char)
    if not char then
        return
    end

    -- 如果跳转出去抽出了角色，回来需要刷新数据。因为如果不刷新，使用的还是筛选器缓存的数据，筛选器的数据是导入时的数据，不是最新的
    -- 并且监听获取新角色的数据只在Onenable的时候注册了，抽卡的时候是无法监听刷新的。只能通过返回来时触发OnEnable，Onenable再次SetCurCharacter的时候刷新
    local isFragment = XMVCA.XCharacter:CheckIsFragment(char.Id)  
    if not isFragment then
        self.CurCharacter = XMVCA.XCharacter:GetCharacter(char.Id)
        return
    end

    self.CurCharacter = char
end

-- 子界面通过该接口同步3d角色模型
function XUiCharacterSystemV2P6:RefreshRoleModel(cb)
    if not self.CurCharacter then
        return
    end

    self.PanelModel.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.PanelModel.ImgEffectHuanren1.gameObject:SetActiveEx(false)

    local subCb = function (model)
        -- 切换特效 只有换人才播放
        if model ~= self.CurModelTransform then
            if XMVCA.XCharacter:GetIsIsomer(self.CurCharacter.Id) then
                self.PanelModel.ImgEffectHuanren1.gameObject:SetActiveEx(true)
            else
                self.PanelModel.ImgEffectHuanren.gameObject:SetActiveEx(true)
            end
        end

        -- 适配看特效球text的相机位置
        self.PanelModel:FixUiCameraMainToEffectBall()
        self.CurModelTransform = model
        
        if cb then
            cb(model)
        end
    end
   
    --MODEL_UINAME对应UiModelTransform表，设置模型位置
    self.RoleModelPanel:UpdateCharacterModel(self.CurCharacter.Id, self.PanelRoleModel, self.Name, subCb)
end

function XUiCharacterSystemV2P6:OnStart(initCharId, skipArgs)
    initCharId = XRobotManager.CheckIdToCharacterId(initCharId)
    self.InitCharId = initCharId
    self.SkipArgs = skipArgs
end

function XUiCharacterSystemV2P6:OnEnable()
    if self.IsUiInit then
        return
    end
    -- 整个生命周期只触发一次
    if not self.IsUiInit then
        if self.SkipArgs then
            self:OpenBySkipArgs()
        else
            self:OpenChildUi("UiCharacterV2P6")
        end
    end

    self.IsUiInit = true
end

function XUiCharacterSystemV2P6:OnDisable()
    self.PanelModel.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.PanelModel.ImgEffectHuanren1.gameObject:SetActiveEx(false)
end

function XUiCharacterSystemV2P6:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_CHANGE_SYNC_SYSTEM, self.SetCurCharacter, self)
end

function XUiCharacterSystemV2P6:OpenBySkipArgs()
    local arg = self.SkipArgs
    if arg == XEnumConst.CHARACTER.SkipEnumV2P6.Character then
        self:OpenChildUi("UiCharacterV2P6")
    elseif arg == XEnumConst.CHARACTER.SkipEnumV2P6.PropertyLvUp then
        self:OpenChildUi("UiCharacterPropertyV2P6")
    elseif arg == XEnumConst.CHARACTER.SkipEnumV2P6.PropertyGrade then
        self:OpenChildUi("UiCharacterPropertyV2P6", 2)
    elseif arg == XEnumConst.CHARACTER.SkipEnumV2P6.PropertySkill then
        self:OpenChildUi("UiCharacterPropertyV2P6", 3)
    else
        self:OpenChildUi("UiCharacterV2P6")
        XLog.Error("SkipArgs传入的枚举错误 查看 XEnumConst.CHARACTER.SkipEnumV2P6，传入", self.SkipArgs)
    end
end

function XUiCharacterSystemV2P6:OpenChildUi(uiname, ...)
    self:OpenOneChildUi(uiname, ...)
    -- 打开子界面时转正model
    if self.OpenChildStack:Peek() == uiname then
        return
    end
    self.OpenChildStack:Push(uiname)

    -- 打开子ui时转正角色
    self:ReturnModelToInitRotation()
end

-- 回正角色转向
function XUiCharacterSystemV2P6:ReturnModelToInitRotation()
    local targetModelTransform = self.RoleModelPanel:GetTransform()
    if targetModelTransform then
        targetModelTransform:DOLocalRotate(Vector3.zero, 0.4)
    end
end

function XUiCharacterSystemV2P6:OpenLastChildUi()
    if not self.OpenChildStack or self.OpenChildStack:Count() < 2 then
        return
    end
    local uiName = self.OpenChildStack:Peek()
    self.OpenChildStack:Pop()
    uiName = self.OpenChildStack:Peek()

    self:OpenChildUi(uiName)
end

function XUiCharacterSystemV2P6:OnBtnBackClick()
    -- 给子界面复写backBtn
    if self.BackTrigger then
        self.BackTrigger()
        self.BackTrigger = nil
        return
    end

    -- 子界面关闭时，打开上一次打开的子界面
    if self.OpenChildStack and self.OpenChildStack:Count() >= 2 then
        self:OpenLastChildUi()
        return
    end
 
    self:Close()
end

function XUiCharacterSystemV2P6:SetBackTrigger(cb)
    self.BackTrigger = cb
end

return XUiCharacterSystemV2P6
