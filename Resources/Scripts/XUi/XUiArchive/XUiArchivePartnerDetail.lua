local XUiArchivePartnerDetail = XLuaUiManager.Register(XLuaUi, "UiArchivePartnerDetail")
local tableInsert = table.insert
local Object = CS.UnityEngine.Object
local Vector3 = CS.UnityEngine.Vector3
local Dropdown = CS.UnityEngine.UI.Dropdown

local FirstIndex = 1
local CSUnityEngineGameObject = CS.UnityEngine.GameObject
function XUiArchivePartnerDetail:OnEnable()

end

function XUiArchivePartnerDetail:OnDisable()
    self.RoleModelPanel:HideAllEffects()
end

function XUiArchivePartnerDetail:OnStart(dataList, index)
    self.Data = dataList and dataList[index]
    self.DataList = dataList

    if not self.Data then
        return
    end
    
    self.ModelEffect = {}
    self.CurPartnerState = XPartnerConfigs.PartnerState.Standby
    self.PartnerIndex = index
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:Init()

end

function XUiArchivePartnerDetail:Init()
    self.MosterEffects = {}
    self:InitScene3DRoot()
    self:SetButtonCallBack()
    self:UpdateRoleModel(self.Data:GetStandbyModel(), self.Data, true)
    self:UpdateCamera()
    self:CheckNextPartnerAndPrePartner()
    self:UpdatePartnerInfo()
end

function XUiArchivePartnerDetail:InitScene3DRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")

    self.CameraFar = {
        [XPartnerConfigs.CameraType.Standby] = root:FindTransform("UiCamFarStandby"),
        [XPartnerConfigs.CameraType.Combat] = root:FindTransform("UiCamFarCombat"),
    }
    self.CameraNear = {
        [XPartnerConfigs.CameraType.Standby] = root:FindTransform("UiCamNearStandby"),
        [XPartnerConfigs.CameraType.Combat] = root:FindTransform("UiCamNearCombat"),
    }

    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiArchivePartnerDetail:SetButtonCallBack()
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
    self.BtnNext.CallBack = function()
        self:OnBtnNextClick()
    end
    self.BtnLast.CallBack = function()
        self:OnBtnLastClick()
    end
    self.BtnStandby.CallBack = function()
        self:OnBtnStandbyClick()
    end
    self.BtnCombat.CallBack = function()
        self:OnBtnCombatClick()
    end
    self.BtnMoveStroy.CallBack = function()
        self:OnBtnMoveStroyClick()
    end

end

function XUiArchivePartnerDetail:DoPartnerStateChange(state)
    if state == self.CurPartnerState then
        return
    end

    local partner = self.Data

    XLuaUiManager.SetMask(true)
    local closeMask = function()
        XLuaUiManager.SetMask(false)
    end

    if self:IsPartnerStandby() then

        local voiceId = partner:GetSToCVoice()
        if voiceId and voiceId > 0 then
            XSoundManager.PlaySoundByType(voiceId, XSoundManager.SoundType.Sound)
        end

        self.CurPartnerState = state
        self:UpdateCamera()
        self.RoleModelPanel:LoadEffect(partner:GetSToCEffect(), "ModelOffEffect", true, true)
        self:PlayPartnerAnima(partner:GetSToCAnime(), true, function ()
                self:UpdateRoleModel(partner:GetCombatModel(), partner, false)
                self.RoleModelPanel:LoadEffect(partner:GetCombatBornEffect(), "ModelOnEffect", true, true)
                self:PlayPartnerAnima(partner:GetCombatBornAnime(), true, closeMask)
            end)

    elseif self:IsPartnerCombat() then

        local voiceId = partner:GetCToSVoice()
        if voiceId and voiceId > 0 then
            XSoundManager.PlaySoundByType(voiceId, XSoundManager.SoundType.Sound)
        end
        self.RoleModelPanel:LoadEffect(partner:GetCToSEffect(), "ModelOnEffect", true, true)
        self:PlayPartnerAnima(partner:GetCToSAnime(), true, function ()
                self.CurPartnerState = state
                self:UpdateCamera()
                self:UpdateRoleModel(partner:GetStandbyModel(), partner, false)
                self.RoleModelPanel:LoadEffect(partner:GetStandbyBornEffect(), "ModelOffEffect", true, true)
                self:PlayPartnerAnima(partner:GetStandbyBornAnime(), true, closeMask)
            end)

    else
        closeMask()
    end
end

function XUiArchivePartnerDetail:PlayPartnerAnima(animaName, fromBegin, callBack)
    local IsCanPlay = self.RoleModelPanel:PlayAnima(animaName, fromBegin, callBack)
    if not IsCanPlay then
        if callBack then callBack() end
    end
end

--更新模型
function XUiArchivePartnerDetail:UpdateRoleModel(modelId, partner, IsShowEffect)
    self.RoleModelPanel:UpdatePartnerModel(modelId, XModelManager.MODEL_UINAME.XUiPartnerMain, nil, function(model)
            self.PanelDrag.Target = model.transform
            if IsShowEffect then
                self.ImgEffectHuanren.gameObject:SetActiveEx(false)
                self.ImgEffectHuanren.gameObject:SetActiveEx(true)
            end
        end, false, true)

end

function XUiArchivePartnerDetail:SetCameraType(type)
    for k, _ in pairs(self.CameraFar) do
        self.CameraFar[k].gameObject:SetActiveEx(k == type)
    end

    for k, _ in pairs(self.CameraNear) do
        self.CameraNear[k].gameObject:SetActiveEx(k == type)
    end
end

function XUiArchivePartnerDetail:UpdateCamera()
    if self:IsPartnerCombat() then
        self:SetCameraType(XPartnerConfigs.CameraType.Combat)
    elseif self:IsPartnerStandby() then
        self:SetCameraType(XPartnerConfigs.CameraType.Standby)
    end
end

function XUiArchivePartnerDetail:UpdatePartnerInfo()
    local storyId = self.Data:GetStoryId()
    self.PartnerNameText.text = self.Data:GetOriginalName()
    
    if not string.IsNilOrEmpty(storyId) then
        self.BtnMoveStroy:SetName(self.Data:GetStoryTitle())
        self.BtnMoveStroy.gameObject:SetActiveEx(true)
    else
        self.BtnMoveStroy.gameObject:SetActiveEx(false)
    end
    
    self:UpdatePartnerStory()
    self:UpdatePartnerSetting()
end

function XUiArchivePartnerDetail:UpdatePartnerStory()
    local storyDataList = self.Data:GetStoryEntityList()
    local storyObjList = {
        self.PartnerStory:GetObject("GridStory1"),
        self.PartnerStory:GetObject("GridStory2"),
        self.PartnerStory:GetObject("GridStory3"),
        self.PartnerStory:GetObject("GridStory4"),
        self.PartnerStory:GetObject("GridStory5")
        }
    
    for index,grid in pairs(storyObjList or {}) do
        if storyDataList[index] then
            grid.gameObject:SetActiveEx(true)
            self:UpdateGrid(storyDataList[index],grid)
        else
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiArchivePartnerDetail:UpdatePartnerSetting()
    local IsEmpty = true
    local settingDataList = self.Data:GetSettingEntityList()
    local settingObjList = {
        self.PartnerSetting:GetObject("GridSetting1"),
        self.PartnerSetting:GetObject("GridSetting2"),
        self.PartnerSetting:GetObject("GridSetting3"),
        self.PartnerSetting:GetObject("GridSetting4"),
        self.PartnerSetting:GetObject("GridSetting5")
    }
    
    for index,grid in pairs(settingObjList or {}) do
        if settingDataList[index] then
            grid.gameObject:SetActiveEx(true)
            self:UpdateGrid(settingDataList[index],grid)
            IsEmpty = false
        else
            grid.gameObject:SetActiveEx(false)
        end
    end
    
    self.PartnerSetting:GetObject("PanelNoSetting").gameObject:SetActiveEx(IsEmpty)
end

function XUiArchivePartnerDetail:UpdateGrid(data,grid)
    if not data:GetIsLock() then
        grid:GetObject("TxtTitle").text = data:GetTitle()
        grid:GetObject("TxtContent").text = string.gsub(data:GetText(), "\\n", "\n")
    else
        grid:GetObject("TxtLockContent").text = data:GetConditionDesc()
    end
    grid:GetObject("PanelUnlock").gameObject:SetActiveEx(not data:GetIsLock())
    grid:GetObject("PanelLock").gameObject:SetActiveEx(data:GetIsLock())
end

function XUiArchivePartnerDetail:IsPartnerStandby()
    return self.CurPartnerState == XPartnerConfigs.PartnerState.Standby
end

function XUiArchivePartnerDetail:IsPartnerCombat()
    return self.CurPartnerState == XPartnerConfigs.PartnerState.Combat
end

function XUiArchivePartnerDetail:OnBtnBackClick()
    if self.IsHide then
        return
    end
    self:Close()
end

function XUiArchivePartnerDetail:OnBtnMainUiClick()
    if self.IsHide then
        return
    end
    XLuaUiManager.RunMain()
end

function XUiArchivePartnerDetail:OnBtnScreenShotClick()
    self.IsHide = true
    self.BtnScreenShot.gameObject:SetActiveEx(false)
    self.BtnHide.gameObject:SetActiveEx(true)
    self.AssetPanel.GameObject:SetActiveEx(false)
    self:PlayAnimation("UiDisable")
end

function XUiArchivePartnerDetail:OnBtnHideClick()
    self.IsHide = false
    self.BtnScreenShot.gameObject:SetActiveEx(true)
    self.BtnHide.gameObject:SetActiveEx(false)
    self.AssetPanel.GameObject:SetActiveEx(true)
    self:PlayAnimation("UiEnable")
end

function XUiArchivePartnerDetail:OnBtnStandbyClick()
    self:DoPartnerStateChange(XPartnerConfigs.PartnerState.Standby)
end

function XUiArchivePartnerDetail:OnBtnCombatClick()
    self:DoPartnerStateChange(XPartnerConfigs.PartnerState.Combat)
end

function XUiArchivePartnerDetail:OnBtnMoveStroyClick()
    if self.IsHide then
       return 
    end
    
    local storyId = self.Data:GetStoryId()
    
    if not string.IsNilOrEmpty(storyId) then
        XDataCenter.MovieManager.PlayMovie(storyId)
    end
end

function XUiArchivePartnerDetail:OnBtnNextClick()
    if self.NextIndex == 0 then
        return
    end
    XLuaUiManager.PopThenOpen("UiArchivePartnerDetail", self.DataList, self.NextIndex)
end

function XUiArchivePartnerDetail:OnBtnLastClick()
    if self.PreviousIndex == 0 then
        return
    end
    XLuaUiManager.PopThenOpen("UiArchivePartnerDetail", self.DataList, self.PreviousIndex)
end

function XUiArchivePartnerDetail:CheckNextPartnerAndPrePartner()
    self.NextIndex = self:CheckNext(self.PartnerIndex + 1)
    self.PreviousIndex = self:CheckPrevious(self.PartnerIndex - 1)

    if self.NextIndex == 0 then
        self.NextIndex = self:CheckNext(FirstIndex)
    end

    if self.PreviousIndex == 0 then
        self.PreviousIndex = self:CheckPrevious(#self.DataList)
    end
end

function XUiArchivePartnerDetail:CheckNext(index)
    local next = 0
    for i = index , #self.DataList , 1 do
        local tmpData = self.DataList[i]
        if tmpData and not tmpData:GetIsArchiveLock() then
            next = i
            break
        end
    end
    return next
end

function XUiArchivePartnerDetail:CheckPrevious(index)
    local previous = 0
    for i = index , FirstIndex , -1 do
        local tmpData = self.DataList[i]
        if tmpData and not tmpData:GetIsArchiveLock() then
            previous = i
            break
        end
    end
    return previous
end