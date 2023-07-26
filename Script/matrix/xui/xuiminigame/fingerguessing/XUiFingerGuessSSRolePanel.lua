--选择关卡界面角色展示面板
local XUiFingerGuessSSRolePanel = XClass(nil, "XUiFingerGuessSSRolePanel")
local INITIAL_NAME_STR = "ENEMY_NAME"
--================
--构造函数
--================
function XUiFingerGuessSSRolePanel:Ctor(gameObject, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, gameObject)
    self:InitPanel()
end
--================
--初始化面板
--================
function XUiFingerGuessSSRolePanel:InitPanel()
    self.RImgHero:SetRawImage(self.RootUi.GameController:GetHeroImage())
    self.TxtHeroName.text = self.RootUi.GameController:GetHeroName()
    self.TxtEnemyName.text = INITIAL_NAME_STR
end
--================
--选择关卡时
--================
function XUiFingerGuessSSRolePanel:OnStageSelected()
    self.TxtEnemyName.text = self.RootUi.StageSelected:GetStageName()
    self.RImgEnemy:SetRawImage(self.RootUi.StageSelected:GetRobotImage())
end

return XUiFingerGuessSSRolePanel