local XUiSceneSettingObtain=XLuaUiManager.Register(XLuaUi,'UiSceneSettingObtain')

local XSceneObtainGrid=require('XUi/XUiSceneSettingObtain/XSceneObtainGrid')

--region 生命周期
function XUiSceneSettingObtain:OnAwake()
    self:InitCb()
    self.ObtainGridCtrl=XSceneObtainGrid.New(self.GridFashion)
end

function XUiSceneSettingObtain:OnStart(rewardInfo)
    local rewardSceneId = rewardInfo.BackgroundId
    self.RewardSceneId = rewardSceneId
    self.GridFashion.gameObject:SetActiveEx(false)
    local template=XDataCenter.PhotographManager.GetSceneTemplateById(rewardSceneId)
    self.TxtDesc.text=XUiHelper.GetText('SceneSettingObtain',template.Name)
    self:Refresh(rewardSceneId,template)
end

function XUiSceneSettingObtain:OnEnable()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Common_UiObtain)

    local isBackgroundRandom = XDataCenter.PhotographManager.GetIsRandomBackground()
    self.BtnWear.gameObject:SetActiveEx(not isBackgroundRandom)
    self.BtnAddRandomBackground.gameObject:SetActiveEx(isBackgroundRandom)
end
--endregion

--region 初始化
function XUiSceneSettingObtain:InitCb()
    self:RegisterClickEvent(self.BtnClose, function() self:Close() end)
    self.BtnWear.CallBack = function() self:OnBtnWearClick() end
    self.BtnAddRandomBackground.CallBack = function() self:OnBtnAddRandomBackgroundClick() end
end

function XUiSceneSettingObtain:OnBtnWearClick()
    self:Close()

    --执行同步
    local curChara = XDataCenter.DisplayManager.GetDisplayChar()
    XDataCenter.PhotographManager.ChangeDisplay(self.RewardSceneId, curChara.Id, curChara.FashionId, function ()
        XUiManager.TipText("PhotoModeChangeSuccess")    
    end)
end

function XUiSceneSettingObtain:OnBtnAddRandomBackgroundClick()
    XDataCenter.PhotographManager.AddRandomBackgroundRequest(self.RewardSceneId, function ()
        XDataCenter.PhotographManager.RemoveNewSceneTempData(self.RewardSceneId)
        self:Close()
    end)
end
--endregion

function XUiSceneSettingObtain:Refresh(sceneId, template)
    self.ObtainGridCtrl:Refresh(sceneId, template)
end

function XUiSceneSettingObtain:Close()
    self:EmitSignal("Close")
    XUiSceneSettingObtain.Super.Close(self)
end


return XUiSceneSettingObtain