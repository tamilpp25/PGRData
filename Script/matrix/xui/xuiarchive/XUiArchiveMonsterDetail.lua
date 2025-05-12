local XUiArchiveMonsterSetting = require("XUi/XUiArchive/XUiArchiveMonsterSetting")
local XUiArchiveMonsterInfo = require("XUi/XUiArchive/XUiArchiveMonsterInfo")
local XUiArchiveMonsterSkill = require("XUi/XUiArchive/XUiArchiveMonsterSkill")
local XUiArchiveMonsterSynopsis = require("XUi/XUiArchive/XUiArchiveMonsterSynopsis")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiArchiveMonsterDetail = XLuaUiManager.Register(XLuaUi, "UiArchiveMonsterDetail")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiModelUtility = require("XUi/XUiCharacter/XUiModelUtility")

local tableInsert = table.insert
local Object = CS.UnityEngine.Object
local Vector3 = CS.UnityEngine.Vector3
-- local Dropdown = CS.UnityEngine.UI.Dropdown

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
    self.OperationType = XEnumConst.Archive.MonsterDetailUiType.Default
end

-- dataList : XArchiveMonsterEntity list
-- index : number
-- operationType : XEnumConst.Archive.MonsterDetailUiType
function XUiArchiveMonsterDetail:OnStart(dataList, index, operationType)
    if operationType == nil then operationType = XEnumConst.Archive.MonsterDetailUiType.Default end
    self.OperationType = operationType
    self.Data = dataList and dataList[index]
    self.DataList = dataList

    if not self.Data then
        return
    end

    self.MonsterIndex = index
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:Init()
    self._Control:ClearMonsterNewTag({ self.Data })
    -- if self.OperationType == XEnumConst.Archive.MonsterDetailUiType.Default then
    --     XDataCenter.ArchiveManager.ClearMonsterNewTag({ self.Data })
    -- end
end

function XUiArchiveMonsterDetail:Init()
    self.ArchiveMonsterSynopsis = XUiArchiveMonsterSynopsis.New(self.PanelMonsterSynopsis, self,self.Data, self)
    self.ArchiveMonsterInfo = XUiArchiveMonsterInfo.New(self.PanelMonsterIntro,self, self.Data, self)
    self.ArchiveMonsterSetting = XUiArchiveMonsterSetting.New(self.PanelMonsterSet,self, self.Data, self)
    self.ArchiveMonsterSkill = XUiArchiveMonsterSkill.New(self.PanelMonsterSkill, self,self.Data, self)
    self.IsInit = true
    self:InitScene3DRoot()
    self:SetButtonCallBack()
    self:InitTypeGroup()
    self:SelectDetailState(XEnumConst.Archive.MonsterDetailType.Synopsis)
    self:CheckNextMonsterAndPreMonster()
    self:InitUiDetailByOperationType(self.OperationType)
end

function XUiArchiveMonsterDetail:InitUiDetailByOperationType(operationType)
    self.ArchiveMonsterSynopsis.BtnEvaluate.gameObject:SetActiveEx(operationType == XEnumConst.Archive.MonsterDetailUiType.Default)
    self.ArchiveMonsterSynopsis.BtnGroupContent.gameObject:SetActiveEx(operationType == XEnumConst.Archive.MonsterDetailUiType.Default)
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
    if self.BtnStateWords then
        self.BtnStateWords.gameObject:SetActiveEx(false)
    end
end

function XUiArchiveMonsterDetail:InitTypeGroup()
    self.TypeBtn = {}
    self.ModelIds = {}
    self.NpcIdMap = {}
    self.ModelIdStateMap = {}
    self.MonsterSwitchItem.gameObject:SetActiveEx(false)
    self.CurType = 1
    local npcIds = self.Data:GetNpcId()
    if not XTool.IsTableEmpty(npcIds) then
        local index = 1
        for _, npcId in pairs(npcIds) do
            local modelIds = XMVCA.XArchive:GetMonsterModelIds(npcId)

            if not XTool.IsTableEmpty(modelIds) then
                for i, modelId in pairs(modelIds) do
                    local btn = Object.Instantiate(self.MonsterSwitchItem)
                    btn.gameObject:SetActiveEx(true)
                    btn.transform:SetParent(self.MonsterSwitch.transform, false)
                    local btncs = btn:GetComponent("XUiButton")
                    local name = "0" .. index
                    btncs:SetName(name or "Null")
                    index = index + 1
                    self.ModelIdStateMap[modelId] = i
                    self.NpcIdMap[modelId] = npcId
                    tableInsert(self.ModelIds, modelId)
                    tableInsert(self.TypeBtn, btncs)
                end
            end 
        end
    end
    self.MonsterSwitch:Init(self.TypeBtn, function(index) self:SelectType(index, true) end)
    self.MonsterSwitch:SelectIndex(self.CurType)
    self.MonsterSwitch.gameObject:SetActiveEx(#self.TypeBtn >= 2)
end

function XUiArchiveMonsterDetail:SelectType(index, IsUpdateNpcModel)
    self.CurType = index
    local npcId = self:GetNpcIdByIndex(index)
    if self.DetailType == XEnumConst.Archive.MonsterDetailType.Synopsis then
        self.ArchiveMonsterSynopsis:SelectType(index)
    elseif self.DetailType == XEnumConst.Archive.MonsterDetailType.Info then
        self.ArchiveMonsterInfo:SelectType(npcId)
    elseif self.DetailType == XEnumConst.Archive.MonsterDetailType.Setting then
        self.ArchiveMonsterSetting:SelectType(npcId)
    elseif self.DetailType == XEnumConst.Archive.MonsterDetailType.Skill then
        self.ArchiveMonsterSkill:SelectType(npcId)
    end
    if IsUpdateNpcModel then
        self:UpdateModel(index)
    end
end

function XUiArchiveMonsterDetail:GetNpcIdByIndex(index)
    if XTool.IsTableEmpty(self.ModelIds) or XTool.IsTableEmpty(self.NpcIdMap) then
        return nil
    end
    
    local modelId = self.ModelIds[index] or 0

    return self.NpcIdMap[modelId]
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

    
    local modelId = self.ModelIds[index] or 0
    local npcId = self.NpcIdMap[modelId]
    local npcState = self.ModelIdStateMap[modelId]
    
    XUiModelUtility.UpdateMonsterArchiveModel(self, self.RoleModelPanel, modelId, XModelManager.MODEL_UINAME.UiArchiveMonsterDetail, npcId, npcState, func)
end

function XUiArchiveMonsterDetail:SetCameraType(type)
    local camType = (type == XEnumConst.Archive.MonsterDetailType.ScreenShot) and
    XEnumConst.Archive.MonsterDetailType.Synopsis or type

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

    if type~=XEnumConst.Archive.MonsterDetailType.Synopsis and type ~= XEnumConst.Archive.MonsterDetailType.ScreenShot then
        self.ArchiveMonsterSynopsis:Close()
    end
    
    if type ~= XEnumConst.Archive.MonsterDetailType.Info then
        self.ArchiveMonsterInfo:Close()
    end
    if type ~= XEnumConst.Archive.MonsterDetailType.Setting then
        self.ArchiveMonsterSetting:Close()
    end
    if type ~= XEnumConst.Archive.MonsterDetailType.Skill then
        self.ArchiveMonsterSkill:Close()
    end

    self.TopControl.gameObject:SetActiveEx(type ~= XEnumConst.Archive.MonsterDetailType.ScreenShot and
    type ~= XEnumConst.Archive.MonsterDetailType.Zoom)

    self.PanelAsset.gameObject:SetActiveEx(type ~= XEnumConst.Archive.MonsterDetailType.ScreenShot and
    type ~= XEnumConst.Archive.MonsterDetailType.Zoom)

    self.PanelDragGroup.gameObject:SetActiveEx(not self.Data:GetIsLockMain())

    self.BtnRight.gameObject:SetActiveEx((not self.Data:GetIsLockMain()) and
    type == XEnumConst.Archive.MonsterDetailType.Synopsis or
    type == XEnumConst.Archive.MonsterDetailType.ScreenShot or
    type == XEnumConst.Archive.MonsterDetailType.Zoom)

    self.PanelDragMid.gameObject:SetActiveEx(
    type ~= XEnumConst.Archive.MonsterDetailType.Skill and
    type ~= XEnumConst.Archive.MonsterDetailType.Setting)

    self.PanelDragLeft.gameObject:SetActiveEx(type == XEnumConst.Archive.MonsterDetailType.Skill)

    self.PanelDragRight.gameObject:SetActiveEx(type == XEnumConst.Archive.MonsterDetailType.Setting)

    self:PlayUIAnim(type)
end

function XUiArchiveMonsterDetail:PlayUIAnim(type)
    if type == XEnumConst.Archive.MonsterDetailType.Synopsis then
        if self.IsInit then
            self:PlayAnimation("MonsterSynopsisEnable")
            self.IsInit = false
        else
            self:PlayAnimation("MonsterSwitchEnable")
        end

    elseif type == XEnumConst.Archive.MonsterDetailType.Info then
        self:PlayAnimation("MonsterInfoEnable")
    elseif type == XEnumConst.Archive.MonsterDetailType.Setting then
        self:PlayAnimation("MonsterSetEnable")
    elseif type == XEnumConst.Archive.MonsterDetailType.Skill then
        self:PlayAnimation("MonsterSkillEnable")
    elseif type == XEnumConst.Archive.MonsterDetailType.ScreenShot then
        self:PlayAnimationWithMask("MonsterSwitchDisable", function()
            self.ArchiveMonsterSynopsis:Close()
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
    if self.DetailType ~= XEnumConst.Archive.MonsterDetailType.Synopsis then
        self:SelectDetailState(XEnumConst.Archive.MonsterDetailType.Synopsis)
    else
        self:Close()
    end
end

function XUiArchiveMonsterDetail:OnBtnBackClick()
    if self.DetailType ~= XEnumConst.Archive.MonsterDetailType.Synopsis then
        self:SelectDetailState(XEnumConst.Archive.MonsterDetailType.Synopsis)
        self:ResetScreenShot()
    else
        self:Close()
    end
end

function XUiArchiveMonsterDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArchiveMonsterDetail:OnBtnScreenShotClick()
    self:SelectDetailState(XEnumConst.Archive.MonsterDetailType.ScreenShot)
    self.BtnScreenShot.gameObject:SetActiveEx(false)
    self.BtnHide.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
    self.BtnLensOut.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
end

function XUiArchiveMonsterDetail:OnBtnHideClick()
    self:SelectDetailState(XEnumConst.Archive.MonsterDetailType.Synopsis)
    self:ResetScreenShot()
end

function XUiArchiveMonsterDetail:OnBtnLensInClick()
    self:SelectDetailState(XEnumConst.Archive.MonsterDetailType.ScreenShot)
    self.BtnLensIn.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
    self.BtnLensOut.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
end

function XUiArchiveMonsterDetail:OnBtnLensOutClick()
    self:SelectDetailState(XEnumConst.Archive.MonsterDetailType.Zoom)
    self.BtnLensIn.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
    self.BtnLensOut.gameObject:SetActiveEx(false)--模型精度不够，暂关闭
end

function XUiArchiveMonsterDetail:OnBtnNextClick()
    if self.NextIndex == 0 then
        return
    end
    XMVCA.XArchive:GetMonsterEvaluateFromSever(self.DataList[self.NextIndex]:GetNpcId(), function()
        XLuaUiManager.PopThenOpen("UiArchiveMonsterDetail", self.DataList, self.NextIndex, self.OperationType)
    end)
end

function XUiArchiveMonsterDetail:OnBtnLastClick()
    if self.PreviousIndex == 0 then
        return
    end
    XMVCA.XArchive:GetMonsterEvaluateFromSever(self.DataList[self.PreviousIndex]:GetNpcId(), function()
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