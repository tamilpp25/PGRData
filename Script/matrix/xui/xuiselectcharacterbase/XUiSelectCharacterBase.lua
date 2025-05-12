local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiSelectCharacterBase
local XUiSelectCharacterBase = XLuaUiManager.Register(XLuaUi, "UiSelectCharacterBase")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiSelectCharacterBase:Ctor()
    ---@type XCharacter
    self.CurCharacter = nil
end

function XUiSelectCharacterBase:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self:InitRoleModelPanel()
    self:InitButton()
    self:InitPanelEquip()

    self.ConditionGrids = {}
end

function XUiSelectCharacterBase:InitRoleModelPanel()
    local modelGo = self.UiModelGo
    self.ImgEffectHuanren = modelGo:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = modelGo:FindTransform("ImgEffectHuanren1")
    local PanelRoleModel =  modelGo:FindTransform("PanelRoleModel")
    self.RoleModelPanel = XUiPanelRoleModel.New(PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiSelectCharacterBase:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnTeaching, self.OnBtnTeachingClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFashion, self.OnBtnFashionClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOwnedDetail, self.OnBtnOwnedDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnJoin, self.OnBtnJoinClick)
    XUiHelper.RegisterClickEvent(self, self.BtnQuit, self.OnBtnQuitClick)
end

function XUiSelectCharacterBase:InitFilter()
    self.PanelFilter = XMVCA.XCommonCharacterFilter:InitFilter(self.PanelCharacterFilter, self)
    local onSeleCb = function (character, index, grid, isFirstSelect)
        if not character then
            return
        end

        self:OnSelectCharacter(character)
    end

    local onTagClickCb = function ()
        self:OnTagClickCb()
    end

    self.PanelFilter:InitData(onSeleCb, onTagClickCb, nil, self:GetRefreshFun(), self:GetGridProxy(), nil, self:GetOverrideSortTable())
    local list = self:GetCharList()
    self.PanelFilter:ImportList(list, self.InitSeleCharId)
end

function XUiSelectCharacterBase:InitPanelEquip()
    self.PanelEquips = XMVCA.XEquip:InitPanelCharInfoWithEquip(self.PanelEquip, self, self)
    self.PanelEquips:InitData()
end

function XUiSelectCharacterBase:OnStart(charId, ...)
    self.InitSeleCharId = charId -- 默认选择的角色
    self:OnStartCb(...)
    self:InitFilter()
end

function XUiSelectCharacterBase:OnEnable()
    self.PanelFilter:RefreshList()

    self:OnEnableCb()
    self.FirstInFin = true
end

function XUiSelectCharacterBase:RefreshModel()
    if not self.CurCharacter then
        return
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)

    local cb = function (model)
        -- 切换特效 只有换人才播放
        if model ~= self.CurModelTransform then
            if XMVCA.XCharacter:GetIsIsomer(self.CurCharacter.Id) then
                self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
            else
                self.ImgEffectHuanren.gameObject:SetActiveEx(true)
            end
        end

        -- 适配看特效球text的相机位置
        self.PanelDrag.Target = model.transform
        self.CurModelTransform = model
    end
   
    --MODEL_UINAME对应UiModelTransform表，设置模型位置
    self.RoleModelPanel:UpdateCharacterModel(self.CurCharacter.Id, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiCharacter, cb)
end

--region 可重写
function XUiSelectCharacterBase:GetCharList()
    return XMVCA.XCharacter:GetOwnCharacterList()
end

function XUiSelectCharacterBase:GetGridProxy()
    return nil
end

function XUiSelectCharacterBase:GetRefreshFun()
    return nil
end

function XUiSelectCharacterBase:GetOverrideSortTable()
    return nil
end

function XUiSelectCharacterBase:OnSelectCharacter(character)
    self.CurCharacter = character
    
    self:RefreshModel()
    self:RefreshCharInfo()
end

function XUiSelectCharacterBase:OnTagClickCb()
    local isEmpty = self.PanelFilter:IsCurListEmpty()
    if isEmpty then
        self.PanelEquips:Close()
    else
        self.PanelEquips:Open()
    end
    self.PanelInfo.gameObject:SetActiveEx(not isEmpty)
    self.MidButtons.gameObject:SetActiveEx(not isEmpty)
end

function XUiSelectCharacterBase:RefreshCharInfo()
    if not self.CurCharacter then
        return
    end
    
    self.PanelEquips:UpdateCharacter(self.CurCharacter.Id)

    self:RefreshMid()
    self:RefreshConditionInfo()
end

function XUiSelectCharacterBase:OnBtnJoinClick()
    self:Close()
end

function XUiSelectCharacterBase:OnBtnQuitClick()
    self:Close()
end

function XUiSelectCharacterBase:RefreshMid()
end

function XUiSelectCharacterBase:RefreshConditionInfo()
end

function XUiSelectCharacterBase:OnStartCb()
end

function XUiSelectCharacterBase:OnEnableCb()
end
--endregion 

function XUiSelectCharacterBase:SetMidButtonActive(flag)
    self.MidButtons.gameObject:SetActiveEx(flag)
end

function XUiSelectCharacterBase:SetPanleConditonActive(flag)
    self.PanelCondition.gameObject:SetActiveEx(flag)
end

function XUiSelectCharacterBase:OnBtnTeachingClick()
    XDataCenter.PracticeManager.OpenUiFubenPractice(self.CurCharacter.Id)
end

function XUiSelectCharacterBase:OnBtnFashionClick()
    XLuaUiManager.Open("UiFashion", self.CurCharacter.Id)
end

function XUiSelectCharacterBase:OnBtnOwnedDetailClick()
    XLuaUiManager.Open("UiCharacterDetail", self.CurCharacter.Id)
end

return XUiSelectCharacterBase
