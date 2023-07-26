local XUiArchiveMonsterDetail = XLuaUiManager.Register(XLuaUi, "UiArchiveMonsterDetail")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local tableInsert = table.insert
local Object = CS.UnityEngine.Object
local Vector3 = CS.UnityEngine.Vector3
local Dropdown = CS.UnityEngine.UI.Dropdown

local FirstIndex = 1

local CameraType = {
    Main = 1,
    Info = 2,
    Setting = 3,
    Skill = 4,
    Zoom = 5,
}

function XUiArchiveMonsterDetail:OnEnable()
    XEventManager.AddEventListener(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER, self.UpdateMonsterUnlock, self)
end

function XUiArchiveMonsterDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER, self.UpdateMonsterUnlock, self)
end

function XUiArchiveMonsterDetail:OnDestroy()
    self.ArchiveMonsterSynopsis:Destroy()
end

function XUiArchiveMonsterDetail:OnAwake()
    self.OperationType = XArchiveConfigs.MonsterDetailUiType.Default
end

-- dataList : XArchiveMonsterEntity list
-- index : number
-- operationType : XArchiveConfigs.MonsterDetailUiType
function XUiArchiveMonsterDetail:OnStart(dataList, index, operationType)
    if operationType == nil then operationType = XArchiveConfigs.MonsterDetailUiType.Default end
    self.OperationType = operationType
    self.Data = dataList and dataList[index]
    self.DataList = dataList

    if not self.Data then
        return
    end

    self.MonsterIndex = index
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:Init()
    XDataCenter.ArchiveManager.ClearMonsterNewTag({ self.Data })
    -- if self.OperationType == XArchiveConfigs.MonsterDetailUiType.Default then
    --     XDataCenter.ArchiveManager.ClearMonsterNewTag({ self.Data })
    -- end
end

function XUiArchiveMonsterDetail:Init()
    self.ArchiveMonsterSynopsis = XUiArchiveMonsterSynopsis.New(self.PanelMonsterSynopsis, self.Data, self)
    self.ArchiveMonsterInfo = XUiArchiveMonsterInfo.New(self.PanelMonsterIntro, self.Data, self)
    self.ArchiveMonsterSetting = XUiArchiveMonsterSetting.New(self.PanelMonsterSet, self.Data, self)
    self.ArchiveMonsterSkill = XUiArchiveMonsterSkill.New(self.PanelMonsterSkill, self.Data, self)
    self.IsInit = true
    self.MosterHideParts = {}
    self.MosterEffects = {}
    self:InitScene3DRoot()
    self:SetButtonCallBack()
    self:InitTypeGroup()
    self:SelectDetailState(XArchiveConfigs.MonsterDetailType.Synopsis)
    self:CheckNextMonsterAndPreMonster()
    self:InitUiDetailByOperationType(self.OperationType)
end

function XUiArchiveMonsterDetail:InitUiDetailByOperationType(operationType)
    self.ArchiveMonsterSynopsis.BtnEvaluate.gameObject:SetActiveEx(operationType == XArchiveConfigs.MonsterDetailUiType.Default)
    self.ArchiveMonsterSynopsis.BtnGroupContent.gameObject:SetActiveEx(operationType == XArchiveConfigs.MonsterDetailUiType.Default)
end

function XUiArchiveMonsterDetail:InitScene3DRoot()
    if self.Scene3DRoot then return end
    self.Scene3DRoot = {}
    self.Scene3DRoot.Transform = self.UiModelGo.transform
    XTool.InitUiObject(self.Scene3DRoot)
    self.CamFar = {
        [CameraType.Zoom] = self.Scene3DRoot.UiCamFarZoom,
        [CameraType.Main] = self.Scene3DRoot.UiCamFarMain,
        [CameraType.Info] = self.Scene3DRoot.UiCamFarMonsterInfo,
        [CameraType.Setting] = self.Scene3DRoot.UiCamFarMonsterSetting,
        [CameraType.Skill] = self.Scene3DRoot.UiCamFarMonsterSkill,
    }
    self.CamNear = {
        [CameraType.Zoom] = self.Scene3DRoot.UiCamNearZoom,
        [CameraType.Main] = self.Scene3DRoot.UiCamNearMain,
        [CameraType.Info] = self.Scene3DRoot.UiCamNearMonsterInfo,
        [CameraType.Setting] = self.Scene3DRoot.UiCamNearMonsterSetting,
        [CameraType.Skill] = self.Scene3DRoot.UiCamNearMonsterSkill,
    }
    self.RoleModelPanel = XUiPanelRoleModel.New(self.Scene3DRoot.PanelModel, "", nil, true)
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderCharacterHight, self.OnSliderCharacterHightChanged)
    self.Scene3DRoot.ImgEffectHuanrenWhite.gameObject:SetActiveEx(false)
    self.Scene3DRoot.ImgEffectHuanrenBlack.gameObject:SetActiveEx(false)
end

function XUiArchiveMonsterDetail:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnScreenShot.CallBack = function()
        self:OnBtnScreenShotClick()
    end
    self.BtnHide.CallBack = function()
        self:OnBtnHideClick()
    end
    self.BtnLensIn.CallBack = function()
        self:OnBtnLensInClick()
    end
    self.BtnLensOut.CallBack = function()
        self:OnBtnLensOutClick()
    end
    self.BtnNext.CallBack = function()
        self:OnBtnNextClick()
    end
    self.BtnLast.CallBack = function()
        self:OnBtnLastClick()
    end
    self.BtnStateWords.onValueChanged:AddListener(function()
        self.CurNpcState = self.BtnStateWords.value + 1
        self:UpdateModel(self.CurType)
    end)
end

function XUiArchiveMonsterDetail:InitTypeGroup()
    self.TypeBtn = {}
    self.MonsterSwitchItem.gameObject:SetActiveEx(false)
    self.CurType = 1
    for k, _ in pairs(self.Data:GetNpcId() or {}) do
        local btn = Object.Instantiate(self.MonsterSwitchItem)
        btn.gameObject:SetActiveEx(true)
        btn.transform:SetParent(self.MonsterSwitch.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        local name = "0" .. k
        btncs:SetName(name or "Null")
        tableInsert(self.TypeBtn, btncs)
    end
    self.MonsterSwitch:Init(self.TypeBtn, function(index) self:SelectType(index, true) end)
    self.MonsterSwitch:SelectIndex(self.CurType)
    self.MonsterSwitch.gameObject:SetActiveEx(#self.TypeBtn >= 2)
end

function XUiArchiveMonsterDetail:UpdateDropdown(index)
    local npcId = self.Data:GetNpcId(index)
    self.MonsterStateList = XArchiveConfigs.GetMonsterTransDataGroup(npcId)
    if self.MonsterStateList then
        self.IsHasScreen = true
    else
        self.IsHasScreen = false
    end
    self.CurNpcState = 1
    self.PanelState.gameObject:SetActiveEx(self.IsHasScreen)
    if not self.IsHasScreen then
        return
    end

    self.BtnStateWords:ClearOptions()
    local tabName = self.MonsterStateList[1] and self.MonsterStateList[1].StateText or ""
    self.BtnStateWords.captionText.text = tabName

    for _, v in pairs(self.MonsterStateList) do
        local op = Dropdown.OptionData()
        op.text = v.StateText or ""
        self.BtnStateWords.options:Add(op)
    end

    self.BtnStateWords.value = 0
end

function XUiArchiveMonsterDetail:SelectType(index, IsUpdateNpcModel)
    self.CurType = index
    if self.DetailType == XArchiveConfigs.MonsterDetailType.Synopsis then
        self.ArchiveMonsterSynopsis:SelectType(index)
    elseif self.DetailType == XArchiveConfigs.MonsterDetailType.Info then
        self.ArchiveMonsterInfo:SelectType(index)
    elseif self.DetailType == XArchiveConfigs.MonsterDetailType.Setting then
        self.ArchiveMonsterSetting:SelectType(index)
    elseif self.DetailType == XArchiveConfigs.MonsterDetailType.Skill then
        self.ArchiveMonsterSkill:SelectType(index)
    end
    if IsUpdateNpcModel then
        self:UpdateDropdown(index)
        self:UpdateModel(index)
    end
end
function XUiArchiveMonsterDetail:UpdateModel(index)
    local func = function(model)
        if not model then return end
        self.PanelDragMid.Target = model.transform
        self.PanelDragLeft.Target = model.transform
        self.PanelDragRight.Target = model.transform
        self.Scene3DRoot.ImgEffectHuanrenBlack.gameObject:SetActiveEx(false)
        self.Scene3DRoot.ImgEffectHuanrenBlack.gameObject:SetActiveEx(true)

    end

    for _, prats in pairs(self.MosterHideParts) do
        if not XTool.UObjIsNil(prats) then
            prats.gameObject:SetActiveEx(true)
        end
    end
    for _, effect in pairs(self.MosterEffects) do
        if not XTool.UObjIsNil(effect) then
            effect.gameObject:SetActiveEx(false)
        end
    end
    self.MosterHideParts = {}
    self.MosterEffects = {}
    local npcId = self.Data:GetNpcId(index)
    local modelId = XArchiveConfigs.GetMonsterModel(npcId)
    local transDatas = XArchiveConfigs.GetMonsterTransDatas(npcId, self.CurNpcState)---yaogai
    local effectDatas = XArchiveConfigs.GetMonsterEffectDatas(npcId, self.CurNpcState)

    self.RoleModelPanel:SetDefaultAnimation(transDatas and transDatas.StandAnime)
    self.RoleModelPanel:UpdateArchiveMonsterModel(modelId, XModelManager.MODEL_UINAME.UiArchiveMonsterDetail, nil, func)
    self.RoleModelPanel:ShowRoleModel()

    if transDatas then
        for _, node in pairs(transDatas.HideNodeName or {}) do
            local parts = self.RoleModelPanel.GameObject:FindTransform(node)
            if not XTool.UObjIsNil(parts) then
                parts.gameObject:SetActiveEx(false)
                tableInsert(self.MosterHideParts, parts)
            else
                XLog.Error("HideNodeName Is Wrong :" .. node)
            end
        end

        -- 材质控制器，怪物皮肤
        if XTool.IsNumberValid(transDatas.ScriptPartId) then
            local t = self.RoleModelPanel.Transform:GetChild(0):GetComponent(typeof(CS.XCharSkinDisplay))
            if not XTool.UObjIsNil(t) then
                t:Revert(transDatas.ScriptPartId)
                t:ToState(transDatas.ScriptPartId, 1)
            else
                XLog.Error("配置了材质参数但是找不到脚本 CS.XCharSkinDisplay, transDatas.ScriptPartId:" .. transDatas.ScriptPartId)
            end
        end
    end

    if effectDatas then
        for node, effectPath in pairs(effectDatas) do
            local parts = self.RoleModelPanel.GameObject:FindTransform(node)
            if not XTool.UObjIsNil(parts) then
                local effect = parts.gameObject:LoadPrefab(effectPath, false)
                if effect then
                    effect.gameObject:SetActiveEx(true)
                    tableInsert(self.MosterEffects, effect)
                end
            else
                XLog.Error("EffectNodeName Is Wrong :" .. node)
            end
        end
    end

end
function XUiArchiveMonsterDetail:SetCameraType(type)
    local camType = (type == XArchiveConfigs.MonsterDetailType.ScreenShot) and
    XArchiveConfigs.MonsterDetailType.Synopsis or type

    for k, _ in pairs(self.CamFar) do
        self.CamFar[k].gameObject:SetActiveEx(k == camType)
    end

    for k, _ in pairs(self.CamNear) do
        self.CamNear[k].gameObject:SetActiveEx(k == camType)
    end
end

function XUiArchiveMonsterDetail:SelectDetailState(type)
    self.DetailType = type
    self:SetCameraType(type)
    self:SelectType(self.CurType, false)
    self.PanelMonsterSynopsis.gameObject:SetActiveEx(type == XArchiveConfigs.MonsterDetailType.Synopsis or
    type == XArchiveConfigs.MonsterDetailType.ScreenShot)

    self.PanelMonsterIntro.gameObject:SetActiveEx(type == XArchiveConfigs.MonsterDetailType.Info)

    self.PanelMonsterSet.gameObject:SetActiveEx(type == XArchiveConfigs.MonsterDetailType.Setting)

    self.PanelMonsterSkill.gameObject:SetActiveEx(type == XArchiveConfigs.MonsterDetailType.Skill)

    self.TopControl.gameObject:SetActiveEx(type ~= XArchiveConfigs.MonsterDetailType.ScreenShot and
    type ~= XArchiveConfigs.MonsterDetailType.Zoom)

    self.PanelAsset.gameObject:SetActiveEx(type ~= XArchiveConfigs.MonsterDetailType.ScreenShot and
    type ~= XArchiveConfigs.MonsterDetailType.Zoom)

    self.PanelDragGroup.gameObject:SetActiveEx(not self.Data:GetIsLockMain())

    self.BtnRight.gameObject:SetActiveEx((not self.Data:GetIsLockMain()) and
    type == XArchiveConfigs.MonsterDetailType.Synopsis or
    type == XArchiveConfigs.MonsterDetailType.ScreenShot or
    type == XArchiveConfigs.MonsterDetailType.Zoom)

    self.PanelDragMid.gameObject:SetActiveEx(
    type ~= XArchiveConfigs.MonsterDetailType.Skill and
    type ~= XArchiveConfigs.MonsterDetailType.Setting)

    self.PanelDragLeft.gameObject:SetActiveEx(type == XArchiveConfigs.MonsterDetailType.Skill)

    self.PanelDragRight.gameObject:SetActiveEx(type == XArchiveConfigs.MonsterDetailType.Setting)

    self:PlayUIAnim(type)
end

function XUiArchiveMonsterDetail:PlayUIAnim(type)
    if type == XArchiveConfigs.MonsterDetailType.Synopsis then
        if self.IsInit then
            self:PlayAnimation("MonsterSynopsisEnable")
            self.IsInit = false
        else
            self:PlayAnimation("MonsterSwitchEnable")
        end

    elseif type == XArchiveConfigs.MonsterDetailType.Info then
        self:PlayAnimation("MonsterInfoEnable")
    elseif type == XArchiveConfigs.MonsterDetailType.Setting then
        self:PlayAnimation("MonsterSetEnable")
    elseif type == XArchiveConfigs.MonsterDetailType.Skill then
        self:PlayAnimation("MonsterSkillEnable")
    elseif type == XArchiveConfigs.MonsterDetailType.ScreenShot then
        self:PlayAnimationWithMask("MonsterSwitchDisable", function()
            self.PanelMonsterSynopsis.gameObject:SetActiveEx(false)
        end)
    end
end

function XUiArchiveMonsterDetail:OnSliderCharacterHightChanged()
    local pos = self.CamNear[CameraType.Zoom].position
    self.CamNear[CameraType.Zoom].position = Vector3(pos.x, 1.7 - self.SliderCharacterHight.value, pos.z)
end

function XUiArchiveMonsterDetail:ResetScreenShot()
    self.BtnScreenShot.gameObject:SetActiveEx(true)
    self.BtnHide.gameObject:SetActiveEx(false)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self.BtnLensOut.gameObject:SetActiveEx(false)
    --self:UpdateModel(self.CurType)
end

function XUiArchiveMonsterDetail:OnBtnBackClick()
    if self.DetailType ~= XArchiveConfigs.MonsterDetailType.Synopsis then
        self:SelectDetailState(XArchiveConfigs.MonsterDetailType.Synopsis)
    else
        self:Close()
    end
end

function XUiArchiveMonsterDetail:OnBtnBackClick()
    if self.DetailType ~= XArchiveConfigs.MonsterDetailType.Synopsis then
        self:SelectDetailState(XArchiveConfigs.MonsterDetailType.Synopsis)
        self:ResetScreenShot()
    else
        self:Close()
    end
end

function XUiArchiveMonsterDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArchiveMonsterDetail:OnBtnScreenShotClick()
    self:SelectDetailState(XArchiveConfigs.MonsterDetailType.ScreenShot)
    self.BtnScreenShot.gameObject:SetActiveEx(false)
    self.BtnHide.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
    self.BtnLensOut.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
end

function XUiArchiveMonsterDetail:OnBtnHideClick()
    self:SelectDetailState(XArchiveConfigs.MonsterDetailType.Synopsis)
    self:ResetScreenShot()
end

function XUiArchiveMonsterDetail:OnBtnLensInClick()
    self:SelectDetailState(XArchiveConfigs.MonsterDetailType.ScreenShot)
    self.BtnLensIn.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
    self.BtnLensOut.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
end

function XUiArchiveMonsterDetail:OnBtnLensOutClick()
    self:SelectDetailState(XArchiveConfigs.MonsterDetailType.Zoom)
    self.BtnLensIn.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
    self.BtnLensOut.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
end

function XUiArchiveMonsterDetail:OnBtnNextClick()
    if self.NextIndex == 0 then
        return
    end
    XDataCenter.ArchiveManager.GetMonsterEvaluateFromSever(self.DataList[self.NextIndex]:GetNpcId(), function()
        XLuaUiManager.PopThenOpen("UiArchiveMonsterDetail", self.DataList, self.NextIndex, self.OperationType)
    end)
end

function XUiArchiveMonsterDetail:OnBtnLastClick()
    if self.PreviousIndex == 0 then
        return
    end
    XDataCenter.ArchiveManager.GetMonsterEvaluateFromSever(self.DataList[self.PreviousIndex]:GetNpcId(), function()
        XLuaUiManager.PopThenOpen("UiArchiveMonsterDetail", self.DataList, self.PreviousIndex, self.OperationType)
    end)
end

function XUiArchiveMonsterDetail:CheckNextMonsterAndPreMonster()
    self.NextIndex = self:CheckNext(self.MonsterIndex + 1)
    self.PreviousIndex = self:CheckPrevious(self.MonsterIndex - 1)

    if self.NextIndex == 0 then
        self.NextIndex = self:CheckNext(FirstIndex)
    end

    if self.PreviousIndex == 0 then
        self.PreviousIndex = self:CheckPrevious(#self.DataList)
    end
end

function XUiArchiveMonsterDetail:CheckNext(index)
    local next = 0
    for i = index, #self.DataList, 1 do
        local tmpData = self.DataList[i]
        if tmpData and not tmpData:GetIsLockMain() then
            next = i
            break
        end
    end
    return next
end

function XUiArchiveMonsterDetail:CheckPrevious(index)
    local previous = 0
    for i = index, FirstIndex, -1 do
        local tmpData = self.DataList[i]
        if tmpData and not tmpData:GetIsLockMain() then
            previous = i
            break
        end
    end
    return previous
end

function XUiArchiveMonsterDetail:UpdateMonsterUnlock()
    self.ArchiveMonsterSynopsis:RefreshBtnPracticeBossShow()
end