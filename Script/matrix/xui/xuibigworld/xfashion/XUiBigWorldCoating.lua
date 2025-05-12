---@class XUiBigWorldCoating : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _DisplayController XUiModelDisplayController
---@field _PanelFashion XUiPanelBWCoating
---@field _PanelHead XUiPanelBWCoating
local XUiBigWorldCoating = XLuaUiManager.Register(XLuaUi, "UiBigWorldCoating")

local XUiModelDisplayController = require("XUi/XUiCommon/XUiModelDisplay/XUiModelDisplayController")
local XUiPanelBWCoating = require("XUi/XUiBigWorld/XFashion/Panel/XUiPanelBWCoating")

local TabType = {
    Character = 1,
    Weapon = 2,
    Head = 3,
}

local VirtualCamera = {
    Normal = 1,
    Near = 2,
}

function XUiBigWorldCoating:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldCoating:OnStart(characterId, typeIndex)
    self._CharacterId = characterId
    self:InitView(typeIndex or TabType.Character)
end

function XUiBigWorldCoating:InitUi()
    self._ModelIdKey = "BigWorldCoating"
    ---@type XUiButtonGroup
    self.PanelTagGroup:Init(
            {
                self.BtnTogCharacter,
                self.BtnTogWeapon,
                self.BtnTogHead,
            }, function(tabIndex)
                self:OnClickTabCallBack(tabIndex)
            end)
    
    self.BtnCloseFilter.gameObject:SetActiveEx(false)
    self:InitUiModel()
    
    self._PanelFashion = XUiPanelBWCoating.New(self.ScrollFashionList, self, TabType.Character)
    --self._PanelWeapon = XUiPanelBWCoating.New(self.ScrollWeaponList, self, TabType.Weapon)
    self._PanelHead = XUiPanelBWCoating.New(self.ScrollHeadPortrait, self, TabType.Head)
    
    self.BanParent.gameObject:SetActiveEx(false)
    self.PanelUnOwed.gameObject:SetActiveEx(false)
    self.BtnFashionUnLock.gameObject:SetActiveEx(false)
    self.PanelHeadLock.gameObject:SetActiveEx(false)
    self.PanelCharacterFilter.gameObject:SetActiveEx(false)
    
    self._Drag = self.PanelDrag.gameObject:GetComponent(typeof(CS.XDrag))
end

function XUiBigWorldCoating:InitCb()
    self.BtnBack.CallBack = handler(self, self.Close)
    
    self.BtnLensIn.CallBack = handler(self, self.OnBtnLensInClick)
    self.BtnLensOut.CallBack = handler(self, self.OnBtnLensOutClick)
    self.BtnUse.CallBack = handler(self, self.OnBtnUseClick)
    self.BtnCharacterFilter.CallBack = handler(self, self.OnBtnCharacterFilterClick)
    self.BtnCloseFilter.CallBack = handler(self, self.OnBtnCloseFilterClick)

    XUiHelper.RegisterSliderChangeEvent(self, self.SliderCharacter, self.OnSliderCharacterChanged)
end

function XUiBigWorldCoating:InitView(typeIndex)
    self._CharacterIds = XMVCA.XBigWorldCharacter:GetAllUnlockIdsWithoutCommandant()
    self.PanelTagGroup:SelectIndex(typeIndex)
end

function XUiBigWorldCoating:OnClickTabCallBack(tabIndex)
    if self._TabTypeIndex == tabIndex then
        return
    end
    self._TabTypeIndex = tabIndex
    self:OnSelectCharacter(self._CharacterId)
end

function XUiBigWorldCoating:OnSelectCharacter(characterId)
    if self._CharacterId and self._CharacterId ~= characterId then
        self.PanelEffectHuanren.gameObject:SetActiveEx(false)
        self.PanelEffectHuanren.gameObject:SetActiveEx(true)
    end
    self._CharacterId = characterId
    if self._TabTypeIndex == TabType.Character then
        self:UpdateFashionList()
    elseif self._TabTypeIndex == TabType.Weapon then
        self:UpdateWeaponList()
    elseif self._TabTypeIndex == TabType.Head then
        self:UpdateHeadList()
    end
    self:UpdateCamera(VirtualCamera.Normal)
    self:UpdateFashionStatus()
    self:UpdateCharacterModel()
end

function XUiBigWorldCoating:UpdateCharacterModel()
    local fashionId = self._FashionId
    local uiModelId = XMVCA.XBigWorldCharacter:GetUiModelIdByFashionId(fashionId)
    local modelUrl = XMVCA.XBigWorldResource:GetModelUrl(uiModelId)
    local controller = XMVCA.XBigWorldResource:GetModelControllerUrl(uiModelId)
    if self._DisplayController:IsModelExist(self._ModelIdKey) then
        self._DisplayController:ChangeModelComponent(self._ModelIdKey, 0, modelUrl, controller)
    else
        self._DisplayController:AddSingleModel(self._ModelIdKey, modelUrl, controller)
    end
    local animaName = XMVCA.XBigWorldResource:GetDlcUiDefaultAnimationName(uiModelId)
    self._DisplayController:PlayAnimation(self._ModelIdKey, animaName)
    local model = self._DisplayController:GetModelObject(self._ModelIdKey, 0)
    if model then
        self._Drag.Target = model.transform
    end
end

function XUiBigWorldCoating:UpdateFashionList()
    self._FashionList = XMVCA.XBigWorldCharacter:GetUnlockFashionList(self._CharacterId)
    self._FashionId = self._FashionList[1]
    
    self._PanelFashion:RefreshView(self._CharacterId, self._FashionList, self._FashionId)
    --self._PanelWeapon:Close()
    self._PanelHead:Close()
end

function XUiBigWorldCoating:UpdateWeaponList()
    XLog.Error("未支持武器展示!")
end

function XUiBigWorldCoating:UpdateHeadList()
    self._HeadList = XMVCA.XBigWorldCharacter:GetUnlockHeadList(self._CharacterId)
    self._HeadInfo = self._HeadList[1]
    
    self._PanelFashion:Close()
    --self._PanelWeapon:Close()
    self._PanelHead:RefreshView(self._CharacterId, self._HeadList, self._HeadList[1])
end

function XUiBigWorldCoating:OnSelectItem(type, select)
    if type == TabType.Character then
        self._FashionId = select
        self:UpdateCharacterModel()
    elseif type == TabType.Weapon then
    elseif type == TabType.Head then
        self._HeadInfo = select
    end

    self:UpdateFashionStatus()
    self:UpdateCamera(VirtualCamera.Normal)
end

function XUiBigWorldCoating:UpdateFashionStatus()
    local str = ""
    local intro, title, desc = "", "", ""
    local used = false
    if self._TabTypeIndex == TabType.Character then
        local template = XDataCenter.FashionManager.GetFashionTemplate(self._FashionId)
        str = template.Name
        intro = CsXTextManagerGetText("UiFashionIntroFashion")
        title = XGoodsCommonManager.GetGoodsDescription(self._FashionId)
        desc = XGoodsCommonManager.GetGoodsWorldDesc(self._FashionId)
        used = self._FashionId == XMVCA.XBigWorldCharacter:GetFashionId(self._CharacterId)
    elseif self._TabTypeIndex == TabType.Weapon then
        
    elseif self._TabTypeIndex == TabType.Head then
        if self._HeadInfo.HeadFashionType == XFashionConfigs.HeadPortraitType.Liberation then
            str = CS.XTextManager.GetText("FashionHeadLiberation")
        else
            local template = XDataCenter.FashionManager.GetFashionTemplate(self._HeadInfo.HeadFashionId)
            str = template.Name
        end
        intro = nil --CsXTextManagerGetText("UiFashionIntroHeadPortrait")
        desc = nil--XDataCenter.FashionManager.GetFashionHeadUnlockConditionDesc(self._HeadInfo.HeadFashionType, self._HeadInfo.HeadFashionId)
        used = XMVCA.XBigWorldCharacter:CheckHeadUsing(self._CharacterId, self._HeadInfo.HeadFashionId, self._HeadInfo.HeadFashionType)
    end
    self.TxtTipTitle.transform.parent.gameObject:SetActiveEx(not string.IsNilOrEmpty(intro)) 
    self.TxtTipTitle.text = intro
    self.TxtFashionName.text = str
    self.TxtIntroTitle.gameObject:SetActiveEx(not string.IsNilOrEmpty(title))
    self.TxtIntroTitle.text = title

    self.TxtIntroDesc.gameObject:SetActiveEx(not string.IsNilOrEmpty(desc))
    self.TxtIntroDesc.text = desc
    self.BtnUse.gameObject:SetActiveEx(not used)
    self.BtnUsed.gameObject:SetActiveEx(used)
end

function XUiBigWorldCoating:InitUiModel()
    local uiModelRoot = self.UiModelGo.transform
    self._DisplayController = XUiModelDisplayController.New(uiModelRoot:FindTransform("PanelRoleModel"), true)

    local vRoot = uiModelRoot:FindTransform("VCameraRoot")
    self._VirtualCameraDict = {
        [VirtualCamera.Normal] = vRoot.transform:Find("VCameraNormal"),
        [VirtualCamera.Near] = vRoot.transform:Find("VCameraNear"),
    }
    self.PanelEffectHuanren = uiModelRoot:Find("UiNearRoot/PanelRoleModel/PanelEffectHuanren")
    if self.PanelEffectHuanren then
        self.PanelEffectHuanren.gameObject:SetActiveEx(false)
    end
    self:OnSliderCharacterChanged()
end

function XUiBigWorldCoating:UpdateCamera(state)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    for s, vCamera in pairs(self._VirtualCameraDict) do
        vCamera.gameObject:SetActiveEx(s == state)
    end
    self.BtnLensIn.gameObject:SetActiveEx(state == VirtualCamera.Near)
    self.BtnLensOut.gameObject:SetActiveEx(state == VirtualCamera.Normal)
end

function XUiBigWorldCoating:OnBtnLensInClick()
    self:UpdateCamera(VirtualCamera.Normal)
end

function XUiBigWorldCoating:OnBtnLensOutClick()
    self:UpdateCamera(VirtualCamera.Near)
end

function XUiBigWorldCoating:OnBtnUseClick()
    local charId = self._CharacterId
    local cb = function()
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("ChangeSuccessTip"))
        self:OnSelectCharacter(charId)
    end
    if self._TabTypeIndex == TabType.Character then
        XMVCA.XBigWorldCharacter:RequestSetFashion(charId, self._FashionId, cb)
    elseif self._TabTypeIndex == TabType.Head then
        if self._HeadInfo then
            XMVCA.XBigWorldCharacter:RequestSetHeadInfo(charId, self._HeadInfo.HeadFashionId, self._HeadInfo.HeadFashionType, cb)
        end
    end
end

function XUiBigWorldCoating:OnBtnCharacterFilterClick()
    if self._PanelRoleVList and self._PanelRoleVList:IsNodeShow() then
        self:OnBtnCloseFilterClick()
        return
    end
    if not self._PanelRoleVList then
        self.PanelCharacterFilter.gameObject:SetActiveEx(true)
        local url = XMVCA.XBigWorldResource:GetAssetUrl("PanelVList")
        local ui = self.PanelCharacterFilter:LoadPrefab(url)
        self._PanelRoleVList = require("XUi/XUiBigWorld/XRoleRoom/Panel/XUiPanelBWRoleList").New(ui, self, false)
    end
    self.PanelCharacterFilter.gameObject:SetActiveEx(true)
    self.BtnCloseFilter.gameObject:SetActiveEx(true)
    self.PanelTagGroup.gameObject:SetActiveEx(false)
    local teamId = XMVCA.XBigWorldCharacter:GetCurrentTeamId()
    self._PanelRoleVList:RefreshView(teamId, self._CharacterId, 0)
    self._PanelFashion:Close()
    self._PanelHead:Close()
end

function XUiBigWorldCoating:OnBtnCloseFilterClick()
    if self._PanelRoleVList then
        self._PanelRoleVList:Close()
    end
    self.PanelCharacterFilter.gameObject:SetActiveEx(false)
    self.BtnCloseFilter.gameObject:SetActiveEx(false)
    self.PanelTagGroup.gameObject:SetActiveEx(true)
    self:OnSelectCharacter(self._CharacterId)
end

function XUiBigWorldCoating:OnSelectSingle(pos, characterId)
    if self._CharacterId == characterId then
        return
    end
    self._CharacterId = characterId
    self:UpdateFashionList()
    self:OnSelectCharacter(characterId)
    self:OnBtnCloseFilterClick()
end

function XUiBigWorldCoating:OnSliderCharacterChanged()
    local pos = self._VirtualCameraDict[VirtualCamera.Near].position
    self._VirtualCameraDict[VirtualCamera.Near].position = Vector3(pos.x, 1.7 - self.SliderCharacter.value, pos.z)
end