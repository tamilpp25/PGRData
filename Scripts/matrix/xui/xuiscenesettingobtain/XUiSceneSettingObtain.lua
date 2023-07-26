local XUiSceneSettingObtain=XLuaUiManager.Register(XLuaUi,'UiSceneSettingObtain')

local XSceneObtainGrid=require('XUi/XUiSceneSettingObtain/XSceneObtainGrid')

--region 生命周期
function XUiSceneSettingObtain:OnAwake()
    self:InitCb()
    self.ObtainGridCtrl=XSceneObtainGrid.New(self.GridFashion)
end

function XUiSceneSettingObtain:OnStart(rewardInfo)
    local rewardSceneId=rewardInfo.BackgroundId
    self.RewardSceneId=rewardSceneId
    self.GridFashion.gameObject:SetActiveEx(false)
    local template=XDataCenter.PhotographManager.GetSceneTemplateById(rewardSceneId)
    self.TxtDesc.text=XUiHelper.GetText('SceneSettingObtain',template.Name)
    self:Refresh(rewardSceneId,template)
end

function XUiSceneSettingObtain:OnEnable()
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Common_UiObtain)
end
--endregion

--region 初始化
function XUiSceneSettingObtain:InitCb()
    self:RegisterClickEvent(self.BtnClose, function() self:Close() end)
    self.BtnWear.CallBack=function() 
        --前往场景切换设置界面，且默认首选该场景
        local UiMainMenuMain=1
        self:Close()
        XLuaUiManager.Open('UiSceneSettingMain',UiMainMenuMain,self.RewardSceneId)
    end
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